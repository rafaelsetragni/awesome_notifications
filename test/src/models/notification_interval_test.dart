import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() {
  group('NotificationInterval', () {
    test('should create a NotificationInterval object fromMap', () {
      Map<String, dynamic> dataMap = {
        NOTIFICATION_SCHEDULE_INTERVAL: 120,
      };

      NotificationInterval interval = NotificationInterval(interval: 120)
          .fromMap(dataMap) as NotificationInterval;

      expect(interval.interval, 120);
    });

    test('should throw an exception if interval is negative', () {
      expect(
          () => NotificationInterval(interval: -1).validate(),
          throwsA(isA<AwesomeNotificationsException>().having(
              (error) => error.message,
              'message',
              'interval must be greater or equal to zero.')));
    });

    test('should throw an exception if interval is less than 60 and repeating',
        () {
      expect(
          () => NotificationInterval(interval: 59, repeats: true).validate(),
          throwsA(isA<AwesomeNotificationsException>().having(
              (error) => error.message,
              'message',
              'time interval must be greater or equal to 60 if repeating')));
    });
  });
  group('NotificationInterval - toMap and fromMap', () {
    test('should create a NotificationInterval object and convert it to a map',
        () {
      NotificationInterval interval = NotificationInterval(interval: 120);
      Map<String, dynamic> intervalMap = interval.toMap();
      expect(intervalMap[NOTIFICATION_SCHEDULE_INTERVAL], 120);
    });

    test('should create a NotificationInterval object from a map', () {
      Map<String, dynamic> dataMap = {
        NOTIFICATION_SCHEDULE_INTERVAL: 120,
      };
      NotificationInterval interval = NotificationInterval(interval: 120)
          .fromMap(dataMap) as NotificationInterval;
      expect(interval.interval, 120);
    });

    test(
        'should create a NotificationInterval object and convert it back from a map',
        () {
      NotificationInterval interval = NotificationInterval(
        interval: 120,
        timeZone: 'America/New_York',
        allowWhileIdle: true,
        repeats: true,
        preciseAlarm: true,
      );
      Map<String, dynamic> intervalMap = interval.toMap();
      NotificationInterval intervalFromMap = NotificationInterval(interval: 0)
          .fromMap(intervalMap) as NotificationInterval;

      expect(intervalFromMap.interval, 120);
      expect(intervalFromMap.timeZone, 'America/New_York');
      expect(intervalFromMap.allowWhileIdle, true);
      expect(intervalFromMap.repeats, true);
      expect(intervalFromMap.preciseAlarm, true);
    });
  });

  group('NotificationInterval - toString', () {
    test(
        'should return a string representation of a NotificationInterval object',
        () {
      NotificationInterval interval = NotificationInterval(
        interval: 120,
        timeZone: 'America/New_York',
        allowWhileIdle: true,
        repeats: true,
        preciseAlarm: true,
      );

      String intervalString = interval.toString();
      expect(intervalString.contains('interval: 120'), true);
      expect(intervalString.contains('timeZone: America/New_York'), true);
      expect(intervalString.contains('allowWhileIdle: true'), true);
      expect(intervalString.contains('repeats: true'), true);
      expect(intervalString.contains('preciseAlarm: true'), true);
    });
  });
}
