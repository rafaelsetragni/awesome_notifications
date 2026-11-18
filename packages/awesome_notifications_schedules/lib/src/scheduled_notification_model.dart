import 'package:awesome_notifications/awesome_notifications.dart';

import 'notification_calendar.dart';
import 'notification_interval.dart';
import 'notification_schedule.dart';

/// A scheduled notification, as returned by
/// `AwesomeNotificationsSchedules().listScheduledNotifications()`.
///
/// It is the core [NotificationModel] plus the [schedule] it was created with —
/// the same shape 0.12's `NotificationModel` had: [toMap] carries the
/// `schedule` block next to `content` / `actionButtons`.
class ScheduledNotificationModel extends NotificationModel {
  NotificationSchedule? _schedule;

  /// The schedule to display the notification.
  NotificationSchedule? get schedule => _schedule;

  ScheduledNotificationModel({
    super.content,
    super.actionButtons,
    NotificationSchedule? schedule,
  }) : _schedule = schedule;

  /// Imports data from a serializable object.
  @override
  ScheduledNotificationModel? fromMap(Map<String, dynamic> mapData) {
    try {
      if (super.fromMap(mapData) == null) return null;
      _schedule = _extractScheduleFromMap(mapData);
    } catch (e) {
      return null;
    }
    return this;
  }

  // Same type resolution as 0.12's NotificationModel.
  NotificationSchedule? _extractScheduleFromMap(Map<String, dynamic> mapData) {
    if (mapData[NOTIFICATION_SCHEDULE] is! Map) return null;
    if (mapData[NOTIFICATION_SCHEDULE].isEmpty) return null;

    Map<String, dynamic> scheduleData =
        Map<String, dynamic>.from(mapData[NOTIFICATION_SCHEDULE]);

    if (scheduleData.containsKey(NOTIFICATION_SCHEDULE_INTERVAL)) {
      return NotificationInterval(interval: Duration.zero).fromMap(scheduleData)
        ?..validate();
    }

    return NotificationCalendar().fromMap(scheduleData)?..validate();
  }

  /// Exports all content into a serializable object.
  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> base = super.toMap();
    return {
      NOTIFICATION_CONTENT: base[NOTIFICATION_CONTENT],
      if (_schedule != null) NOTIFICATION_SCHEDULE: _schedule!.toScheduleMap(),
      if (base.containsKey(NOTIFICATION_BUTTONS))
        NOTIFICATION_BUTTONS: base[NOTIFICATION_BUTTONS],
    };
  }
}
