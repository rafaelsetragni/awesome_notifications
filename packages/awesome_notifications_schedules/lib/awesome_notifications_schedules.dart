/// Notification scheduling for awesome_notifications.
///
/// Schedule a notification by passing a concrete [NotificationSchedule]
/// ([NotificationInterval] or [NotificationCalendar]) as an **extension** to the
/// core's `createNotification`:
///
/// ```dart
/// await AwesomeNotifications().createNotification(
///   content: NotificationContent(id: 1, channelKey: 'basic', title: 'Hi'),
///   extensions: [
///     NotificationCalendar(hour: 8, minute: 0, repeats: true),
///   ],
/// );
/// ```
///
/// The native scheduling decorator (installed automatically when this package is
/// added) intercepts the build and registers the delayed delivery. The core
/// stays unaware of scheduling.
library;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/services.dart';

import 'src/notification_schedule.dart';

export 'src/notification_calendar.dart';
export 'src/notification_interval.dart';
export 'src/notification_schedule.dart';

/// Entry point of the scheduling decorator's schedule-management API.
///
/// Creating scheduled notifications does **not** require this class — pass a
/// schedule via `createNotification(extensions: [...])`. This class only groups
/// the schedule-specific operations that used to live on the core
/// (cancel-schedule, list, next-date), keeping the core scheduling-agnostic. It
/// talks to the same native plugin over the shared `awesome_notifications`
/// channel.
class AwesomeNotificationsSchedules {
  static final AwesomeNotificationsSchedules _instance =
      AwesomeNotificationsSchedules._();
  factory AwesomeNotificationsSchedules() => _instance;
  AwesomeNotificationsSchedules._();

  static const MethodChannel _channel = MethodChannel('awesome_notifications');

  /// Cancels a single scheduled notification without dismissing the active one.
  Future<void> cancelSchedule(int id) async {
    await _channel.invokeMethod(CHANNEL_METHOD_CANCEL_SCHEDULE, id);
  }

  /// Cancels all schedules on the given [channelKey], leaving active
  /// notifications intact.
  Future<void> cancelSchedulesByChannelKey(String channelKey) async {
    await _channel.invokeMethod(
        CHANNEL_METHOD_CANCEL_SCHEDULES_BY_CHANNEL_KEY, channelKey);
  }

  /// Cancels all schedules on the given [groupKey], leaving active
  /// notifications intact.
  Future<void> cancelSchedulesByGroupKey(String groupKey) async {
    await _channel.invokeMethod(
        CHANNEL_METHOD_CANCEL_SCHEDULES_BY_GROUP_KEY, groupKey);
  }

  /// Cancels all schedules, leaving active notifications intact.
  Future<void> cancelAllSchedules() async {
    await _channel.invokeMethod(CHANNEL_METHOD_CANCEL_ALL_SCHEDULES);
  }

  /// Lists all active scheduled notifications.
  Future<List<NotificationModel>> listScheduledNotifications() async {
    final List<Object>? returned =
        await _channel.invokeListMethod(CHANNEL_METHOD_LIST_ALL_SCHEDULES);
    final List<NotificationModel> scheduled = [];
    if (returned != null) {
      for (final Object object in returned) {
        if (object is Map) {
          final NotificationModel? model =
              NotificationModel().fromMap(Map<String, dynamic>.from(object));
          if (model != null) scheduled.add(model);
        }
      }
    }
    return scheduled;
  }

  /// Computes the next valid delivery date for a [schedule], relative to
  /// [fixedDate] (defaults to now). Returns null when the schedule has no future
  /// occurrence.
  Future<DateTime?> getNextDate(NotificationSchedule schedule,
      {DateTime? fixedDate}) async {
    fixedDate ??= DateTime.now().toUtc();
    final Map<String, dynamic> parameters = {
      NOTIFICATION_INITIAL_FIXED_DATE:
          AwesomeDateUtils.parseDateToString(fixedDate),
      NOTIFICATION_SCHEDULE: schedule.toScheduleMap(),
    };

    final String? nextDate =
        await _channel.invokeMethod(CHANNEL_METHOD_GET_NEXT_DATE, parameters);
    if (nextDate == null) return null;
    return AwesomeDateUtils.parseStringToDate(nextDate);
  }
}
