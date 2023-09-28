import 'dart:typed_data';

import 'package:awesome_notifications/i_awesome_notifications.dart';
import 'package:desktop_notifications/desktop_notifications.dart';
import 'package:flutter/cupertino.dart';

import 'awesome_notifications.dart';
import 'awesome_notifications_platform_interface.dart';

class AwesomeNotificationsLinux extends AwesomeNotificationsPlatform
    implements IAwesomeNotifications {
  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> cancelAllSchedules() async {}

  @override
  Future<void> cancelNotificationsByChannelKey(String channelKey) async {}

  @override
  Future<void> cancelNotificationsByGroupKey(String groupKey) async {}

  @override
  Future<void> cancelSchedule(int id) async {}

  @override
  Future<void> cancelSchedulesByChannelKey(String channelKey) async {}

  @override
  Future<void> cancelSchedulesByGroupKey(String groupKey) async {}

  @override
  Future<List<NotificationPermission>> checkPermissionList(
      {String? channelKey,
      List<NotificationPermission> permissions = const [
        NotificationPermission.Badge,
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Vibration,
        NotificationPermission.Light
      ]}) async {
    return permissions;
  }

  @override
  Future<bool> createNotification({
    required NotificationContent content,
    NotificationSchedule? schedule,
    List<NotificationActionButton>? actionButtons,
    Map<String, NotificationLocalization>? localizations,
  }) async {
    debugPrint('Sending Linux message: ${content.title}');
    final client = NotificationsClient();
    await client.notify(
      content.title ?? '',
      body: content.body ?? '',
      appIcon: content.icon ?? '',
    );
    await client.close();
    return false;
  }

  @override
  Future<bool> createNotificationFromJsonData(
      Map<String, dynamic> mapData) async {
    return false;
  }

  @override
  Future<int> decrementGlobalBadgeCounter() async {
    return 0;
  }

  @override
  Future<void> dismiss(int id) async {}

  @override
  Future<void> dismissAllNotifications() async {}

  @override
  Future<void> dismissNotificationsByChannelKey(String channelKey) async {}

  @override
  Future<void> dismissNotificationsByGroupKey(String groupKey) async {}

  @override
  Future<NotificationLifeCycle> getAppLifeCycle() async {
    return NotificationLifeCycle.Terminated;
  }

  @override
  Future<Uint8List?> getDrawableData(String drawablePath) async {
    return null;
  }

  @override
  Future<ReceivedAction?> getInitialNotificationAction(
      {bool removeFromActionEvents = false}) async {
    return null;
  }

  @override
  Future<int> getGlobalBadgeCounter() async {
    return 0;
  }

  @override
  Future<String> getLocalTimeZoneIdentifier() async {
    return AwesomeNotifications.localTimeZoneIdentifier;
  }

  @override
  Future<DateTime?> getNextDate(NotificationSchedule schedule,
      {DateTime? fixedDate}) async {
    return null;
  }

  @override
  Future<String> getUtcTimeZoneIdentifier() async {
    return AwesomeNotifications.utcTimeZoneIdentifier;
  }

  @override
  Future<int> incrementGlobalBadgeCounter() async {
    return 0;
  }

  @override
  Future<bool> initialize(
    String? defaultIcon,
    List<NotificationChannel> channels, {
    List<NotificationChannelGroup>? channelGroups,
    bool debug = false,
    String? languageCode,
  }) async {
    return true;
  }

  @override
  Future<bool> isNotificationAllowed() async {
    return false;
  }

  @override
  Future<List<NotificationModel>> listScheduledNotifications() async {
    return [];
  }

  @override
  Future<bool> removeChannel(String channelKey) async {
    return false;
  }

  @override
  Future<bool> requestPermissionToSendNotifications(
      {String? channelKey,
      List<NotificationPermission> permissions = const [
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Badge,
        NotificationPermission.Vibration,
        NotificationPermission.Light
      ]}) async {
    print("linux permissions request");
    return true;
  }

  @override
  Future<void> resetGlobalBadge() async {}

  @override
  Future<void> setChannel(NotificationChannel notificationChannel,
      {bool forceUpdate = false}) async {}

  @override
  Future<void> setGlobalBadgeCounter(int? amount) async {}

  @override
  Future<bool> setListeners(
      {required ActionHandler onActionReceivedMethod,
      NotificationHandler? onNotificationCreatedMethod,
      NotificationHandler? onNotificationDisplayedMethod,
      ActionHandler? onDismissActionReceivedMethod}) async {
    return true;
  }

  @override
  Future<List<NotificationPermission>> shouldShowRationaleToRequest(
      {String? channelKey,
      List<NotificationPermission> permissions = const [
        NotificationPermission.Badge,
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Vibration,
        NotificationPermission.Light
      ]}) async {
    return [];
  }

  @override
  Future<void> showAlarmPage() async {}

  @override
  Future<void> showGlobalDndOverridePage() async {}

  @override
  Future<void> showNotificationConfigPage({String? channelKey}) async {}

  @override
  Future<String> getLocalization() async {
    return '';
  }

  @override
  Future<bool> setLocalization({required String? languageCode}) async {
    return false;
  }

  @override
  Future<bool> isNotificationActiveOnStatusBar({required int id}) async {
    return false;
  }

  @override
  Future<List<int>> getAllActiveNotificationIdsOnStatusBar() async {
    return [];
  }

  @override
  dispose() {}
}
