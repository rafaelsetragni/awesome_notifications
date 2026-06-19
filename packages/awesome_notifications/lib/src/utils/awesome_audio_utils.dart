import 'package:awesome_notifications/src/utils/awesome_media_utils.dart'
    if (dart.library.html) 'package:awesome_notifications/src/utils/awesome_media_utils_web.dart';
import 'package:flutter/material.dart';

class AwesomeAudioUtils extends AwesomeMediaUtils {
  /// FACTORY METHODS *********************************************

  factory AwesomeAudioUtils() => _instance;

  @visibleForTesting
  AwesomeAudioUtils.private();

  static final AwesomeAudioUtils _instance = AwesomeAudioUtils.private();

  /// FACTORY METHODS *********************************************

  @override
  ImageProvider? getFromMediaAsset(String mediaPath) {
    return null;

    /// TODO MISSING IMPLEMENTATION
  }

  @override
  ImageProvider? getFromMediaFile(String mediaPath) {
    return null;

    /// TODO MISSING IMPLEMENTATION
  }

  @override
  ImageProvider? getFromMediaNetwork(String mediaPath) {
    return null;

    /// TODO MISSING IMPLEMENTATION
  }

  @override
  ImageProvider? getFromMediaResource(String mediaPath) {
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
