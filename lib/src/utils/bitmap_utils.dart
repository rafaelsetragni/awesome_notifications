import 'dart:io';

import 'package:flutter/material.dart';

import 'package:awesome_notifications/src/utils/media_abstract_utils.dart';
import 'package:awesome_notifications/src/utils/resource_image_provider.dart';

class BitmapUtils extends MediaUtils {

  /// FACTORY METHODS *********************************************

  factory BitmapUtils() => _instance;

  @visibleForTesting
  BitmapUtils.private();

  static final BitmapUtils _instance = BitmapUtils.private();

  /// FACTORY METHODS *********************************************

  @override
  getFromMediaAsset(String mediaPath) {
    return AssetImage(cleanMediaPath(mediaPath));
  }

  @override
  getFromMediaFile(String mediaPath) {
    return FileImage(File(cleanMediaPath(mediaPath)));
  }

  @override
  getFromMediaNetwork(String mediaPath) {
    return NetworkImage(mediaPath);
  }

  @override
  getFromMediaResource(String mediaPath) {
    return ResourceImage(mediaPath);
  }
}
