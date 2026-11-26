/// Map keys of the `media` block and the channel names, shared with the
/// native side.
abstract final class MediaKeys {
  static const media = 'media';

  // NotificationMedia
  static const sessionId = 'sessionId';
  static const title = 'title';
  static const artist = 'artist';
  static const album = 'album';
  static const artwork = 'artwork';
  static const duration = 'duration';
  static const position = 'position';
  static const playbackSpeed = 'playbackSpeed';
  static const state = 'state';
  static const controls = 'controls';
  static const skipInterval = 'skipInterval';
  static const commandTarget = 'commandTarget';

  /// Added to the content payload so a command tells which session it came
  /// from.
  static const payloadSessionId = 'mediaSessionId';

  /// Prefix of the `buttonKeyPressed` of a media command
  /// (`awn.media.pause`, `awn.media.seekTo`…).
  static const commandPrefix = 'awn.media.';

  // Channel methods of AwesomeNotificationsMedia
  static const methodStop = 'mediaStop';
  static const methodUpdatePosition = 'mediaUpdatePosition';
  static const methodCapabilities = 'mediaCapabilities';

  /// Event channel of the live commands.
  static const commandsChannel = 'awesome_notifications_media/commands';
  static const control = 'control';
}
