import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/awesome_notifications_platform_interface.dart';
import 'package:awesome_notifications/awesome_notifications_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAwesomeNotificationsPlatform
    with MockPlatformInterfaceMixin
    implements AwesomeNotificationsPlatform {
  @override
  Future<void> cancel(int id) {
    // TODO: implement cancel
    throw UnimplementedError();
  }

  @override
  Future<void> cancelAll() {
    // TODO: implement cancelAll
    throw UnimplementedError();
  }

  @override
  Future<void> cancelAllSchedules() {
    // TODO: implement cancelAllSchedules
    throw UnimplementedError();
  }

  @override
  Future<void> cancelNotificationsByChannelKey(String channelKey) {
    // TODO: implement cancelNotificationsByChannelKey
    throw UnimplementedError();
  }

  @override
  Future<void> cancelNotificationsByGroupKey(String groupKey) {
    // TODO: implement cancelNotificationsByGroupKey
    throw UnimplementedError();
  }

  @override
  Future<void> cancelSchedule(int id) {
    // TODO: implement cancelSchedule
    throw UnimplementedError();
  }

  @override
  Future<void> cancelSchedulesByChannelKey(String channelKey) {
    // TODO: implement cancelSchedulesByChannelKey
    throw UnimplementedError();
  }

  @override
  Future<void> cancelSchedulesByGroupKey(String groupKey) {
    // TODO: implement cancelSchedulesByGroupKey
    throw UnimplementedError();
  }

  @override
  Future<List<NotificationPermission>> checkPermissionList({String? channelKey, List<NotificationPermission> permissions = const [NotificationPermission.Badge, NotificationPermission.Alert, NotificationPermission.Sound, NotificationPermission.Vibration, NotificationPermission.Light]}) {
    // TODO: implement checkPermissionList
    throw UnimplementedError();
  }

  @override
  Future<bool> createNotification({required NotificationContent content, NotificationSchedule? schedule, List<NotificationActionButton>? actionButtons}) {
    // TODO: implement createNotification
    throw UnimplementedError();
  }

  @override
  Future<bool> createNotificationFromJsonData(Map<String, dynamic> mapData) {
    // TODO: implement createNotificationFromJsonData
    throw UnimplementedError();
  }

  @override
  Future<int> decrementGlobalBadgeCounter() {
    // TODO: implement decrementGlobalBadgeCounter
    throw UnimplementedError();
  }

  @override
  Future<void> dismiss(int id) {
    // TODO: implement dismiss
    throw UnimplementedError();
  }

  @override
  Future<void> dismissAllNotifications() {
    // TODO: implement dismissAllNotifications
    throw UnimplementedError();
  }

  @override
  Future<void> dismissNotificationsByChannelKey(String channelKey) {
    // TODO: implement dismissNotificationsByChannelKey
    throw UnimplementedError();
  }

  @override
  Future<void> dismissNotificationsByGroupKey(String groupKey) {
    // TODO: implement dismissNotificationsByGroupKey
    throw UnimplementedError();
  }

  @override
  dispose() {
    // TODO: implement dispose
    throw UnimplementedError();
  }

  @override
  Future<NotificationLifeCycle> getAppLifeCycle() {
    // TODO: implement getAppLifeCycle
    throw UnimplementedError();
  }

  @override
  Future<Uint8List?> getDrawableData(String drawablePath) {
    // TODO: implement getDrawableData
    throw UnimplementedError();
  }

  @override
  Future<int> getGlobalBadgeCounter() {
    // TODO: implement getGlobalBadgeCounter
    throw UnimplementedError();
  }

  @override
  Future<String> getLocalTimeZoneIdentifier() {
    // TODO: implement getLocalTimeZoneIdentifier
    throw UnimplementedError();
  }

  @override
  Future<DateTime?> getNextDate(NotificationSchedule schedule, {DateTime? fixedDate}) {
    // TODO: implement getNextDate
    throw UnimplementedError();
  }

  @override
  Future<String?> getPlatformVersion() {
    // TODO: implement getPlatformVersion
    throw UnimplementedError();
  }

  @override
  Future<String> getUtcTimeZoneIdentifier() {
    // TODO: implement getUtcTimeZoneIdentifier
    throw UnimplementedError();
  }

  @override
  Future<int> incrementGlobalBadgeCounter() {
    // TODO: implement incrementGlobalBadgeCounter
    throw UnimplementedError();
  }

  @override
  Future<bool> initialize(String? defaultIcon, List<NotificationChannel> channels, {List<NotificationChannelGroup>? channelGroups, bool debug = false}) {
    // TODO: implement initialize
    throw UnimplementedError();
  }

  @override
  Future<bool> isNotificationAllowed() {
    // TODO: implement isNotificationAllowed
    throw UnimplementedError();
  }

  @override
  Future<List<NotificationModel>> listScheduledNotifications() {
    // TODO: implement listScheduledNotifications
    throw UnimplementedError();
  }

  @override
  Future<bool> removeChannel(String channelKey) {
    // TODO: implement removeChannel
    throw UnimplementedError();
  }

  @override
  Future<bool> requestPermissionToSendNotifications({String? channelKey, List<NotificationPermission> permissions = const [NotificationPermission.Alert, NotificationPermission.Sound, NotificationPermission.Badge, NotificationPermission.Vibration, NotificationPermission.Light]}) {
    // TODO: implement requestPermissionToSendNotifications
    throw UnimplementedError();
  }

  @override
  Future<void> resetGlobalBadge() {
    // TODO: implement resetGlobalBadge
    throw UnimplementedError();
  }

  @override
  Future<void> setChannel(NotificationChannel notificationChannel, {bool forceUpdate = false}) {
    // TODO: implement setChannel
    throw UnimplementedError();
  }

  @override
  Future<void> setGlobalBadgeCounter(int? amount) {
    // TODO: implement setGlobalBadgeCounter
    throw UnimplementedError();
  }

  @override
  Future<bool> setListeners({required ActionHandler onActionReceivedMethod, NotificationHandler? onNotificationCreatedMethod, NotificationHandler? onNotificationDisplayedMethod, ActionHandler? onDismissActionReceivedMethod}) {
    // TODO: implement setListeners
    throw UnimplementedError();
  }

  @override
  Future<List<NotificationPermission>> shouldShowRationaleToRequest({String? channelKey, List<NotificationPermission> permissions = const [NotificationPermission.Badge, NotificationPermission.Alert, NotificationPermission.Sound, NotificationPermission.Vibration, NotificationPermission.Light]}) {
    // TODO: implement shouldShowRationaleToRequest
    throw UnimplementedError();
  }

  @override
  Future<void> showAlarmPage() {
    // TODO: implement showAlarmPage
    throw UnimplementedError();
  }

  @override
  Future<void> showGlobalDndOverridePage() {
    // TODO: implement showGlobalDndOverridePage
    throw UnimplementedError();
  }

  @override
  Future<void> showNotificationConfigPage({String? channelKey}) {
    // TODO: implement showNotificationConfigPage
    throw UnimplementedError();
  }
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

    // expect(await awesomeNotificationsPlugin.getPlatformVersion(), '42');
  });
}
