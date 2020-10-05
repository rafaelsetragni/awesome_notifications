import 'package:awesome_notifications/src/models/model.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';
import 'package:awesome_notifications/src/utils/date_utils.dart';
import 'package:awesome_notifications/src/utils/list_utils.dart';

/// Notification schedule configuration
/// [initialDate]: (YYYY-MM-DD hh:mm:ss) The initial date that schedule should be called by first time
/// [crontabSchedule]: Crontab expression as repetition rule (with seconds precision), as described in https://www.baeldung.com/cron-expressions
/// [allowWhileIdle]: Determines if notification will send, even when the device is in critical situation, such as low battery.
class NotificationSchedule extends Model {
  DateTime initialDateTime;
  String crontabSchedule;
  bool allowWhileIdle;
  List<DateTime> preciseSchedules;

  NotificationSchedule(
      {this.initialDateTime,
      this.crontabSchedule,
      this.allowWhileIdle,
      this.preciseSchedules});

  NotificationSchedule fromMap(Map<String, dynamic> dataMap) {
    this.initialDateTime = DateUtils.parseStringToDate(
        AssertUtils.extractValue(dataMap, 'initialDateTime'));
    this.crontabSchedule = AssertUtils.extractValue(dataMap, 'crontabSchedule');
    this.allowWhileIdle = AssertUtils.extractValue(dataMap, 'allowWhileIdle');

    if (dataMap['preciseSchedules'] != null &&
        dataMap['preciseSchedules'] is List) {
      List<String> schedules = List<String>.from(dataMap['preciseSchedules']);
      preciseSchedules = List<DateTime>();

      for (String schedule in schedules) {
        DateTime scheduleDate = DateUtils.parseStringToDate(schedule);
        if (schedule != null) {
          preciseSchedules.add(scheduleDate);
        }
      }
    }

    return this;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> dataMap = {
      'initialDateTime': DateUtils.parseDateToString(initialDateTime),
      'crontabSchedule': crontabSchedule,
      'allowWhileIdle': allowWhileIdle,
      'preciseSchedules': null
    };

    if (!ListUtils.isNullOrEmpty(preciseSchedules)) {
      List<String> schedulesMap = [];

      for (DateTime schedule in preciseSchedules) {
        String scheduleDate = DateUtils.parseDateToString(schedule);
        if (schedule != null) {
          schedulesMap.add(scheduleDate);
        }
      }

      dataMap['preciseSchedules'] = schedulesMap;
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
        crontabSchedule != null ||
        preciseSchedules != null);
  }
}
