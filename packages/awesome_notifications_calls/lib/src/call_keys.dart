/// Map keys of the `call` block, the channel methods and the event channel,
/// shared with the native side.
abstract final class CallKeys {
  static const call = 'call';

  // NotificationCall
  static const callId = 'callId';
  static const caller = 'caller';
  static const handle = 'handle';
  static const video = 'video';
  static const groupName = 'groupName';
  static const state = 'state';

  /// Milliseconds since the epoch (UTC).
  static const startedAt = 'startedAt';

  /// Milliseconds.
  static const ringTimeout = 'ringTimeout';
  static const missedNotification = 'missedNotification';
  static const controls = 'controls';
  static const commandTarget = 'commandTarget';
  static const systemCallUI = 'systemCallUI';
  static const texts = 'texts';

  // CallTexts
  static const textIncoming = 'incoming';
  static const textIncomingVideo = 'incomingVideo';
  static const textOutgoing = 'outgoing';
  static const textOngoing = 'ongoing';
  static const textMissed = 'missed';
  static const textMissedVideo = 'missedVideo';
  static const textAccept = 'accept';
  static const textDecline = 'decline';
  static const textHangUp = 'hangUp';
  static const textHeld = 'held';
  static const textMute = 'mute';
  static const textUnmute = 'unmute';
  static const textHold = 'hold';
  static const textResume = 'resume';

  /// Added to the content payload so an action tells which call it came from.
  static const payloadCallId = 'callId';

  /// Prefix of the `buttonKeyPressed` of a call command (`awn.call.accept`,
  /// `awn.call.hangUp`…).
  static const commandPrefix = 'awn.call.';

  // Channel methods of AwesomeNotificationsCalls
  static const methodEnd = 'callEnd';
  static const methodActiveCalls = 'callActiveCalls';
  static const methodVoipToken = 'callVoipToken';
  static const methodCanUseFullScreenIntent = 'callCanUseFullScreenIntent';
  static const methodRequestFullScreenIntent = 'callRequestFullScreenIntent';
  static const methodCapabilities = 'callCapabilities';

  /// `callEnd` argument.
  static const reason = 'reason';

  /// Event channel of the live commands and the VoIP token.
  static const eventsChannel = 'awesome_notifications_calls/events';

  /// An event's kind: [kindCommand] or [kindVoipToken].
  static const kind = 'kind';
  static const kindCommand = 'command';
  static const kindVoipToken = 'voipToken';

  /// A command event's action name ([CallAction] name).
  static const action = 'action';
  static const token = 'token';
}
