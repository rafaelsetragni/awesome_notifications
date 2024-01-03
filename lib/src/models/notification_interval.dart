import '../../awesome_notifications.dart';

/// Represents a notification scheduling configuration based on time intervals.
class NotificationInterval extends NotificationSchedule {
  /// The amount of seconds between each notification repetition. Must be greater than 0 or 60 if repeating.
  int? interval;

  /// Constructs a [NotificationInterval] object with various scheduling options.
  ///
  /// [interval] specifies the time interval between each notification (minimum of 60 seconds if repeating).
  /// [timeZone] specifies the time zone identifier as a reference for the schedule date.
  /// [allowWhileIdle] allows the notification to be displayed even when the device is in low battery mode.
  /// [repeats] determines whether the notification should play only once or keep repeating.
  /// [preciseAlarm] enables maximum precision for scheduling notifications at exact times, which may consume more battery. Requires explicit user consent on Android 12 and beyond.
  NotificationInterval(
      {required this.interval,
      String? timeZone,
      super.allowWhileIdle,
      super.repeats,
      super.preciseAlarm = true})
      : super(
            timeZone: timeZone ?? AwesomeNotifications.localTimeZoneIdentifier);

  /// Creates a [NotificationInterval] instance from a map of data.
  @override
  NotificationInterval? fromMap(Map<String, dynamic> mapData) {
    super.fromMap(mapData);

    interval = AwesomeAssertUtils.extractValue<int>(
        NOTIFICATION_SCHEDULE_INTERVAL, mapData);

    try {
      validate();
    } catch (e) {
      return null;
    }

    return this;
  }

  /// Converts the [NotificationInterval] instance to a map.
  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = super.toMap();
    return map..addAll({NOTIFICATION_SCHEDULE_INTERVAL: interval});
  }

  /// Returns a string representation of the [NotificationInterval] instance.
  @override
  String toString() {
    return toMap().toString().replaceAll(',', ',\n');
  }

  /// Validates the notification interval settings.
  ///
  /// Throws an [AwesomeNotificationsException] if the interval is negative or less than 60 seconds when repeating.
  @override
  void validate() {
    if ((interval ?? -1) < 0) {
      throw const AwesomeNotificationsException(
          message: 'interval must be greater or equal to zero.');
    }

    if (repeats && (interval ?? 0) < 60) {
      throw const AwesomeNotificationsException(
          message: 'time interval must be greater or equal to 60 if repeating');
    }
  }
}
