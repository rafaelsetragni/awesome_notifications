
import 'awesome_notifications_schedules_platform_interface.dart';

class AwesomeNotificationsSchedules {
  Future<String?> getPlatformVersion() {
    return AwesomeNotificationsSchedulesPlatform.instance.getPlatformVersion();
  }
}
