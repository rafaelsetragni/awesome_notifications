import 'package:awesome_notifications/awesome_notifications.dart';
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
  int? millisecond;

  /// Field number for get and set indicating the day of the week (1 = Monday).
  int? weekday;

  /// Field number for get and set indicating the count of weeks of the month.
  int? weekOfMonth;

  /// Field number for get and set indicating the weeks of the year.
  int? weekOfYear;

  /// Notification Schedule based on calendar components. At least one date parameter is required.
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
    bool repeats = false,
  }) : super(
            timeZone: timeZone ?? AwesomeNotifications.localTimeZoneIdentifier,
            allowWhileIdle: allowWhileIdle,
            repeats: repeats);

  /// Initialize a notification schedule calendar based on a date object
  NotificationCalendar.fromDate(
      {required DateTime date,
      String? timeZoneIdentifier,
      bool allowWhileIdle = false,
      bool repeats = false})
      : super(
            timeZone: timeZoneIdentifier ??
                (date.isUtc
                    ? AwesomeNotifications.utcTimeZoneIdentifier
                    : AwesomeNotifications.localTimeZoneIdentifier),
            allowWhileIdle: allowWhileIdle,
            repeats: repeats) {
    this.year = date.year;
    this.month = date.month;
    this.day = date.day;
    this.hour = date.hour;
    this.minute = date.minute;
    this.second = date.second;
    this.millisecond = date.millisecond;
  }

  @override
  NotificationCalendar? fromMap(Map<String, dynamic> dataMap) {
    this.timeZone = AssertUtils.extractValue(dataMap, NOTIFICATION_SCHEDULE_TIMEZONE);
    this.era = AssertUtils.extractValue(dataMap, NOTIFICATION_SCHEDULE_ERA);
    this.year = AssertUtils.extractValue(dataMap, NOTIFICATION_SCHEDULE_YEAR);
    this.month = AssertUtils.extractValue(dataMap, NOTIFICATION_SCHEDULE_MONTH);
    this.day = AssertUtils.extractValue(dataMap, NOTIFICATION_SCHEDULE_DAY);
    this.hour = AssertUtils.extractValue(dataMap, NOTIFICATION_SCHEDULE_HOUR);
    this.minute = AssertUtils.extractValue(dataMap, NOTIFICATION_SCHEDULE_MINUTE);
    this.second = AssertUtils.extractValue(dataMap, NOTIFICATION_SCHEDULE_SECOND);
    this.millisecond = AssertUtils.extractValue(dataMap, NOTIFICATION_SCHEDULE_MILLISECOND);
    this.weekday = AssertUtils.extractValue(dataMap, NOTIFICATION_SCHEDULE_WEEKDAY);
    this.weekOfMonth = AssertUtils.extractValue(dataMap, NOTIFICATION_SCHEDULE_WEEKOFMONTH);
    this.weekOfYear = AssertUtils.extractValue(dataMap, NOTIFICATION_SCHEDULE_WEEKOFYEAR);
    this.allowWhileIdle =
        AssertUtils.extractValue(dataMap, NOTIFICATION_ALLOW_WHILE_IDLE) ?? false;
    this.repeats = AssertUtils.extractValue(dataMap, NOTIFICATION_SCHEDULE_REPEATS) ?? false;

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
      NOTIFICATION_SCHEDULE_ERA: this.era,
      NOTIFICATION_SCHEDULE_YEAR: this.year,
      NOTIFICATION_SCHEDULE_MONTH: this.month,
      NOTIFICATION_SCHEDULE_DAY: this.day,
      NOTIFICATION_SCHEDULE_HOUR: this.hour,
      NOTIFICATION_SCHEDULE_MINUTE: this.minute,
      NOTIFICATION_SCHEDULE_SECOND: this.second,
      NOTIFICATION_SCHEDULE_MILLISECOND: this.millisecond,
      NOTIFICATION_SCHEDULE_WEEKDAY: this.weekday,
      NOTIFICATION_SCHEDULE_WEEKOFMONTH: this.weekOfMonth,
      NOTIFICATION_SCHEDULE_WEEKOFYEAR: this.weekOfYear,
      NOTIFICATION_ALLOW_WHILE_IDLE: this.allowWhileIdle,
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
    assert(this.era != null ||
        this.year != null ||
        this.month != null ||
        this.day != null ||
        this.hour != null ||
        this.minute != null ||
        this.second != null ||
        this.millisecond != null ||
        this.weekday != null ||
        this.weekOfMonth != null ||
        this.weekOfYear != null);

    assert((this.era ?? 0) >= 0 &&
        (this.year ?? 0) >= 0 &&
        (this.month ?? 0) >= 0 &&
        (this.day ?? 0) >= 0 &&
        (this.hour ?? 0) >= 0 &&
        (this.minute ?? 0) >= 0 &&
        (this.second ?? 0) >= 0 &&
        (this.millisecond ?? 0) >= 0 &&
        (this.weekday ?? 0) >= 0 &&
        (this.weekOfMonth ?? 0) >= 0 &&
        (this.weekOfYear ?? 0) >= 0);
  }
}
