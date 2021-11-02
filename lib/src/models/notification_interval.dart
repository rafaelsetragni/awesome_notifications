import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/src/models/notification_schedule.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';

class NotificationInterval extends NotificationSchedule {
  /// Field number for get and set indicating the amount of seconds between each repetition (greater than 0).
  int? interval;

  /// Notification Schedule based on calendar components. At least one date parameter is required.
  /// [interval] Time interval between each notification (minimum of 60 sec case repeating)
  /// [allowWhileIdle] Displays the notification, even when the device is low battery
  /// [repeats] Defines if the notification should play only once or keeps repeating
  /// [timeZone] time zone identifier as reference of this schedule date. (https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
  NotificationInterval({
    required int interval,
    String? timeZone,
    bool allowWhileIdle = false,
    bool repeats = false,
  }) : super(
            timeZone: timeZone ?? AwesomeNotifications.localTimeZoneIdentifier,
            allowWhileIdle: allowWhileIdle,
            repeats: repeats) {
    this.interval = interval;
  }

  @override
  NotificationInterval? fromMap(Map<String, dynamic> dataMap) {
    this.timeZone = AssertUtils.extractValue(
        NOTIFICATION_SCHEDULE_TIMEZONE, dataMap, String);
    this.interval = AssertUtils.extractValue(
        NOTIFICATION_SCHEDULE_INTERVAL, dataMap, String);
    this.repeats =
        AssertUtils.extractValue(NOTIFICATION_SCHEDULE_REPEATS, dataMap, bool);
    this.allowWhileIdle = AssertUtils.extractValue(
        NOTIFICATION_SCHEDULE_ALLOW_WHILE_IDLE, dataMap, bool);

    try {
      validate();
    } catch (e) {
      return null;
    }

    return this;
  }

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> dataMap = {
      NOTIFICATION_SCHEDULE_TIMEZONE: this.timeZone,
      NOTIFICATION_SCHEDULE_ALLOW_WHILE_IDLE: this.allowWhileIdle,
      NOTIFICATION_SCHEDULE_INTERVAL: this.interval,
      NOTIFICATION_SCHEDULE_REPEATS: this.repeats
    };

    return dataMap;
  }

  @override
  String toString() {
    return toMap().toString().replaceAll(',', ',\n');
  }

  @override
  void validate() {
    assert((this.interval ?? -1) >= 0);

    assert(this.repeats && (this.interval ?? 0) >= 60,
        'time interval must be at least 60 if repeating');
  }
}
