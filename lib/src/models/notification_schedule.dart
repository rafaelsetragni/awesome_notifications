import 'package:awesome_notifications/src/models/model.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';

import '../definitions.dart';

/// Abstract base class for notification schedule configuration.
/// Defines the common properties and methods for scheduling notifications.
abstract class NotificationSchedule extends Model {
  /// Constructs a [NotificationSchedule] with various scheduling options.
  ///
  /// [timeZone]: Specifies the time zone reference for the schedule.
  /// [allowWhileIdle]: Determines if the notification should be sent even in critical device situations like low battery.
  /// [repeats]: Specifies whether the notification should repeat.
  /// [preciseAlarm]: Requires precise scheduling, which may consume more battery. Needs explicit permission on Android 12+.
  /// [delayTolerance]: Specifies the delay tolerance in milliseconds for scheduling notifications.
  NotificationSchedule(
      {required this.timeZone,
      this.allowWhileIdle = false,
      this.repeats = false,
      this.preciseAlarm = false,
      this.delayTolerance = 600000});

  /// Full time zone identifier for scheduling the notification. Example: 'America/Sao_Paulo', 'America/New_York', 'Europe/Helsinki'.
  String timeZone;

  /// Allows the notification to be displayed even when the device is in low battery mode.
  bool allowWhileIdle;

  /// Requires precise timing for the notification schedule, especially important on devices with strict power-saving features.
  bool preciseAlarm;

  /// Delay tolerance in milliseconds for scheduling the notification. Minimum tolerance is typically 600,000 ms (10 minutes).
  int delayTolerance;

  /// Indicates whether the notification should be delivered once (false) or rescheduled each time it's delivered (true).
  bool repeats;

  /// Creates a [NotificationSchedule] instance from a map of data.
  /// Returns null if invalid [mapData] is provided.
  @override
  NotificationSchedule? fromMap(Map<String, dynamic> mapData) {
    timeZone = AwesomeAssertUtils.extractValue(
            NOTIFICATION_SCHEDULE_TIMEZONE, mapData) ??
        timeZone;

    allowWhileIdle = AwesomeAssertUtils.extractValue(
            NOTIFICATION_ALLOW_WHILE_IDLE, mapData) ??
        false;

    repeats = AwesomeAssertUtils.extractValue(
            NOTIFICATION_SCHEDULE_REPEATS, mapData) ??
        false;

    delayTolerance = AwesomeAssertUtils.extractValue(
            NOTIFICATION_SCHEDULE_DELAY_TOLERANCE, mapData) ??
        0;

    preciseAlarm = AwesomeAssertUtils.extractValue(
            NOTIFICATION_SCHEDULE_PRECISE_ALARM, mapData) ??
        false;

    return this;
  }

  /// Converts the [NotificationSchedule] instance to a map.
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
}
