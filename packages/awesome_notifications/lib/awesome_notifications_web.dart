// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter
//import 'dart:html' as html show window;
import 'dart:typed_data';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'awesome_notifications.dart';
import 'awesome_notifications_platform_web.dart';

/// Takes over `createNotification` on the web for the models an add-on owns:
/// answers null when the model isn't its own, true / false when it handled
/// it, or throws to reject it.
typedef WebNotificationBuilder = Future<bool?> Function(
    Map<String, dynamic> model);

/// A web implementation of the AwesomeNotificationsPlatform of the AwesomeNotifications plugin.
class AwesomeNotificationsWeb extends AwesomeNotificationsPlatform {
  /// Constructs a AwesomeNotificationsWeb
  AwesomeNotificationsWeb();

  static void registerWith(Registrar registrar) {
    AwesomeNotificationsPlatform.instance = AwesomeNotificationsWeb();
  }

  static final List<WebNotificationBuilder> _builders = [];
  static ActionHandler? _actionHandler;

  /// Lets an add-on take over `createNotification` for the models it owns.
  /// [builder] receives the whole model map (content, actionButtons and every
  /// extension's entries).
  static void registerNotificationBuilder(WebNotificationBuilder builder) {
    if (!_builders.contains(builder)) _builders.add(builder);
  }

  /// Emits the action event of [model] (a model map, as given to a builder),
  /// as a pressed button does: `onActionReceivedMethod` receives it.
  static Future<void> dispatchAction(
    Map<String, dynamic> model, {
    required String buttonKey,
    String? input,
    Map<String, dynamic>? button,
  }) async {
    final handler = _actionHandler;
    if (handler == null) return;
    final content = Map<String, dynamic>.from(
        (model[NOTIFICATION_CONTENT] as Map?) ?? const {});
    final action = ReceivedAction().fromMap({
      ...content,
      NOTIFICATION_BUTTON_KEY_PRESSED: buttonKey,
      NOTIFICATION_BUTTON_KEY_INPUT: input ?? '',
      if (button?[NOTIFICATION_ACTION_TYPE] != null)
        NOTIFICATION_ACTION_TYPE: button![NOTIFICATION_ACTION_TYPE],
      NOTIFICATION_ACTION_LIFECYCLE: NotificationLifeCycle.Foreground.name,
      NOTIFICATION_ACTION_DATE:
          AwesomeDateUtils.parseDateToString(DateTime.now().toUtc()),
    });
    await handler(action);
  }

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> cancelNotificationsByChannelKey(String channelKey) async {}

  @override
  Future<void> cancelNotificationsByGroupKey(String groupKey) async {}

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
  Future<bool> createNotification({
    required NotificationContent content,
    List<NotificationActionButton>? actionButtons,
    List<NotificationExtension>? extensions,
  }) async {
    if (_builders.isEmpty) return false;
    final Map<String, dynamic> data = NotificationModel(
      content: content,
      actionButtons: actionButtons,
    ).toMap();
    for (final extension in extensions ?? const <NotificationExtension>[]) {
      data.addAll(extension.toMap());
    }
    for (final builder in _builders) {
      final handled = await builder(data);
      if (handled != null) return handled;
    }
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
  }) async {
    return false;
  }

  @override
  Future<bool> isNotificationAllowed() async {
    return false;
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
    _actionHandler = onActionReceivedMethod;
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
  Future<bool> isNotificationActiveOnStatusBar({required int id}) async {
    return false;
  }

  @override
  Future<List<int>> getAllActiveNotificationIdsOnStatusBar() async {
    return [];
  }

  @override
  Future<void> dispose() async {}
}
