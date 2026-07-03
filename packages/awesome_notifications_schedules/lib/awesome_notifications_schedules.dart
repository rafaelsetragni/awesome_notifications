/// Notification scheduling for awesome_notifications.
///
/// Schedule a notification by passing a concrete [NotificationSchedule]
/// ([NotificationInterval] or [NotificationCalendar]) to the core's
/// `AwesomeNotifications().createNotification(..., schedule: ...)`.
library;

import 'package:awesome_notifications/awesome_notifications.dart';

import 'src/notification_calendar.dart';
import 'src/notification_interval.dart';

export 'src/notification_calendar.dart';
export 'src/notification_interval.dart';

/// Entry point of the scheduling decorator.
///
/// Notifications are still created through the core
/// `AwesomeNotifications().createNotification(..., schedule: NotificationCalendar(...))`;
/// this class only registers the decoder the core uses to rebuild a concrete
/// schedule from its serialized map (e.g. when listing scheduled notifications).
class AwesomeNotificationsSchedules {
  static final AwesomeNotificationsSchedules _instance =
      AwesomeNotificationsSchedules._();
  factory AwesomeNotificationsSchedules() => _instance;
  AwesomeNotificationsSchedules._();

  /// Registers the concrete schedule decoder on the core. Call once at startup,
  /// before listing scheduled notifications.
  void initialize() {
    NotificationModel.scheduleDecoder = _decodeSchedule;
  }

  /// Rebuilds a concrete [NotificationSchedule] from a serialized map: an
  /// `interval` key means a [NotificationInterval]; otherwise a
  /// [NotificationCalendar].
  static NotificationSchedule? _decodeSchedule(Map<String, dynamic> data) {
    if (data.containsKey(NOTIFICATION_SCHEDULE_INTERVAL)) {
      return NotificationInterval(interval: Duration.zero).fromMap(data);
    }
    return NotificationCalendar().fromMap(data);
  }
}
