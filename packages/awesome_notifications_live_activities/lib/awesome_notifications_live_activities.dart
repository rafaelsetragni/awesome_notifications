/// Live activities for awesome_notifications.
///
/// Attach a [NotificationLiveActivity] to a notification: iOS shows a Live
/// Activity (Lock Screen, Dynamic Island, StandBy, CarPlay), Android 16+ a
/// Live Update (status bar chip, Always-On Display), and every other platform
/// its notification, updated in place without alerting again.
library;

import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'src/live_activity_keys.dart';
import 'src/notification_live_activity.dart';

export 'src/notification_live_activity.dart';

/// What the platform shows for live activities.
class LiveActivityCapabilities {
  /// A surface of its own beyond the notification list (iOS Live Activity,
  /// Android 16+ Live Update).
  final bool systemSurface;

  /// Segments, points and icons on the progress bar.
  final bool progressSegments;

  /// Metrics in a layout of their own (iOS; Android's own layout, before
  /// Android 16 or without its Live Update); elsewhere a line in the body.
  final bool metrics;

  /// The activity shows the notification's action buttons (iOS 17+, Android,
  /// Windows, Linux, macOS).
  final bool buttons;

  /// Activities can start and update by push with the app killed.
  final bool push;

  const LiveActivityCapabilities({
    required this.systemSurface,
    required this.progressSegments,
    required this.metrics,
    required this.buttons,
    required this.push,
  });

  static const none = LiveActivityCapabilities(
      systemSurface: false, progressSegments: false, metrics: false, buttons: false, push: false);
}

/// Where an activity is in its life, as the system reports it.
enum LiveActivityStatus {
  /// Shown and current.
  active,

  /// Shown, past its `staleAt` (iOS).
  stale,

  /// Over, still on the Lock Screen until its dismissal (iOS).
  ended,

  /// Gone: removed by the user, by the system (iOS's 8-hour limit, the user
  /// turned live activities off) or by its dismissal.
  dismissed,
}

/// An activity the system shows now.
class ActiveLiveActivity {
  final String activityId;
  final LiveActivityStatus status;

  const ActiveLiveActivity({required this.activityId, required this.status});

  @override
  bool operator ==(Object other) =>
      other is ActiveLiveActivity && other.activityId == activityId && other.status == status;

  @override
  int get hashCode => Object.hash(activityId, status);

  @override
  String toString() => 'ActiveLiveActivity($activityId, ${status.name})';
}

/// A new push token of one activity (iOS): send it to the server that
/// updates the activity by push.
class LiveActivityPushToken {
  final String activityId;
  final String token;

  const LiveActivityPushToken({required this.activityId, required this.token});

  @override
  bool operator ==(Object other) =>
      other is LiveActivityPushToken && other.activityId == activityId && other.token == token;

  @override
  int get hashCode => Object.hash(activityId, token);
}

/// Internal: platform implementations only. Not part of the public API (it
/// may change at any time); apps use [AwesomeNotificationsLiveActivities].
///
/// Answers the methods and gives the events in the app's own process, where
/// there is no platform channel (web).
abstract class LiveActivitiesPlatformBridge {
  Future<Object?> invokeMethod(String method, [Object? arguments]);
  Stream<Object?> get events;
}

/// The live activity operations the core doesn't have.
class AwesomeNotificationsLiveActivities {
  /// Internal: platform implementations only. Not part of the public API.
  static LiveActivitiesPlatformBridge? bridge;

  static final AwesomeNotificationsLiveActivities _instance =
      AwesomeNotificationsLiveActivities.private(
          const MethodChannel('awesome_notifications'),
          const EventChannel(LiveActivityKeys.eventsChannel));
  factory AwesomeNotificationsLiveActivities() => _instance;

  @visibleForTesting
  AwesomeNotificationsLiveActivities.private(this._channel, this._eventChannel);

  final MethodChannel _channel;
  final EventChannel _eventChannel;

  /// Every platform of the 1.0 line.
  static bool get isPlatformSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  Stream<Map<String, dynamic>>? _events;
  Stream<Map<String, dynamic>> get _eventMaps => _events ??=
      (bridge?.events ?? _eventChannel.receiveBroadcastStream())
          .where((event) => event is Map)
          .map((event) => (event as Map).cast<String, dynamic>())
          .asBroadcastStream();

  Future<Object?> _invoke(String method, [Object? arguments]) =>
      bridge?.invokeMethod(method, arguments) ?? _channel.invokeMethod(method, arguments);

  static LiveActivityStatus? _status(Object? name) =>
      LiveActivityStatus.values.where((s) => s.name == name).firstOrNull;

  /// iOS 17.2+: each new push-to-start token, while the app runs. A push to
  /// it starts an activity with the app killed.
  Stream<String> get onPushToStartToken => _eventMaps
      .where((map) => map[LiveActivityKeys.kind] == LiveActivityKeys.kindPushToStartToken)
      .map((map) => map[LiveActivityKeys.token])
      .where((token) => token is String && token.isNotEmpty)
      .cast<String>();

  /// iOS: each new push token of an activity, while the app runs.
  Stream<LiveActivityPushToken> get onPushToken => _eventMaps
      .where((map) => map[LiveActivityKeys.kind] == LiveActivityKeys.kindPushToken)
      .where((map) =>
          map[LiveActivityKeys.activityId] is String &&
          map[LiveActivityKeys.token] is String &&
          (map[LiveActivityKeys.token] as String).isNotEmpty)
      .map((map) => LiveActivityPushToken(
          activityId: map[LiveActivityKeys.activityId] as String,
          token: map[LiveActivityKeys.token] as String));

  /// Each change the system or the user makes to an activity (stale, ended,
  /// dismissed), while the app runs.
  Stream<ActiveLiveActivity> get onStatusChanged => _eventMaps
      .where((map) => map[LiveActivityKeys.kind] == LiveActivityKeys.kindState)
      .map((map) => (map[LiveActivityKeys.activityId], _status(map[LiveActivityKeys.state])))
      .where((pair) => pair.$1 is String && pair.$2 != null)
      .map((pair) => ActiveLiveActivity(activityId: pair.$1 as String, status: pair.$2!));

  /// Ends the activity, showing its last content until [dismissal].
  Future<void> end(String activityId,
      {LiveActivityDismissal dismissal = LiveActivityDismissal.system}) async {
    if (!isPlatformSupported) return;
    await _invoke(LiveActivityKeys.methodEnd, {
      LiveActivityKeys.activityId: activityId,
      LiveActivityKeys.dismissal: dismissal.toValue(),
    });
  }

  /// The activities the system shows now.
  Future<List<ActiveLiveActivity>> activities() async {
    if (!isPlatformSupported) return const [];
    final result = await _invoke(LiveActivityKeys.methodList);
    if (result is! List) return const [];
    return [
      for (final item in result)
        if (item is Map)
          if (_status(item[LiveActivityKeys.state]) case final status?)
            if (item[LiveActivityKeys.activityId] case final String activityId)
              ActiveLiveActivity(activityId: activityId, status: status)
    ];
  }

  /// Whether the user allows live activities: iOS's per-app switch, Android
  /// 16+'s "Live notifications" (promotion) permission. True elsewhere.
  Future<bool> areEnabled() async {
    if (!isPlatformSupported) return false;
    return await _invoke(LiveActivityKeys.methodAreEnabled) == true;
  }

  /// Opens the system page where the user allows live activities (iOS: the
  /// app's Settings; Android 16+: its promotion settings). Returns
  /// [areEnabled] when the user comes back.
  Future<bool> requestPermission() async {
    if (!isPlatformSupported) return false;
    return await _invoke(LiveActivityKeys.methodRequestPermission) == true;
  }

  /// iOS 17.2+: the push-to-start token (null elsewhere, or before ActivityKit
  /// gives one). See [onPushToStartToken].
  Future<String?> pushToStartToken() async {
    if (!isPlatformSupported) return null;
    final token = await _invoke(LiveActivityKeys.methodPushToStartToken);
    return token is String && token.isNotEmpty ? token : null;
  }

  /// iOS: the push token of an activity (null elsewhere, or before ActivityKit
  /// gives one). See [onPushToken].
  Future<String?> pushToken(String activityId) async {
    if (!isPlatformSupported) return null;
    final token = await _invoke(
        LiveActivityKeys.methodPushToken, {LiveActivityKeys.activityId: activityId});
    return token is String && token.isNotEmpty ? token : null;
  }

  /// What live activities look like here.
  Future<LiveActivityCapabilities> capabilities() async {
    if (!isPlatformSupported) return LiveActivityCapabilities.none;
    final result = await _invoke(LiveActivityKeys.methodCapabilities);
    if (result is! Map) return LiveActivityCapabilities.none;
    final map = result.cast<String, dynamic>();
    return LiveActivityCapabilities(
      systemSurface: map[LiveActivityKeys.capSystemSurface] == true,
      progressSegments: map[LiveActivityKeys.capProgressSegments] == true,
      metrics: map[LiveActivityKeys.capMetrics] == true,
      buttons: map[LiveActivityKeys.capButtons] == true,
      push: map[LiveActivityKeys.capPush] == true,
    );
  }

  /// The activity a received notification or action belongs to (null when
  /// it is not one).
  static String? activityIdOf(ReceivedNotification received) =>
      received.payload?[LiveActivityKeys.payloadActivityId];
}
