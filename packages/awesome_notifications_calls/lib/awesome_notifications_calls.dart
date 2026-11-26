/// Calls for awesome_notifications.
///
/// Attach a [NotificationCall] to a notification: the system shows its own
/// call UI for the app's calls (Android CallStyle over the lock screen, iOS
/// CallKit) or its strongest notification (macOS, Windows, Linux, Web), and
/// the user's answers come back to Dart. The package does not carry the
/// call's audio or video: the app does.
library;

import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'src/call_command.dart';
import 'src/call_keys.dart';

export 'package:awesome_notifications/awesome_notifications.dart'
    show NotificationPerson;
export 'src/call_command.dart';
export 'src/notification_call.dart';

/// What the call UI can do on this platform.
class CallCapabilities {
  /// The system's own call UI (Android CallStyle, iOS CallKit).
  final bool systemCallUI;

  /// An incoming call shows over the lock screen.
  final bool lockScreen;

  /// The system UI has mute and hold.
  final bool muteAndHold;

  /// Calls can ring with the app killed (Android FCM, iOS VoIP push).
  final bool push;

  const CallCapabilities({
    required this.systemCallUI,
    required this.lockScreen,
    required this.muteAndHold,
    required this.push,
  });

  static const none =
      CallCapabilities(systemCallUI: false, lockScreen: false, muteAndHold: false, push: false);
}

/// A call the system shows now.
class ActiveCall {
  final String callId;
  final CallState state;

  const ActiveCall({required this.callId, required this.state});

  @override
  bool operator ==(Object other) =>
      other is ActiveCall && other.callId == callId && other.state == state;

  @override
  int get hashCode => Object.hash(callId, state);

  @override
  String toString() => 'ActiveCall($callId, ${state.name})';
}

/// Internal: platform implementations only. Not part of the public API (it
/// may change at any time); apps use [AwesomeNotificationsCalls].
///
/// Answers the call methods and gives the events in the app's own process,
/// where there is no platform channel (web).
abstract class CallsPlatformBridge {
  /// Answers a channel method (`callEnd`, `callActiveCalls`…) as the native
  /// side does.
  Future<Object?> invokeMethod(String method, [Object? arguments]);

  /// The events, shaped as the event channel's.
  Stream<Object?> get events;
}

/// The call operations the core doesn't have.
class AwesomeNotificationsCalls {
  /// Internal: platform implementations only. Not part of the public API.
  ///
  /// Set by a platform implementation that doesn't use the channels (web).
  static CallsPlatformBridge? bridge;

  static final AwesomeNotificationsCalls _instance = AwesomeNotificationsCalls.private(
      const MethodChannel('awesome_notifications'),
      const EventChannel(CallKeys.eventsChannel));
  factory AwesomeNotificationsCalls() => _instance;

  @visibleForTesting
  AwesomeNotificationsCalls.private(this._channel, this._eventChannel);

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

  /// The call command in a received action (null when the action is not
  /// one). For calls whose `commandTarget` includes the action event.
  static CallCommand? commandOf(ReceivedAction action) => CallCommand.parse(
        key: action.buttonKeyPressed,
        callId: action.payload?[CallKeys.payloadCallId],
      );

  /// The call a received notification or action belongs to (null when it is
  /// not a call).
  static String? callIdOf(ReceivedNotification received) =>
      received.payload?[CallKeys.payloadCallId];

  Stream<Map<String, dynamic>>? _events;
  Stream<Map<String, dynamic>> get _eventMaps => _events ??=
      (bridge?.events ?? _eventChannel.receiveBroadcastStream())
          .where((event) => event is Map)
          .map((event) => (event as Map).cast<String, dynamic>())
          .asBroadcastStream();

  /// The commands of every call whose `commandTarget` includes the stream,
  /// while the app runs.
  Stream<CallCommand> get commands => _eventMaps
      .where((map) => map[CallKeys.kind] == CallKeys.kindCommand)
      .map((map) => CallCommand.parse(
            key: '${CallKeys.commandPrefix}${map[CallKeys.action]}',
            callId: map[CallKeys.callId] as String?,
          ))
      .where((command) => command != null)
      .cast<CallCommand>();

  /// iOS: each new PushKit VoIP token, while the app runs. Send it to the
  /// server that sends the VoIP pushes.
  Stream<String> get onVoipToken => _eventMaps
      .where((map) => map[CallKeys.kind] == CallKeys.kindVoipToken)
      .map((map) => map[CallKeys.token])
      .where((token) => token is String && token.isNotEmpty)
      .cast<String>();

  Future<Object?> _invoke(String method, [Object? arguments]) =>
      bridge?.invokeMethod(method, arguments) ?? _channel.invokeMethod(method, arguments);

  /// Ends the call everywhere: the system call UI, its notification and, when
  /// [reason] is [CallEndReason.unanswered], shows the missed call
  /// notification (unless the call turned it off).
  Future<void> endCall(String callId, {CallEndReason reason = CallEndReason.remoteEnded}) async {
    if (!isPlatformSupported) return;
    await _invoke(CallKeys.methodEnd, {CallKeys.callId: callId, CallKeys.reason: reason.name});
  }

  /// The calls the system shows now.
  Future<List<ActiveCall>> activeCalls() async {
    if (!isPlatformSupported) return const [];
    final result = await _invoke(CallKeys.methodActiveCalls);
    if (result is! List) return const [];
    return [
      for (final item in result)
        if (item is Map)
          if (CallState.values.where((s) => s.name == item[CallKeys.state]).firstOrNull
              case final state?)
            if (item[CallKeys.callId] case final String callId)
              ActiveCall(callId: callId, state: state)
    ];
  }

  /// iOS: the PushKit VoIP token (null elsewhere, or before PushKit gives
  /// one). See [onVoipToken].
  Future<String?> voipToken() async {
    if (!isPlatformSupported) return null;
    final token = await _invoke(CallKeys.methodVoipToken);
    return token is String && token.isNotEmpty ? token : null;
  }

  /// Android 14+: whether the app may show a call over the lock screen
  /// (`USE_FULL_SCREEN_INTENT`, which the user can revoke). True elsewhere.
  Future<bool> canUseFullScreenIntent() async {
    if (!isPlatformSupported) return false;
    return await _invoke(CallKeys.methodCanUseFullScreenIntent) == true;
  }

  /// Android 14+: opens the system page where the user allows full-screen
  /// calls. Returns [canUseFullScreenIntent] when the user comes back.
  Future<bool> requestFullScreenIntent() async {
    if (!isPlatformSupported) return false;
    return await _invoke(CallKeys.methodRequestFullScreenIntent) == true;
  }

  /// What the call UI can do here.
  Future<CallCapabilities> capabilities() async {
    if (!isPlatformSupported) return CallCapabilities.none;
    final result = await _invoke(CallKeys.methodCapabilities);
    if (result is! Map) return CallCapabilities.none;
    final map = result.cast<String, dynamic>();
    return CallCapabilities(
      systemCallUI: map['systemCallUI'] == true,
      lockScreen: map['lockScreen'] == true,
      muteAndHold: map['muteAndHold'] == true,
      push: map['push'] == true,
    );
  }
}
