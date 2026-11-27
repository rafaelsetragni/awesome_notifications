import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_schedules/awesome_notifications_schedules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a schedule map without a time zone keeps the current one', () {
    final interval = NotificationInterval(interval: const Duration(minutes: 1), timeZone: 'America/Sao_Paulo')
        .fromMap({NOTIFICATION_SCHEDULE_INTERVAL: 120})!;
    expect(interval.timeZone, 'America/Sao_Paulo');
    expect(interval.interval, const Duration(minutes: 2));
  });

  test('a scheduled model keeps its buttons next to content and schedule', () {
    final map = ScheduledNotificationModel(
      content: NotificationContent(id: 1, channelKey: 'ch'),
      actionButtons: [NotificationActionButton(key: 'OK', label: 'Ok')],
      schedule: NotificationInterval(interval: const Duration(minutes: 1)),
    ).toMap();
    expect((map[NOTIFICATION_BUTTONS] as List).single[NOTIFICATION_KEY], 'OK');
    expect(map[NOTIFICATION_SCHEDULE], isA<Map>());
  });

  test('weekOfMonth is refused (as in 0.12)', () {
    // ignore: deprecated_member_use_from_same_package
    expect(() => NotificationCalendar(weekOfMonth: 1), throwsUnimplementedError);
    // ignore: deprecated_member_use_from_same_package
    final calendar = NotificationCalendar(day: 1)..weekOfMonth = 1;
    expect(calendar.validate, throwsUnimplementedError);
  });
}
