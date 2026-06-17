import 'dart:typed_data';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/src/models/model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_test/flutter_test.dart';

enum TestEnum { value1, value2 }

class TestModel extends Model {
  TestModel({this.id, this.name});

  final int? id;
  final String? name;

  @override
  TestModel fromMap(Map<String, dynamic> map) {
    return TestModel(
      id: map['id'] as int?,
      name: map['name'] as String?,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  void validate() {}
}

class MockModel extends Model {
  final int id;

  MockModel({required this.id});

  @override
  MockModel fromMap(Map<String, dynamic> map) {
    return MockModel(id: map['id']);
  }

  @override
  Map<String, dynamic> toMap() {
    return {'id': id};
  }

  @override
  void validate() {}
}

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
    expect(AwesomeAssertUtils.getValueOrDefault<Color>('key', Colors.red),
        Colors.red.shade500);

    // Test for MaterialAccentColor
    expect(
        AwesomeAssertUtils.getValueOrDefault<Color>('key', Colors.pinkAccent),
        Color(Colors.pinkAccent.value));

    // Test for CupertinoDynamicColor
    expect(
        AwesomeAssertUtils.getValueOrDefault<Color>(
            'key', CupertinoColors.systemBlue),
        Color(CupertinoColors.systemBlue.value));

    // Test for invalid value
    expect(AwesomeAssertUtils.getValueOrDefault<Color>('key', 123), null);
  });

  test('extractValueTest', () async {
    expect("title",
        AwesomeAssertUtils.extractValue<String>("test", {"test": "title"}));
    expect(" title",
        AwesomeAssertUtils.extractValue<String>("test", {"test": " title"}));
    expect("", AwesomeAssertUtils.extractValue<String>("test", {"test": ""}));
    expect(" ", AwesomeAssertUtils.extractValue<String>("test", {"test": " "}));


    expect(null,
        AwesomeAssertUtils.extractValue<List<String>>("test", {"test": []}));
    expect([""],
        AwesomeAssertUtils.extractValue<List<String>>("test", {"test": [""]}));
    expect(["1"],
        AwesomeAssertUtils.extractValue<List<String>>("test", {"test": ["1"]}));
    expect(["1","2"],
        AwesomeAssertUtils.extractValue<List<String>>("test", {"test": ["1","2"]}));
    expect(["1","2","3"],
        AwesomeAssertUtils.extractValue<List<String>>("test", {"test": ["1","2","3"]}));
    expect(["1","1","1"],
        AwesomeAssertUtils.extractValue<List<String>>("test", {"test": ["1","1","1"]}));

    expect(
        AwesomeAssertUtils.extractValue<Uint8List>(
            "test", {"test": Uint8List.fromList([])}),
        Uint8List.fromList([]));

    expect(10, AwesomeAssertUtils.extractValue<int>("test", {"test": "10"}));
    expect(10, AwesomeAssertUtils.extractValue<int>("test", {"test": 10}));
    expect(10, AwesomeAssertUtils.extractValue<int>("test", {"test": "10.0"}));
    expect(10.0,
        AwesomeAssertUtils.extractValue<double>("test", {"test": "10.0"}));
    expect(0, AwesomeAssertUtils.extractValue<int>("test", {"test": "0"}));
    expect(0.0, AwesomeAssertUtils.extractValue<double>("test", {"test": "0"}));
    expect(0, AwesomeAssertUtils.extractValue<int>("test", {"test": "0.0"}));
    expect(0, AwesomeAssertUtils.extractValue<int>("test", {"test": 0}));

    expect(0xFFFF0000,
        AwesomeAssertUtils.extractValue<int>("test", {"test": "#FF0000"}));
    expect(0xFFFF0000,
        AwesomeAssertUtils.extractValue<int>("test", {"test": "#ff0000"}));
    expect(0xFFFF0000,
        AwesomeAssertUtils.extractValue<int>("test", {"test": "#FFFF0000"}));
    expect(0x00FF0000,
        AwesomeAssertUtils.extractValue<int>("test", {"test": "#00FF0000"}));
    expect(0xFFFF0000,
        AwesomeAssertUtils.extractValue<int>("test", {"test": "0xFF0000"}));
    expect(0xFFFF0000,
        AwesomeAssertUtils.extractValue<int>("test", {"test": "0xFFff0000"}));

    expect(Colors.black,
        AwesomeAssertUtils.extractValue<Color>("test", {"test": "#000000"}));
    expect(Colors.black,
        AwesomeAssertUtils.extractValue<Color>("test", {"test": "#FF000000"}));
    expect(Colors.transparent,
        AwesomeAssertUtils.extractValue<Color>("test", {"test": "#00000000"}));

    expect(
        null, AwesomeAssertUtils.extractValue<Color>("test", {"test": null}));
    expect(null,
        AwesomeAssertUtils.extractValue<Color>("test", {"test": "#0004"}));
    expect(
        null, AwesomeAssertUtils.extractValue<Color>("test", {"test": "#04"}));
    expect(null, AwesomeAssertUtils.extractValue<Color>("test", {"test": " "}));

    expect(null, AwesomeAssertUtils.extractValue<int>("test", {"test": null}));
    expect(null, AwesomeAssertUtils.extractValue<int>("test", {"test": ""}));
    expect(null, AwesomeAssertUtils.extractValue<int>("test", {"test": " "}));

    expect(null, AwesomeAssertUtils.extractValue<String>("test", {"test": 0}));
    expect(
        null, AwesomeAssertUtils.extractValue<String>("test", {"test": null}));

    expect(true, AwesomeAssertUtils.extractValue<bool>("test", {"test": true}));
    expect(
        true, AwesomeAssertUtils.extractValue<bool>("test", {"test": "true"}));
    expect(false,
        AwesomeAssertUtils.extractValue<bool>("test", {"test": "false"}));
  });

  test('extractEnumTest', () async {
    expect(
        NotificationPrivacy.Private,
        AwesomeAssertUtils.extractEnum<NotificationPrivacy>(
            "test", {"test": "Private"}, NotificationPrivacy.values));

    expect(
        NotificationPrivacy.Public,
        AwesomeAssertUtils.extractEnum<NotificationPrivacy>(
            "test", {"test": "Public"}, NotificationPrivacy.values));

    expect(
        null,
        AwesomeAssertUtils.extractEnum<NotificationPrivacy>(
            "test", {"test": ""}, NotificationPrivacy.values));

    expect(
        null,
        AwesomeAssertUtils.extractEnum<NotificationPrivacy>(
            "test", {"test": " "}, NotificationPrivacy.values));

    expect(
        null,
        AwesomeAssertUtils.extractEnum<NotificationPrivacy>(
            "test", {"test": null}, NotificationPrivacy.values));
  });

  group('AwesomeAssertUtils tests', () {
    test('toSimpleEnumString returns the correct string representation', () {
      const testEnumValue = NotificationPrivacy.Secret;

      final result = AwesomeAssertUtils.toSimpleEnumString(testEnumValue);
      expect(result, 'Secret');
    });

    test('isNullOrEmptyOrInvalid returns the correct boolean value', () {
      expect(AwesomeAssertUtils.isNullOrEmptyOrInvalid<String>(null), true);
      expect(AwesomeAssertUtils.isNullOrEmptyOrInvalid<String>(''), true);
      expect(AwesomeAssertUtils.isNullOrEmptyOrInvalid<String>(123), true);
      expect(AwesomeAssertUtils.isNullOrEmptyOrInvalid<String>('test'), false);
    });

    test('toListMap returns the correct list of maps', () {
      final input = [
        TestModel(id: 1, name: 'test1'),
        TestModel(id: 2, name: 'test2')
      ];

      final result = AwesomeAssertUtils.toListMap<TestModel>(input);

      expect(
        result,
        [
          {'id': 1, 'name': 'test1'},
          {'id': 2, 'name': 'test2'}
        ],
      );
    });

    // Add more tests for the remaining methods
  });
  group('fromListMap', () {
    // Other test cases...

    test('returns the correct list of models when using fromListMap', () {
      final listData = [
        {'id': 1},
        {'id': 2},
        {'id': 3},
      ];

      final result = AwesomeAssertUtils.fromListMap<MockModel>(
        listData,
        () => MockModel(id: 0),
      );

      expect(result, isNotNull);
      expect(result!.length, 3);
      expect(result[0].id, 1);
      expect(result[1].id, 2);
      expect(result[2].id, 3);
    });

    test('returns null when mapData is null in fromListMap', () {
      final result = AwesomeAssertUtils.fromListMap<MockModel>(
        null,
        () => MockModel(id: 0),
      );
      expect(result, isNull);
    });

    test('returns null when mapData is not a list in fromListMap', () {
      final mapData = {'id': 1};
      final result = AwesomeAssertUtils.fromListMap<MockModel>(
        mapData,
        () => MockModel(id: 0),
      );
      expect(result, isNull);
    });

    test('returns null when list is empty in fromListMap', () {
      final listData = [];
      final result = AwesomeAssertUtils.fromListMap<MockModel>(
        listData,
        () => MockModel(id: 0),
      );
      expect(result, isNull);
    });
  });

  group('extractValue', () {
    test('returns the correct value when T is DateTime', () {
      final dataMap = {'reference': '2021-09-01T10:00:00'};
      final result =
          AwesomeAssertUtils.extractValue<DateTime>('reference', dataMap);
      expect(result, DateTime.parse('2021-09-01T10:00:00'));
    });

    test(
        'returns the correct value when T is DateTime and value is string with timezone',
        () {
      final dataMap = {'reference': '2021-09-01 10:00:00 UTC'};
      final result =
          AwesomeAssertUtils.extractValue<DateTime>('reference', dataMap);
      expect(result, DateTime.parse('2021-09-01T10:00:00Z'));
    });

    test('returns the default value when T is DateTime and input is invalid',
        () {
      final dataMap = {'reference': 'invalid date'};
      final result =
          AwesomeAssertUtils.extractValue<DateTime>('reference', dataMap);
      expect(result, null);
    });

    test('returns the correct value when T is a string with double', () {
      final dataMap = {'reference': '10.5'};
      final result =
          AwesomeAssertUtils.extractValue<double>('reference', dataMap);
      expect(result, 10.5);
    });

    test('returns the correct value when T is double', () {
      final dataMap = {'reference': 10.5};
      final result =
          AwesomeAssertUtils.extractValue<double>('reference', dataMap);
      expect(result, 10.5);
    });

    test('returns the default value when T is double and input is invalid', () {
      final dataMap = {'reference': 'invalid double'};
      final result =
          AwesomeAssertUtils.extractValue<double>('reference', dataMap);
      expect(result, null);
    });

    test('returns the correct value when T is bool', () {
      final dataMap = {'reference': 'true'};
      final result =
          AwesomeAssertUtils.extractValue<bool>('reference', dataMap);
      expect(result, true);
    });

    test('returns the correct value when T is bool and input is 1', () {
      final dataMap = {'reference': '1'};
      final result =
          AwesomeAssertUtils.extractValue<bool>('reference', dataMap);
      expect(result, true);
    });

    test('returns the default value when T is bool and input is invalid', () {
      final dataMap = {'reference': 'invalid bool'};
      final result =
          AwesomeAssertUtils.extractValue<bool>('reference', dataMap);
      expect(result, null);
    });

    test('returns the correct value when T is int and value is double', () {
      final dataMap = {'reference': 10.5};
      final result = AwesomeAssertUtils.extractValue<int>('reference', dataMap);
      expect(result, 11);
    });

    test('returns the default value when T is int and value is invalid', () {
      final dataMap = {'reference': 'invalid int'};
      final result = AwesomeAssertUtils.extractValue<int>('reference', dataMap);
      expect(result, null);
    });

    test('returns the correct value when T is double and value is int', () {
      final dataMap = {'reference': 10};
      final result =
          AwesomeAssertUtils.extractValue<double>('reference', dataMap);
      expect(result, 10.0);
    });

    test('returns the correct value when T is Color and value is MaterialColor',
        () {
      final dataMap = {'reference': Colors.blue};
      final result =
          AwesomeAssertUtils.extractValue<Color>('reference', dataMap);
      expect(result, Colors.blue.shade500);
    });

    test(
        'returns the correct value when T is Color and value is MaterialAccentColor',
        () {
      final dataMap = {'reference': Colors.pinkAccent};
      final result =
          AwesomeAssertUtils.extractValue<Color>('reference', dataMap);
      expect(result, Color(Colors.pinkAccent.value));
    });

    test(
        'returns the correct value when T is Color and value is CupertinoDynamicColor',
        () {
      final dataMap = {'reference': CupertinoColors.systemBlue};
      final result =
          AwesomeAssertUtils.extractValue<Color>('reference', dataMap);
      expect(result, Color(CupertinoColors.systemBlue.value));
    });

    test('returns the default value when T is Color and value is invalid', () {
      final dataMap = {'reference': 'invalid color'};
      final result =
          AwesomeAssertUtils.extractValue<Color>('reference', dataMap);
      expect(result, null);
    });

    test('returns the correct value when T is int and value is hex string', () {
      final dataMap = {'reference': '0xFF123456'};
      final result = AwesomeAssertUtils.extractValue<int>('reference', dataMap);
      expect(result, 0xFF123456);
    });

    test('returns the correct value when T is Color and value is hex string',
        () {
      final dataMap = {'reference': '#FF123456'};
      final result =
          AwesomeAssertUtils.extractValue<Color>('reference', dataMap);
      expect(result, const Color(0xFF123456));
    });

    test('returns the correct value when T is Color and value is an integer',
        () {
      final dataMap = {'reference': 0xFF123456};
      final result =
          AwesomeAssertUtils.extractValue<Color>('reference', dataMap);
      expect(result, const Color(0xFF123456));
    });

    test(
        'returns the default value when T is int and value is invalid hex string',
        () {
      final dataMap = {'reference': 'invalid hex'};
      final result = AwesomeAssertUtils.extractValue<int>('reference', dataMap);
      expect(result, null);
    });

    test(
        'returns the correct value when T is int and value is a decimal string',
        () {
      final dataMap = {'reference': '10.5'};
      final result = AwesomeAssertUtils.extractValue<int>('reference', dataMap);
      expect(result, 10);
    });

    test('returns the correct value when T is bool and value is null', () {
      final dataMap = {'reference': null};
      final result =
          AwesomeAssertUtils.extractValue<bool>('reference', dataMap);
      expect(result, null);
    });

    test('returns the correct value when T is bool and value is int', () {
      final dataMap = {'reference': 1};
      final result =
          AwesomeAssertUtils.extractValue<bool>('reference', dataMap);
      expect(result, true);
    });

    test('returns the correct value when T is bool and value is false', () {
      final dataMap = {'reference': false};
      final result =
          AwesomeAssertUtils.extractValue<bool>('reference', dataMap);
      expect(result, false);
    });
  });
}
