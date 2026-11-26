import 'package:awesome_notifications/awesome_notifications.dart';

import 'call_command.dart';
import 'call_keys.dart';

/// The words the package shows where the system has none of its own: the
/// notification of a platform without a call UI (macOS, Windows, Linux, Web,
/// iOS with `systemCallUI: false`), Android's text under the caller, and the
/// missed call notification. Android's CallStyle buttons and iOS CallKit use
/// the system's own, translated, words (Android's extra mute / hold buttons
/// use these).
class CallTexts {
  final String incoming;
  final String incomingVideo;
  final String outgoing;
  final String ongoing;
  final String missed;
  final String missedVideo;
  final String accept;
  final String decline;
  final String hangUp;
  final String held;
  final String mute;
  final String unmute;
  final String hold;
  final String resume;

  const CallTexts({
    this.incoming = 'Incoming call',
    this.incomingVideo = 'Incoming video call',
    this.outgoing = 'Calling…',
    this.ongoing = 'Ongoing call',
    this.missed = 'Missed call',
    this.missedVideo = 'Missed video call',
    this.accept = 'Accept',
    this.decline = 'Decline',
    this.hangUp = 'Hang up',
    this.held = 'On hold',
    this.mute = 'Mute',
    this.unmute = 'Unmute',
    this.hold = 'Hold',
    this.resume = 'Resume',
  });

  Map<String, dynamic> toMap() => {
        CallKeys.textIncoming: incoming,
        CallKeys.textIncomingVideo: incomingVideo,
        CallKeys.textOutgoing: outgoing,
        CallKeys.textOngoing: ongoing,
        CallKeys.textMissed: missed,
        CallKeys.textMissedVideo: missedVideo,
        CallKeys.textAccept: accept,
        CallKeys.textDecline: decline,
        CallKeys.textHangUp: hangUp,
        CallKeys.textHeld: held,
        CallKeys.textMute: mute,
        CallKeys.textUnmute: unmute,
        CallKeys.textHold: hold,
        CallKeys.textResume: resume,
      };
}

/// A call, attached to a notification through `createNotification`'s
/// `extensions`: the system shows its own call UI for it (Android CallStyle
/// and full-screen intent, iOS CallKit) or the strongest notification it has
/// (macOS, Windows, Linux, Web). Send it again (same notification id and
/// [callId]) on every change of the call: answered, on hold, over.
///
/// ```dart
/// await AwesomeNotifications().createNotification(
///   content: NotificationContent(id: 300, channelKey: 'calls'),
///   extensions: [
///     NotificationCall(
///       callId: 'c-2026-001',
///       caller: const NotificationPerson(key: 'u-2', name: 'Ana'),
///       handle: 'tel:+5511999999999',
///       state: CallState.incoming,
///     ),
///   ],
/// );
/// ```
///
/// The package doesn't carry the call's audio or video: the app does.
class NotificationCall implements NotificationExtension {
  /// One system call per id.
  final String callId;

  /// Who is calling (incoming) or being called (outgoing).
  final NotificationPerson caller;

  /// `tel:`, `mailto:` or an app's own id of the caller: the CallKit handle
  /// and the Telecom address. The caller's key when absent.
  final String? handle;

  /// A video call: the system's video call UI and icons.
  final bool video;

  /// A group call's name, shown instead of the caller's.
  final String? groupName;

  final CallState state;

  /// When the call was answered: the ongoing call's timer.
  final DateTime? startedAt;

  /// How long an incoming call rings before it is missed.
  final Duration ringTimeout;

  /// Show a missed call notification when the call is missed.
  final bool missedNotification;

  /// The controls the system offers.
  final Set<CallControl> controls;

  /// Where the commands are delivered.
  final CallCommandTarget commandTarget;

  /// iOS: the system's call UI (CallKit). False shows a time-sensitive
  /// notification instead, for App Store builds in China, where CallKit is
  /// not allowed. Ignored elsewhere.
  final bool systemCallUI;

  /// The words the package shows where the system has none.
  final CallTexts texts;

  const NotificationCall({
    required this.callId,
    required this.caller,
    required this.state,
    this.handle,
    this.video = false,
    this.groupName,
    this.startedAt,
    this.ringTimeout = const Duration(seconds: 60),
    this.missedNotification = true,
    this.controls = const {
      CallControl.accept,
      CallControl.decline,
      CallControl.hangUp,
      CallControl.mute,
      CallControl.hold,
    },
    this.commandTarget = CallCommandTarget.actionEvent,
    this.systemCallUI = true,
    this.texts = const CallTexts(),
  });

  /// Throws [AwesomeNotificationsException] when the model is invalid. Whether
  /// it suits the notification (a schedule, for example) is checked natively.
  void validate() {
    void fail(String message) => throw AwesomeNotificationsException(message: message);
    if (callId.trim().isEmpty) fail('The call needs a non-empty callId');
    caller.validate('caller');
    if (handle != null && handle!.trim().isEmpty) {
      fail('The call handle can\'t be empty (leave it out to use the caller\'s key)');
    }
    if (groupName != null && groupName!.trim().isEmpty) {
      fail('The call groupName can\'t be empty');
    }
    if (ringTimeout <= Duration.zero) fail('The ring timeout must be positive');
    if (state == CallState.incoming &&
        !controls.contains(CallControl.accept) &&
        !controls.contains(CallControl.decline)) {
      fail('An incoming call needs the accept or the decline control');
    }
  }

  /// Validates, then serializes under the `call` key (called by the core's
  /// `createNotification`, before anything reaches the platform).
  @override
  Map<String, dynamic> toMap() {
    validate();
    return {
      CallKeys.call: {
        CallKeys.callId: callId,
        CallKeys.caller: caller.toMap(),
        if (handle != null) CallKeys.handle: handle,
        CallKeys.video: video,
        if (groupName != null) CallKeys.groupName: groupName,
        CallKeys.state: state.name,
        if (startedAt != null)
          CallKeys.startedAt: startedAt!.toUtc().millisecondsSinceEpoch,
        CallKeys.ringTimeout: ringTimeout.inMilliseconds,
        CallKeys.missedNotification: missedNotification,
        CallKeys.controls: [
          for (final c in CallControl.values)
            if (controls.contains(c)) c.name
        ],
        CallKeys.commandTarget: commandTarget.name,
        CallKeys.systemCallUI: systemCallUI,
        CallKeys.texts: texts.toMap(),
      },
    };
  }
}
