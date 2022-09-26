import '../../awesome_notifications.dart';

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
            preciseAlarm: preciseAlarm) {
    if (weekOfMonth != null) {
      throw UnimplementedError("weekOfMonth is not fully implemented yet");
    }
  }

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
    year = date.year;
    month = date.month;
    day = date.day;
    hour = date.hour;
    minute = date.minute;
    second = date.second;
  }

  @override
  NotificationCalendar? fromMap(Map<String, dynamic> mapData) {
    era = AwesomeAssertUtils.extractValue(
        NOTIFICATION_SCHEDULE_ERA, mapData, int);
    year = AwesomeAssertUtils.extractValue(
        NOTIFICATION_SCHEDULE_YEAR, mapData, int);
    month = AwesomeAssertUtils.extractValue(
        NOTIFICATION_SCHEDULE_MONTH, mapData, int);
    day = AwesomeAssertUtils.extractValue(
        NOTIFICATION_SCHEDULE_DAY, mapData, int);
    hour = AwesomeAssertUtils.extractValue(
        NOTIFICATION_SCHEDULE_HOUR, mapData, int);
    minute = AwesomeAssertUtils.extractValue(
        NOTIFICATION_SCHEDULE_MINUTE, mapData, int);
    second = AwesomeAssertUtils.extractValue(
        NOTIFICATION_SCHEDULE_SECOND, mapData, int);
    weekday = AwesomeAssertUtils.extractValue(
        NOTIFICATION_SCHEDULE_WEEKDAY, mapData, int);
    weekOfMonth = AwesomeAssertUtils.extractValue(
        NOTIFICATION_SCHEDULE_WEEKOFMONTH, mapData, int);
    weekOfYear = AwesomeAssertUtils.extractValue(
        NOTIFICATION_SCHEDULE_WEEKOFYEAR, mapData, int);

    super.fromMap(mapData);

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
        NOTIFICATION_SCHEDULE_ERA: era,
        NOTIFICATION_SCHEDULE_YEAR: year,
        NOTIFICATION_SCHEDULE_MONTH: month,
        NOTIFICATION_SCHEDULE_DAY: day,
        NOTIFICATION_SCHEDULE_HOUR: hour,
        NOTIFICATION_SCHEDULE_MINUTE: minute,
        NOTIFICATION_SCHEDULE_SECOND: second,
        NOTIFICATION_SCHEDULE_WEEKDAY: weekday,
        NOTIFICATION_SCHEDULE_WEEKOFMONTH: weekOfMonth,
        NOTIFICATION_SCHEDULE_WEEKOFYEAR: weekOfYear
      });

    return dataMap;
  }

  @override
  String toString() {
    return toMap().toString().replaceAll(',', ',\n');
  }

  @override
  void validate() {
    if (era == null &&
        year == null &&
        month == null &&
        day == null &&
        hour == null &&
        minute == null &&
        second == null &&
        weekday == null &&
        weekOfMonth == null &&
        weekOfYear == null) {
      throw const AwesomeNotificationsException(
          message: 'At least one shedule time condition is required.');
    }

    if (weekOfMonth != null) {
      throw UnimplementedError("weekOfMonth is not fully implemented yet");
    }

    if ((era ?? 0) < 0 ||
        (year ?? 0) < 0 ||
        (month ?? 0) < 0 ||
        (day ?? 0) < 0 ||
        (hour ?? 0) < 0 ||
        (minute ?? 0) < 0 ||
        (second ?? 0) < 0 ||
        (weekday ?? 0) < 0 ||
        (weekOfMonth ?? 0) < 0 ||
        (weekOfYear ?? 0) < 0) {
      throw const AwesomeNotificationsException(
          message:
              'A shedule time condition must be greater or equal to zero.');
    }
  }
}
