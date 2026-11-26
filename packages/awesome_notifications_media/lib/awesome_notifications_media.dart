/// Media controls for awesome_notifications.
///
/// Attach a [NotificationMedia] to a `MediaPlayer` notification: the system
/// shows its own media controls for the app's player (Android media
/// notification, iOS / macOS Now Playing, Windows, Linux and Web media
/// sessions) and the user's commands come back to Dart. The package does not
/// play audio: the app's player does.
library;

import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'src/media_control.dart';
import 'src/media_keys.dart';

export 'src/media_control.dart';
export 'src/notification_media.dart';

/// What the media controls can do on this platform.
class MediaCapabilities {
  /// A progress bar (draggable with `seekTo`).
  final bool seekBar;

  /// The cover art is shown.
  final bool artwork;

  /// Custom buttons (`actionButtons`) are shown.
  final bool customButtons;

  /// The controls show on the lock screen.
  final bool lockScreen;

  const MediaCapabilities({
    required this.seekBar,
    required this.artwork,
    required this.customButtons,
    required this.lockScreen,
  });

  static const none =
      MediaCapabilities(seekBar: false, artwork: false, customButtons: false, lockScreen: false);
}

/// Internal: platform implementations only. Not part of the public API (it
/// may change at any time); apps use [AwesomeNotificationsMedia].
///
/// Answers the media methods and gives the command events in the app's own
/// process, where there is no platform channel (web).
abstract class MediaPlatformBridge {
  /// Answers a channel method (`mediaStop`, `mediaUpdatePosition`,
  /// `mediaCapabilities`) as the native side does.
  Future<Object?> invokeMethod(String method, [Object? arguments]);

  /// The command events, shaped as the event channel's.
  Stream<Object?> get commandEvents;
}

/// The media session operations the core doesn't have.
class AwesomeNotificationsMedia {
  /// Internal: platform implementations only. Not part of the public API.
  ///
  /// Set by a platform implementation that doesn't use the channels (web).
  static MediaPlatformBridge? bridge;

  static final AwesomeNotificationsMedia _instance = AwesomeNotificationsMedia.private(
      const MethodChannel('awesome_notifications'),
      const EventChannel(MediaKeys.commandsChannel));
  factory AwesomeNotificationsMedia() => _instance;

  @visibleForTesting
  AwesomeNotificationsMedia.private(this._channel, this._events);

  final MethodChannel _channel;
  final EventChannel _events;

  /// The clock [bindPosition] throttles with.
  @visibleForTesting
  DateTime Function() now = DateTime.now;

  /// The shortest time between two position updates sent by [bindPosition]
  /// (a jump is sent at once).
  static const positionUpdateInterval = Duration(seconds: 1);

  final Map<String, StreamSubscription<Duration>> _bindings = {};

  /// Every platform of the 1.0 line.
  static bool get isPlatformSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  /// The media command in a received action (null when the action is not
  /// one). For sessions whose `commandTarget` includes the action event.
  static MediaCommand? commandOf(ReceivedAction action) => MediaCommand.parse(
        key: action.buttonKeyPressed,
        input: action.buttonKeyInput,
        sessionId: action.payload?[MediaKeys.payloadSessionId],
      );

  Stream<MediaCommand>? _commands;

  /// The commands of every session whose `commandTarget` includes the stream,
  /// while the app runs.
  Stream<MediaCommand> get commands => _commands ??=
      (bridge?.commandEvents ?? _events.receiveBroadcastStream()).map((event) {
        final map = (event as Map).cast<String, dynamic>();
        return MediaCommand.parse(
          key: '${MediaKeys.commandPrefix}${map[MediaKeys.control]}',
          input: map[MediaKeys.position]?.toString(),
          sessionId: map[MediaKeys.sessionId] as String?,
        );
      })
      .where((command) => command != null)
      .cast<MediaCommand>();

  /// Keeps the system's position of [sessionId] in step with [positions]
  /// (for example, the player's own position stream), instead of sending the
  /// position in the model. Replaces an earlier binding of the session.
  void bindPosition(String sessionId, Stream<Duration> positions) {
    unbindPosition(sessionId);
    DateTime? sentAt;
    Duration? sent;
    _bindings[sessionId] = positions.listen((position) {
      final time = now();
      final elapsed = sentAt == null ? null : time.difference(sentAt!);
      final expected = sent == null || elapsed == null ? null : sent! + elapsed;
      final jumped = expected == null ||
          (position - expected).abs() > positionUpdateInterval * 2;
      if (!jumped && elapsed! < positionUpdateInterval) return;
      sentAt = time;
      sent = position;
      _updatePosition(sessionId, position);
    });
  }

  /// Stops the binding made by [bindPosition].
  void unbindPosition(String sessionId) {
    _bindings.remove(sessionId)?.cancel();
  }

  Future<void> _updatePosition(String sessionId, Duration position) async {
    if (!isPlatformSupported) return;
    await _invoke(MediaKeys.methodUpdatePosition, {
      MediaKeys.sessionId: sessionId,
      MediaKeys.position: position.inMilliseconds,
    });
  }

  /// Releases the session and removes its controls everywhere.
  Future<void> stop(String sessionId) async {
    unbindPosition(sessionId);
    if (!isPlatformSupported) return;
    await _invoke(MediaKeys.methodStop, sessionId);
  }

  Future<Object?> _invoke(String method, [Object? arguments]) =>
      bridge?.invokeMethod(method, arguments) ?? _channel.invokeMethod(method, arguments);

  /// What the media controls can do here.
  Future<MediaCapabilities> capabilities() async {
    if (!isPlatformSupported) return MediaCapabilities.none;
    final result = await _invoke(MediaKeys.methodCapabilities);
    if (result is! Map) return MediaCapabilities.none;
    final map = result.cast<String, dynamic>();
    return MediaCapabilities(
      seekBar: map['seekBar'] == true,
      artwork: map['artwork'] == true,
      customButtons: map['customButtons'] == true,
      lockScreen: map['lockScreen'] == true,
    );
  }
}
