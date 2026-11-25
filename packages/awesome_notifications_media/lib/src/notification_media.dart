import 'package:awesome_notifications/awesome_notifications.dart';

import 'media_control.dart';
import 'media_keys.dart';

/// What is playing, attached to a `MediaPlayer` notification through
/// `createNotification`'s `extensions`. Send it again (same notification id)
/// on every change of the player: play, pause, seek, next track.
///
/// ```dart
/// await AwesomeNotifications().createNotification(
///   content: NotificationContent(
///     id: 100,
///     channelKey: 'media_player',
///     notificationLayout: NotificationLayout.MediaPlayer,
///   ),
///   extensions: [
///     NotificationMedia(
///       sessionId: 'main-player',
///       title: 'Champagne Supernova',
///       artist: 'Bright Sharp',
///       duration: const Duration(minutes: 4, seconds: 21),
///       position: const Duration(seconds: 37),
///       state: NotificationPlayState.playing,
///       controls: {MediaControl.skipPrevious, MediaControl.pause, MediaControl.skipNext},
///     ),
///   ],
/// );
/// ```
class NotificationMedia implements NotificationExtension {
  /// One system media session per id.
  final String sessionId;

  /// The track.
  final String title;
  final String? artist;
  final String? album;

  /// Cover art (asset://, file://, https:// or resource://).
  final String? artwork;

  /// Absent for a live stream (no progress bar).
  final Duration? duration;

  /// At the time of the call: the system advances it while playing.
  final Duration position;

  /// 1.0 while playing when absent.
  final double? playbackSpeed;

  final NotificationPlayState state;

  /// The standard controls the system draws.
  final Set<MediaControl> controls;

  /// How far `skipForward` / `skipBackward` jump.
  final Duration skipInterval;

  /// Where the commands are delivered.
  final MediaCommandTarget commandTarget;

  const NotificationMedia({
    required this.sessionId,
    required this.title,
    required this.state,
    this.artist,
    this.album,
    this.artwork,
    this.duration,
    this.position = Duration.zero,
    this.playbackSpeed,
    this.controls = const {MediaControl.play, MediaControl.pause},
    this.skipInterval = const Duration(seconds: 15),
    this.commandTarget = MediaCommandTarget.actionEvent,
  });

  /// Throws [AwesomeNotificationsException] when the model is invalid. Whether
  /// it suits the layout is checked natively.
  void validate() {
    void fail(String message) => throw AwesomeNotificationsException(message: message);
    if (sessionId.trim().isEmpty) fail('The media session needs a non-empty sessionId');
    if (title.trim().isEmpty) fail('The media needs a non-empty title');
    if (position.isNegative) fail('The media position can\'t be negative');
    if (duration != null && duration! <= Duration.zero) {
      fail('The media duration must be positive (leave it out for a live stream)');
    }
    if (duration != null && position > duration!) {
      fail('The media position is past its duration');
    }
    if (playbackSpeed != null && playbackSpeed! < 0) fail('The playback speed can\'t be negative');
    if (skipInterval <= Duration.zero) fail('The skip interval must be positive');
  }

  /// Validates, then serializes under the `media` key (called by the core's
  /// `createNotification`, before anything reaches the platform).
  @override
  Map<String, dynamic> toMap() {
    validate();
    return {
      MediaKeys.media: {
        MediaKeys.sessionId: sessionId,
        MediaKeys.title: title,
        if (artist != null) MediaKeys.artist: artist,
        if (album != null) MediaKeys.album: album,
        if (artwork != null) MediaKeys.artwork: artwork,
        if (duration != null) MediaKeys.duration: duration!.inMilliseconds,
        MediaKeys.position: position.inMilliseconds,
        MediaKeys.playbackSpeed:
            playbackSpeed ?? (state == NotificationPlayState.playing ? 1.0 : 0.0),
        MediaKeys.state: state.name,
        MediaKeys.controls: [for (final c in MediaControl.values) if (controls.contains(c)) c.name],
        MediaKeys.skipInterval: skipInterval.inMilliseconds,
        MediaKeys.commandTarget: commandTarget.name,
      },
    };
  }
}
