import 'package:awesome_notifications/awesome_notifications.dart';

/// Abstract base class for a notification schedule configuration.
///
/// A schedule is a [NotificationExtension]: it is attached to a notification
/// through the core's
/// `createNotification(extensions: [NotificationCalendar(...) | NotificationInterval(...)])`.
/// As an extension it contributes a top-level `schedule` block to the serialized
/// notification map ([toMap]); the native scheduling decorator reads that block
/// and registers the delayed delivery. The core stays unaware of scheduling.
///
/// Concrete subclasses ([NotificationInterval], [NotificationCalendar]) extend
/// the flat serialization via [toScheduleMap].
abstract class NotificationSchedule extends Model
    implements NotificationExtension {
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

  /// Creates a [NotificationSchedule] instance from a map of the flat `schedule`
  /// block. Returns null if invalid [mapData] is provided.
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

  /// The flat `schedule` block (timeZone, repeats, …). Subclasses extend this
  /// with their own scheduling fields.
  Map<String, dynamic> toScheduleMap() {
    return {
      NOTIFICATION_SCHEDULE_TIMEZONE: timeZone,
      NOTIFICATION_ALLOW_WHILE_IDLE: allowWhileIdle,
      NOTIFICATION_SCHEDULE_REPEATS: repeats,
      NOTIFICATION_SCHEDULE_PRECISE_ALARM: preciseAlarm,
      NOTIFICATION_SCHEDULE_DELAY_TOLERANCE: delayTolerance
    };
  }

  /// [NotificationExtension] contract: contributes the `schedule` block to the
  /// notification map, as a sibling of `content` / `actionButtons`.
  @override
  Map<String, dynamic> toMap() {
    return {NOTIFICATION_SCHEDULE: toScheduleMap()};
  }
}
