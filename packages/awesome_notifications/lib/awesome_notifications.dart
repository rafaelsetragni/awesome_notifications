
import 'awesome_notifications_platform_interface.dart';

class AwesomeNotifications {
  Future<String?> getPlatformVersion() {
    return AwesomeNotificationsPlatform.instance.getPlatformVersion();
  }

  /// Request the user's permission to display notifications.
  Future<bool> requestPermission() =>
      AwesomeNotificationsPlatform.instance.requestPermission();

  /// Show a minimal local notification.
  Future<void> showNotification({required int id, String? title, String? body}) =>
      AwesomeNotificationsPlatform.instance
          .showNotification(id: id, title: title, body: body);

  /// Dismiss a delivered notification by id.
  Future<void> dismiss(int id) =>
      AwesomeNotificationsPlatform.instance.dismiss(id);
}
