import 'call_keys.dart';

/// The moment of a call the system shows.
enum CallState {
  /// Ringing: the system's incoming call UI, over the lock screen.
  incoming,

  /// A call the user started in the app, not answered yet.
  outgoing,

  /// In progress: the system's in-call indicator.
  ongoing,

  /// In progress, on hold.
  held,

  /// Over: the system call ends and its notification goes away.
  ended,

  /// Not answered: the system call ends and, unless turned off, a missed call
  /// notification is shown.
  missed,
}

/// A control the system offers for a call.
enum CallControl {
  accept,
  decline,
  hangUp,

  /// Mute and unmute.
  mute,

  /// Hold and resume.
  hold,
}

/// Where a call's commands are delivered.
enum CallCommandTarget {
  /// The core's action event (`onActionReceivedMethod`): also reaches an app
  /// that was killed. Read it with `AwesomeNotificationsCalls.commandOf`.
  actionEvent,

  /// `AwesomeNotificationsCalls().commands`, only while the app runs.
  stream,

  /// Both.
  both,
}

/// What happened to a call, from the user or the system.
enum CallAction {
  /// The user answered. The system call is already ongoing: connect the
  /// media, then send the call again as `ongoing` with `startedAt`.
  accept,

  /// The user refused to answer. The system call is already over.
  decline,

  /// The user ended the call. The system call is already over.
  hangUp,

  mute,
  unmute,
  hold,
  unhold,

  /// The ring timed out (`ringTimeout`): the call is over and missed.
  timeout,

  /// iOS (CallKit): the system activated the call's audio session. Start the
  /// call's audio only now.
  audioActivated,

  /// iOS (CallKit): the system deactivated the call's audio session.
  audioDeactivated;

  /// The `buttonKeyPressed` of this action's commands.
  String get key => '${CallKeys.commandPrefix}$name';
}

/// Why the app ends a call with `AwesomeNotificationsCalls.endCall`.
enum CallEndReason {
  /// The other side hung up.
  remoteEnded,

  /// The call was declined on another device of the user.
  declinedElsewhere,

  /// The call was answered on another device of the user.
  answeredElsewhere,

  /// The caller gave up before an answer: a missed call.
  unanswered,

  /// The call could not be connected.
  failed,
}

/// A call's action, from the system call UI or its notification.
class CallCommand {
  final CallAction action;

  /// The call it came from.
  final String? callId;

  const CallCommand({required this.action, this.callId});

  /// Reads a command from its key (null when it is not one).
  static CallCommand? parse({String? key, String? callId}) {
    if (key == null || !key.startsWith(CallKeys.commandPrefix)) return null;
    final name = key.substring(CallKeys.commandPrefix.length);
    final action = CallAction.values.where((a) => a.name == name).firstOrNull;
    if (action == null) return null;
    return CallCommand(action: action, callId: callId);
  }

  @override
  bool operator ==(Object other) =>
      other is CallCommand && other.action == action && other.callId == callId;

  @override
  int get hashCode => Object.hash(action, callId);

  @override
  String toString() => 'CallCommand(${action.name}, $callId)';
}
