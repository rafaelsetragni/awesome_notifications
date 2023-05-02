import 'dart:io';

import 'package:awesome_notifications/i_awesome_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'awesome_notifications_empty.dart';
import 'awesome_notifications_method_channel.dart';

abstract class AwesomeNotificationsPlatform extends PlatformInterface
    implements IAwesomeNotifications {
  /// Constructs a AwesomeNotificationsPlatform.
  AwesomeNotificationsPlatform() : super(token: _token);

  static final Object _token = Object();

  static AwesomeNotificationsPlatform? _instance;

  @visibleForTesting
  static String operatingSystem = Platform.operatingSystem;

  /// The default instance of [AwesomeNotificationsPlatform] to use.
  ///
  /// Defaults to [MethodChannelAwesomeNotifications].
  static AwesomeNotificationsPlatform get instance {
    if (_instance == null) {
      switch (operatingSystem) {
        case "android":
        case "ios":
          _instance = MethodChannelAwesomeNotifications();
          break;
        default:
          _instance = AwesomeNotificationsEmpty();
          break;
      }
    }
    return _instance!;
  }

  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AwesomeNotificationsPlatform] when
  /// they register themselves.
  static set instance(AwesomeNotificationsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }
}
