import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/src/isolates/isolate_main.dart';
// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter
//import 'dart:html' as html;
//import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'package:awesome_notifications/src/logs/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class AwesomeNotifications {
  static String tag = "AwesomeNotifications";
  static String? rootNativePath;

  static String _utcTimeZoneIdentifier = 'UTC',
      _localTimeZoneIdentifier = DateTime.now().timeZoneName;

  static String get utcTimeZoneIdentifier => _utcTimeZoneIdentifier;
  static String get localTimeZoneIdentifier => _localTimeZoneIdentifier;

  ActionHandler? _actionHandler;
  ActionHandler? _dismissedHandler;
  NotificationHandler? _createdHandler;
  NotificationHandler? _displayedHandler;

  /// WEB SUPPORT METHODS *********************************************
/*
  static void registerWith(Registrar registrar) {
  }

  /// Handles method calls over the MethodChannel of this plugin.
  /// Note: Check the "federated" architecture for a new way of doing this:
  /// https://flutter.dev/go/federated-plugins
  Future<dynamic> handleMethodCall(MethodCall call) async {
    _handleWebMethodCall(call);
  }
*/

  /// DISPOSE METHODS *********************************************

  dispose() {}

  /// SINGLETON METHODS *********************************************

  final MethodChannel _channel;

  factory AwesomeNotifications() => _instance;

  @visibleForTesting
  AwesomeNotifications.private(MethodChannel channel) : _channel = channel;

  static final AwesomeNotifications _instance =
      AwesomeNotifications.private(const MethodChannel(CHANNEL_FLUTTER_PLUGIN));

  /// INITIALIZING METHODS *********************************************

  /// Initializes the plugin, creating a default icon and the initial channels. Only needs
  /// to be called at main.dart once.
  /// OBS: [defaultIcon] needs to be a Resource media type
  /// OBS 2: [channels] are updated if they already exists
  Future<bool> initialize(
      String? defaultIcon, List<NotificationChannel> channels,
      {List<NotificationChannelGroup>? channelGroups,
      bool debug = false}) async {
    WidgetsFlutterBinding.ensureInitialized();

    _channel.setMethodCallHandler(_handleMethod);

    List<dynamic> serializedChannels = [];
    for (NotificationChannel channel in channels) {
      serializedChannels.add(channel.toMap());
    }

    List<dynamic> serializedChannelGroups = [];
    if (channelGroups != null)
      for (NotificationChannelGroup channelGroup in channelGroups) {
        serializedChannelGroups.add(channelGroup.toMap());
      }

    String? defaultIconPath;
    if (kIsWeb) {
      // For web release
    } else {
      if (!AwesomeAssertUtils.isNullOrEmptyOrInvalid(defaultIcon, String)) {
        // To set a icon on top of notification, is mandatory to user a native resource
        assert(AwesomeBitmapUtils().getMediaSource(defaultIcon!) ==
            MediaSource.Resource);
        defaultIconPath = defaultIcon;
      }
    }

    final CallbackHandle? dartCallbackReference =
        PluginUtilities.getCallbackHandle(dartIsolateMain);

    var result = await _channel.invokeMethod(CHANNEL_METHOD_INITIALIZE, {
      INITIALIZE_DEBUG_MODE: debug,
      INITIALIZE_DEFAULT_ICON: defaultIconPath,
      INITIALIZE_CHANNELS: serializedChannels,
      INITIALIZE_CHANNELS_GROUPS: serializedChannelGroups,
      BACKGROUND_HANDLE: dartCallbackReference!.toRawHandle()
    });

    _localTimeZoneIdentifier = await _channel
        .invokeMethod(CHANNEL_METHOD_GET_LOCAL_TIMEZONE_IDENTIFIER);
    _utcTimeZoneIdentifier =
        await _channel.invokeMethod(CHANNEL_METHOD_GET_UTC_TIMEZONE_IDENTIFIER);

    return result;
  }

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
      ActionHandler? onDismissActionReceivedMethod}) async {
    if (_actionHandler != null && _actionHandler != onActionReceivedMethod)
      Logger.w(tag, 'Static listener for notifications actions was redefined.');

    _actionHandler = onActionReceivedMethod;
    _dismissedHandler = onDismissActionReceivedMethod;
    _createdHandler = onNotificationCreatedMethod;
    _displayedHandler = onNotificationDisplayedMethod;

    final CallbackHandle? actionCallbackReference =
        PluginUtilities.getCallbackHandle(onActionReceivedMethod);

    bool result =
        await _channel.invokeMethod(CHANNEL_METHOD_SET_ACTION_HANDLE, {
      ACTION_HANDLE: actionCallbackReference?.toRawHandle(),
      RECOVER_DISPLAYED: _displayedHandler != null
    });

    if (!result) {
      Logger.e(tag,
          'onActionNotificationMethod is not a valid global or static method.');
      return false;
    }

    return result;
  }

  /// NATIVE MEDIA METHODS *********************************************

  /// Decode a drawable resource bytes into a Uint8List to be used in Flutter widgets
  Future<Uint8List?> getDrawableData(String drawablePath) async {
    var result2 = await _channel.invokeMethod(
        CHANNEL_METHOD_GET_DRAWABLE_DATA, drawablePath);

    if (result2 == null) return null;

    return result2;
  }

  String _silentBGActionTypeKey =
      AwesomeAssertUtils.toSimpleEnumString(ActionType.SilentBackgroundAction)!;

  Future<dynamic> _handleMethod(MethodCall call) async {
    Map<String, dynamic> arguments =
        (call.arguments as Map).cast<String, dynamic>();

    switch (call.method) {
      case EVENT_NOTIFICATION_CREATED:
        var received = ReceivedNotification().fromMap(arguments);
        if (_createdHandler != null) await _createdHandler!(received);
        return;

      case EVENT_NOTIFICATION_DISPLAYED:
        var received = ReceivedNotification().fromMap(arguments);
        if (_displayedHandler != null) await _displayedHandler!(received);
        return;

      case EVENT_NOTIFICATION_DISMISSED:
        var received = ReceivedAction().fromMap(arguments);
        if (_dismissedHandler != null) await _dismissedHandler!(received);
        return;

      case EVENT_DEFAULT_ACTION:
        var received = ReceivedAction().fromMap(arguments);
        if (_actionHandler != null) await _actionHandler!(received);
        return;

      case EVENT_SILENT_ACTION:
        if (arguments[NOTIFICATION_ACTION_TYPE] == _silentBGActionTypeKey) {
          compute(receiveSilentAction, arguments);
        } else {
          receiveSilentAction(arguments);
        }
        return;

      default:
        throw UnsupportedError('Unrecognized JSON message');
    }
  }

  static int get maxID => 2147483647;

  void _validateId(int id) {
    if (id > 0x7FFFFFFF || id < -0x80000000) {
      throw ArgumentError(
          'The id field must be the limited to 32-bit size integer');
    }
  }

  /// LOCAL NOTIFICATION METHODS *********************************************

  /// Creates a new notification.
  /// If notification has no [body] or [title], it will only be created, but never displayed. (background notification)
  /// [schedule] and [actionButtons] are optional
  Future<bool> createNotification({
    required NotificationContent content,
    NotificationSchedule? schedule,
    List<NotificationActionButton>? actionButtons,
  }) async {
    _validateId(content.id!);

    final bool wasCreated = await _channel.invokeMethod(
        CHANNEL_METHOD_CREATE_NOTIFICATION,
        NotificationModel(
                content: content,
                schedule: schedule,
                actionButtons: actionButtons)
            .toMap());

    return wasCreated;
  }

  Future<bool> createNotificationFromJsonData(
      Map<String, dynamic> mapData) async {
    try {
      if (mapData[NOTIFICATION_CONTENT] is String)
        mapData[NOTIFICATION_CONTENT] =
            json.decode(mapData[NOTIFICATION_CONTENT]);

      if (mapData[NOTIFICATION_SCHEDULE] is String)
        mapData[NOTIFICATION_SCHEDULE] =
            json.decode(mapData[NOTIFICATION_SCHEDULE]);

      if (mapData[NOTIFICATION_BUTTONS] is String)
        mapData[NOTIFICATION_BUTTONS] =
            json.decode(mapData[NOTIFICATION_BUTTONS]);

      // Invalid Notification
      NotificationModel? notificationModel =
          NotificationModel().fromMap(mapData);
      if (notificationModel == null) {
        throw Exception('Notification map data is invalid');
      }

      return createNotification(
          content: notificationModel.content!,
          schedule: notificationModel.schedule,
          actionButtons: notificationModel.actionButtons);
    } catch (e) {
      return false;
    }
  }

  /// Opens the app notifications page
  Future<void> showNotificationConfigPage({String? channelKey}) async {
    await _channel.invokeMethod(
        CHANNEL_METHOD_SHOW_NOTIFICATION_PAGE, channelKey);
  }

  /// Opens the app notifications page
  Future<void> showAlarmPage() async {
    await _channel.invokeMethod(CHANNEL_METHOD_SHOW_ALARM_PAGE);
  }

  /// Opens the app page to allows to override device DnD
  Future<void> showGlobalDndOverridePage() async {
    await _channel.invokeMethod(CHANNEL_METHOD_SHOW_GLOBAL_DND_PAGE);
  }

  /// Check if the notifications are globally permitted
  Future<bool> isNotificationAllowed() async {
    final bool isAllowed =
        await _channel.invokeMethod(CHANNEL_METHOD_IS_NOTIFICATION_ALLOWED);
    return isAllowed;
  }

  /// Prompts the user to enabled notifications
  Future<bool> requestPermissionToSendNotifications(
      {String? channelKey,
      List<NotificationPermission> permissions = const [
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Badge,
        NotificationPermission.Vibration,
        NotificationPermission.Light,
      ]}) async {
    final List<String> permissionList = [];
    for (final permission in permissions) {
      String? permissionValue =
          AwesomeAssertUtils.toSimpleEnumString(permission);
      if (permissionValue != null) permissionList.add(permissionValue);
    }

    final List<Object?>? missingPermissions = await _channel.invokeMethod(
        CHANNEL_METHOD_REQUEST_NOTIFICATIONS, {
      NOTIFICATION_CHANNEL_KEY: channelKey,
      NOTIFICATION_PERMISSIONS: permissionList
    });

    return missingPermissions?.isEmpty ?? false;
  }

  /// Check each individual permission to send notifications and returns only the allowed permissions
  Future<List<NotificationPermission>> checkPermissionList(
      {String? channelKey,
      List<NotificationPermission> permissions = const [
        NotificationPermission.Badge,
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Vibration,
        NotificationPermission.Light
      ]}) async {
    List<Object?> permissionList = _listPermissionToListString(permissions);

    permissionList = await _channel.invokeMethod(
        CHANNEL_METHOD_CHECK_PERMISSIONS, {
      NOTIFICATION_CHANNEL_KEY: channelKey,
      NOTIFICATION_PERMISSIONS: permissionList
    });

    return _listStringToListPermission(permissionList);
  }

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
      ]}) async {
    List<Object?> permissionList = _listPermissionToListString(permissions);

    permissionList = await _channel.invokeMethod(
        CHANNEL_METHOD_SHOULD_SHOW_RATIONALE, {
      NOTIFICATION_CHANNEL_KEY: channelKey,
      NOTIFICATION_PERMISSIONS: permissionList
    });

    return _listStringToListPermission(permissionList);
  }

  List<Object?> _listPermissionToListString(
      List<NotificationPermission> permissions) {
    List<Object?> permissionList = [];
    for (final permission in permissions) {
      String? permissionValue =
          AwesomeAssertUtils.toSimpleEnumString(permission);
      if (permissionValue != null) permissionList.add(permissionValue);
    }
    return permissionList;
  }

  List<NotificationPermission> _listStringToListPermission(
      List<Object?> permissionList) {
    List<NotificationPermission> lockedPermissions = [];
    for (final permission in permissionList) {
      NotificationPermission? permissionValue =
          AwesomeAssertUtils.enumToString<NotificationPermission>(
              permission.toString(), NotificationPermission.values, null);
      if (permissionValue != null) lockedPermissions.add(permissionValue);
    }
    return lockedPermissions;
  }

  /// List all active scheduled notifications.
  Future<List<NotificationModel>> listScheduledNotifications() async {
    List<NotificationModel> scheduledNotifications = [];
    List<Object>? returned =
        await _channel.invokeListMethod(CHANNEL_METHOD_LIST_ALL_SCHEDULES);
    if (returned != null) {
      for (Object object in returned) {
        if (object is Map) {
          try {
            NotificationModel notificationModel =
                NotificationModel().fromMap(Map<String, dynamic>.from(object))!;
            scheduledNotifications.add(notificationModel);
          } catch (e) {
            return [];
          }
        }
      }
    }
    return scheduledNotifications;
  }

  /// Set a new notification channel or updates if already exists
  /// [forceUpdate]: completely updates the channel on Android Oreo and above, but cancels all current notifications.
  Future<void> setChannel(
    NotificationChannel notificationChannel, {
    bool forceUpdate = false,
  }) async {
    Map<String, dynamic> parameters = notificationChannel.toMap();
    parameters.addAll({CHANNEL_FORCE_UPDATE: forceUpdate});

    await _channel.invokeMethod(
        CHANNEL_METHOD_SET_NOTIFICATION_CHANNEL, parameters);
  }

  /// Remove a notification channel
  Future<bool> removeChannel(String channelKey) async {
    final bool wasRemoved = await _channel.invokeMethod(
        CHANNEL_METHOD_REMOVE_NOTIFICATION_CHANNEL, channelKey);
    return wasRemoved;
  }

  /// Get badge counter
  Future<int> getGlobalBadgeCounter() async {
    final int badgeCount =
        await _channel.invokeMethod(CHANNEL_METHOD_GET_BADGE_COUNT);
    return badgeCount;
  }

  /// Set the badge counter to any value
  Future<void> setGlobalBadgeCounter(int? amount) async {
    await _channel.invokeMethod(CHANNEL_METHOD_SET_BADGE_COUNT, amount);
  }

  /// Increment the badge counter
  Future<int> incrementGlobalBadgeCounter() async {
    final int badgeCount =
        await _channel.invokeMethod(CHANNEL_METHOD_INCREMENT_BADGE_COUNT);
    return badgeCount;
  }

  /// Decrement the badge counter
  Future<int> decrementGlobalBadgeCounter() async {
    final int badgeCount =
        await _channel.invokeMethod(CHANNEL_METHOD_DECREMENT_BADGE_COUNT);
    return badgeCount;
  }

  /// Resets the badge counter
  Future<void> resetGlobalBadge() async {
    await _channel.invokeListMethod(CHANNEL_METHOD_RESET_BADGE);
  }

  /// Get the next valid date for a notification schedule
  Future<DateTime?> getNextDate(
    /// A valid Notification schedule model
    NotificationSchedule schedule, {

    /// reference date to simulate a schedule in different time. If null, the reference date will be now
    DateTime? fixedDate,
  }) async {
    fixedDate ??= DateTime.now().toUtc();
    Map parameters = {
      NOTIFICATION_INITIAL_FIXED_DATE:
          AwesomeDateUtils.parseDateToString(fixedDate),
      NOTIFICATION_SCHEDULE: schedule.toMap()
    };

    final String? nextDate =
        await _channel.invokeMethod(CHANNEL_METHOD_GET_NEXT_DATE, parameters);

    if (nextDate == null) return null;

    return AwesomeDateUtils.parseStringToDate(nextDate)!;
  }

  /// Get the current UTC time zone identifier
  Future<String> getUtcTimeZoneIdentifier() async {
    final String utcIdentifier =
        await _channel.invokeMethod(CHANNEL_METHOD_GET_UTC_TIMEZONE_IDENTIFIER);
    return utcIdentifier;
  }

  /// Get the current Local time zone identifier
  Future<String> getLocalTimeZoneIdentifier() async {
    final String localIdentifier = await _channel
        .invokeMethod(CHANNEL_METHOD_GET_LOCAL_TIMEZONE_IDENTIFIER);
    return localIdentifier;
  }

  /// Get the current Local time zone identifier
  Future<NotificationLifeCycle> getAppLifeCycle() async {
    final String? lifeCycleRaw =
        await _channel.invokeMethod(CHANNEL_METHOD_GET_APP_LIFE_CYCLE);
    return NotificationLifeCycle.values
        .firstWhere((e) => e.name == lifeCycleRaw);
  }

  /// Cancel a single notification and its respective schedule
  Future<void> cancel(int id) async {
    _validateId(id);
    await _channel.invokeMethod(CHANNEL_METHOD_CANCEL_NOTIFICATION, id);
  }

  /// Dismiss a single notification, without cancel its schedule
  Future<void> dismiss(int id) async {
    _validateId(id);
    await _channel.invokeMethod(CHANNEL_METHOD_DISMISS_NOTIFICATION, id);
  }

  /// Cancel a single scheduled notification, without dismiss the active notification
  Future<void> cancelSchedule(int id) async {
    _validateId(id);
    await _channel.invokeMethod(CHANNEL_METHOD_CANCEL_SCHEDULE, id);
  }

  /// Dismiss all active notifications with the same channel key on status bar,
  /// without cancel the active respective schedules
  Future<void> dismissNotificationsByChannelKey(String channelKey) async {
    await _channel.invokeMethod(
        CHANNEL_METHOD_DISMISS_NOTIFICATIONS_BY_CHANNEL_KEY, channelKey);
  }

  /// Cancel all active schedules with the same channel key,
  /// without dismiss the respective notifications on status bar
  Future<void> cancelSchedulesByChannelKey(String channelKey) async {
    await _channel.invokeMethod(
        CHANNEL_METHOD_CANCEL_SCHEDULES_BY_CHANNEL_KEY, channelKey);
  }

  /// Cancel and dismiss all notifications and schedules with the same channel key
  Future<void> cancelNotificationsByChannelKey(String channelKey) async {
    await _channel.invokeMethod(
        CHANNEL_METHOD_CANCEL_NOTIFICATIONS_BY_CHANNEL_KEY, channelKey);
  }

  /// Dismiss all active notifications with the same group key on status bar,
  /// without cancel the active respective schedules
  Future<void> dismissNotificationsByGroupKey(String groupKey) async {
    await _channel.invokeMethod(
        CHANNEL_METHOD_DISMISS_NOTIFICATIONS_BY_GROUP_KEY, groupKey);
  }

  /// Cancel all active schedules with the same group key,
  /// without dismiss the respective notifications on status bar
  Future<void> cancelSchedulesByGroupKey(String groupKey) async {
    await _channel.invokeMethod(
        CHANNEL_METHOD_CANCEL_SCHEDULES_BY_GROUP_KEY, groupKey);
  }

  /// Cancel and dismiss all notifications and schedules with the same group key
  Future<void> cancelNotificationsByGroupKey(String groupKey) async {
    await _channel.invokeMethod(
        CHANNEL_METHOD_CANCEL_NOTIFICATIONS_BY_GROUP_KEY, groupKey);
  }

  /// Dismiss all active notifications, without cancel the active respective schedules
  Future<void> dismissAllNotifications() async {
    await _channel.invokeMethod(CHANNEL_METHOD_DISMISS_ALL_NOTIFICATIONS);
  }

  /// Cancel all active notification schedules without dismiss the respective notifications
  Future<void> cancelAllSchedules() async {
    await _channel.invokeMethod(CHANNEL_METHOD_CANCEL_ALL_SCHEDULES);
  }

  /// Cancel and dismiss all notifications and the active schedules
  Future<void> cancelAll() async {
    await _channel.invokeMethod(CHANNEL_METHOD_CANCEL_ALL_NOTIFICATIONS);
  }
}
