import 'package:awesome_notifications/src/models/notification_schedule.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';

class NotificationCalendar extends NotificationSchedule {
  /// Field number for get and set indicating the era, e.g., AD or BC in the Julian calendar
  int? era;

  /// Field number for get and set indicating the year.
  int? year;

  /// Field number for get and set indicating the month.
  int? month;

  /// Field number for get and set indicating the day number within the current year (1-12).
  int? day;

  /// Field number for get and set indicating the hour of the day (0-23).
  int? hour;

  /// Field number for get and set indicating the minute within the hour (0-59).
  int? minute;

  /// Field number for get and set indicating the second within the minute (0-59).
  int? second;

  /// Field number for get and set indicating the millisecond within the second.
  int? millisecond;

  /// Field number for get and set indicating the day of the week.
  int? weekday;

  /// Field number for get and set indicating the count of weeks of the month.
  int? weekOfMonth;

  /// Field number for get and set indicating the weeks of the year.
  int? weekOfYear;

  /// Specify false to deliver the notification one time. Specify true to reschedule the notification request each time the notification is delivered.
  late bool repeats;

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
    this.repeats = false,
  });

  NotificationCalendar.fromDate({required DateTime date, this.repeats = false}) {
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
    this.repeats = AssertUtils.extractValue(dataMap, 'repeats') ?? false;

    try{
      validate();
    }
    catch(e){
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
    assert(
        this.era != null ||
        this.year != null ||
        this.month != null ||
        this.day != null ||
        this.hour != null ||
        this.minute != null ||
        this.second != null ||
        this.millisecond != null ||
        this.weekday != null ||
        this.weekOfMonth != null ||
        this.weekOfYear != null
    );
  }
}
