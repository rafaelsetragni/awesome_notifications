import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'awesome_notifications_schedules_platform_interface.dart';

/// An implementation of [AwesomeNotificationsSchedulesPlatform] that uses method channels.
class MethodChannelAwesomeNotificationsSchedules extends AwesomeNotificationsSchedulesPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('awesome_notifications_schedules');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
