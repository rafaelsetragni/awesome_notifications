import '../../awesome_notifications.dart';
import '../utils/list_utils.dart';

/// (Only for Android devices) Represents a notification scheduling configuration based on crontab rules or a list of valid dates.
class NotificationAndroidCrontab extends NotificationSchedule {
  DateTime? _initialDateTime;
  DateTime? _expirationDateTime;
  List<DateTime>? _preciseSchedules;
  String? _crontabExpression;

  /// Gets the initial limit date that a schedule is considered valid.
  DateTime? get initialDateTime {
    return _initialDateTime;
  }

  /// Gets the final limit date that a schedule is considered valid.
  DateTime? get expirationDateTime {
    return _expirationDateTime;
  }

  /// Gets a list of precise valid schedule dates.
  List<DateTime>? get preciseSchedules {
    return _preciseSchedules;
  }

  /// Gets the crontab expression as a repetition rule with seconds precision
  /// (if set to *, considers all possible values for the respective component as valid).
  /// For more information, please take a look at https://www.baeldung.com/cron-expressions
  String? get crontabExpression {
    return _crontabExpression;
  }

  /// Constructs a [NotificationAndroidCrontab] with various crontab-based scheduling options.
  ///
  /// [initialDateTime]: The initial date limit for the schedule's validity.
  /// [expirationDateTime]: The final date limit for the schedule's validity.
  /// [preciseSchedules]: A list of specific dates for scheduling notifications.
  /// [crontabExpression]: A crontab expression defining the repetition rule with second precision.
  /// [timeZone]: Specifies the time zone identifier for the schedule.
  /// [allowWhileIdle]: Allows the notification to display even when the device is in low battery mode.
  /// [repeats]: Determines if the notification will be repeated.
  /// [preciseAlarm]: Requires maximum precision for scheduling notifications, which may use more battery.
  NotificationAndroidCrontab(
      {DateTime? initialDateTime,
      DateTime? expirationDateTime,
      List<DateTime>? preciseSchedules,
      String? crontabExpression,
      String? timeZone,
      super.allowWhileIdle,
      super.repeats,
      super.preciseAlarm = true})
      : _initialDateTime = AwesomeAssertUtils.getValueOrDefault<DateTime>(
            NOTIFICATION_INITIAL_DATE_TIME, initialDateTime),
        _expirationDateTime = AwesomeAssertUtils.getValueOrDefault<DateTime>(
            NOTIFICATION_EXPIRATION_DATE_TIME, expirationDateTime),
        _preciseSchedules =
            AwesomeAssertUtils.getValueOrDefault<List<DateTime>>(
                NOTIFICATION_PRECISE_SCHEDULES, preciseSchedules),
        _crontabExpression = AwesomeAssertUtils.getValueOrDefault<String>(
            NOTIFICATION_CRONTAB_EXPRESSION, crontabExpression),
        super(
            timeZone: timeZone ?? AwesomeNotifications.localTimeZoneIdentifier);

  /// Initializes a notification schedule based on a single date reference.
  NotificationAndroidCrontab.fromDate(
      {required DateTime date, int initialSecond = 0, super.allowWhileIdle})
      : super(
            timeZone: date.isUtc
                ? AwesomeNotifications.utcTimeZoneIdentifier
                : AwesomeNotifications.localTimeZoneIdentifier,
            repeats: false) {
    _initialDateTime = date;
    _crontabExpression = CronHelper().atDate(referenceDateTime: date);
  }

  /// Initializes a notification crontab schedule to be triggered yearly at a specific date and time.
  /// [referenceDateTime]: The date and time at which the notification should be scheduled each year.
  /// [allowWhileIdle]: Allows the notification to display even when the device is in low battery mode.
  NotificationAndroidCrontab.yearly(
      {required DateTime referenceDateTime, super.allowWhileIdle})
      : super(
            timeZone: referenceDateTime.isUtc
                ? AwesomeNotifications.utcTimeZoneIdentifier
                : AwesomeNotifications.localTimeZoneIdentifier,
            repeats: false) {
    _crontabExpression =
        CronHelper().yearly(referenceDateTime: referenceDateTime);
  }

  /// Initializes a notification crontab schedule to be triggered monthly at a specific date and time.
  /// [referenceDateTime]: The date and time at which the notification should be scheduled each month.
  /// [allowWhileIdle]: Allows the notification to display even when the device is in low battery mode.
  NotificationAndroidCrontab.monthly(
      {required DateTime referenceDateTime, super.allowWhileIdle})
      : super(
            timeZone: referenceDateTime.isUtc
                ? AwesomeNotifications.utcTimeZoneIdentifier
                : AwesomeNotifications.localTimeZoneIdentifier,
            repeats: false) {
    _crontabExpression =
        CronHelper().monthly(referenceDateTime: referenceDateTime);
  }

  /// Initializes a notification crontab schedule to be triggered weekly at a specific date and time.
  /// [referenceDateTime]: The date and time at which the notification should be scheduled each week.
  /// [allowWhileIdle]: Allows the notification to display even when the device is in low battery mode.
  NotificationAndroidCrontab.weekly(
      {required DateTime referenceDateTime, super.allowWhileIdle})
      : super(
            timeZone: referenceDateTime.isUtc
                ? AwesomeNotifications.utcTimeZoneIdentifier
                : AwesomeNotifications.localTimeZoneIdentifier,
            repeats: false) {
    _crontabExpression =
        CronHelper().weekly(referenceDateTime: referenceDateTime);
  }

  /// Initializes a notification crontab schedule to be triggered daily at a specific time.
  /// [referenceDateTime]: The time at which the notification should be scheduled each day.
  /// [allowWhileIdle]: Allows the notification to display even when the device is in low battery mode.
  NotificationAndroidCrontab.daily(
      {required DateTime referenceDateTime, super.allowWhileIdle})
      : super(
            timeZone: referenceDateTime.isUtc
                ? AwesomeNotifications.utcTimeZoneIdentifier
                : AwesomeNotifications.localTimeZoneIdentifier,
            repeats: false) {
    _crontabExpression =
        CronHelper().daily(referenceDateTime: referenceDateTime);
  }

  /// Initializes a notification crontab schedule to be triggered hourly at a specific minute and second.
  /// [referenceDateTime]: The minute and second at which the notification should be scheduled each hour.
  /// [allowWhileIdle]: Allows the notification to display even when the device is in low battery mode.
  NotificationAndroidCrontab.hourly(
      {required DateTime referenceDateTime, super.allowWhileIdle})
      : super(
            timeZone: referenceDateTime.isUtc
                ? AwesomeNotifications.utcTimeZoneIdentifier
                : AwesomeNotifications.localTimeZoneIdentifier,
            repeats: false) {
    _crontabExpression =
        CronHelper().hourly(referenceDateTime: referenceDateTime);
  }

  /// Initializes a notification crontab schedule to be triggered every minute at a specific second.
  /// [referenceDateTime]: The second at which the notification should be scheduled each minute.
  /// [allowWhileIdle]: Allows the notification to display even when the device is in low battery mode.
  NotificationAndroidCrontab.minutely(
      {required DateTime referenceDateTime, super.allowWhileIdle})
      : super(
            timeZone: referenceDateTime.isUtc
                ? AwesomeNotifications.utcTimeZoneIdentifier
                : AwesomeNotifications.localTimeZoneIdentifier,
            repeats: false) {
    _crontabExpression =
        CronHelper().minutely(initialSecond: referenceDateTime.second);
  }

  /// Initializes a notification crontab schedule to be triggered on workweek days (Monday to Friday) at a specific time.
  /// [referenceDateTime]: The time at which the notification should be scheduled on workweek days.
  /// [allowWhileIdle]: Allows the notification to display even when the device is in low battery mode.
  NotificationAndroidCrontab.workweekDay(
      {required DateTime referenceDateTime, super.allowWhileIdle})
      : super(
            timeZone: referenceDateTime.isUtc
                ? AwesomeNotifications.utcTimeZoneIdentifier
                : AwesomeNotifications.localTimeZoneIdentifier,
            repeats: false) {
    _crontabExpression =
        CronHelper().workweekDay(referenceDateTime: referenceDateTime);
  }

  /// Initializes a notification crontab schedule to be triggered on weekend days (Saturday and Sunday) at a specific time.
  /// [referenceDateTime]: The time at which the notification should be scheduled on weekend days.
  /// [allowWhileIdle]: Allows the notification to display even when the device is in low battery mode.
  NotificationAndroidCrontab.weekendDay(
      {required DateTime referenceDateTime, super.allowWhileIdle})
      : super(
            timeZone: referenceDateTime.isUtc
                ? AwesomeNotifications.utcTimeZoneIdentifier
                : AwesomeNotifications.localTimeZoneIdentifier,
            repeats: false) {
    _crontabExpression =
        CronHelper().weekendDay(referenceDateTime: referenceDateTime);
  }

  /// Creates a [NotificationAndroidCrontab] instance from a map of data.
  @override
  NotificationAndroidCrontab? fromMap(Map<String, dynamic> mapData) {
    super.fromMap(mapData);

    _crontabExpression = AwesomeAssertUtils.extractValue<String>(
        NOTIFICATION_CRONTAB_EXPRESSION, mapData);
    _initialDateTime = AwesomeAssertUtils.extractValue<DateTime>(
        NOTIFICATION_INITIAL_DATE_TIME, mapData);
    _expirationDateTime = AwesomeAssertUtils.extractValue<DateTime>(
        NOTIFICATION_EXPIRATION_DATE_TIME, mapData);

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
    validate();
    return this;
  }

  /// Converts the [NotificationAndroidCrontab] instance to a map.
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

  /// Returns a string representation of the [NotificationAndroidCrontab] instance.
  @override
  String toString() {
    return toMap().toString().replaceAll(',', ',\n');
  }

  /// Validates the crontab schedule settings.
  ///
  /// Throws an [AwesomeNotificationsException] if both crontabExpression and preciseSchedules are null.
  @override
  void validate() {
    if (_crontabExpression == null && _preciseSchedules == null) {
      throw const AwesomeNotificationsException(
          message:
              'At least crontabExpression or preciseSchedules is requried');
    }
  }
}
