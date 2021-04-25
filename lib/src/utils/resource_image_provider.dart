import 'dart:typed_data';
import 'dart:ui' as ui show Codec;

import 'package:awesome_notifications/src/awesome_notifications_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Decodes the given [Uint8List] buffer as an image, associating it with the
/// given scale.
///
/// The provided [bytes] buffer should not be changed after it is provided
/// to a [ResourceImage]. To provide an [ImageStream] that represents an image
/// that changes over time, consider creating a new subclass of [ImageProvider]
/// whose [load] method returns a subclass of [ImageStreamCompleter] that can
/// handle providing multiple images.
///
/// See also:
///
///  * [Image.memory] for a shorthand of an [Image] widget backed by [ResourceImage].
class ResourceImage extends ImageProvider<ResourceImage> {
  /// Creates an object that decodes a [Uint8List] buffer as an image.
  ///
  /// The arguments must not be null.
  const ResourceImage(this.drawablePath, {this.scale = 1.0});

  final String drawablePath;

  /// The scale to place in the [ImageInfo] object of the image.
  final double scale;

  @override
  Future<ResourceImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<ResourceImage>(this);
  }

  @override
  ImageStreamCompleter load(ResourceImage key, DecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
    );
  }

  Future<ui.Codec> _loadAsync(ResourceImage key, DecoderCallback decode) async {
    assert(key == this);
    Uint8List? bytes;

    AwesomeNotifications awesomeNotifications = AwesomeNotifications();
    bytes = await awesomeNotifications.getDrawableData(this.drawablePath);

    return decode(bytes!);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is ResourceImage &&
        other.drawablePath == drawablePath &&
        other.scale == scale;
  }

  @override
  int get hashCode => hashValues(drawablePath.hashCode, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'ResourceImage')}($drawablePath, scale: $scale)';
}
