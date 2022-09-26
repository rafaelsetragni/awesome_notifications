import 'dart:typed_data';

import 'i_awesome_notifications.dart';
import 'src/enumerators/notification_life_cycle.dart';
import 'src/enumerators/notification_permission.dart';
import 'src/models/notification_button.dart';
import 'src/models/notification_channel.dart';
import 'src/models/notification_channel_group.dart';
import 'src/models/notification_content.dart';
import 'src/models/notification_model.dart';
import 'src/models/notification_schedule.dart';
import 'src/models/received_models/received_action.dart';
import 'src/models/received_models/received_notification.dart';

export 'src/enumerators/action_type.dart';
export 'src/enumerators/group_alert_behaviour.dart';
export 'src/enumerators/media_source.dart';
export 'src/enumerators/emojis.dart';
export 'src/enumerators/default_ringtone_type.dart';
export 'src/enumerators/notification_importance.dart';
export 'src/enumerators/notification_layout.dart';
export 'src/enumerators/notification_life_cycle.dart';
export 'src/enumerators/notification_privacy.dart';
export 'src/enumerators/notification_source.dart';
export 'src/enumerators/notification_category.dart';
export 'src/enumerators/time_and_date.dart';
export 'src/enumerators/group_sort.dart';
export 'src/enumerators/notification_permission.dart';
export 'src/extensions/extension_navigator_state.dart';
export 'src/exceptions/awesome_exception.dart';
export 'src/exceptions/isolate_callback_exception.dart';
export 'src/helpers/bitmap_helper.dart';
export 'src/helpers/cron_helper.dart';
export 'src/models/notification_button.dart';
export 'src/models/notification_channel.dart';
export 'src/models/notification_channel_group.dart';
export 'src/models/notification_content.dart';
export 'src/models/notification_schedule.dart';
export 'src/models/notification_calendar.dart';
export 'src/models/notification_interval.dart';
export 'src/models/notification_android_crontab.dart';
export 'src/models/received_models/push_notification.dart';
export 'src/models/notification_model.dart';
export 'src/models/received_models/received_action.dart';
export 'src/models/received_models/received_notification.dart';
export 'src/utils/assert_utils.dart';
export 'src/utils/bitmap_utils.dart';
export 'src/utils/date_utils.dart';
export 'src/utils/map_utils.dart';
export 'src/utils/resource_image_provider.dart';
export 'src/utils/string_utils.dart';
export 'src/definitions.dart';

import 'awesome_notifications_platform_interface.dart';

/// Method structure to listen to an incoming action with dart
typedef ActionHandler = Future<void> Function(ReceivedAction receivedAction);

/// Method structure to listen to an notification event with dart
typedef NotificationHandler = Future<void> Function(
    ReceivedNotification receivedNotification);

// Pause and Play vibration sequences
Int64List lowVibrationPattern = Int64List.fromList([0, 200, 200, 200]);
Int64List mediumVibrationPattern =
    Int64List.fromList([0, 500, 200, 200, 200, 200]);
Int64List highVibrationPattern =
    Int64List.fromList([0, 1000, 200, 200, 200, 200, 200, 200]);

class AwesomeNotifications implements IAwesomeNotifications {
  static int get maxID => 2147483647;
  static String localTimeZoneIdentifier = 'UTC';
  static String utcTimeZoneIdentifier = DateTime.now().timeZoneName;

  @override
  Future<void> cancel(int id) {
    return AwesomeNotificationsPlatform.instance.cancel(id);
  }

  @override
  Future<void> cancelAll() {
    return AwesomeNotificationsPlatform.instance.cancelAll();
  }

  @override
  Future<void> cancelAllSchedules() {
    return AwesomeNotificationsPlatform.instance.cancelAllSchedules();
  }

  @override
  Future<void> cancelNotificationsByChannelKey(String channelKey) {
    return AwesomeNotificationsPlatform.instance
        .cancelNotificationsByChannelKey(channelKey);
  }

  @override
  Future<void> cancelNotificationsByGroupKey(String groupKey) {
    return AwesomeNotificationsPlatform.instance
        .cancelNotificationsByGroupKey(groupKey);
  }

  @override
  Future<void> cancelSchedule(int id) {
    return AwesomeNotificationsPlatform.instance.cancelSchedule(id);
  }

  @override
  Future<void> cancelSchedulesByChannelKey(String channelKey) {
    return AwesomeNotificationsPlatform.instance
        .cancelSchedulesByChannelKey(channelKey);
  }

  @override
  Future<void> cancelSchedulesByGroupKey(String groupKey) {
    return AwesomeNotificationsPlatform.instance
        .cancelSchedulesByGroupKey(groupKey);
  }

  @override
  Future<List<NotificationPermission>> checkPermissionList(
      {String? channelKey,
      List<NotificationPermission> permissions = const [
        NotificationPermission.Badge,
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Vibration,
        NotificationPermission.Light
      ]}) {
    return AwesomeNotificationsPlatform.instance
        .checkPermissionList(channelKey: channelKey, permissions: permissions);
  }

  @override
  Future<bool> createNotification(
      {required NotificationContent content,
      NotificationSchedule? schedule,
      List<NotificationActionButton>? actionButtons}) {
    return AwesomeNotificationsPlatform.instance.createNotification(
        content: content, schedule: schedule, actionButtons: actionButtons);
  }

  @override
  Future<bool> createNotificationFromJsonData(Map<String, dynamic> mapData) {
    return AwesomeNotificationsPlatform.instance
        .createNotificationFromJsonData(mapData);
  }

  @override
  Future<int> decrementGlobalBadgeCounter() {
    return AwesomeNotificationsPlatform.instance.decrementGlobalBadgeCounter();
  }

  @override
  Future<void> dismiss(int id) {
    return AwesomeNotificationsPlatform.instance.dismiss(id);
  }

  @override
  Future<void> dismissAllNotifications() {
    return AwesomeNotificationsPlatform.instance.dismissAllNotifications();
  }

  @override
  Future<void> dismissNotificationsByChannelKey(String channelKey) {
    return AwesomeNotificationsPlatform.instance
        .dismissNotificationsByChannelKey(channelKey);
  }

  @override
  Future<void> dismissNotificationsByGroupKey(String groupKey) {
    return AwesomeNotificationsPlatform.instance
        .dismissNotificationsByGroupKey(groupKey);
  }

  @override
  dispose() {
    return AwesomeNotificationsPlatform.instance.dispose();
  }

  @override
  Future<NotificationLifeCycle> getAppLifeCycle() {
    return AwesomeNotificationsPlatform.instance.getAppLifeCycle();
  }

  @override
  Future<Uint8List?> getDrawableData(String drawablePath) {
    return AwesomeNotificationsPlatform.instance.getDrawableData(drawablePath);
  }

  @override
  Future<int> getGlobalBadgeCounter() {
    return AwesomeNotificationsPlatform.instance.getGlobalBadgeCounter();
  }

  @override
  Future<String> getLocalTimeZoneIdentifier() {
    return AwesomeNotificationsPlatform.instance.getLocalTimeZoneIdentifier();
  }

  @override
  Future<DateTime?> getNextDate(NotificationSchedule schedule,
      {DateTime? fixedDate}) {
    return AwesomeNotificationsPlatform.instance
        .getNextDate(schedule, fixedDate: fixedDate);
  }

  @override
  Future<String> getUtcTimeZoneIdentifier() {
    return AwesomeNotificationsPlatform.instance.getUtcTimeZoneIdentifier();
  }

  @override
  Future<int> incrementGlobalBadgeCounter() {
    return AwesomeNotificationsPlatform.instance.incrementGlobalBadgeCounter();
  }

  @override
  Future<bool> initialize(
      String? defaultIcon, List<NotificationChannel> channels,
      {List<NotificationChannelGroup>? channelGroups, bool debug = false}) {
    return AwesomeNotificationsPlatform.instance.initialize(
        defaultIcon, channels,
        channelGroups: channelGroups, debug: debug);
  }

  @override
  Future<bool> isNotificationAllowed() {
    return AwesomeNotificationsPlatform.instance.isNotificationAllowed();
  }

  @override
  Future<List<NotificationModel>> listScheduledNotifications() {
    return AwesomeNotificationsPlatform.instance.listScheduledNotifications();
  }

  @override
  Future<bool> removeChannel(String channelKey) {
    return AwesomeNotificationsPlatform.instance.removeChannel(channelKey);
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
      ]}) {
    return AwesomeNotificationsPlatform.instance
        .requestPermissionToSendNotifications(
      channelKey: channelKey,
      permissions: permissions,
    );
  }

  @override
  Future<void> resetGlobalBadge() {
    return AwesomeNotificationsPlatform.instance.resetGlobalBadge();
  }

  @override
  Future<void> setChannel(NotificationChannel notificationChannel,
      {bool forceUpdate = false}) {
    return AwesomeNotificationsPlatform.instance
        .setChannel(notificationChannel, forceUpdate: forceUpdate);
  }

  @override
  Future<void> setGlobalBadgeCounter(int? amount) {
    return AwesomeNotificationsPlatform.instance.setGlobalBadgeCounter(amount);
  }

  @override
  Future<bool> setListeners(
      {required ActionHandler onActionReceivedMethod,
      NotificationHandler? onNotificationCreatedMethod,
      NotificationHandler? onNotificationDisplayedMethod,
      ActionHandler? onDismissActionReceivedMethod}) {
    return AwesomeNotificationsPlatform.instance.setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    );
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
    return AwesomeNotificationsPlatform.instance.shouldShowRationaleToRequest(
      channelKey: channelKey,
      permissions: permissions,
    );
  }

  @override
  Future<void> showAlarmPage() {
    return AwesomeNotificationsPlatform.instance.showAlarmPage();
  }

  @override
  Future<void> showGlobalDndOverridePage() {
    return AwesomeNotificationsPlatform.instance.showGlobalDndOverridePage();
  }

  @override
  Future<void> showNotificationConfigPage({String? channelKey}) {
    return AwesomeNotificationsPlatform.instance
        .showNotificationConfigPage(channelKey: channelKey);
  }
}
