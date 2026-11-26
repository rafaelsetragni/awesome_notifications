import 'media_keys.dart';

/// A standard control the system draws (with its own icon) for a media
/// session.
enum MediaControl {
  play,
  pause,
  stop,

  /// Next track.
  skipNext,

  /// Previous track.
  skipPrevious,

  /// Jumps forward by `skipInterval` (seconds, not tracks).
  skipForward,

  /// Jumps back by `skipInterval`.
  skipBackward,

  /// Moves to a position: makes the progress bar draggable.
  seekTo,

  fastForward,
  rewind;

  /// The `buttonKeyPressed` of this control's commands.
  String get key => '${MediaKeys.commandPrefix}$name';
}

/// Where a session's commands are delivered.
enum MediaCommandTarget {
  /// The core's action event (`onActionReceivedMethod`): also reaches an app
  /// that was killed (Android). Read it with
  /// `AwesomeNotificationsMedia.commandOf`.
  actionEvent,

  /// `AwesomeNotificationsMedia().commands`, only while the app runs.
  stream,

  /// Both.
  both,
}

/// A command the user gave from the system's media controls.
class MediaCommand {
  final MediaControl control;

  /// The session it came from.
  final String? sessionId;

  /// The target position of a `seekTo`.
  final Duration? position;

  const MediaCommand({required this.control, this.sessionId, this.position});

  /// Reads a command from its key and value (null when it is not one).
  static MediaCommand? parse({String? key, String? input, String? sessionId}) {
    if (key == null || !key.startsWith(MediaKeys.commandPrefix)) return null;
    final name = key.substring(MediaKeys.commandPrefix.length);
    final control = MediaControl.values.where((c) => c.name == name).firstOrNull;
    if (control == null) return null;
    final millis = input == null ? null : int.tryParse(input);
    return MediaCommand(
      control: control,
      sessionId: sessionId,
      position: millis == null ? null : Duration(milliseconds: millis),
    );
  }

  @override
  String toString() => 'MediaCommand(${control.name}, $sessionId, $position)';
}
