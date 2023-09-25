import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('toString', () {
    test('toString prints the respective inherited notification model', () {
      NotificationSchedule schedule1 = NotificationCalendar(second: 0);
      NotificationSchedule schedule2 = NotificationInterval(interval: 60);
      NotificationSchedule schedule3 =
          NotificationAndroidCrontab(crontabExpression: '0 30 14 * * *');

      expect(
          schedule1.toString(),
          '{timeZone: UTC,\n'
          ' allowWhileIdle: false,\n'
          ' repeats: false,\n'
          ' preciseAlarm: true,\n'
          ' delayTolerance: 600000,\n'
          ' era: null,\n'
          ' year: null,\n'
          ' month: null,\n'
          ' day: null,\n'
          ' hour: null,\n'
          ' minute: null,\n'
          ' second: 0,\n'
          ' weekday: null,\n'
          ' weekOfMonth: null,\n'
          ' weekOfYear: null}');

      expect(
          schedule2.toString(),
          '{timeZone: UTC,\n'
          ' allowWhileIdle: false,\n'
          ' repeats: false,\n'
          ' preciseAlarm: true,\n'
          ' delayTolerance: 600000,\n'
          ' interval: 60}');

      expect(
          schedule3.toString(),
          '{timeZone: UTC,\n'
          ' allowWhileIdle: false,\n'
          ' repeats: false,\n'
          ' preciseAlarm: true,\n'
          ' delayTolerance: 600000,\n'
          ' crontabExpression: 0 30 14 * * *,\n'
          ' initialDateTime: null,\n'
          ' expirationDateTime: null,\n'
          ' preciseSchedules: null}');
    });
  });
}
