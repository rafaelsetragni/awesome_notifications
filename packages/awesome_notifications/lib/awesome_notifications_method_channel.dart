import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'awesome_notifications_platform_interface.dart';

/// An implementation of [AwesomeNotificationsPlatform] that uses method channels.
class MethodChannelAwesomeNotifications extends AwesomeNotificationsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('awesome_notifications');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
