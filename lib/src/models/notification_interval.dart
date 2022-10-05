import '../../awesome_notifications.dart';

class NotificationInterval extends NotificationSchedule {
  /// Field number for get and set indicating the amount of seconds between each repetition (greater than 0).
  int? interval;

  /// Notification Schedule based on calendar components. At least one date parameter is required.
  /// [interval] Time interval between each notification (minimum of 60 sec case repeating)
  /// [allowWhileIdle] Displays the notification, even when the device is low battery
  /// [repeats] Defines if the notification should play only once or keeps repeating
  /// [preciseAlarm] Requires maximum precision to schedule notifications at exact time, but may use more battery. Requires the explicit user consent for Android 12 and beyond.
  /// [timeZone] time zone identifier as reference of this schedule date. (https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
  NotificationInterval(
      {required this.interval,
      String? timeZone,
      bool allowWhileIdle = false,
      bool repeats = false,
      bool preciseAlarm = false})
      : super(
            timeZone: timeZone ?? AwesomeNotifications.localTimeZoneIdentifier,
            allowWhileIdle: allowWhileIdle,
            repeats: repeats,
            preciseAlarm: preciseAlarm);

  @override
  NotificationInterval? fromMap(Map<String, dynamic> mapData) {
    super.fromMap(mapData);

    interval = AwesomeAssertUtils.extractValue(
        NOTIFICATION_SCHEDULE_INTERVAL, mapData, String);

    try {
      validate();
    } catch (e) {
      return null;
    }

    return this;
  }

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = super.toMap();
    return map..addAll({NOTIFICATION_SCHEDULE_INTERVAL: interval});
  }

  @override
  String toString() {
    return toMap().toString().replaceAll(',', ',\n');
  }

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
