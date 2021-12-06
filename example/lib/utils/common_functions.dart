import 'dart:ui';
import 'dart:io';

import 'dart:math' as math;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:device_info/device_info.dart';
import 'package:path_provider/path_provider.dart';

Future<String> saveAssetOnDisk(ImageProvider image, String fileName) async {
  Directory directory = await getApplicationDocumentsDirectory();
  String filePath = '${directory.path}/$fileName';
  File newFile = File(filePath);

  if (!await newFile.exists()) {
    BitmapHelper bitmapHelper = await BitmapHelper.fromProvider(image);
    await newFile.writeAsBytes(bitmapHelper.content);
  }

  return filePath;
}

void lockScreenPortrait(){
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

void unlockScreenPortrait(){
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

Future<String> getPlatformVersion() async {
  if (Platform.isAndroid) {
    var androidInfo = await DeviceInfoPlugin().androidInfo;
    var sdkInt = androidInfo.version.sdkInt;
    return 'Android-$sdkInt';
  }

  if (Platform.isIOS) {
    var iosInfo = await DeviceInfoPlugin().iosInfo;
    var systemName = iosInfo.systemName;
    var version = iosInfo.systemVersion;
    return '$systemName-$version';
  }

  return 'unknow';
}

String printDuration(Duration? duration) {
  if (duration == null) return '00:00';
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "$twoDigitMinutes:$twoDigitSeconds";
}

Future<String> downloadAndSaveImageOnDisk(String url, String fileName) async {
  var directory = await getApplicationDocumentsDirectory();
  var filePath = '${directory.path}/$fileName';
  var file = File(filePath);


  if(!await file.exists()){
    var response = await http.get(Uri.parse(url));
    await file.writeAsBytes(response.bodyBytes);
  }

  return filePath;
}

String fileSize(dynamic size, [int round = 2]) {
  /**
   * [size] can be passed as number or as string
   *
   * the optional parameter [round] specifies the number
   * of digits after comma/point (default is 2)
   */
  int divider = 1024;
  int _size;
  try {
    _size = int.parse(size.toString());
  } catch (e) {
    throw ArgumentError("Can not parse the size parameter: $e");
  }

  if (_size < divider) {
    return "$_size B";
  }

  if (_size < divider * divider && _size % divider == 0) {
    return "${(_size / divider).toStringAsFixed(0)} KB";
  }

  if (_size < divider * divider) {
    return "${(_size / divider).toStringAsFixed(round)} KB";
  }

  if (_size < divider * divider * divider && _size % divider == 0) {
    return "${(_size / (divider * divider)).toStringAsFixed(0)} MB";
  }

  if (_size < divider * divider * divider) {
    return "${(_size / divider / divider).toStringAsFixed(round)} MB";
  }

  if (_size < divider * divider * divider * divider && _size % divider == 0) {
    return "${(_size / (divider * divider * divider)).toStringAsFixed(0)} GB";
  }

  if (_size < divider * divider * divider * divider) {
    return "${(_size / divider / divider / divider).toStringAsFixed(round)} GB";
  }

  if (_size < divider * divider * divider * divider * divider &&
      _size % divider == 0) {
    num r = _size / divider / divider / divider / divider;
    return "${r.toStringAsFixed(0)} TB";
  }

  if (_size < divider * divider * divider * divider * divider) {
    num r = _size / divider / divider / divider / divider;
    return "${r.toStringAsFixed(round)} TB";
  }

  if (_size < divider * divider * divider * divider * divider * divider &&
      _size % divider == 0) {
    num r = _size / divider / divider / divider / divider / divider;
    return "${r.toStringAsFixed(0)} PB";
  } else {
    num r = _size / divider / divider / divider / divider / divider;
    return "${r.toStringAsFixed(round)} PB";
  }
}

Color getRandomColor() {
  return Color((math.Random().nextDouble() * 0xFFFFFF).toInt() << 0)
      .withOpacity(1.0);
}
