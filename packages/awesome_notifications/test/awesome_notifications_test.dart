import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/awesome_notifications_platform_interface.dart';
import 'package:awesome_notifications/awesome_notifications_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAwesomeNotificationsPlatform
    with MockPlatformInterfaceMixin
    implements AwesomeNotificationsPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AwesomeNotificationsPlatform initialPlatform = AwesomeNotificationsPlatform.instance;

  test('$MethodChannelAwesomeNotifications is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAwesomeNotifications>());
  });

  test('getPlatformVersion', () async {
    AwesomeNotifications awesomeNotificationsPlugin = AwesomeNotifications();
    MockAwesomeNotificationsPlatform fakePlatform = MockAwesomeNotificationsPlatform();
    AwesomeNotificationsPlatform.instance = fakePlatform;

    expect(await awesomeNotificationsPlugin.getPlatformVersion(), '42');
  });
}
