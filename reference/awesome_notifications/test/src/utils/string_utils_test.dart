import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isNullOrEmpty()', () {
    test('Empty string', () {
      expect(AwesomeStringUtils.isNullOrEmpty(""), true);
    });

    test('Null string', () {
      expect(AwesomeStringUtils.isNullOrEmpty(null), true);
    });

    test('Non-empty string', () {
      expect(AwesomeStringUtils.isNullOrEmpty("Hello"), false);
    });

    test('White space string with considerWhiteSpaceAsEmpty = false', () {
      expect(AwesomeStringUtils.isNullOrEmpty(" ", considerWhiteSpaceAsEmpty: false), false);
    });

    test('White space string with considerWhiteSpaceAsEmpty = true', () {
      expect(AwesomeStringUtils.isNullOrEmpty(" ", considerWhiteSpaceAsEmpty: true), true);
    });

    test('White space and newline string with considerWhiteSpaceAsEmpty = true', () {
      expect(AwesomeStringUtils.isNullOrEmpty(" \n", considerWhiteSpaceAsEmpty: true), true);
    });
  });
}