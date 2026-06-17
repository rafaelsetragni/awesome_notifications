import '../../awesome_notifications.dart';

/// Represents a notification scheduling configuration based on calendar components.
class NotificationCalendar extends NotificationSchedule {
  /// The era for scheduling, e.g., AD or BC in the Julian calendar.
  int? era;

  /// The year for scheduling the notification.
  int? year;

  /// The month of the year (1-12) for scheduling the notification.
  int? month;

  /// The day of the month (1-31) for scheduling the notification.
  int? day;

  /// The hour of the day (0-23) for scheduling the notification.
  int? hour;

  /// The minute within the hour (0-59) for scheduling the notification.
  int? minute;

  /// The second within the minute (0-59) for scheduling the notification.
  int? second;

  /// Millisecond precision is deprecated due to device limitations. This field will be ignored.
  @Deprecated(
      'Millisecond precision was deprecated, due devices do not provide or ignore such precision. The value will be ignored')
  int? millisecond;

  /// The day of the week (1 = Monday) for scheduling the notification.
  int? weekday;

  /// The count of weeks of the month for scheduling. This parameter is now deprecated and will be no longer supported.
  @Deprecated(
      'The weekOfMonth parameter is deprecated and scheduled for removal in a future release due to unimplemented dependencies expected in versions beyond 1.0.0. It may be reconsidered for inclusion in later versions.')
  int? weekOfMonth;

  /// The week of the year for scheduling the notification.
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
    super.allowWhileIdle,
    super.preciseAlarm = true,
    super.repeats,
  }) : super(
            timeZone:
                timeZone ?? AwesomeNotifications.localTimeZoneIdentifier) {
    if (weekOfMonth != null) {
      throw UnimplementedError("weekOfMonth is not fully implemented yet");
    }
  }

  /// Initializes a [NotificationCalendar] from a [DateTime] object.
  NotificationCalendar.fromDate(
      {required DateTime date,
      super.allowWhileIdle,
      super.repeats,
      super.preciseAlarm})
      : super(
            timeZone: date.isUtc
                ? AwesomeNotifications.utcTimeZoneIdentifier
                : AwesomeNotifications.localTimeZoneIdentifier) {
    year = date.year;
    month = date.month;
    day = date.day;
    hour = date.hour;
    minute = date.minute;
    second = date.second;
  }

  /// Creates a [NotificationCalendar] instance from a map of data.
  @override
  NotificationCalendar? fromMap(Map<String, dynamic> mapData) {
    era = AwesomeAssertUtils.extractValue<int>(
        NOTIFICATION_SCHEDULE_ERA, mapData);
    year = AwesomeAssertUtils.extractValue<int>(
        NOTIFICATION_SCHEDULE_YEAR, mapData);
    month = AwesomeAssertUtils.extractValue<int>(
        NOTIFICATION_SCHEDULE_MONTH, mapData);
    day = AwesomeAssertUtils.extractValue<int>(
        NOTIFICATION_SCHEDULE_DAY, mapData);
    hour = AwesomeAssertUtils.extractValue<int>(
        NOTIFICATION_SCHEDULE_HOUR, mapData);
    minute = AwesomeAssertUtils.extractValue<int>(
        NOTIFICATION_SCHEDULE_MINUTE, mapData);
    second = AwesomeAssertUtils.extractValue<int>(
        NOTIFICATION_SCHEDULE_SECOND, mapData);
    weekday = AwesomeAssertUtils.extractValue<int>(
        NOTIFICATION_SCHEDULE_WEEKDAY, mapData);
    weekOfMonth = AwesomeAssertUtils.extractValue<int>(
        NOTIFICATION_SCHEDULE_WEEKOFMONTH, mapData);
    weekOfYear = AwesomeAssertUtils.extractValue<int>(
        NOTIFICATION_SCHEDULE_WEEKOFYEAR, mapData);

    super.fromMap(mapData);

    try {
      validate();
    } catch (e) {
      return null;
    }

    return this;
  }

  /// Converts the [NotificationCalendar] instance to a map.
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

  /// Returns a string representation of the [NotificationCalendar] instance.
  @override
  String toString() {
    return toMap().toString().replaceAll(',', ',\n');
  }

  /// Validates the calendar schedule settings.
  ///
  /// Throws an [AwesomeNotificationsException] if no schedule time condition is provided or if any condition is negative.
  /// Throws an [UnimplementedError] if [weekOfMonth] is not null as it's not fully implemented.
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
