import 'dart:typed_data';

import 'package:awesome_notifications/i_awesome_notifications.dart';

import 'awesome_notifications.dart';
import 'awesome_notifications_platform_interface.dart';

class AwesomeNotificationsEmpty extends AwesomeNotificationsPlatform
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
  Future<bool> createNotification(
      {required NotificationContent content,
      NotificationSchedule? schedule,
      List<NotificationActionButton>? actionButtons}) async {
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
    return NotificationLifeCycle.AppKilled;
  }

  @override
  Future<Uint8List?> getDrawableData(String drawablePath) async {
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
      String? defaultIcon, List<NotificationChannel> channels,
      {List<NotificationChannelGroup>? channelGroups,
      bool debug = false}) async {
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
    return false;
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
      ]}) {
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

  @override
  dispose() {}
}
