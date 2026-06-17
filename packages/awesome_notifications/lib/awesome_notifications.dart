
import 'awesome_notifications_platform_interface.dart';

class AwesomeNotifications {
  Future<String?> getPlatformVersion() {
    return AwesomeNotificationsPlatform.instance.getPlatformVersion();
  }
}
