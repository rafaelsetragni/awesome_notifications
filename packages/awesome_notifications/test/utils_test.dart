import 'dart:ui' show Color;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AwesomeStringUtils', () {
    test('isNullOrEmpty', () {
      expect(AwesomeStringUtils.isNullOrEmpty(null), isTrue);
      expect(AwesomeStringUtils.isNullOrEmpty(''), isTrue);
      expect(AwesomeStringUtils.isNullOrEmpty('x'), isFalse);
      // Whitespace is only "empty" when explicitly asked.
      expect(AwesomeStringUtils.isNullOrEmpty('  '), isFalse);
      expect(
          AwesomeStringUtils.isNullOrEmpty('  ',
              considerWhiteSpaceAsEmpty: true),
          isTrue);
    });
  });

  group('AwesomeDateUtils', () {
    test('round-trips date <-> string', () {
      final date = DateTime(2026, 7, 5, 20, 56, 23);
      final text = AwesomeDateUtils.parseDateToString(date);
      expect(text, '2026-07-05 20:56:23');
      expect(AwesomeDateUtils.parseStringToDate(text), date);
    });

    test('handles null and invalid input', () {
      expect(AwesomeDateUtils.parseDateToString(null), isNull);
      expect(AwesomeDateUtils.parseStringToDate(null), isNull);
      expect(AwesomeDateUtils.parseStringToDate(''), isNull);
      expect(AwesomeDateUtils.parseStringToDate('not a date'), isNull);
    });

    test('parses the ISO "T" separator', () {
      expect(AwesomeDateUtils.parseStringToDate('2026-07-05T20:56:23'),
          DateTime(2026, 7, 5, 20, 56, 23));
    });

    test('parseStringToDateUtc yields a UTC date', () {
      final date = AwesomeDateUtils.parseStringToDateUtc('2026-07-05 20:56:23');
      expect(date, isNotNull);
      expect(date!.isUtc, isTrue);
    });
  });

  group('AwesomeAssertUtils', () {
    test('toSimpleEnumString', () {
      expect(
          AwesomeAssertUtils.toSimpleEnumString(ActionType.KeepOnTop), 'KeepOnTop');
      expect(AwesomeAssertUtils.toSimpleEnumString<ActionType>(null), isNull);
    });

    test('extractValue for String / int / bool', () {
      expect(AwesomeAssertUtils.extractValue<String>('k', {'k': 'v'}), 'v');
      expect(AwesomeAssertUtils.extractValue<int>('k', {'k': 5}), 5);
      expect(AwesomeAssertUtils.extractValue<int>('k', {'k': '7'}), 7);
      expect(AwesomeAssertUtils.extractValue<bool>('k', {'k': 'true'}), true);
      expect(AwesomeAssertUtils.extractValue<bool>('k', {'k': 'false'}), false);
    });

    test('extractValue for DateTime and Color', () {
      expect(
          AwesomeAssertUtils.extractValue<DateTime>(
              'k', {'k': '2026-07-05 20:56:23'}),
          isA<DateTime>());
      expect(AwesomeAssertUtils.extractValue<Color>('k', {'k': '#FF0000'}),
          isA<Color>());
    });

    test('extractEnum', () {
      expect(
          AwesomeAssertUtils.extractEnum<ActionType>(
              'k', {'k': 'DismissAction'}, ActionType.values),
          ActionType.DismissAction);
      expect(
          AwesomeAssertUtils.extractEnum<ActionType>(
              'k', {'k': 'Nope'}, ActionType.values),
          isNull);
    });

    test('isNullOrEmptyOrInvalid', () {
      expect(AwesomeAssertUtils.isNullOrEmptyOrInvalid<String>(null), isTrue);
      expect(AwesomeAssertUtils.isNullOrEmptyOrInvalid<String>(''), isTrue);
      expect(AwesomeAssertUtils.isNullOrEmptyOrInvalid<String>('x'), isFalse);
      expect(AwesomeAssertUtils.isNullOrEmptyOrInvalid<Map>(<String, dynamic>{}),
          isTrue);
    });
  });
}
