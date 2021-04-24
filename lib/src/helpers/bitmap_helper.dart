import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

const int bitmapPixelLength = 4;
const int RGBA32HeaderSize = 122;

///
/// EXTRACTED FROM bitmap: ^0.0.6 DUE TO BUILD GRADLE INCOMPATIBILITIES
///
class BitmapHelper {
  BitmapHelper.fromHeadless(this.width, this.height, this.content);

  BitmapHelper.fromHeadful(this.width, this.height, Uint8List headedIntList)
      : content = headedIntList.sublist(
          RGBA32HeaderSize,
          headedIntList.length,
        );

  BitmapHelper.blank(
    this.width,
    this.height,
  ) : content = Uint8List.fromList(
          List.filled(width * height * bitmapPixelLength, 0),
        );

  final int width;
  final int height;
  final Uint8List content;

  int get size => (width * height) * bitmapPixelLength;

  BitmapHelper cloneHeadless() {
    return BitmapHelper.fromHeadless(
      width,
      height,
      Uint8List.fromList(content),
    );
  }

  static Future<BitmapHelper> fromProvider(ImageProvider provider) async {
    final Completer completer = Completer<ImageInfo>();
    final ImageStream stream = provider.resolve(const ImageConfiguration());
    final listener =
        ImageStreamListener((ImageInfo info, bool synchronousCall) {
      if (!completer.isCompleted) {
        completer.complete(info);
      }
    });
    stream.addListener(listener);
    final imageInfo = await completer.future;
    final ui.Image image = imageInfo.image;
    final ByteData? byteData = await image.toByteData();
    final Uint8List listInt = byteData!.buffer.asUint8List();

    return BitmapHelper.fromHeadless(image.width, image.height, listInt);
  }

  Future<ui.Image> buildImage() async {
    final Completer<ui.Image> imageCompleter = Completer();
    final headedContent = buildHeaded();
    ui.decodeImageFromList(headedContent, (ui.Image img) {
      imageCompleter.complete(img);
    });
    return imageCompleter.future;
  }

  Uint8List buildHeaded() {
    final header = RGBA32BitmapHeader(size, width, height)
      ..applyContent(content);
    return header.headerIntList;
  }
}

class RGBA32BitmapHeader {
  RGBA32BitmapHeader(this.contentSize, int width, int height) {
    headerIntList = Uint8List(fileLength);

    final ByteData bd = headerIntList.buffer.asByteData();
    bd.setUint8(0x0, 0x42);
    bd.setUint8(0x1, 0x4d);
    bd.setInt32(0x2, fileLength, Endian.little);
    bd.setInt32(0xa, RGBA32HeaderSize, Endian.little);
    bd.setUint32(0xe, 108, Endian.little);
    bd.setUint32(0x12, width, Endian.little);
    bd.setUint32(0x16, -height, Endian.little);
    bd.setUint16(0x1a, 1, Endian.little);
    bd.setUint32(0x1c, 32, Endian.little); // pixel size
    bd.setUint32(0x1e, 3, Endian.little); //BI_BITFIELDS
    bd.setUint32(0x22, contentSize, Endian.little);
    bd.setUint32(0x36, 0x000000ff, Endian.little);
    bd.setUint32(0x3a, 0x0000ff00, Endian.little);
    bd.setUint32(0x3e, 0x00ff0000, Endian.little);
    bd.setUint32(0x42, 0xff000000, Endian.little);
  }

  int contentSize;

  void applyContent(Uint8List contentIntList) {
    headerIntList.setRange(
      RGBA32HeaderSize,
      fileLength,
      contentIntList,
    );
  }

  late Uint8List headerIntList;

  int get fileLength => contentSize + RGBA32HeaderSize;
}
