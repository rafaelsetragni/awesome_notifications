import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'awesome_notifications.dart';
import 'awesome_notifications_platform.dart';
import 'src/isolates/isolate_controller.dart';
import 'src/logs/logger.dart';

/// An implementation of [AwesomeNotificationsPlatform] that uses method channels.
class MethodChannelAwesomeNotifications extends AwesomeNotificationsPlatform {
  final String tag = 'MethodChannelAwesomeNotifications';

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel('awesome_notifications');

  ActionHandler? actionHandler;
  ActionHandler? dismissedHandler;
  NotificationHandler? createdHandler;
  NotificationHandler? displayedHandler;

  @override
  Future<void> cancel(int id) async {
    validateId(id);
    await methodChannel.invokeMethod(CHANNEL_METHOD_CANCEL_NOTIFICATION, id);
  }

  @override
  Future<void> cancelAll() async {
    await methodChannel.invokeMethod(CHANNEL_METHOD_CANCEL_ALL_NOTIFICATIONS);
  }

  @override
  Future<void> cancelAllSchedules() async {
    await methodChannel.invokeMethod(CHANNEL_METHOD_CANCEL_ALL_SCHEDULES);
  }

  @override
  Future<void> cancelNotificationsByChannelKey(String channelKey) async {
    await methodChannel.invokeMethod(
        CHANNEL_METHOD_CANCEL_NOTIFICATIONS_BY_CHANNEL_KEY, channelKey);
  }

  @override
  Future<void> cancelNotificationsByGroupKey(String groupKey) async {
    await methodChannel.invokeMethod(
        CHANNEL_METHOD_CANCEL_NOTIFICATIONS_BY_GROUP_KEY, groupKey);
  }

  @override
  Future<void> cancelSchedule(int id) async {
    validateId(id);
    await methodChannel.invokeMethod(CHANNEL_METHOD_CANCEL_SCHEDULE, id);
  }

  @override
  Future<void> cancelSchedulesByChannelKey(String channelKey) async {
    await methodChannel.invokeMethod(
        CHANNEL_METHOD_CANCEL_SCHEDULES_BY_CHANNEL_KEY, channelKey);
  }

  @override
  Future<void> cancelSchedulesByGroupKey(String groupKey) async {
    await methodChannel.invokeMethod(
        CHANNEL_METHOD_CANCEL_SCHEDULES_BY_GROUP_KEY, groupKey);
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
      ]}) async {
    List<Object?> permissionList = _listPermissionToListString(permissions);

    permissionList = await methodChannel.invokeMethod(
        CHANNEL_METHOD_CHECK_PERMISSIONS, {
      NOTIFICATION_CHANNEL_KEY: channelKey,
      NOTIFICATION_PERMISSIONS: permissionList
    });

    return _listStringToListPermission(permissionList);
  }

  @override
  Future<bool> createNotification({
    required NotificationContent content,
    NotificationSchedule? schedule,
    List<NotificationActionButton>? actionButtons,
    List<NotificationExtension>? extensions,
  }) async {
    validateId(content.id!);

    final Map<String, dynamic> data = NotificationModel(
      content: content,
      schedule: schedule,
      actionButtons: actionButtons,
    ).toMap();

    // Merge whatever add-on extensions contribute (e.g. localizations). The core
    // doesn't know what these are — it just forwards the extra map entries.
    for (final extension in extensions ?? const <NotificationExtension>[]) {
      data.addAll(extension.toMap());
    }

    final bool wasCreated =
        await methodChannel.invokeMethod(CHANNEL_METHOD_CREATE_NOTIFICATION, data);

    return wasCreated;
  }

  @override
  Future<bool> createNotificationFromJsonData(
      Map<String, dynamic> mapData) async {
    try {
      // FCM data arrives as a flat Map<String, String>, so work on a typed copy.
      // Normalize every top-level string that parses as a JSON object/array —
      // this covers content/schedule/actionButtons, the `localizations` block and
      // any future add-on key, without the core needing to know them by name.
      final Map<String, dynamic> normalized = Map<String, dynamic>.from(mapData);
      for (final String key in normalized.keys.toList()) {
        final dynamic value = normalized[key];
        if (value is String) {
          try {
            final dynamic decoded = json.decode(value);
            if (decoded is Map || decoded is List) normalized[key] = decoded;
          } catch (_) {
            // Not JSON — keep the original string value.
          }
        }
      }

      // Invalid Notification
      NotificationModel? notificationModel =
          NotificationModel().fromMap(normalized);
      if (notificationModel == null) {
        throw Exception('Notification map data is invalid');
      }

      // Forward the normalized known sections AND preserve any extra top-level
      // keys from the payload (e.g. `localizations` from a push, or other add-on
      // data) so the native side still receives the original JSON shape.
      final Map<String, dynamic> data = notificationModel.toMap();
      for (final MapEntry<String, dynamic> entry in normalized.entries) {
        data.putIfAbsent(entry.key, () => entry.value);
      }

      final bool wasCreated =
          await methodChannel.invokeMethod(CHANNEL_METHOD_CREATE_NOTIFICATION, data);

      return wasCreated;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int> decrementGlobalBadgeCounter() async {
    final int badgeCount =
        await methodChannel.invokeMethod(CHANNEL_METHOD_DECREMENT_BADGE_COUNT);
    return badgeCount;
  }

  @override
  Future<void> dismiss(int id) async {
    validateId(id);
    await methodChannel.invokeMethod(CHANNEL_METHOD_DISMISS_NOTIFICATION, id);
  }

  @override
  Future<void> dismissAllNotifications() async {
    await methodChannel.invokeMethod(CHANNEL_METHOD_DISMISS_ALL_NOTIFICATIONS);
  }

  @override
  Future<void> dismissNotificationsByChannelKey(String channelKey) async {
    await methodChannel.invokeMethod(
        CHANNEL_METHOD_DISMISS_NOTIFICATIONS_BY_CHANNEL_KEY, channelKey);
  }

  @override
  Future<void> dismissNotificationsByGroupKey(String groupKey) async {
    await methodChannel.invokeMethod(
        CHANNEL_METHOD_DISMISS_NOTIFICATIONS_BY_GROUP_KEY, groupKey);
  }

  @override
  Future<NotificationLifeCycle> getAppLifeCycle() async {
    final String? lifeCycleRaw =
        await methodChannel.invokeMethod(CHANNEL_METHOD_GET_APP_LIFE_CYCLE);
    return NotificationLifeCycle.values
        .firstWhere((e) => e.name == lifeCycleRaw);
  }

  @override
  Future<Uint8List?> getDrawableData(String drawablePath) async {
    var result2 = await methodChannel.invokeMethod(
        CHANNEL_METHOD_GET_DRAWABLE_DATA, drawablePath);

    if (result2 == null) return null;

    return result2;
  }

  @override
  Future<ReceivedAction?> getInitialNotificationAction(
      {bool removeFromActionEvents = false}) async {
    dynamic returnedData = await methodChannel.invokeMethod(
        CHANNEL_METHOD_GET_INITIAL_ACTION, removeFromActionEvents);
    if (returnedData == null) return null;

    Map<String, dynamic>? actionData = Map<String, dynamic>.from(returnedData);
    ReceivedAction? receivedAction = ReceivedAction().fromMap(actionData);
    return receivedAction;
  }

  @override
  Future<int> getGlobalBadgeCounter() async {
    final int badgeCount =
        await methodChannel.invokeMethod(CHANNEL_METHOD_GET_BADGE_COUNT);
    return badgeCount;
  }

  @override
  Future<String> getLocalTimeZoneIdentifier() async {
    final String localIdentifier = await methodChannel
        .invokeMethod(CHANNEL_METHOD_GET_LOCAL_TIMEZONE_IDENTIFIER);
    return localIdentifier;
  }

  @override
  Future<DateTime?> getNextDate(NotificationSchedule schedule,
      {DateTime? fixedDate}) async {
    fixedDate ??= DateTime.now().toUtc();
    Map parameters = {
      NOTIFICATION_INITIAL_FIXED_DATE:
          AwesomeDateUtils.parseDateToString(fixedDate),
      NOTIFICATION_SCHEDULE: schedule.toMap()
    };

    final String? nextDate = await methodChannel.invokeMethod(
        CHANNEL_METHOD_GET_NEXT_DATE, parameters);

    if (nextDate == null) return null;

    return AwesomeDateUtils.parseStringToDate(nextDate)!;
  }

  @override
  Future<String> getUtcTimeZoneIdentifier() async {
    final String utcIdentifier = await methodChannel
        .invokeMethod(CHANNEL_METHOD_GET_UTC_TIMEZONE_IDENTIFIER);
    return utcIdentifier;
  }

  @override
  Future<int> incrementGlobalBadgeCounter() async {
    final int badgeCount =
        await methodChannel.invokeMethod(CHANNEL_METHOD_INCREMENT_BADGE_COUNT);
    return badgeCount;
  }

  @override
  Future<bool> initialize(
    String? defaultIcon,
    List<NotificationChannel> channels, {
    List<NotificationChannelGroup>? channelGroups,
    bool debug = false,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();

    methodChannel.setMethodCallHandler(handleMethod);

    List<dynamic> serializedChannels = [];
    for (NotificationChannel channel in channels) {
      serializedChannels.add(channel.toMap());
    }

    List<dynamic> serializedChannelGroups = [];
    if (channelGroups != null) {
      for (NotificationChannelGroup channelGroup in channelGroups) {
        serializedChannelGroups.add(channelGroup.toMap());
      }
    }

    String? defaultIconPath;
    if (kIsWeb) {
      // For web release
    } else {
      if (!AwesomeAssertUtils.isNullOrEmptyOrInvalid(defaultIcon)) {
        // To set a icon on top of notification, is mandatory to user a native resource
        assert(AwesomeBitmapUtils().getMediaSource(defaultIcon!) ==
            MediaSource.Resource);
        defaultIconPath = defaultIcon;
      }
    }

    final CallbackHandle? dartCallbackReference =
        PluginUtilities.getCallbackHandle(dartIsolateMain);

    var result = await methodChannel.invokeMethod(CHANNEL_METHOD_INITIALIZE, {
      INITIALIZE_DEBUG_MODE: debug,
      INITIALIZE_DEFAULT_ICON: defaultIconPath,
      INITIALIZE_CHANNELS: serializedChannels,
      INITIALIZE_CHANNELS_GROUPS: serializedChannelGroups,
      BACKGROUND_HANDLE: dartCallbackReference!.toRawHandle()
    });

    AwesomeNotifications.localTimeZoneIdentifier = await methodChannel
        .invokeMethod(CHANNEL_METHOD_GET_LOCAL_TIMEZONE_IDENTIFIER);

    AwesomeNotifications.utcTimeZoneIdentifier = await methodChannel
        .invokeMethod(CHANNEL_METHOD_GET_UTC_TIMEZONE_IDENTIFIER);

    return result;
  }

  @override
  Future<bool> isNotificationAllowed() async {
    final bool isAllowed = await methodChannel
        .invokeMethod(CHANNEL_METHOD_IS_NOTIFICATION_ALLOWED);
    return isAllowed;
  }

  @override
  Future<List<NotificationModel>> listScheduledNotifications() async {
    List<NotificationModel> scheduledNotifications = [];
    List<Object>? returned =
        await methodChannel.invokeListMethod(CHANNEL_METHOD_LIST_ALL_SCHEDULES);
    if (returned != null) {
      for (Object object in returned) {
        if (object is Map) {
          NotificationModel? notificationModel =
              NotificationModel().fromMap(Map<String, dynamic>.from(object));
          if (notificationModel == null) continue;

          scheduledNotifications.add(notificationModel);
        }
      }
    }
    return scheduledNotifications;
  }

  @override
  Future<bool> removeChannel(String channelKey) async {
    final bool wasRemoved = await methodChannel.invokeMethod(
        CHANNEL_METHOD_REMOVE_NOTIFICATION_CHANNEL, channelKey);
    return wasRemoved;
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
    final List<String> permissionList = [];
    for (final permission in permissions) {
      String? permissionValue =
          AwesomeAssertUtils.toSimpleEnumString(permission);
      if (permissionValue != null) permissionList.add(permissionValue);
    }

    final List<Object?>? missingPermissions = await methodChannel.invokeMethod(
        CHANNEL_METHOD_REQUEST_NOTIFICATIONS, {
      NOTIFICATION_CHANNEL_KEY: channelKey,
      NOTIFICATION_PERMISSIONS: permissionList
    });

    return missingPermissions?.isEmpty ?? false;
  }

  @override
  Future<void> resetGlobalBadge() async {
    await methodChannel.invokeMethod(CHANNEL_METHOD_RESET_BADGE);
  }

  @override
  Future<void> setChannel(NotificationChannel notificationChannel,
      {bool forceUpdate = false}) async {
    Map<String, dynamic> parameters = notificationChannel.toMap();
    parameters.addAll({CHANNEL_FORCE_UPDATE: forceUpdate});

    await methodChannel.invokeMethod(
        CHANNEL_METHOD_SET_NOTIFICATION_CHANNEL, parameters);
  }

  @override
  Future<void> setGlobalBadgeCounter(int? amount) async {
    await methodChannel.invokeMethod(CHANNEL_METHOD_SET_BADGE_COUNT, amount);
  }

  @override
  Future<bool> setListeners(
      {required ActionHandler onActionReceivedMethod,
      NotificationHandler? onNotificationCreatedMethod,
      NotificationHandler? onNotificationDisplayedMethod,
      ActionHandler? onDismissActionReceivedMethod}) async {
    if (actionHandler != null && actionHandler != onActionReceivedMethod) {
      Logger.w(tag, 'Static listener for notifications actions was redefined.');
    }

    actionHandler = onActionReceivedMethod;
    dismissedHandler = onDismissActionReceivedMethod;
    createdHandler = onNotificationCreatedMethod;
    displayedHandler = onNotificationDisplayedMethod;

    final CallbackHandle? createdCallbackReference =
        onNotificationCreatedMethod != null
            ? PluginUtilities.getCallbackHandle(onNotificationCreatedMethod)
            : null;

    final CallbackHandle? displayedCallbackReference =
        onNotificationDisplayedMethod != null
            ? PluginUtilities.getCallbackHandle(onNotificationDisplayedMethod)
            : null;

    final CallbackHandle? actionCallbackReference =
        PluginUtilities.getCallbackHandle(onActionReceivedMethod);

    final CallbackHandle? dismissedCallbackReference =
        onDismissActionReceivedMethod != null
            ? PluginUtilities.getCallbackHandle(onDismissActionReceivedMethod)
            : null;

    bool result =
        await methodChannel.invokeMethod(CHANNEL_METHOD_SET_EVENT_HANDLES, {
      CREATED_HANDLE: createdCallbackReference?.toRawHandle(),
      DISPLAYED_HANDLE: displayedCallbackReference?.toRawHandle(),
      ACTION_HANDLE: actionCallbackReference?.toRawHandle(),
      DISMISSED_HANDLE: dismissedCallbackReference?.toRawHandle()
    });

    if (!result) {
      Logger.e(tag,
          'onActionNotificationMethod is not a valid global or static method.');
      return false;
    }

    return result;
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
    List<Object?> permissionList = _listPermissionToListString(permissions);

    permissionList = await methodChannel.invokeMethod(
        CHANNEL_METHOD_SHOULD_SHOW_RATIONALE, {
      NOTIFICATION_CHANNEL_KEY: channelKey,
      NOTIFICATION_PERMISSIONS: permissionList
    });

    return _listStringToListPermission(permissionList);
  }

  @override
  Future<void> showAlarmPage() async {
    await methodChannel.invokeMethod(CHANNEL_METHOD_SHOW_ALARM_PAGE);
  }

  @override
  Future<void> showGlobalDndOverridePage() async {
    await methodChannel.invokeMethod(CHANNEL_METHOD_SHOW_GLOBAL_DND_PAGE);
  }

  @override
  Future<void> showNotificationConfigPage({String? channelKey}) async {
    await methodChannel.invokeMethod(
        CHANNEL_METHOD_SHOW_NOTIFICATION_PAGE, channelKey);
  }

  @override
  Future<bool> isNotificationActiveOnStatusBar({required int id}) async {
    var success = await methodChannel.invokeMethod(
        CHANNEL_METHOD_IS_NOTIFICATION_ACTIVE, id);
    return success;
  }

  @override
  Future<List<int>> getAllActiveNotificationIdsOnStatusBar() async {
    return await methodChannel
            .invokeMethod(CHANNEL_METHOD_GET_ALL_ACTIVE_NOTIFICATION_IDS) ??
        [];
  }

  final String _silentBGActionTypeKey =
      AwesomeAssertUtils.toSimpleEnumString(ActionType.SilentBackgroundAction)!;

  @visibleForTesting
  Future<dynamic> handleMethod(MethodCall call) async {
    Map<String, dynamic> arguments =
        (call.arguments as Map).cast<String, dynamic>();

    switch (call.method) {
      case EVENT_NOTIFICATION_CREATED:
        var received = ReceivedNotification().fromMap(arguments);
        if (createdHandler != null) await createdHandler!(received);
        return;

      case EVENT_NOTIFICATION_DISPLAYED:
        var received = ReceivedNotification().fromMap(arguments);
        if (displayedHandler != null) await displayedHandler!(received);
        return;

      case EVENT_NOTIFICATION_DISMISSED:
        var received = ReceivedAction().fromMap(arguments);
        if (dismissedHandler != null) await dismissedHandler!(received);
        return;

      case EVENT_DEFAULT_ACTION:
        var received = ReceivedAction().fromMap(arguments);
        if (actionHandler != null) await actionHandler!(received);
        return;

      case EVENT_SILENT_ACTION:
        if (arguments[NOTIFICATION_ACTION_TYPE] == _silentBGActionTypeKey) {
          await compute(IsolateController().receiveSilentAction, arguments);
        } else {
          await IsolateController().receiveSilentAction(arguments);
        }
        return;

      default:
        throw UnsupportedError('Unrecognized JSON message');
    }
  }

  @visibleForTesting
  void validateId(int id) {
    if (id > 0x7FFFFFFF || id < -0x80000000) {
      throw ArgumentError(
          'The id field must be the limited to 32-bit size integer');
    }
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

  @override
  void dispose() {}
}
