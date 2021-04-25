import 'package:awesome_notifications/src/models/notification_schedule.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';

class NotificationInterval extends NotificationSchedule {
  /// Field number for get and set indicating the amount of seconds between each repetition (greater than 0).
  int? interval;

  NotificationInterval({
    this.interval,
    bool allowWhileIdle = false,
    bool repeats = false,
  }) : super(allowWhileIdle: allowWhileIdle, repeats: repeats);

  @override
  NotificationInterval? fromMap(Map<String, dynamic> dataMap) {
    this.interval = AssertUtils.extractValue(dataMap, 'interval');
    this.repeats = AssertUtils.extractValue(dataMap, 'repeats') ?? false;
    this.allowWhileIdle = AssertUtils.extractValue(dataMap, 'repeats') ?? false;

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
    assert((this.interval ?? -1) >= 0);
  }
}
