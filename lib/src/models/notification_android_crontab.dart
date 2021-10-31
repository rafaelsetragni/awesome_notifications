import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/src/models/notification_schedule.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';
import 'package:awesome_notifications/src/utils/list_utils.dart';

class NotificationAndroidCrontab extends NotificationSchedule {
  /// Field number for get and set indicating the era, e.g., AD or BC in the Julian calendar
  DateTime? initialDateTime;

  /// Field number for get and set indicating the year.
  DateTime? expirationDateTime;

  /// Field number for get and set indicating the year.
  List<DateTime>? preciseSchedules;

  /// Field number for get and set indicating the month of the year (1-12).
  String? crontabExpression;

  /// Notification Schedule based on calendar components. At least one date parameter is required.
  /// [initialDate]: (YYYY-MM-DD hh:mm:ss) The initial date that schedule should be called by first time
  /// [expirationDate]: (YYYY-MM-DD hh:mm:ss) The initial date that schedule should be called by first time
  /// [crontabExpression]: Crontab expression as repetition rule (with seconds precision), as described in https://www.baeldung.com/cron-expressions
  /// [preciseSchedules]: Crontab expression as repetition rule (with seconds precision), as described in https://www.baeldung.com/cron-expressions
  /// [timeZone] time zone identifier as reference of this schedule date. (https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
  /// [allowWhileIdle]: Determines if notification will send, even when the device is in critical situation, such as low battery.
  /// [repeats]: Determines if notification will send, even when the device is in critical situation, such as low battery.
  NotificationAndroidCrontab({
    this.initialDateTime,
    this.expirationDateTime,
    this.preciseSchedules,
    this.crontabExpression,
    String? timeZone,
    bool allowWhileIdle = false,
    bool repeats = false,
  }) : super(
            timeZone: timeZone ?? AwesomeNotifications.localTimeZoneIdentifier,
            allowWhileIdle: allowWhileIdle,
            repeats: repeats);

  /// Initialize a notification crontab schedule based on a date reference
  NotificationAndroidCrontab.fromDate(
      {required DateTime date,
      int initialSecond = 0,
      bool allowWhileIdle = false})
      : super(
            timeZone: date.isUtc
                ? AwesomeNotifications.utcTimeZoneIdentifier
                : AwesomeNotifications.localTimeZoneIdentifier,
            allowWhileIdle: allowWhileIdle,
            repeats: false) {
    this.initialDateTime = date;
    this.crontabExpression = CronHelper().atDate(referenceDateTime: date);
  }

  /// Generates a Cron expression to be played only once at year based on a date reference
  NotificationAndroidCrontab.yearly(
      {required DateTime referenceDateTime, bool allowWhileIdle = false})
      : super(
      timeZone: referenceDateTime.isUtc
          ? AwesomeNotifications.utcTimeZoneIdentifier
          : AwesomeNotifications.localTimeZoneIdentifier,
      allowWhileIdle: allowWhileIdle,
      repeats: false) {
    this.crontabExpression = CronHelper().yearly(referenceDateTime: referenceDateTime);
  }

  /// Generates a Cron expression to be played only once at month based on a date reference
  NotificationAndroidCrontab.monthly(
      {required DateTime referenceDateTime,
       bool allowWhileIdle = false})
      : super(
      timeZone: referenceDateTime.isUtc
          ? AwesomeNotifications.utcTimeZoneIdentifier
          : AwesomeNotifications.localTimeZoneIdentifier,
      allowWhileIdle: allowWhileIdle,
      repeats: false) {
    this.crontabExpression = CronHelper().monthly(referenceDateTime: referenceDateTime);
  }

  /// Generates a Cron expression to be played only once at week based on a date reference
  NotificationAndroidCrontab.weekly(
      {required DateTime referenceDateTime,
        bool allowWhileIdle = false})
      : super(
      timeZone: referenceDateTime.isUtc
          ? AwesomeNotifications.utcTimeZoneIdentifier
          : AwesomeNotifications.localTimeZoneIdentifier,
      allowWhileIdle: allowWhileIdle,
      repeats: false) {
    this.crontabExpression = CronHelper().monthly(referenceDateTime: referenceDateTime);
  }

  /// Generates a Cron expression to be played only once at day based on a date reference
  NotificationAndroidCrontab.daily(
      {required DateTime referenceDateTime,
        bool allowWhileIdle = false})
      : super(
      timeZone: referenceDateTime.isUtc
          ? AwesomeNotifications.utcTimeZoneIdentifier
          : AwesomeNotifications.localTimeZoneIdentifier,
      allowWhileIdle: allowWhileIdle,
      repeats: false) {
    this.crontabExpression = CronHelper().monthly(referenceDateTime: referenceDateTime);
  }

  /// Generates a Cron expression to be played only once at hour based on a date reference
  NotificationAndroidCrontab.hourly(
      {required DateTime referenceDateTime,
        bool allowWhileIdle = false})
      : super(
      timeZone: referenceDateTime.isUtc
          ? AwesomeNotifications.utcTimeZoneIdentifier
          : AwesomeNotifications.localTimeZoneIdentifier,
      allowWhileIdle: allowWhileIdle,
      repeats: false) {
    this.crontabExpression = CronHelper().monthly(referenceDateTime: referenceDateTime);
  }

  /// Generates a Cron expression to be played only once at every minute based on a date reference
  NotificationAndroidCrontab.minutely(
      {required DateTime referenceDateTime,
        bool allowWhileIdle = false})
      : super(
      timeZone: referenceDateTime.isUtc
          ? AwesomeNotifications.utcTimeZoneIdentifier
          : AwesomeNotifications.localTimeZoneIdentifier,
      allowWhileIdle: allowWhileIdle,
      repeats: false) {
    this.crontabExpression = CronHelper().minutely(initialSecond: referenceDateTime.second);
  }

  /// Generates a Cron expression to be played only on workweek days based on a date reference
  NotificationAndroidCrontab.workweekDay(
      {required DateTime referenceDateTime,
        bool allowWhileIdle = false})
      : super(
      timeZone: referenceDateTime.isUtc
          ? AwesomeNotifications.utcTimeZoneIdentifier
          : AwesomeNotifications.localTimeZoneIdentifier,
      allowWhileIdle: allowWhileIdle,
      repeats: false) {
    this.crontabExpression = CronHelper().monthly(referenceDateTime: referenceDateTime);
  }

  /// Generates a Cron expression to be played only on weekend days based on a date reference
  NotificationAndroidCrontab.weekendDay(
      {required DateTime referenceDateTime,
        bool allowWhileIdle = false})
      : super(
      timeZone: referenceDateTime.isUtc
          ? AwesomeNotifications.utcTimeZoneIdentifier
          : AwesomeNotifications.localTimeZoneIdentifier,
      allowWhileIdle: allowWhileIdle,
      repeats: false) {
    this.crontabExpression = CronHelper().monthly(referenceDateTime: referenceDateTime);
  }

  @override
  NotificationAndroidCrontab? fromMap(Map<String, dynamic> dataMap) {
    super.fromMap(dataMap);

    this.crontabExpression =
        AssertUtils.extractValue(NOTIFICATION_CRONTAB_EXPRESSION, dataMap, DateTime);
    this.initialDateTime =
        AssertUtils.extractValue(NOTIFICATION_INITIAL_DATE_TIME, dataMap, DateTime);
    this.expirationDateTime =
        AssertUtils.extractValue(NOTIFICATION_EXPIRATION_DATE_TIME, dataMap, DateTime);

    if (dataMap[NOTIFICATION_PRECISE_SCHEDULES] is List) {
      List<String> schedules = List<String>.from(dataMap[NOTIFICATION_PRECISE_SCHEDULES]);
      preciseSchedules = [];

      for (String schedule in schedules) {
        DateTime? scheduleDate = DateUtils.parseStringToDate(schedule);
        if (scheduleDate != null) {
          preciseSchedules!.add(scheduleDate);
        }
      }
    }

    try {
      validate();
    } catch (e) {
      return null;
    }

    return this;
  }

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> dataMap =
    super.toMap()
      ..addAll({
      NOTIFICATION_CRONTAB_EXPRESSION: this.crontabExpression,
      NOTIFICATION_INITIAL_DATE_TIME: DateUtils.parseDateToString(this.initialDateTime),
      NOTIFICATION_EXPIRATION_DATE_TIME: DateUtils.parseDateToString(this.expirationDateTime),
      NOTIFICATION_PRECISE_SCHEDULES: null
    });

    if (!ListUtils.isNullOrEmpty(preciseSchedules)) {
      List<String> schedulesMap = [];

      for (DateTime schedule in preciseSchedules!) {
        String? scheduleDate = DateUtils.parseDateToString(schedule);
        if (scheduleDate != null) {
          schedulesMap.add(scheduleDate);
        }
      }
      dataMap[NOTIFICATION_PRECISE_SCHEDULES] = schedulesMap;
    }

    return dataMap;
  }

  @override
  String toString() {
    return toMap().toString().replaceAll(',', ',\n');
  }

  @override
  void validate() {
    assert(initialDateTime != null ||
        crontabExpression != null ||
        preciseSchedules != null);
  }
}
