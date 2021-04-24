import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class CloseCaptionElement {
  Duration start;
  Duration end;
  String subtitle;

  CloseCaptionElement(this.start, this.end, this.subtitle);
}

class MediaModel {
  String _diskImagePath;

  bool isPlaying;

  final String bandName;
  final String trackName;
  final Duration trackSize;

  final Size colorCaptureSize;

  final List<CloseCaptionElement> closeCaption = [
    CloseCaptionElement(Duration(minutes: 0, seconds: 15),
        Duration(minutes: 0, seconds: 20), 'la la la la la la'),
    CloseCaptionElement(Duration(minutes: 0, seconds: 30),
        Duration(minutes: 0, seconds: 35), 'la la la la la la'),
    CloseCaptionElement(Duration(minutes: 0, seconds: 45),
        Duration(minutes: 0, seconds: 50), 'la la la la la la'),
    CloseCaptionElement(Duration(minutes: 1, seconds: 00),
        Duration(minutes: 1, seconds: 05), 'la la la la la la'),
    CloseCaptionElement(Duration(minutes: 1, seconds: 15),
        Duration(minutes: 1, seconds: 20), 'la la la la la la'),
    CloseCaptionElement(Duration(minutes: 1, seconds: 30),
        Duration(minutes: 1, seconds: 35), 'la la la la la la'),
    CloseCaptionElement(Duration(minutes: 1, seconds: 45),
        Duration(minutes: 1, seconds: 50), 'la la la la la la'),
    CloseCaptionElement(Duration(minutes: 2, seconds: 00),
        Duration(minutes: 2, seconds: 05), 'la la la la la la'),
    CloseCaptionElement(Duration(minutes: 2, seconds: 15),
        Duration(minutes: 2, seconds: 20), 'la la la la la la'),
    CloseCaptionElement(Duration(minutes: 2, seconds: 30),
        Duration(minutes: 2, seconds: 35), 'la la la la la la'),
    CloseCaptionElement(Duration(minutes: 2, seconds: 45),
        Duration(minutes: 2, seconds: 50), 'la la la la la la'),
    CloseCaptionElement(Duration(minutes: 3, seconds: 00),
        Duration(minutes: 3, seconds: 05), 'la la la la la la'),
    CloseCaptionElement(Duration(minutes: 3, seconds: 15),
        Duration(minutes: 3, seconds: 20), 'la la la la la la'),
    CloseCaptionElement(Duration(minutes: 3, seconds: 30),
        Duration(minutes: 3, seconds: 35), 'la la la la la la'),
    CloseCaptionElement(Duration(minutes: 3, seconds: 45),
        Duration(minutes: 3, seconds: 50), 'la la la la la la'),
  ];

  MediaModel({
    required String diskImagePath,
    required this.bandName,
    required this.trackName,
    required this.trackSize,
    this.colorCaptureSize = const Size(50.0, 50.0),
  })  : assert(diskImagePath.isNotEmpty),
        assert(bandName.isNotEmpty),
        assert(trackName.isNotEmpty),
        _diskImagePath = diskImagePath,
        isPlaying = false;

  ImageProvider get diskImage => BitmapUtils().getFromMediaPath(_diskImagePath);
  String get diskImagePath => _diskImagePath;
}
