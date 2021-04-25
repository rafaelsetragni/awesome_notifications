import 'package:awesome_notifications/src/models/model.dart';

/// Notification schedule configuration
/// [initialDate]: (YYYY-MM-DD hh:mm:ss) The initial date that schedule should be called by first time
/// [crontabSchedule]: Crontab expression as repetition rule (with seconds precision), as described in https://www.baeldung.com/cron-expressions
/// [allowWhileIdle]: Determines if notification will send, even when the device is in critical situation, such as low battery.

abstract class NotificationSchedule extends Model {
  NotificationSchedule();

  NotificationSchedule? fromMap(Map<String, dynamic> dataMap);

  Map<String, dynamic> toMap();

  @override
  String toString() {
    return toMap().toString().replaceAll(',', ',\n');
  }
}
