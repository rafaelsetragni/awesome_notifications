import 'package:awesome_notifications/src/enumerators/media_source.dart';
import 'package:flutter/material.dart';

abstract class MediaUtils {
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

  @protected
  getFromMediaAsset(String mediaPath);

  @protected
  getFromMediaFile(String mediaPath);

  @protected
  getFromMediaNetwork(String mediaPath);

  @protected
  getFromMediaResource(String mediaPath);

  getFromMediaPath(String mediaPath) {
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
      default:
        return null;
    }
  }
}
