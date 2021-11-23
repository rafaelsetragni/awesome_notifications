import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/src/exceptions/awesome_exception.dart';
import 'package:awesome_notifications/src/models/notification_schedule.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';

class NotificationCalendar extends NotificationSchedule {
  /// Field number for get and set indicating the era, e.g., AD or BC in the Julian calendar
  int? era;

  /// Field number for get and set indicating the year.
  int? year;

  /// Field number for get and set indicating the month of the year (1-12).
  int? month;

  /// Field number for get and set indicating the day of the month (1-31).
  int? day;

  /// Field number for get and set indicating the hour of the day (0-23).
  int? hour;

  /// Field number for get and set indicating the minute within the hour (0-59).
  int? minute;

  /// Field number for get and set indicating the second within the minute (0-59).
  int? second;

  /// Field number for get and set indicating the millisecond within the second.
  @Deprecated(
      'Millisecond precision was deprecated, due devices do not provide or ignore such precision. The value will be ignored')
  int? millisecond;

  /// Field number for get and set indicating the day of the week (1 = Monday).
  int? weekday;

  /// Field number for get and set indicating the count of weeks of the month.
  int? weekOfMonth;

  /// Field number for get and set indicating the weeks of the year.
  int? weekOfYear;

  /// Notification Schedule based on calendar components. At least one date parameter is required.
  /// [era] Schedule era condition
  /// [year] Schedule year condition
  /// [month] Schedule month condition
  /// [day] Schedule day condition
  /// [hour] Schedule hour condition
  /// [minute] Schedule minute condition
  /// [second] Schedule second condition
  /// [weekday] Schedule weekday condition
  /// [weekOfMonth] Schedule weekOfMonth condition
  /// [weekOfMonth] Schedule weekOfMonth condition
  /// [weekOfYear] Schedule weekOfYear condition
  /// [allowWhileIdle] Displays the notification, even when the device is low battery
  /// [repeats] Defines if the notification should play only once or keeps repeating
  /// [preciseAlarm] Requires maximum precision to schedule notifications at exact time, but may use more battery. Requires the explicit user consent for Android 12 and beyond.
  /// [timeZone] time zone identifier as reference of this schedule date. (https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
  NotificationCalendar({
    this.era,
    this.year,
    this.month,
    this.day,
    this.hour,
    this.minute,
    this.second,
    this.millisecond,
    this.weekday,
    this.weekOfMonth,
    this.weekOfYear,
    String? timeZone,
    bool allowWhileIdle = false,
    bool preciseAlarm = false,
    bool repeats = false,
  }) : super(
            timeZone: timeZone ?? AwesomeNotifications.localTimeZoneIdentifier,
            allowWhileIdle: allowWhileIdle,
            repeats: repeats,
            preciseAlarm: preciseAlarm);

  /// Initialize a notification schedule calendar based on a date object
  NotificationCalendar.fromDate(
      {required DateTime date,
      bool allowWhileIdle = false,
      bool repeats = false,
      bool preciseAlarm = false})
      : super(
            timeZone: date.isUtc
                ? AwesomeNotifications.utcTimeZoneIdentifier
                : AwesomeNotifications.localTimeZoneIdentifier,
            allowWhileIdle: allowWhileIdle,
            repeats: repeats,
            preciseAlarm: preciseAlarm) {
    this.year = date.year;
    this.month = date.month;
    this.day = date.day;
    this.hour = date.hour;
    this.minute = date.minute;
    this.second = date.second;
  }

  @override
  NotificationCalendar? fromMap(Map<String, dynamic> dataMap) {
    this.era =
        AssertUtils.extractValue(NOTIFICATION_SCHEDULE_ERA, dataMap, int);
    this.year =
        AssertUtils.extractValue(NOTIFICATION_SCHEDULE_YEAR, dataMap, int);
    this.month =
        AssertUtils.extractValue(NOTIFICATION_SCHEDULE_MONTH, dataMap, int);
    this.day =
        AssertUtils.extractValue(NOTIFICATION_SCHEDULE_DAY, dataMap, int);
    this.hour =
        AssertUtils.extractValue(NOTIFICATION_SCHEDULE_HOUR, dataMap, int);
    this.minute =
        AssertUtils.extractValue(NOTIFICATION_SCHEDULE_MINUTE, dataMap, int);
    this.second =
        AssertUtils.extractValue(NOTIFICATION_SCHEDULE_SECOND, dataMap, int);
    this.weekday =
        AssertUtils.extractValue(NOTIFICATION_SCHEDULE_WEEKDAY, dataMap, int);
    this.weekOfMonth = AssertUtils.extractValue(
        NOTIFICATION_SCHEDULE_WEEKOFMONTH, dataMap, int);
    this.weekOfYear = AssertUtils.extractValue(
        NOTIFICATION_SCHEDULE_WEEKOFYEAR, dataMap, int);

    super.fromMap(dataMap);

    try {
      validate();
    } catch (e) {
      return null;
    }

    return this;
  }

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> dataMap = super.toMap()
      ..addAll({
        NOTIFICATION_SCHEDULE_ERA: this.era,
        NOTIFICATION_SCHEDULE_YEAR: this.year,
        NOTIFICATION_SCHEDULE_MONTH: this.month,
        NOTIFICATION_SCHEDULE_DAY: this.day,
        NOTIFICATION_SCHEDULE_HOUR: this.hour,
        NOTIFICATION_SCHEDULE_MINUTE: this.minute,
        NOTIFICATION_SCHEDULE_SECOND: this.second,
        NOTIFICATION_SCHEDULE_WEEKDAY: this.weekday,
        NOTIFICATION_SCHEDULE_WEEKOFMONTH: this.weekOfMonth,
        NOTIFICATION_SCHEDULE_WEEKOFYEAR: this.weekOfYear
      });

    return dataMap;
  }

  @override
  String toString() {
    return toMap().toString().replaceAll(',', ',\n');
  }

  @override
  void validate() {
    if (this.era == null &&
        this.year == null &&
        this.month == null &&
        this.day == null &&
        this.hour == null &&
        this.minute == null &&
        this.second == null &&
        this.weekday == null &&
        this.weekOfMonth == null &&
        this.weekOfYear == null)
      throw AwesomeNotificationsException(
          message: 'At least one shedule time condition is required.');

    if ((this.era ?? 0) < 0 ||
        (this.year ?? 0) < 0 ||
        (this.month ?? 0) < 0 ||
        (this.day ?? 0) < 0 ||
        (this.hour ?? 0) < 0 ||
        (this.minute ?? 0) < 0 ||
        (this.second ?? 0) < 0 ||
        (this.weekday ?? 0) < 0 ||
        (this.weekOfMonth ?? 0) < 0 ||
        (this.weekOfYear ?? 0) < 0)
      throw AwesomeNotificationsException(
          message:
              'A shedule time condition must be greater or equal to zero.');
  }
}
