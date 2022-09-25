import 'package:awesome_notifications/i_awesome_notifications.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'awesome_notifications_core.dart';

abstract class AwesomeNotificationsPlatform extends PlatformInterface
    implements IAwesomeNotifications {
  /// Constructs a AwesomeNotificationsPlatform.
  AwesomeNotificationsPlatform() : super(token: _token);

  static final Object _token = Object();

  static AwesomeNotificationsPlatform _instance = AwesomeNotificationsCore();

  /// The default instance of [AwesomeNotificationsPlatform] to use.
  ///
  /// Defaults to [MethodChannelAwesomeNotificationsFcm].
  static AwesomeNotificationsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AwesomeNotificationsPlatform] when
  /// they register themselves.
  static set instance(AwesomeNotificationsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }
}
