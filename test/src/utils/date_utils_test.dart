import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseStringToDate()', () {
    test('Null string', () {
      expect(AwesomeDateUtils.parseStringToDateUtc(null), null);
    });

    test('Empty string', () {
      expect(AwesomeDateUtils.parseStringToDateUtc(''), null);
    });

    test('Valid date string', () {
      expect(
          AwesomeDateUtils.parseStringToDateUtc('2023-01-01 00:00:00')
              ?.toIso8601String(),
          '2023-01-01T00:00:00.000Z');
    });
  });

  group('parseDateToString()', () {
    test('Null DateTime', () {
      expect(AwesomeDateUtils.parseDateToString(null), null);
    });

    test('Valid DateTime', () {
      DateTime dateTime = DateTime.parse('2023-01-01T00:00:00.000Z');
      expect(
          AwesomeDateUtils.parseDateToString(dateTime), '2023-01-01 00:00:00');
    });
  });

  group('utcToLocal()', () {
    test('UTC to Local conversion', () {
      DateTime utcDate = DateTime.parse('2023-01-01T00:00:00.000Z');
      DateTime localDate = AwesomeDateUtils.utcToLocal(utcDate);
      expect(localDate.isAtSameMomentAs(utcDate.toLocal()), true);
    });
  });

  group('localToUtc()', () {
    test('Local to UTC conversion', () {
      DateTime localDate = DateTime.parse('2023-01-01T00:00:00.000Z').toLocal();
      DateTime utcDate = AwesomeDateUtils.localToUtc(localDate);
      expect(utcDate.isAtSameMomentAs(localDate.toUtc()), true);
    });
  });
}
