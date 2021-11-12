import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/src/exceptions/awesome_exception.dart';
import 'package:awesome_notifications/src/models/notification_schedule.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';
import 'package:awesome_notifications/src/utils/list_utils.dart';

class NotificationAndroidCrontab extends NotificationSchedule {
  ///  The initial limit date that an schedule is considered valid (YYYY-MM-DD hh:mm:ss)
  DateTime? initialDateTime;

  /// The final limit date that an schedule is considered valid (YYYY-MM-DD hh:mm:ss)
  DateTime? expirationDateTime;

  /// List of precise valid schedule dates
  List<DateTime>? preciseSchedules;

  /// Crontab expression as repetition rule (with seconds precision), as described in https://www.baeldung.com/cron-expressions
  String? crontabExpression;

  /// Notification Schedule based on crontab rules or a list of valid dates.
  /// [initialDate]: The initial limit date that an schedule is considered valid (YYYY-MM-DD hh:mm:ss)
  /// [expirationDate]: The final limit date that an schedule is considered valid (YYYY-MM-DD hh:mm:ss)
  /// [crontabExpression]: Crontab expression as repetition rule (with seconds precision), as described in https://www.baeldung.com/cron-expressions
  /// [preciseSchedules]: List of precise valid schedule dates
  /// [allowWhileIdle]: Determines if notification will send, even when the device is in critical situation, such as low battery.
  /// [repeats]: Determines if notification will send, even when the device is in critical situation, such as low battery.
  /// [preciseAlarm] Requires maximum precision to schedule notifications at exact time, but may use more battery. Requires the explicit user consent for Android 12 and beyond.
  /// [timeZone] time zone identifier as reference of this schedule date. (https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
  NotificationAndroidCrontab(
      {this.initialDateTime,
      this.expirationDateTime,
      this.preciseSchedules,
      this.crontabExpression,
      String? timeZone,
      bool allowWhileIdle = false,
      bool repeats = false,
      bool preciseAlarm = false})
      : super(
            timeZone: timeZone ?? AwesomeNotifications.localTimeZoneIdentifier,
            allowWhileIdle: allowWhileIdle,
            repeats: repeats,
            preciseAlarm: preciseAlarm);

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
    this.crontabExpression =
        CronHelper().yearly(referenceDateTime: referenceDateTime);
  }

  /// Generates a Cron expression to be played only once at month based on a date reference
  NotificationAndroidCrontab.monthly(
      {required DateTime referenceDateTime, bool allowWhileIdle = false})
      : super(
            timeZone: referenceDateTime.isUtc
                ? AwesomeNotifications.utcTimeZoneIdentifier
                : AwesomeNotifications.localTimeZoneIdentifier,
            allowWhileIdle: allowWhileIdle,
            repeats: false) {
    this.crontabExpression =
        CronHelper().monthly(referenceDateTime: referenceDateTime);
  }

  /// Generates a Cron expression to be played only once at week based on a date reference
  NotificationAndroidCrontab.weekly(
      {required DateTime referenceDateTime, bool allowWhileIdle = false})
      : super(
            timeZone: referenceDateTime.isUtc
                ? AwesomeNotifications.utcTimeZoneIdentifier
                : AwesomeNotifications.localTimeZoneIdentifier,
            allowWhileIdle: allowWhileIdle,
            repeats: false) {
    this.crontabExpression =
        CronHelper().monthly(referenceDateTime: referenceDateTime);
  }

  /// Generates a Cron expression to be played only once at day based on a date reference
  NotificationAndroidCrontab.daily(
      {required DateTime referenceDateTime, bool allowWhileIdle = false})
      : super(
            timeZone: referenceDateTime.isUtc
                ? AwesomeNotifications.utcTimeZoneIdentifier
                : AwesomeNotifications.localTimeZoneIdentifier,
            allowWhileIdle: allowWhileIdle,
            repeats: false) {
    this.crontabExpression =
        CronHelper().monthly(referenceDateTime: referenceDateTime);
  }

  /// Generates a Cron expression to be played only once at hour based on a date reference
  NotificationAndroidCrontab.hourly(
      {required DateTime referenceDateTime, bool allowWhileIdle = false})
      : super(
            timeZone: referenceDateTime.isUtc
                ? AwesomeNotifications.utcTimeZoneIdentifier
                : AwesomeNotifications.localTimeZoneIdentifier,
            allowWhileIdle: allowWhileIdle,
            repeats: false) {
    this.crontabExpression =
        CronHelper().monthly(referenceDateTime: referenceDateTime);
  }

  /// Generates a Cron expression to be played only once at every minute based on a date reference
  NotificationAndroidCrontab.minutely(
      {required DateTime referenceDateTime, bool allowWhileIdle = false})
      : super(
            timeZone: referenceDateTime.isUtc
                ? AwesomeNotifications.utcTimeZoneIdentifier
                : AwesomeNotifications.localTimeZoneIdentifier,
            allowWhileIdle: allowWhileIdle,
            repeats: false) {
    this.crontabExpression =
        CronHelper().minutely(initialSecond: referenceDateTime.second);
  }

  /// Generates a Cron expression to be played only on workweek days based on a date reference
  NotificationAndroidCrontab.workweekDay(
      {required DateTime referenceDateTime, bool allowWhileIdle = false})
      : super(
            timeZone: referenceDateTime.isUtc
                ? AwesomeNotifications.utcTimeZoneIdentifier
                : AwesomeNotifications.localTimeZoneIdentifier,
            allowWhileIdle: allowWhileIdle,
            repeats: false) {
    this.crontabExpression =
        CronHelper().monthly(referenceDateTime: referenceDateTime);
  }

  /// Generates a Cron expression to be played only on weekend days based on a date reference
  NotificationAndroidCrontab.weekendDay(
      {required DateTime referenceDateTime, bool allowWhileIdle = false})
      : super(
            timeZone: referenceDateTime.isUtc
                ? AwesomeNotifications.utcTimeZoneIdentifier
                : AwesomeNotifications.localTimeZoneIdentifier,
            allowWhileIdle: allowWhileIdle,
            repeats: false) {
    this.crontabExpression =
        CronHelper().monthly(referenceDateTime: referenceDateTime);
  }

  @override
  NotificationAndroidCrontab? fromMap(Map<String, dynamic> dataMap) {
    super.fromMap(dataMap);

    this.crontabExpression = AssertUtils.extractValue(
        NOTIFICATION_CRONTAB_EXPRESSION, dataMap, DateTime);
    this.initialDateTime = AssertUtils.extractValue(
        NOTIFICATION_INITIAL_DATE_TIME, dataMap, DateTime);
    this.expirationDateTime = AssertUtils.extractValue(
        NOTIFICATION_EXPIRATION_DATE_TIME, dataMap, DateTime);

    if (dataMap[NOTIFICATION_PRECISE_SCHEDULES] is List) {
      List<String> schedules =
          List<String>.from(dataMap[NOTIFICATION_PRECISE_SCHEDULES]);
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
    Map<String, dynamic> dataMap = super.toMap()
      ..addAll({
        NOTIFICATION_CRONTAB_EXPRESSION: this.crontabExpression,
        NOTIFICATION_INITIAL_DATE_TIME:
            DateUtils.parseDateToString(this.initialDateTime),
        NOTIFICATION_EXPIRATION_DATE_TIME:
            DateUtils.parseDateToString(this.expirationDateTime),
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
    if (crontabExpression == null && preciseSchedules == null) {
      throw AwesomeNotificationsException(
          message:
              'At least crontabExpression or preciseSchedules is requried');
    }
  }
}
