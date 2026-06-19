import 'dart:ui' as ui show Codec;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../awesome_notifications.dart';

/// Decodes the given [Uint8List] buffer as an image, associating it with the
/// given scale.
///
/// The provided [bytes] buffer should not be changed after it is provided
/// to a [ResourceImage]. To provide an [ImageStream] that represents an image
/// that changes over time, consider creating a new subclass of [ImageProvider]
/// whose [loadImage] method returns a subclass of [ImageStreamCompleter] that can
/// handle providing multiple images.
///
/// See also:
///
///  * [Image.memory] for a shorthand of an [Image] widget backed by [ResourceImage].
class ResourceImage extends ImageProvider<ResourceImage> {
  /// Creates an object that decodes a [Uint8List] buffer as an image.
  ///
  /// The arguments must not be null.
  const ResourceImage(this.drawablePath,
      {this.scale = 1.0, AwesomeNotifications? awesomeNotifications})
      : _awesomeNotifications = awesomeNotifications;

  final String drawablePath;
  final AwesomeNotifications? _awesomeNotifications;

  /// The scale to place in the [ImageInfo] object of the image.
  final double scale;

  @override
  Future<ResourceImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<ResourceImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(
      ResourceImage key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: loadAsync(key, decode),
      scale: key.scale,
    );
  }

  @visibleForTesting
  Future<ui.Codec> loadAsync(
      ResourceImage key, ImageDecoderCallback decode) async {
    assert(key == this);
    Uint8List? bytes = await (_awesomeNotifications ?? AwesomeNotifications())
        .getDrawableData(drawablePath);

    if ((bytes?.lengthInBytes ?? 0) == 0) {
      throw const AwesomeNotificationsException(message: 'image is invalid');
    }

    final ImmutableBuffer buffer = await ImmutableBuffer.fromUint8List(bytes!);
    final ImageDescriptor descriptor = await ImageDescriptor.encoded(buffer);

    buffer.dispose();
    return descriptor.instantiateCodec();
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is ResourceImage &&
        other.drawablePath == drawablePath &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(drawablePath.hashCode, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'ResourceImage')}($drawablePath, scale: $scale)';
}
