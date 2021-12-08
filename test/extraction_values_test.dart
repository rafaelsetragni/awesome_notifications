import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {});

  tearDown(() {});

  test('extractValueTest', () async {
    expect("title", AssertUtils.extractValue("test", {"test": "title"}, String));
    expect(" title", AssertUtils.extractValue("test", {"test": " title"}, String));
    expect("", AssertUtils.extractValue("test", {"test": ""}, String));
    expect(" ", AssertUtils.extractValue("test", {"test": " "}, String));

    expect(10, AssertUtils.extractValue("test", {"test": "10"}, int));
    expect(10, AssertUtils.extractValue("test", {"test": 10}, int));
    expect(10, AssertUtils.extractValue("test", {"test": "10.0"}, int));
    expect(10.0, AssertUtils.extractValue("test", {"test": "10.0"}, double));
    expect(0, AssertUtils.extractValue("test", {"test": "0"}, int));
    expect(0.0, AssertUtils.extractValue("test", {"test": "0"}, double));
    expect(0, AssertUtils.extractValue("test", {"test": "0.0"}, int));
    expect(0, AssertUtils.extractValue("test", {"test": 0}, int));

    expect(0xFFFF0000, AssertUtils.extractValue("test", {"test": "#FF0000"}, int));
    expect(0xFFFF0000, AssertUtils.extractValue("test", {"test": "#ff0000"}, int));
    expect(0xFFFF0000, AssertUtils.extractValue("test", {"test": "#FFFF0000"}, int));
    expect(0x00FF0000, AssertUtils.extractValue("test", {"test": "#00FF0000"}, int));
    expect(0xFFFF0000, AssertUtils.extractValue("test", {"test": "0xFF0000"}, int));
    expect(0xFFFF0000, AssertUtils.extractValue("test", {"test": "0xFFff0000"}, int));

    expect(Colors.black, AssertUtils.extractValue("test", {"test": "#000000"}, Color));
    expect(Colors.black, AssertUtils.extractValue("test", {"test": "#FF000000"}, Color));
    expect(Colors.transparent, AssertUtils.extractValue("test", {"test": "#00000000"}, Color));

    expect(null, AssertUtils.extractValue("test", {"test": null}, Color));
    expect(null, AssertUtils.extractValue("test", {"test": "#0004"}, Color));
    expect(null, AssertUtils.extractValue("test", {"test": "#04"}, Color));
    expect(null, AssertUtils.extractValue("test", {"test": " "}, Color));

    expect(null, AssertUtils.extractValue("test", {"test": null}, int));
    expect(null, AssertUtils.extractValue("test", {"test": ""}, int));
    expect(null, AssertUtils.extractValue("test", {"test": " "}, int));

    expect(null, AssertUtils.extractValue("test", {"test": 0}, String));
    expect(null, AssertUtils.extractValue("test", {"test": null}, String));
  });

  test('extractEnumTest', () async {
    expect(NotificationPrivacy.Private,
        AssertUtils.extractEnum<NotificationPrivacy>(
            "test", {"test": "Private"}, NotificationPrivacy.values));

    expect(NotificationPrivacy.Public,
        AssertUtils.extractEnum<NotificationPrivacy>(
            "test", {"test": "Public"}, NotificationPrivacy.values));

    expect(null,
        AssertUtils.extractEnum<NotificationPrivacy>(
            "test", {"test": ""}, NotificationPrivacy.values));

    expect(null,
        AssertUtils.extractEnum<NotificationPrivacy>(
            "test", {"test": " "}, NotificationPrivacy.values));

    expect(null,
        AssertUtils.extractEnum<NotificationPrivacy>(
            "test", {"test": null}, NotificationPrivacy.values));
  });
}
