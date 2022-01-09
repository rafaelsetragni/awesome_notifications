import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {});

  tearDown(() {});

  test('extractValueTest', () async {
    expect("title", AwesomeAssertUtils.extractValue("test", {"test": "title"}, String));
    expect(" title", AwesomeAssertUtils.extractValue("test", {"test": " title"}, String));
    expect("", AwesomeAssertUtils.extractValue("test", {"test": ""}, String));
    expect(" ", AwesomeAssertUtils.extractValue("test", {"test": " "}, String));

    expect(10, AwesomeAssertUtils.extractValue("test", {"test": "10"}, int));
    expect(10, AwesomeAssertUtils.extractValue("test", {"test": 10}, int));
    expect(10, AwesomeAssertUtils.extractValue("test", {"test": "10.0"}, int));
    expect(10.0, AwesomeAssertUtils.extractValue("test", {"test": "10.0"}, double));
    expect(0, AwesomeAssertUtils.extractValue("test", {"test": "0"}, int));
    expect(0.0, AwesomeAssertUtils.extractValue("test", {"test": "0"}, double));
    expect(0, AwesomeAssertUtils.extractValue("test", {"test": "0.0"}, int));
    expect(0, AwesomeAssertUtils.extractValue("test", {"test": 0}, int));

    expect(0xFFFF0000, AwesomeAssertUtils.extractValue("test", {"test": "#FF0000"}, int));
    expect(0xFFFF0000, AwesomeAssertUtils.extractValue("test", {"test": "#ff0000"}, int));
    expect(0xFFFF0000, AwesomeAssertUtils.extractValue("test", {"test": "#FFFF0000"}, int));
    expect(0x00FF0000, AwesomeAssertUtils.extractValue("test", {"test": "#00FF0000"}, int));
    expect(0xFFFF0000, AwesomeAssertUtils.extractValue("test", {"test": "0xFF0000"}, int));
    expect(0xFFFF0000, AwesomeAssertUtils.extractValue("test", {"test": "0xFFff0000"}, int));

    expect(Colors.black, AwesomeAssertUtils.extractValue("test", {"test": "#000000"}, Color));
    expect(Colors.black, AwesomeAssertUtils.extractValue("test", {"test": "#FF000000"}, Color));
    expect(Colors.transparent, AwesomeAssertUtils.extractValue("test", {"test": "#00000000"}, Color));

    expect(null, AwesomeAssertUtils.extractValue("test", {"test": null}, Color));
    expect(null, AwesomeAssertUtils.extractValue("test", {"test": "#0004"}, Color));
    expect(null, AwesomeAssertUtils.extractValue("test", {"test": "#04"}, Color));
    expect(null, AwesomeAssertUtils.extractValue("test", {"test": " "}, Color));

    expect(null, AwesomeAssertUtils.extractValue("test", {"test": null}, int));
    expect(null, AwesomeAssertUtils.extractValue("test", {"test": ""}, int));
    expect(null, AwesomeAssertUtils.extractValue("test", {"test": " "}, int));

    expect(null, AwesomeAssertUtils.extractValue("test", {"test": 0}, String));
    expect(null, AwesomeAssertUtils.extractValue("test", {"test": null}, String));

    expect(true, AwesomeAssertUtils.extractValue("test", {"test": true}, bool));
    expect(true, AwesomeAssertUtils.extractValue("test", {"test": "true"}, bool));
    expect(false, AwesomeAssertUtils.extractValue("test", {"test": "false"}, bool));
  });

  test('extractEnumTest', () async {
    expect(NotificationPrivacy.Private,
        AwesomeAssertUtils.extractEnum<NotificationPrivacy>(
            "test", {"test": "Private"}, NotificationPrivacy.values));

    expect(NotificationPrivacy.Public,
        AwesomeAssertUtils.extractEnum<NotificationPrivacy>(
            "test", {"test": "Public"}, NotificationPrivacy.values));

    expect(null,
        AwesomeAssertUtils.extractEnum<NotificationPrivacy>(
            "test", {"test": ""}, NotificationPrivacy.values));

    expect(null,
        AwesomeAssertUtils.extractEnum<NotificationPrivacy>(
            "test", {"test": " "}, NotificationPrivacy.values));

    expect(null,
        AwesomeAssertUtils.extractEnum<NotificationPrivacy>(
            "test", {"test": null}, NotificationPrivacy.values));
  });
}
