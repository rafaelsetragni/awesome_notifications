import 'package:awesome_notifications/src/enumerators/media_source.dart';
import 'package:awesome_notifications/src/utils/resource_image.dart';
import 'package:flutter/material.dart';

// File-backed images depend on dart:io, which is unavailable on the web. The
// conditional import swaps in a web stub (loadFileImage -> null) so the core
// stays web-safe without duplicating this whole class per platform.
import 'package:awesome_notifications/src/utils/image_file_loader.dart'
    if (dart.library.html)
        'package:awesome_notifications/src/utils/image_file_loader_web.dart';

/// Resolves notification media paths (asset/file/network/resource) into Flutter
/// [ImageProvider]s. This is the only media helper the core needs; audio and
/// rich-media handling belong to their decorator packages.
class AwesomeBitmapUtils {
  factory AwesomeBitmapUtils() => _instance;

  @visibleForTesting
  AwesomeBitmapUtils.private();

  static final AwesomeBitmapUtils _instance = AwesomeBitmapUtils.private();

  /// Classifies a media path by its scheme prefix.
  MediaSource getMediaSource(String? mediaPath) {
    if (mediaPath != null) {
      if (RegExp(r'^https?:\/\/').hasMatch(mediaPath)) {
        return MediaSource.Network;
      }

      if (RegExp(r'^file:\/\/').hasMatch(mediaPath)) {
        return MediaSource.File;
      }

      if (RegExp(r'^asset:\/\/').hasMatch(mediaPath)) {
        return MediaSource.Asset;
      }

      if (RegExp(r'^resource:\/\/').hasMatch(mediaPath)) {
        return MediaSource.Resource;
      }
    }
    return MediaSource.Unknown;
  }

  /// Strips the scheme prefix from a media path.
  String cleanMediaPath(String mediaPath) {
    if (RegExp(r'^file:\/\/').hasMatch(mediaPath)) {
      return mediaPath.replaceAll(RegExp(r'file:\/'), '');
    }
    if (RegExp(r'^asset:\/\/').hasMatch(mediaPath)) {
      return mediaPath.replaceAll(RegExp(r'asset:\/\/'), '');
    }
    if (RegExp(r'^resource:\/\/').hasMatch(mediaPath)) {
      return mediaPath.replaceAll(RegExp(r'resource:\/\/'), '');
    }
    return mediaPath;
  }

  ImageProvider getFromMediaAsset(String mediaPath) =>
      AssetImage(cleanMediaPath(mediaPath));

  ImageProvider? getFromMediaFile(String mediaPath) =>
      loadFileImage(cleanMediaPath(mediaPath));

  ImageProvider getFromMediaNetwork(String mediaPath) => NetworkImage(mediaPath);

  ImageProvider getFromMediaResource(String mediaPath) =>
      ResourceImage(mediaPath);

  /// Resolves any supported media path into an [ImageProvider], or `null` when
  /// the scheme is unknown (or unavailable on the current platform).
  ImageProvider? getFromMediaPath(String mediaPath) {
    switch (getMediaSource(mediaPath)) {
      case MediaSource.Asset:
        return getFromMediaAsset(mediaPath);

      case MediaSource.File:
        return getFromMediaFile(mediaPath);

      case MediaSource.Network:
        return getFromMediaNetwork(mediaPath);

      case MediaSource.Resource:
        return getFromMediaResource(mediaPath);

      case MediaSource.Unknown:
        return null;
    }
  }
}
