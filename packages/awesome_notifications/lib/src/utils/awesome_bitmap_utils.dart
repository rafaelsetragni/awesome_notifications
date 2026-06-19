import 'package:awesome_notifications/src/utils/awesome_media_utils.dart'
    if (dart.library.html) 'package:awesome_notifications/src/utils/awesome_media_utils_web.dart';
import 'package:awesome_notifications/src/utils/resource_image.dart';
import 'package:flutter/material.dart';

class AwesomeBitmapUtils extends AwesomeMediaUtils {
  /// FACTORY METHODS *********************************************

  factory AwesomeBitmapUtils() => _instance;

  @visibleForTesting
  AwesomeBitmapUtils.private();

  static final AwesomeBitmapUtils _instance = AwesomeBitmapUtils.private();

  /// FACTORY METHODS *********************************************

  @override
  ImageProvider getFromMediaAsset(String mediaPath) {
    return AssetImage(cleanMediaPath(mediaPath));
  }

  @override
  ImageProvider getFromMediaNetwork(String mediaPath) {
    return NetworkImage(mediaPath);
  }

  @override
  ImageProvider getFromMediaResource(String mediaPath) {
    return ResourceImage(mediaPath);
  }
}
