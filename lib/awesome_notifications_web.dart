// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter
//import 'dart:html' as html show window;
import 'dart:typed_data';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'awesome_notifications.dart';
import 'awesome_notifications_platform_interface.dart';

/// A web implementation of the AwesomeNotificationsPlatform of the AwesomeNotifications plugin.
class AwesomeNotificationsWeb extends AwesomeNotificationsPlatform {
  /// Constructs a AwesomeNotificationsWeb
  AwesomeNotificationsWeb();

  static void registerWith(Registrar registrar) {
    AwesomeNotificationsPlatform.instance = AwesomeNotificationsWeb();
  }

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
    return [];
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
    return false;
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
    return false;
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
  dispose() async {}
}
