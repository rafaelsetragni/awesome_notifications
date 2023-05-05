import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() {
  group('NotificationAndroidCrontab', () {
    test('Constructors and toMap', () {
      DateTime initialDate = DateTime(2023, 5, 1);
      DateTime expirationDate = DateTime(2023, 5, 31);
      DateTime referenceDate = DateTime(2023, 5, 15, 14, 30);
      String crontabExpression = '0 30 14 * * *';

      // Test main constructor
      NotificationAndroidCrontab crontab = NotificationAndroidCrontab(
          initialDateTime: initialDate,
          expirationDateTime: expirationDate,
          crontabExpression: crontabExpression);
      expect(crontab.initialDateTime, initialDate);
      expect(crontab.expirationDateTime, expirationDate);
      expect(crontab.crontabExpression, crontabExpression);

      // Test fromDate constructor
      NotificationAndroidCrontab crontabFromDate =
          NotificationAndroidCrontab.fromDate(date: referenceDate);
      expect(crontabFromDate.initialDateTime, referenceDate);

      // Test daily constructor
      NotificationAndroidCrontab crontabDaily =
          NotificationAndroidCrontab.daily(referenceDateTime: referenceDate);
      // Check if crontabDaily has a crontabExpression

      // Test other constructors similarly...

      // Test toMap
      Map<String, dynamic> crontabMap = crontab.toMap();
      expect(crontabMap[NOTIFICATION_INITIAL_DATE_TIME],
          AwesomeDateUtils.parseDateToString(initialDate));
      expect(crontabMap[NOTIFICATION_EXPIRATION_DATE_TIME],
          AwesomeDateUtils.parseDateToString(expirationDate));
      expect(crontabMap[NOTIFICATION_CRONTAB_EXPRESSION], crontabExpression);
    });

    test('NotificationAndroidCrontab toMap with preciseSchedules', () {
      DateTime initialDateTime = DateTime(2023, 5, 2, 15, 30);
      DateTime expirationDateTime = DateTime(2023, 5, 10, 15, 30);
      List<DateTime> preciseSchedules = [
        DateTime(2023, 5, 2, 15, 30),
        DateTime(2023, 5, 3, 16, 30),
      ];
      String crontabExpression = '0 30 15 2 5 ? *';

      NotificationAndroidCrontab crontab = NotificationAndroidCrontab(
        initialDateTime: initialDateTime,
        expirationDateTime: expirationDateTime,
        preciseSchedules: preciseSchedules,
        crontabExpression: crontabExpression,
      );

      expect(crontab.initialDateTime, initialDateTime);
      expect(crontab.expirationDateTime, expirationDateTime);
      expect(crontab.preciseSchedules, preciseSchedules);
      expect(crontab.crontabExpression, crontabExpression);

      var toMapData = crontab.toMap();

      expect(toMapData['initialDateTime'], "2023-05-02 15:30:00");
      expect(toMapData['expirationDateTime'], "2023-05-10 15:30:00");
      expect(toMapData['preciseSchedules'], isNotNull);
      expect(toMapData['preciseSchedules'][0], "2023-05-02 15:30:00");
      expect(toMapData['preciseSchedules'][1], "2023-05-03 16:30:00");
      expect(toMapData['crontabExpression'], '0 30 15 2 5 ? *');
    });

    test('fromMap', () {
      DateTime initialDate = DateTime(2023, 5, 1);
      DateTime expirationDate = DateTime(2023, 5, 31);
      String crontabExpression = '0 30 14 * * *';

      Map<String, dynamic> crontabMap = {
        NOTIFICATION_INITIAL_DATE_TIME:
            AwesomeDateUtils.parseDateToString(initialDate),
        NOTIFICATION_EXPIRATION_DATE_TIME:
            AwesomeDateUtils.parseDateToString(expirationDate),
        NOTIFICATION_CRONTAB_EXPRESSION: crontabExpression
      };

      NotificationAndroidCrontab crontab = NotificationAndroidCrontab()
          .fromMap(crontabMap) as NotificationAndroidCrontab;

      expect(crontab.initialDateTime, initialDate);
      expect(crontab.expirationDateTime, expirationDate);
      expect(crontab.crontabExpression, crontabExpression);
    });
  });

  group('NotificationAndroidCrontab factories using local date', () {
    test(
        'fromDate constructor creates a NotificationAndroidCrontab with the given date',
        () {
      DateTime date = DateTime(2023, 5, 2, 15, 30);
      NotificationAndroidCrontab crontab =
          NotificationAndroidCrontab.fromDate(date: date);

      expect(crontab.initialDateTime, date);
    });

    test(
        'yearly constructor creates a NotificationAndroidCrontab with the given date',
        () {
      DateTime date = DateTime(2023, 5, 2, 15, 30);
      NotificationAndroidCrontab crontab =
          NotificationAndroidCrontab.yearly(referenceDateTime: date);

      expect(crontab.crontabExpression, '0 30 15 2 5 ? *');
    });

    test(
        'monthly constructor creates a NotificationAndroidCrontab with the given date',
        () {
      DateTime date = DateTime(2023, 5, 2, 15, 30);
      NotificationAndroidCrontab crontab =
          NotificationAndroidCrontab.monthly(referenceDateTime: date);

      expect(crontab.crontabExpression, '0 30 15 2 * ? *');
    });

    test(
        'weekly constructor creates a NotificationAndroidCrontab with the given date',
        () {
      DateTime date = DateTime(2023, 5, 2, 15, 30);
      NotificationAndroidCrontab crontab =
          NotificationAndroidCrontab.weekly(referenceDateTime: date);

      expect(crontab.crontabExpression, '0 30 15 ? 5 TUE *');
    });

    test(
        'daily constructor creates a NotificationAndroidCrontab with the given date',
        () {
      DateTime date = DateTime(2023, 5, 2, 15, 30);
      NotificationAndroidCrontab crontab =
          NotificationAndroidCrontab.daily(referenceDateTime: date);

      expect(crontab.crontabExpression, '0 30 15 * * ? *');
    });

    test(
        'hourly constructor creates a NotificationAndroidCrontab with the given date',
        () {
      DateTime date = DateTime(2023, 5, 2, 15, 30);
      NotificationAndroidCrontab crontab =
          NotificationAndroidCrontab.hourly(referenceDateTime: date);

      expect(crontab.crontabExpression, '0 30 * * * ? *');
    });

    test(
        'minutely constructor creates a NotificationAndroidCrontab with the given date',
        () {
      DateTime date = DateTime(2023, 5, 2, 15, 30, 45);
      NotificationAndroidCrontab crontab =
          NotificationAndroidCrontab.minutely(referenceDateTime: date);

      expect(crontab.crontabExpression, '45 * * * * ? *');
    });

    test(
        'workweekDay constructor creates a NotificationAndroidCrontab with the given date',
        () {
      DateTime date = DateTime(2023, 5, 2, 15, 30);
      NotificationAndroidCrontab crontab =
          NotificationAndroidCrontab.workweekDay(referenceDateTime: date);

      expect(crontab.crontabExpression, '0 30 15 ? * MON-FRI *');
    });
    test(
        'weekendDay constructor creates a NotificationAndroidCrontab with the given date',
        () {
      DateTime date = DateTime(2023, 5, 2, 15, 30);
      NotificationAndroidCrontab crontab =
          NotificationAndroidCrontab.weekendDay(referenceDateTime: date);

      expect(crontab.crontabExpression, '0 30 15 ? * SAT,SUN *');
    });

    test('NotificationAndroidCrontab constructor with preciseSchedules', () {
      DateTime initialDateTime = DateTime(2023, 5, 2, 15, 30);
      DateTime expirationDateTime = DateTime(2023, 5, 10, 15, 30);
      List<DateTime> preciseSchedules = [
        DateTime(2023, 5, 2, 15, 30),
        DateTime(2023, 5, 3, 16, 30),
      ];
      String crontabExpression = '0 30 15 2 5 ? *';

      NotificationAndroidCrontab crontab = NotificationAndroidCrontab(
        initialDateTime: initialDateTime,
        expirationDateTime: expirationDateTime,
        preciseSchedules: preciseSchedules,
        crontabExpression: crontabExpression,
      );

      expect(crontab.initialDateTime, initialDateTime);
      expect(crontab.expirationDateTime, expirationDateTime);
      expect(crontab.preciseSchedules, preciseSchedules);
      expect(crontab.crontabExpression, crontabExpression);
    });
  });

  group('NotificationAndroidCrontab factories using utc date', () {
    test(
        'fromDate constructor creates a NotificationAndroidCrontab with the given UTC date',
        () {
      DateTime date = DateTime.utc(2023, 5, 2, 15, 30);
      NotificationAndroidCrontab crontab =
          NotificationAndroidCrontab.fromDate(date: date);

      expect(crontab.initialDateTime, date);
    });

    test(
        'yearly constructor creates a NotificationAndroidCrontab with the given UTC date',
        () {
      DateTime date = DateTime.utc(2023, 5, 2, 15, 30);
      NotificationAndroidCrontab crontab =
          NotificationAndroidCrontab.yearly(referenceDateTime: date);

      expect(crontab.crontabExpression, '0 30 15 2 5 ? *');
    });

    test(
        'monthly constructor creates a NotificationAndroidCrontab with the given UTC date',
        () {
      DateTime date = DateTime.utc(2023, 5, 2, 15, 30);
      NotificationAndroidCrontab crontab =
          NotificationAndroidCrontab.monthly(referenceDateTime: date);

      expect(crontab.crontabExpression, '0 30 15 2 * ? *');
    });

    test(
        'weekly constructor creates a NotificationAndroidCrontab with the given UTC date',
        () {
      DateTime date = DateTime.utc(2023, 5, 2, 15, 30);
      NotificationAndroidCrontab crontab =
          NotificationAndroidCrontab.weekly(referenceDateTime: date);

      expect(crontab.crontabExpression, '0 30 15 ? 5 TUE *');
    });

    test(
        'daily constructor creates a NotificationAndroidCrontab with the given UTC date',
        () {
      DateTime date = DateTime.utc(2023, 5, 2, 15, 30);
      NotificationAndroidCrontab crontab =
          NotificationAndroidCrontab.daily(referenceDateTime: date);

      expect(crontab.crontabExpression, '0 30 15 * * ? *');
    });

    test(
        'hourly constructor creates a NotificationAndroidCrontab with the given UTC date',
        () {
      DateTime date = DateTime.utc(2023, 5, 2, 15, 30);
      NotificationAndroidCrontab crontab =
          NotificationAndroidCrontab.hourly(referenceDateTime: date);

      expect(crontab.crontabExpression, '0 30 * * * ? *');
    });

    test(
        'minutely constructor creates a NotificationAndroidCrontab with the given UTC date',
        () {
      DateTime date = DateTime.utc(2023, 5, 2, 15, 30, 45);
      NotificationAndroidCrontab crontab =
          NotificationAndroidCrontab.minutely(referenceDateTime: date);

      expect(crontab.crontabExpression, '45 * * * * ? *');
    });

    test(
        'workweekDay constructor creates a NotificationAndroidCrontab with the given UTC date',
        () {
      DateTime date = DateTime.utc(2023, 5, 2, 15, 30);
      NotificationAndroidCrontab crontab =
          NotificationAndroidCrontab.workweekDay(referenceDateTime: date);

      expect(crontab.crontabExpression, '0 30 15 ? * MON-FRI *');
    });

    test(
        'weekendDay constructor creates a NotificationAndroidCrontab with the given UTC date',
        () {
      DateTime date = DateTime.utc(2023, 5, 215, 30);
      NotificationAndroidCrontab crontab =
          NotificationAndroidCrontab.weekendDay(referenceDateTime: date);

      expect(crontab.crontabExpression, '0 0 6 ? * SAT,SUN *');
    });

    test(
        'NotificationAndroidCrontab constructor creates a NotificationAndroidCrontab with the given UTC parameters',
        () {
      DateTime initialDateTime = DateTime.utc(2023, 5, 2, 15, 30);
      DateTime expirationDateTime = DateTime.utc(2023, 5, 10, 15, 30);
      List<DateTime> preciseSchedules = [
        DateTime.utc(2023, 5, 2, 15, 30),
        DateTime.utc(2023, 5, 3, 16, 30),
      ];
      String crontabExpression = '0 30 15 2 5 ? *';

      NotificationAndroidCrontab crontab = NotificationAndroidCrontab(
        initialDateTime: initialDateTime,
        expirationDateTime: expirationDateTime,
        preciseSchedules: preciseSchedules,
        crontabExpression: crontabExpression,
      );

      expect(crontab.initialDateTime, initialDateTime);
      expect(crontab.expirationDateTime, expirationDateTime);
      expect(crontab.preciseSchedules, preciseSchedules);
      expect(crontab.crontabExpression, crontabExpression);
    });

    test(
        'fromMap constructor populates preciseSchedules correctly when given a valid list of strings',
        () {
      Map<String, dynamic> mapData = {
        NOTIFICATION_CRONTAB_EXPRESSION: '0 30 15 2 5 ? *',
        NOTIFICATION_INITIAL_DATE_TIME:
            DateTime(2023, 5, 2, 15, 30).toIso8601String(),
        NOTIFICATION_EXPIRATION_DATE_TIME:
            DateTime(2023, 5, 10, 15, 30).toIso8601String(),
        NOTIFICATION_PRECISE_SCHEDULES: [
          DateTime(2023, 5, 2, 15, 30).toIso8601String(),
          DateTime(2023, 5, 3, 16, 30).toIso8601String(),
        ],
      };

      NotificationAndroidCrontab crontab =
          NotificationAndroidCrontab().fromMap(mapData)!;

      expect(crontab.crontabExpression, '0 30 15 2 5 ? *');
      expect(crontab.initialDateTime, DateTime(2023, 5, 2, 15, 30));
      expect(crontab.expirationDateTime, DateTime(2023, 5, 10, 15, 30));
      expect(crontab.preciseSchedules, [
        DateTime(2023, 5, 2, 15, 30),
        DateTime(2023, 5, 3, 16, 30),
      ]);
    });
  });
}
