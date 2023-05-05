import 'package:awesome_notifications/src/helpers/cron_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CronHelper tests', () {
    late CronHelper cronHelper;

    setUp(() {
      DateTime fixedNow = DateTime(2023, 05, 01, 12, 30, 15);
      cronHelper = CronHelper.private(fixedNow: fixedNow);
    });

    test('atDate', () {
      DateTime referenceDateTime = DateTime(2023, 05, 01, 14, 45, 00);
      expect(cronHelper.atDate(referenceDateTime: referenceDateTime),
          '0 45 14 1 5 ? 2023');
    });

    test('yearly', () {
      DateTime referenceDateTime = DateTime(2023, 12, 25, 07, 00, 00);
      expect(cronHelper.yearly(referenceDateTime: referenceDateTime),
          '0 0 7 25 12 ? *');
    });

    test('monthly', () {
      DateTime referenceDateTime = DateTime(2023, 05, 15, 10, 30, 00);
      expect(cronHelper.monthly(referenceDateTime: referenceDateTime),
          '0 30 10 15 * ? *');
    });

    test('weekly', () {
      DateTime referenceDateTime = DateTime(2023, 05, 02, 18, 30, 00);
      expect(cronHelper.weekly(referenceDateTime: referenceDateTime),
          '0 30 18 ? 5 TUE *');
    });

    test('daily', () {
      DateTime referenceDateTime = DateTime(2023, 05, 01, 22, 15, 00);
      expect(cronHelper.daily(referenceDateTime: referenceDateTime),
          '0 15 22 * * ? *');
    });

    test('hourly', () {
      DateTime referenceDateTime = DateTime(2023, 05, 01, 12, 45, 00);
      expect(cronHelper.hourly(referenceDateTime: referenceDateTime),
          '0 45 * * * ? *');
    });

    test('minutely', () {
      expect(cronHelper.minutely(initialSecond: 10), '10 * * * * ? *');
    });

    test('workweekDay', () {
      DateTime referenceDateTime = DateTime(2023, 05, 01, 9, 0, 0);
      expect(cronHelper.workweekDay(referenceDateTime: referenceDateTime),
          '0 0 9 ? * MON-FRI *');
    });

    test('weekendDay', () {
      DateTime referenceDateTime = DateTime(2023, 05, 01, 10, 30, 0);
      expect(cronHelper.weekendDay(referenceDateTime: referenceDateTime),
          '0 30 10 ? * SAT,SUN *');
    });
  });
}
