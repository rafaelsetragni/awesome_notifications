import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() {
  group('NotificationCalendar', () {
    test('should create a NotificationCalendar object fromMap', () {
      Map<String, dynamic> dataMap = {
        NOTIFICATION_SCHEDULE_ERA: 1,
        NOTIFICATION_SCHEDULE_YEAR: 2023,
        NOTIFICATION_SCHEDULE_MONTH: 5,
        NOTIFICATION_SCHEDULE_DAY: 1,
        NOTIFICATION_SCHEDULE_HOUR: 12,
        NOTIFICATION_SCHEDULE_MINUTE: 30,
        NOTIFICATION_SCHEDULE_SECOND: 45,
        NOTIFICATION_SCHEDULE_WEEKDAY: 1,
        NOTIFICATION_SCHEDULE_WEEKOFYEAR: 23,
      };

      NotificationCalendar calendar =
          NotificationCalendar().fromMap(dataMap) as NotificationCalendar;

      expect(calendar.era, 1);
      expect(calendar.year, 2023);
      expect(calendar.month, 5);
      expect(calendar.day, 1);
      expect(calendar.hour, 12);
      expect(calendar.minute, 30);
      expect(calendar.second, 45);
      expect(calendar.weekday, 1);
      expect(calendar.weekOfYear, 23);
    });

    test(
        'should throw an exception a NotificationCalendar '
        'object fromMap warning about weekOfMonth is not implemented yet', () {
      Map<String, dynamic> dataMap = {
        NOTIFICATION_SCHEDULE_ERA: 1,
        NOTIFICATION_SCHEDULE_YEAR: 2023,
        NOTIFICATION_SCHEDULE_MONTH: 5,
        NOTIFICATION_SCHEDULE_DAY: 1,
        NOTIFICATION_SCHEDULE_HOUR: 12,
        NOTIFICATION_SCHEDULE_MINUTE: 30,
        NOTIFICATION_SCHEDULE_SECOND: 45,
        NOTIFICATION_SCHEDULE_WEEKDAY: 1,
        NOTIFICATION_SCHEDULE_WEEKOFYEAR: 23,
        NOTIFICATION_SCHEDULE_WEEKOFMONTH: 1
      };

      expect(
          () => NotificationCalendar()
            ..fromMap(dataMap)
            ..validate(),
          throwsA(isA<UnimplementedError>()));
    });

    test('should create a NotificationCalendar object fromDate using local',
        () {
      DateTime date = DateTime(2023, 5, 1, 12, 30, 45);
      NotificationCalendar calendar = NotificationCalendar.fromDate(date: date);

      expect(calendar.year, 2023);
      expect(calendar.month, 5);
      expect(calendar.day, 1);
      expect(calendar.hour, 12);
      expect(calendar.minute, 30);
      expect(calendar.second, 45);
    });

    test('should create a NotificationCalendar object fromDate using UTC', () {
      DateTime date = DateTime.utc(2023, 5, 1, 12, 30, 45);
      NotificationCalendar calendar = NotificationCalendar.fromDate(date: date);

      expect(calendar.year, 2023);
      expect(calendar.month, 5);
      expect(calendar.day, 1);
      expect(calendar.hour, 12);
      expect(calendar.minute, 30);
      expect(calendar.second, 45);
    });

    test('should throw an exception if no time condition is provided', () {
      expect(
          () => NotificationCalendar().validate(),
          throwsA(isA<AwesomeNotificationsException>().having(
              (error) => error.message,
              'message',
              'At least one shedule time condition is required.')));
    });

    test('should throw an exception if weekOfMonth is used', () {
      expect(
          () => NotificationCalendar(weekOfMonth: 2),
          throwsA(isA<UnimplementedError>().having((error) => error.message,
              'message', 'weekOfMonth is not fully implemented yet')));
    });

    test('should throw an exception if a time condition is negative', () {
      expect(
          () => NotificationCalendar(day: -1).validate(),
          throwsA(isA<AwesomeNotificationsException>().having(
              (error) => error.message,
              'message',
              'A shedule time condition must be greater or equal to zero.')));
    });
  });
}
