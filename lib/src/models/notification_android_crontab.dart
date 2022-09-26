import '../../awesome_notifications.dart';
import '../utils/list_utils.dart';

class NotificationAndroidCrontab extends NotificationSchedule {
  DateTime? _initialDateTime;
  DateTime? _expirationDateTime;
  List<DateTime>? _preciseSchedules;
  String? _crontabExpression;

  ///  The initial limit date that an schedule is considered valid (YYYY-MM-DD hh:mm:ss)
  DateTime? get initialDateTime {
    return _initialDateTime;
  }

  /// The final limit date that an schedule is considered valid (YYYY-MM-DD hh:mm:ss)
  DateTime? get expirationDateTime {
    return _expirationDateTime;
  }

  /// List of precise valid schedule dates
  List<DateTime>? get preciseSchedules {
    return _preciseSchedules;
  }

  /// Crontab expression as repetition rule (with seconds precision), as described in https://www.baeldung.com/cron-expressions
  String? get crontabExpression {
    return _crontabExpression;
  }

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
      {DateTime? initialDateTime,
      DateTime? expirationDateTime,
      List<DateTime>? preciseSchedules,
      String? crontabExpression,
      String? timeZone,
      bool allowWhileIdle = false,
      bool repeats = false,
      bool preciseAlarm = false})
      : _initialDateTime = initialDateTime,
        _expirationDateTime = expirationDateTime,
        _preciseSchedules = preciseSchedules,
        _crontabExpression = crontabExpression,
        super(
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
    _initialDateTime = date;
    _crontabExpression = CronHelper().atDate(referenceDateTime: date);
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
    _crontabExpression =
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
    _crontabExpression =
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
    _crontabExpression =
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
    _crontabExpression =
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
    _crontabExpression =
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
    _crontabExpression =
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
    _crontabExpression =
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
    _crontabExpression =
        CronHelper().monthly(referenceDateTime: referenceDateTime);
  }

  @override
  NotificationAndroidCrontab? fromMap(Map<String, dynamic> mapData) {
    super.fromMap(mapData);

    _crontabExpression = AwesomeAssertUtils.extractValue(
        NOTIFICATION_CRONTAB_EXPRESSION, mapData, DateTime);
    _initialDateTime = AwesomeAssertUtils.extractValue(
        NOTIFICATION_INITIAL_DATE_TIME, mapData, DateTime);
    _expirationDateTime = AwesomeAssertUtils.extractValue(
        NOTIFICATION_EXPIRATION_DATE_TIME, mapData, DateTime);

    if (mapData[NOTIFICATION_PRECISE_SCHEDULES] is List) {
      List<String> schedules =
          List<String>.from(mapData[NOTIFICATION_PRECISE_SCHEDULES]);
      _preciseSchedules = [];

      for (String schedule in schedules) {
        DateTime? scheduleDate = AwesomeDateUtils.parseStringToDate(schedule);
        if (scheduleDate != null) {
          _preciseSchedules!.add(scheduleDate);
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
        NOTIFICATION_CRONTAB_EXPRESSION: _crontabExpression,
        NOTIFICATION_INITIAL_DATE_TIME:
            AwesomeDateUtils.parseDateToString(_initialDateTime),
        NOTIFICATION_EXPIRATION_DATE_TIME:
            AwesomeDateUtils.parseDateToString(_expirationDateTime),
        NOTIFICATION_PRECISE_SCHEDULES: null
      });

    if (!AwesomeListUtils.isNullOrEmpty(_preciseSchedules)) {
      List<String> schedulesMap = [];

      for (DateTime schedule in _preciseSchedules!) {
        String? scheduleDate = AwesomeDateUtils.parseDateToString(schedule);
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
    if (_crontabExpression == null && _preciseSchedules == null) {
      throw const AwesomeNotificationsException(
          message:
              'At least crontabExpression or preciseSchedules is requried');
    }
  }
}
