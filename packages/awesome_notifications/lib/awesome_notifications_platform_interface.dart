import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'awesome_notifications_method_channel.dart';

abstract class AwesomeNotificationsPlatform extends PlatformInterface {
  /// Constructs a AwesomeNotificationsPlatform.
  AwesomeNotificationsPlatform() : super(token: _token);

  static final Object _token = Object();

  static AwesomeNotificationsPlatform _instance = MethodChannelAwesomeNotifications();

  /// The default instance of [AwesomeNotificationsPlatform] to use.
  ///
  /// Defaults to [MethodChannelAwesomeNotifications].
  static AwesomeNotificationsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AwesomeNotificationsPlatform] when
  /// they register themselves.
  static set instance(AwesomeNotificationsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Request the user's permission to display notifications.
  Future<bool> requestPermission() {
    throw UnimplementedError('requestPermission() has not been implemented.');
  }

  /// Show a minimal local notification immediately.
  Future<void> showNotification({required int id, String? title, String? body}) {
    throw UnimplementedError('showNotification() has not been implemented.');
  }

  /// Dismiss a delivered notification by id.
  Future<void> dismiss(int id) {
    throw UnimplementedError('dismiss() has not been implemented.');
  }
}
