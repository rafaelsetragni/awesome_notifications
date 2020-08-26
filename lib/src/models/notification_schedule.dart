import 'package:awesome_notifications/src/models/model.dart';

import 'package:awesome_notifications/src/utils/assert_utils.dart';
import 'package:awesome_notifications/src/utils/date_utils.dart';

class NotificationSchedule extends Model {

  DateTime initialDateTime;
  String crontabSchedule;
  bool allowWhileIdle;

  NotificationSchedule({
    this.initialDateTime,
    this.crontabSchedule,
    this.allowWhileIdle
  });

  NotificationSchedule fromMap(Map<String, dynamic> dataMap) {

    this.initialDateTime = DateUtils.parseStringToDate(AssertUtils.extractValue(dataMap, 'initialDateTime'));
    this.crontabSchedule = AssertUtils.extractValue(dataMap, 'crontabSchedule');
    this.allowWhileIdle  = AssertUtils.extractValue(dataMap, 'allowWhileIdle');

    return this;
  }

  Map<String, dynamic> toMap() {
    return {
      'initialDateTime': DateUtils.parseDateToString(initialDateTime),
      'crontabSchedule': crontabSchedule,
      'allowWhileIdle': allowWhileIdle,
    };
  }

  @override
  String toString() {
    return toMap().toString().replaceAll(',', ',\n');
  }

  @override
  void validate() {
    assert(initialDateTime != null || crontabSchedule != null);
  }

}