import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_notifications_schedules/awesome_notifications_schedules.dart';
import 'package:awesome_notifications_schedules/awesome_notifications_schedules_platform_interface.dart';
import 'package:awesome_notifications_schedules/awesome_notifications_schedules_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAwesomeNotificationsSchedulesPlatform
    with MockPlatformInterfaceMixin
    implements AwesomeNotificationsSchedulesPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AwesomeNotificationsSchedulesPlatform initialPlatform = AwesomeNotificationsSchedulesPlatform.instance;

  test('$MethodChannelAwesomeNotificationsSchedules is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAwesomeNotificationsSchedules>());
  });

  test('getPlatformVersion', () async {
    AwesomeNotificationsSchedules awesomeNotificationsSchedulesPlugin = AwesomeNotificationsSchedules();
    MockAwesomeNotificationsSchedulesPlatform fakePlatform = MockAwesomeNotificationsSchedulesPlatform();
    AwesomeNotificationsSchedulesPlatform.instance = fakePlatform;

    expect(await awesomeNotificationsSchedulesPlugin.getPlatformVersion(), '42');
  });
}
