import 'package:awesome_notifications/src/models/model.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';

import '../definitions.dart';

/// Notification schedule configuration
/// [timeZone]: time zone reference to this schedule
/// [crontabExpression]: Crontab expression as repetition rule (with seconds precision), as described in https://www.baeldung.com/cron-expressions
/// [allowWhileIdle]: Determines if notification will send, even when the device is in critical situation, such as low battery.

abstract class NotificationSchedule extends Model {
  NotificationSchedule(
      {required this.timeZone,
      this.allowWhileIdle = false,
      this.repeats = false,
      this.preciseAlarm = false,
      this.delayTolerance = 600000});

  String? _createdDate;

  /// Reference
  String? get createdDate => _createdDate;

  /// Full time zone identifier to schedule a notification, in english (ex: America/Sao_Paulo, America/New_York, Europe/Helsinki or GMT-07:00)
  String timeZone;

  /// Displays the notification, even when the device is low battery
  bool allowWhileIdle;

  /// Require schedules to be precise, even when the device is low battery. Requires explicit permission in Android 12 and beyond.
  bool preciseAlarm;

  /// Delay tolerance in milliseconds to schedule notifications being displayed. The minimum tolerance for inexact schedules is 600.000 (10 minutes).
  int delayTolerance;

  /// Specify false to deliver the notification one time. Specify true to reschedule the notification request each time the notification is delivered.
  bool repeats;

  /// Returns null if  invalid mapData is provided
  @override
  NotificationSchedule? fromMap(Map<String, dynamic> mapData) {
    timeZone = AwesomeAssertUtils.extractValue(
            NOTIFICATION_SCHEDULE_TIMEZONE, mapData, String) ?? timeZone;

    allowWhileIdle = AwesomeAssertUtils.extractValue(
            NOTIFICATION_ALLOW_WHILE_IDLE, mapData, bool) ??
        false;

    repeats = AwesomeAssertUtils.extractValue(
            NOTIFICATION_SCHEDULE_REPEATS, mapData, bool) ??
        false;

    delayTolerance = AwesomeAssertUtils.extractValue(
        NOTIFICATION_SCHEDULE_DELAY_TOLERANCE, mapData, int) ??
        0;

    preciseAlarm = AwesomeAssertUtils.extractValue(
        NOTIFICATION_SCHEDULE_PRECISE_ALARM, mapData, bool) ??
        false;

    return this;
  }

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> dataMap = {
      NOTIFICATION_SCHEDULE_TIMEZONE: timeZone,
      NOTIFICATION_ALLOW_WHILE_IDLE: allowWhileIdle,
      NOTIFICATION_SCHEDULE_REPEATS: repeats,
      NOTIFICATION_SCHEDULE_PRECISE_ALARM: preciseAlarm,
      NOTIFICATION_SCHEDULE_DELAY_TOLERANCE: delayTolerance
    };

    return dataMap;
  }

  @override
  String toString() {
    return toMap().toString().replaceAll(',', ',\n');
  }
}
