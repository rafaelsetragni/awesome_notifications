import 'dart:typed_data';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_test/flutter_test.dart';

import 'dart:typed_data';

enum TestEnum { value1, value2 }

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {});

  tearDown(() {});

  test('isNullOrEmptyOrInvalid() tests', () {
    expect(AwesomeAssertUtils.isNullOrEmptyOrInvalid<String>(""), true);
    expect(AwesomeAssertUtils.isNullOrEmptyOrInvalid<String>("Hello"), false);
    expect(AwesomeAssertUtils.isNullOrEmptyOrInvalid<String>(123), true);
  });

  test('toSimpleEnumString() tests', () {
    expect(AwesomeAssertUtils.toSimpleEnumString(TestEnum.value1), 'value1');
    expect(AwesomeAssertUtils.toSimpleEnumString(TestEnum.value2), 'value2');
  });

  test('getValueOrDefault() tests', () {
    // Test for MaterialColor
    expect(
        AwesomeAssertUtils.getValueOrDefault<Color>('key', Colors.red),
        Colors.red.shade500);

    // Test for MaterialAccentColor
    expect(
        AwesomeAssertUtils.getValueOrDefault<Color>(
            'key', Colors.pinkAccent),
        Color(Colors.pinkAccent.value));

    // Test for CupertinoDynamicColor
    expect(
        AwesomeAssertUtils.getValueOrDefault<Color>(
            'key', CupertinoColors.systemBlue),
        Color(CupertinoColors.systemBlue.value));

    // Test for invalid value
    expect(
        AwesomeAssertUtils.getValueOrDefault<Color>('key', 123),
        null);
  });


  test('extractValueTest', () async {
    expect("title", AwesomeAssertUtils.extractValue<String>("test", {"test": "title"}));
    expect(" title", AwesomeAssertUtils.extractValue<String>("test", {"test": " title"}));
    expect("", AwesomeAssertUtils.extractValue<String>("test", {"test": ""}));
    expect(" ", AwesomeAssertUtils.extractValue<String>("test", {"test": " "}));

    expect(AwesomeAssertUtils
        .extractValue<Uint8List>("test", {"test": Uint8List.fromList([])}),
        Uint8List.fromList([])
    );

    expect(10, AwesomeAssertUtils.extractValue<int>("test", {"test": "10"}));
    expect(10, AwesomeAssertUtils.extractValue<int>("test", {"test": 10}));
    expect(10, AwesomeAssertUtils.extractValue<int>("test", {"test": "10.0"}));
    expect(10.0, AwesomeAssertUtils.extractValue<double>("test", {"test": "10.0"}));
    expect(0, AwesomeAssertUtils.extractValue<int>("test", {"test": "0"}));
    expect(0.0, AwesomeAssertUtils.extractValue<double>("test", {"test": "0"}));
    expect(0, AwesomeAssertUtils.extractValue<int>("test", {"test": "0.0"}));
    expect(0, AwesomeAssertUtils.extractValue<int>("test", {"test": 0}));

    expect(0xFFFF0000, AwesomeAssertUtils.extractValue<int>("test", {"test": "#FF0000"}));
    expect(0xFFFF0000, AwesomeAssertUtils.extractValue<int>("test", {"test": "#ff0000"}));
    expect(0xFFFF0000, AwesomeAssertUtils.extractValue<int>("test", {"test": "#FFFF0000"}));
    expect(0x00FF0000, AwesomeAssertUtils.extractValue<int>("test", {"test": "#00FF0000"}));
    expect(0xFFFF0000, AwesomeAssertUtils.extractValue<int>("test", {"test": "0xFF0000"}));
    expect(0xFFFF0000, AwesomeAssertUtils.extractValue<int>("test", {"test": "0xFFff0000"}));

    expect(Colors.black, AwesomeAssertUtils.extractValue<Color>("test", {"test": "#000000"}));
    expect(Colors.black, AwesomeAssertUtils.extractValue<Color>("test", {"test": "#FF000000"}));
    expect(Colors.transparent, AwesomeAssertUtils.extractValue<Color>("test", {"test": "#00000000"}));

    expect(null, AwesomeAssertUtils.extractValue<Color>("test", {"test": null}));
    expect(null, AwesomeAssertUtils.extractValue<Color>("test", {"test": "#0004"}));
    expect(null, AwesomeAssertUtils.extractValue<Color>("test", {"test": "#04"}));
    expect(null, AwesomeAssertUtils.extractValue<Color>("test", {"test": " "}));

    expect(null, AwesomeAssertUtils.extractValue<int>("test", {"test": null}));
    expect(null, AwesomeAssertUtils.extractValue<int>("test", {"test": ""}));
    expect(null, AwesomeAssertUtils.extractValue<int>("test", {"test": " "}));

    expect(null, AwesomeAssertUtils.extractValue<String>("test", {"test": 0}));
    expect(null, AwesomeAssertUtils.extractValue<String>("test", {"test": null}));

    expect(true, AwesomeAssertUtils.extractValue<bool>("test", {"test": true}));
    expect(true, AwesomeAssertUtils.extractValue<bool>("test", {"test": "true"}));
    expect(false, AwesomeAssertUtils.extractValue<bool>("test", {"test": "false"}));
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
