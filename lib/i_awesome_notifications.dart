import 'dart:typed_data';

import 'awesome_notifications.dart';

abstract class IAwesomeNotifications {
  /// DISPOSE METHODS *********************************************

  dispose();

  /// INITIALIZING METHODS *********************************************

  /// Initializes the plugin, creating a default icon and the initial channels. Only needs
  /// to be called at main.dart once.
  /// OBS: [defaultIcon] needs to be a Resource media type
  /// OBS 2: [channels] are updated if they already exists
  Future<bool> initialize(
      String? defaultIcon, List<NotificationChannel> channels,
      {List<NotificationChannelGroup>? channelGroups, bool debug = false});

  /// Defines the global or static methods that gonna receive the notification
  /// events. OBS: Only after set at least one method, the notification's events are delivered.
  ///
  /// [onActionReceivedMethod] method that receives all the notification actions
  /// [onNotificationCreatedMethod] method that gets called when a new notification or schedule is created on the system
  /// [onNotificationDisplayedMethod] method that gets called when a new notification is displayed on status bar
  /// [onDismissActionReceivedMethod] method that receives the notification dismiss actions
  Future<bool> setListeners(
      {required ActionHandler onActionReceivedMethod,
      NotificationHandler? onNotificationCreatedMethod,
      NotificationHandler? onNotificationDisplayedMethod,
      ActionHandler? onDismissActionReceivedMethod});

  /// NATIVE MEDIA METHODS *********************************************

  /// Decode a native drawable resource into a Uint8List to be used by Flutter widgets
  Future<Uint8List?> getDrawableData(String drawablePath);

  /// LOCAL NOTIFICATION METHODS *********************************************

  /// Creates a new notification.
  /// If notification has no [body] or [title], it will only be created, but never displayed. (background notification)
  /// [schedule] and [actionButtons] are optional
  Future<bool> createNotification({
    required NotificationContent content,
    NotificationSchedule? schedule,
    List<NotificationActionButton>? actionButtons,
  });

  Future<bool> createNotificationFromJsonData(Map<String, dynamic> mapData);

  /// Opens the app notifications page
  Future<void> showNotificationConfigPage({String? channelKey});

  /// Opens the app notifications page
  Future<void> showAlarmPage();

  /// Opens the app page to allows to override device DnD
  Future<void> showGlobalDndOverridePage();

  /// Check if the notifications are globally permitted
  Future<bool> isNotificationAllowed();

  /// Prompts the user to enabled notifications
  Future<bool> requestPermissionToSendNotifications(
      {String? channelKey,
      List<NotificationPermission> permissions = const [
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Badge,
        NotificationPermission.Vibration,
        NotificationPermission.Light,
      ]});

  /// Check each individual permission to send notifications and returns only the allowed permissions
  Future<List<NotificationPermission>> checkPermissionList(
      {String? channelKey,
      List<NotificationPermission> permissions = const [
        NotificationPermission.Badge,
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Vibration,
        NotificationPermission.Light
      ]});

  /// Check if the app must show some rationale before request the user's consent. Returns the
  /// list of permissions that can only be changed via user's intervention.
  Future<List<NotificationPermission>> shouldShowRationaleToRequest(
      {String? channelKey,
      List<NotificationPermission> permissions = const [
        NotificationPermission.Badge,
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Vibration,
        NotificationPermission.Light
      ]});

  /// List all active scheduled notifications.
  Future<List<NotificationModel>> listScheduledNotifications();

  /// Set a new notification channel or updates if already exists
  /// [forceUpdate]: completely updates the channel on Android Oreo and above, but cancels all current notifications.
  Future<void> setChannel(
    NotificationChannel notificationChannel, {
    bool forceUpdate = false,
  });

  /// Remove a notification channel
  Future<bool> removeChannel(String channelKey);

  /// Get badge counter
  Future<int> getGlobalBadgeCounter();

  /// Set the badge counter to any value
  Future<void> setGlobalBadgeCounter(int? amount);

  /// Increment the badge counter
  Future<int> incrementGlobalBadgeCounter();

  /// Decrement the badge counter
  Future<int> decrementGlobalBadgeCounter();

  /// Resets the badge counter
  Future<void> resetGlobalBadge();

  /// Get the next valid date for a notification schedule
  Future<DateTime?> getNextDate(
    /// A valid Notification schedule model
    NotificationSchedule schedule, {

    /// reference date to simulate a schedule in different time. If null, the reference date will be now
    DateTime? fixedDate,
  });

  /// Get the current UTC time zone identifier
  Future<String> getUtcTimeZoneIdentifier();

  /// Get the current Local time zone identifier
  Future<String> getLocalTimeZoneIdentifier();

  /// Get the current Local time zone identifier
  Future<NotificationLifeCycle> getAppLifeCycle();

  /// Cancel a single notification and its respective schedule
  Future<void> cancel(int id);

  /// Dismiss a single notification, without cancel its schedule
  Future<void> dismiss(int id);

  /// Cancel a single scheduled notification, without dismiss the active notification
  Future<void> cancelSchedule(int id);

  /// Dismiss all active notifications with the same channel key on status bar,
  /// without cancel the active respective schedules
  Future<void> dismissNotificationsByChannelKey(String channelKey);

  /// Cancel all active schedules with the same channel key,
  /// without dismiss the respective notifications on status bar
  Future<void> cancelSchedulesByChannelKey(String channelKey);

  /// Cancel and dismiss all notifications and schedules with the same channel key
  Future<void> cancelNotificationsByChannelKey(String channelKey);

  /// Dismiss all active notifications with the same group key on status bar,
  /// without cancel the active respective schedules
  Future<void> dismissNotificationsByGroupKey(String groupKey);

  /// Cancel all active schedules with the same group key,
  /// without dismiss the respective notifications on status bar
  Future<void> cancelSchedulesByGroupKey(String groupKey);

  /// Cancel and dismiss all notifications and schedules with the same group key
  Future<void> cancelNotificationsByGroupKey(String groupKey);

  /// Dismiss all active notifications, without cancel the active respective schedules
  Future<void> dismissAllNotifications();

  /// Cancel all active notification schedules without dismiss the respective notifications
  Future<void> cancelAllSchedules();

  /// Cancel and dismiss all notifications and the active schedules
  Future<void> cancelAll();
}
