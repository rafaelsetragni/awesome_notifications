import 'package:awesome_notifications/src/models/notification_schedule.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';

class NotificationInterval extends NotificationSchedule {

  /// Field number for get and set indicating the amount of seconds between each repetition (greater than 0).
  int interval;
  /// Specify false to deliver the notification one time. Specify true to reschedule the notification request each time the notification is delivered.
  bool repeats;

  NotificationInterval({
    this.interval,
    this.repeats,
  });

  @override
  NotificationSchedule fromMap(Map<String, dynamic> dataMap) {

    this.interval = AssertUtils.extractValue(dataMap, 'interval');
    this.repeats  = AssertUtils.extractValue(dataMap, 'repeats');

    return this;
  }

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> dataMap = {
      'interval': this.interval,
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
  }
}