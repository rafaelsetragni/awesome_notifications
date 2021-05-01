import 'package:awesome_notifications/src/models/notification_schedule.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';

class NotificationCalendar extends NotificationSchedule {
  /// Field number for get and set indicating the era, e.g., AD or BC in the Julian calendar
  int? era;

  /// Field number for get and set indicating the year.
  int? year;

  /// Field number for get and set indicating the month of the year (1-12).
  int? month;

  /// Field number for get and set indicating the day number of the month (1-31).
  int? day;

  /// Field number for get and set indicating the hour of the day (0-23).
  int? hour;

  /// Field number for get and set indicating the minute within the hour (0-59).
  int? minute;

  /// Field number for get and set indicating the second within the minute (0-59).
  int? second;

  /// Field number for get and set indicating the millisecond within the second.
  int? millisecond;

  /// Field number for get and set indicating the day of the week .
  int? weekday;

  /// Field number for get and set indicating the count of weeks of the month.
  int? weekOfMonth;

  /// Field number for get and set indicating the weeks of the year.
  int? weekOfYear;

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
    bool allowWhileIdle = false,
    bool repeats = false,
  }) : super(allowWhileIdle: allowWhileIdle, repeats: repeats);

  NotificationCalendar.fromDate(
      {required DateTime date,
      bool allowWhileIdle = false,
      bool repeats = false}) {
    this.year = date.year;
    this.month = date.month;
    this.day = date.day;
    this.hour = date.hour;
    this.minute = date.minute;
    this.second = date.second;
    this.millisecond = date.millisecond;
    this.allowWhileIdle = allowWhileIdle;
    this.repeats = repeats;
  }

  @override
  NotificationCalendar? fromMap(Map<String, dynamic> dataMap) {
    this.era = AssertUtils.extractValue(dataMap, 'era');
    this.year = AssertUtils.extractValue(dataMap, 'year');
    this.month = AssertUtils.extractValue(dataMap, 'month');
    this.day = AssertUtils.extractValue(dataMap, 'day');
    this.hour = AssertUtils.extractValue(dataMap, 'hour');
    this.minute = AssertUtils.extractValue(dataMap, 'minute');
    this.second = AssertUtils.extractValue(dataMap, 'second');
    this.millisecond = AssertUtils.extractValue(dataMap, 'millisecond');
    this.weekday = AssertUtils.extractValue(dataMap, 'weekday');
    this.weekOfMonth = AssertUtils.extractValue(dataMap, 'weekOfMonth');
    this.weekOfYear = AssertUtils.extractValue(dataMap, 'weekOfYear');
    this.allowWhileIdle =
        AssertUtils.extractValue(dataMap, 'allowWhileIdle') ?? false;
    this.repeats = AssertUtils.extractValue(dataMap, 'repeats') ?? false;

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
      'era': this.era,
      'year': this.year,
      'month': this.month,
      'day': this.day,
      'hour': this.hour,
      'minute': this.minute,
      'second': this.second,
      'millisecond': this.millisecond,
      'weekday': this.weekday,
      'weekOfMonth': this.weekOfMonth,
      'weekOfYear': this.weekOfYear,
      'allowWhileIdle': this.allowWhileIdle,
      'repeats': this.repeats
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
