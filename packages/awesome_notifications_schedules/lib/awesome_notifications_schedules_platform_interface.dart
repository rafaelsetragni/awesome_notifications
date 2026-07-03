import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'awesome_notifications_schedules_method_channel.dart';

abstract class AwesomeNotificationsSchedulesPlatform extends PlatformInterface {
  /// Constructs a AwesomeNotificationsSchedulesPlatform.
  AwesomeNotificationsSchedulesPlatform() : super(token: _token);

  static final Object _token = Object();

  static AwesomeNotificationsSchedulesPlatform _instance = MethodChannelAwesomeNotificationsSchedules();

  /// The default instance of [AwesomeNotificationsSchedulesPlatform] to use.
  ///
  /// Defaults to [MethodChannelAwesomeNotificationsSchedules].
  static AwesomeNotificationsSchedulesPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AwesomeNotificationsSchedulesPlatform] when
  /// they register themselves.
  static set instance(AwesomeNotificationsSchedulesPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
