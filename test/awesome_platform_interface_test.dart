import 'package:awesome_notifications/awesome_notifications_empty.dart';
import 'package:awesome_notifications/awesome_notifications_platform_interface.dart';
import 'package:awesome_notifications/awesome_notifications_method_channel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io' show Platform;

import 'package:mocktail/mocktail.dart';

class MockAwesomeNotificationsIOS extends AwesomeNotificationsPlatform
    with Mock {}

class MockAwesomeNotificationsAndroid extends AwesomeNotificationsPlatform
    with Mock {}

class MockAwesomeNotificationsEmpty extends AwesomeNotificationsPlatform
    with Mock {}

void main() {
  group('AwesomeNotificationsPlatform', () {
    test('sets instance for iOS', () {
      AwesomeNotificationsPlatform.operatingSystem = 'ios';
      AwesomeNotificationsPlatform.resetInstance();

      // Test if the instance is set correctly
      expect(AwesomeNotificationsPlatform.instance,
          isA<MethodChannelAwesomeNotifications>());
    });

    test('sets instance for Android', () {
      AwesomeNotificationsPlatform.operatingSystem = 'android';
      AwesomeNotificationsPlatform.resetInstance();

      // Test if the instance is set correctly
      expect(AwesomeNotificationsPlatform.instance,
          isA<MethodChannelAwesomeNotifications>());
    });

    test('sets instance for other platforms', () {
      AwesomeNotificationsPlatform.operatingSystem = 'web';
      AwesomeNotificationsPlatform.resetInstance();

      // Test if the instance is set correctly
      expect(AwesomeNotificationsPlatform.instance,
          isA<AwesomeNotificationsEmpty>());

      AwesomeNotificationsPlatform.operatingSystem = "linux";
      AwesomeNotificationsPlatform.resetInstance();

      // Test if the instance is set correctly
      expect(AwesomeNotificationsPlatform.instance,
          isA<AwesomeNotificationsEmpty>());

      AwesomeNotificationsPlatform.operatingSystem = "macos";
      AwesomeNotificationsPlatform.resetInstance();

      // Test if the instance is set correctly
      expect(AwesomeNotificationsPlatform.instance,
          isA<AwesomeNotificationsEmpty>());

      AwesomeNotificationsPlatform.operatingSystem = "windows";
      AwesomeNotificationsPlatform.resetInstance();

      // Test if the instance is set correctly
      expect(AwesomeNotificationsPlatform.instance,
          isA<AwesomeNotificationsEmpty>());

      AwesomeNotificationsPlatform.operatingSystem = "fuchsia";
      AwesomeNotificationsPlatform.resetInstance();

      // Test if the instance is set correctly
      expect(AwesomeNotificationsPlatform.instance,
          isA<AwesomeNotificationsEmpty>());
    });
  });
}
