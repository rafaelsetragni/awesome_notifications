import 'package:universal_io/io.dart' as uio;

import 'dart:math' as math;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';

Future<String> saveAssetOnDisk(ImageProvider image, String fileName) async {
  return '';
}

void lockScreenPortrait() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

void unlockScreenPortrait() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

Future<String> getPlatformVersion() async {
  if (uio.Platform.isAndroid) {
    var androidInfo = await DeviceInfoPlugin().androidInfo;
    var sdkInt = androidInfo.version.sdkInt;
    return 'Android-$sdkInt';
  }

  if (uio.Platform.isIOS) {
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

void loadSingletonPage(
  NavigatorState? navigatorState, {
  required String targetPage,
  required ReceivedAction receivedAction,
}) {
  // Avoid to open the notification details page over another details page already opened
  // Navigate into pages, avoiding to open the notification details page over another details page already opened
  navigatorState?.pushNamedAndRemoveUntil(
    targetPage,
    (route) => (route.settings.name != targetPage) || route.isFirst,
    arguments: receivedAction,
  );
}

Future<String> downloadAndSaveImageOnDisk(String url, String fileName) async {
  var directory = await getApplicationDocumentsDirectory();
  var filePath = '${directory.path}/$fileName';
  var file = uio.File(filePath);

  if (!await file.exists()) {
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
  int size0;
  try {
    size0 = int.parse(size.toString());
  } catch (e) {
    throw ArgumentError("Can not parse the size parameter: $e");
  }

  if (size0 < divider) {
    return "$size0 B";
  }

  if (size0 < divider * divider && size0 % divider == 0) {
    return "${(size0 / divider).toStringAsFixed(0)} KB";
  }

  if (size0 < divider * divider) {
    return "${(size0 / divider).toStringAsFixed(round)} KB";
  }

  if (size0 < divider * divider * divider && size0 % divider == 0) {
    return "${(size0 / (divider * divider)).toStringAsFixed(0)} MB";
  }

  if (size0 < divider * divider * divider) {
    return "${(size0 / divider / divider).toStringAsFixed(round)} MB";
  }

  if (size0 < divider * divider * divider * divider && size0 % divider == 0) {
    return "${(size0 / (divider * divider * divider)).toStringAsFixed(0)} GB";
  }

  if (size0 < divider * divider * divider * divider) {
    return "${(size0 / divider / divider / divider).toStringAsFixed(round)} GB";
  }

  if (size0 < divider * divider * divider * divider * divider &&
      size0 % divider == 0) {
    num r = size0 / divider / divider / divider / divider;
    return "${r.toStringAsFixed(0)} TB";
  }

  if (size0 < divider * divider * divider * divider * divider) {
    num r = size0 / divider / divider / divider / divider;
    return "${r.toStringAsFixed(round)} TB";
  }

  if (size0 < divider * divider * divider * divider * divider * divider &&
      size0 % divider == 0) {
    num r = size0 / divider / divider / divider / divider / divider;
    return "${r.toStringAsFixed(0)} PB";
  } else {
    num r = size0 / divider / divider / divider / divider / divider;
    return "${r.toStringAsFixed(round)} PB";
  }
}

Color getRandomColor() {
  return Color((math.Random().nextDouble() * 0xFFFFFF).toInt() << 0)
      .withOpacity(1.0);
}
