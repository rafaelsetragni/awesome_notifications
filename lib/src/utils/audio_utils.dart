import 'package:awesome_notifications/src/utils/media_abstract_utils.dart';
import 'package:flutter/material.dart';

class AudioUtils extends MediaUtils {
  /// FACTORY METHODS *********************************************

  factory AudioUtils() => _instance;

  @visibleForTesting
  AudioUtils.private();

  static final AudioUtils _instance = AudioUtils.private();

  /// FACTORY METHODS *********************************************

  @override
  getFromMediaAsset(String mediaPath) {
    return null;

    /// TODO MISSING IMPLEMENTATION
  }

  @override
  getFromMediaFile(String mediaPath) {
    return null;

    /// TODO MISSING IMPLEMENTATION
  }

  @override
  getFromMediaNetwork(String mediaPath) {
    return null;

    /// TODO MISSING IMPLEMENTATION
  }

  @override
  getFromMediaResource(String mediaPath) {
    return null;

    /// TODO MISSING IMPLEMENTATION
    /*
        String cleanPath = BitmapUtils.cleanMediaPath(mediaPath);
        rootBundle.loadString(cleanPath).then((value){
          print(value);
        });
        break;
        */
  }
}
