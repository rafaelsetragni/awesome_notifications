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

  @override
  Future<bool> requestPermission() async {
    final granted = await methodChannel.invokeMethod<bool>('requestPermission');
    return granted ?? false;
  }

  @override
  Future<void> showNotification({
    required int id,
    String? title,
    String? body,
  }) async {
    await methodChannel.invokeMethod<void>('showNotification', <String, dynamic>{
      'id': id,
      'title': title,
      'body': body,
    });
  }

  @override
  Future<void> dismiss(int id) async {
    await methodChannel.invokeMethod<void>('dismiss', <String, dynamic>{
      'id': id,
    });
  }
}
