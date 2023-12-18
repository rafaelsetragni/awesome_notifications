/*
  State of PlaybackStateCompat
  https://developer.android.com/reference/kotlin/android/support/v4/media/session/PlaybackStateCompat
 */

/// Notification Layout to be used as reference to build the notification.
/// If is not possible to build the desired layout, use the default one.
///
///   [none] This is the default playback state and indicates that no media has been added yet, or the performer has been reset and has no content to play.
///   [stopped] State indicating this item is currently stopped.
///   [paused] State indicating this item is currently paused.
///   [playing] State indicating this item is currently playing.
///   [forwarding] State indicating this item is currently fast forwarding.
///   [rewinding] State indicating this item is currently rewinding.
///   [buffering] State indicating this item is currently buffering and will begin playing when enough data has buffered.
///   [error] State indicating this item is currently in an error state. The error code should also be set when entering this state.
///   [connecting] On devices earlier than API 21, this will appear as STATE_BUFFERING
///   [previous] State indicating the player is currently skipping to the previous item.
///   [next] State indicating the player is currently skipping to the next item.
///   [skippingToQueueItem] State indicating the player is currently skipping to a specific item in the queue.
///   [unknown] Use this value for the position to indicate the position is not known.
enum NotificationPlayState {

  /// Use this value for the position to indicate the position is not known.
  unknown,
  /// This is the default playback state and indicates that no media has been added yet, or the performer has been reset and has no content to play.
  none,
  /// State indicating this item is currently stopped.
  stopped,
  /// State indicating this item is currently paused.
  paused,
  /// State indicating this item is currently playing.
  playing,
  /// State indicating this item is currently fast forwarding.
  forwarding,
  /// State indicating this item is currently rewinding.
  rewinding,
  /// State indicating this item is currently buffering and will begin playing when enough data has buffered.
  buffering,
  /// State indicating this item is currently in an error state. The error code should also be set when entering this state.
  error,
  /// State indicating the class doing playback is currently connecting to a route. Depending on the implementation you may return to the previous state when the connection finishes or enter STATE_NONE. If the connection failed STATE_ERROR should be used.
  /// On devices earlier than API 21, this will appear as STATE_BUFFERING
  connecting,
  /// State indicating the player is currently skipping to the previous item.
  previous,
  /// State indicating the player is currently skipping to the next item.
  next,
  /// State indicating the player is currently skipping to a specific item in the queue.
  skippingToQueueItem;

  int toMap() => index -1;
  static NotificationPlayState? fromMap(dynamic value) {
    if (value == null) return null;
    if (value is String){
      return NotificationPlayState
          .values
          .cast<NotificationPlayState?>()
          .toList()
          .firstWhere(
              (e) => e?.name == value,
          orElse: () => null
      );
    }
    if (value is int){
      return value >= NotificationPlayState.values.length || value < -1
          ? null
          : NotificationPlayState.values[value + 1];
    }
    return null;
  }
}