import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/src/exceptions/awesome_exception.dart';
import 'package:awesome_notifications/src/models/notification_schedule.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';

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
      {required int interval,
      String? timeZone,
      bool allowWhileIdle = false,
      bool repeats = false,
      bool preciseAlarm = false})
      : super(
            timeZone: timeZone ?? AwesomeNotifications.localTimeZoneIdentifier,
            allowWhileIdle: allowWhileIdle,
            repeats: repeats,
            preciseAlarm: preciseAlarm) {
    this.interval = interval;
  }

  @override
  NotificationInterval? fromMap(Map<String, dynamic> dataMap) {
    super.fromMap(dataMap);

    this.interval = AssertUtils.extractValue(
        NOTIFICATION_SCHEDULE_INTERVAL, dataMap, String);

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
    return map..addAll({NOTIFICATION_SCHEDULE_INTERVAL: this.interval});
  }

  @override
  String toString() {
    return toMap().toString().replaceAll(',', ',\n');
  }

  @override
  void validate() {
    if ((this.interval ?? -1) < 0)
      throw AwesomeNotificationsException(
          message: 'interval must be greater or equal to zero.');

    if (this.repeats && (this.interval ?? 0) < 60)
      throw AwesomeNotificationsException(
          message: 'time interval must be greater or equal to 60 if repeating');
  }
}
