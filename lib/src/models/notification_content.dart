import '../definitions.dart';
import '../enumerators/notification_layout.dart';
import '../enumerators/notification_play_state.dart';
import '../utils/assert_utils.dart';
import 'base_notification_content.dart';

/// Represents the content of a notification with customizable options.
/// If notification has no [body] or [title], it will only be created, but not displayed to the user (background notification).
class NotificationContent extends BaseNotificationContent {
  bool? _hideLargeIconOnExpand;
  int? _progress, _badge;
  Duration? _duration;
  NotificationPlayState? _playState;
  String? _ticker;
  double? _playbackSpeed;

  NotificationLayout? _notificationLayout;

  bool? _displayOnForeground;
  bool? _displayOnBackground;

  bool? _locked;

  /// Returns whether to hide the large icon when the notification is expanded.
  bool? get hideLargeIconOnExpand {
    return _hideLargeIconOnExpand;
  }

  /// Returns the progress value of the notification, if set.
  int? get progress {
    return _progress;
  }

  /// Returns the badge number for the notification.
  int? get badge {
    return _badge;
  }

  /// Returns the ticker text of the notification.
  String? get ticker {
    return _ticker;
  }

  /// Returns the layout type of the notification.
  NotificationLayout? get notificationLayout {
    return _notificationLayout;
  }

  /// Indicates whether the notification is displayed when the app is in the foreground.
  bool? get displayOnForeground {
    return _displayOnForeground;
  }

  /// Indicates whether the notification is displayed when the app is in the background.
  bool? get displayOnBackground {
    return _displayOnBackground;
  }

  /// Indicates whether the notification is locked.
  bool? get locked {
    return _locked;
  }

  /// Returns the play media duration (media player).
  Duration? get duration {
    return _duration;
  }

  /// Returns the play state of the notification  (media player).
  NotificationPlayState? get playState {
    return _playState;
  }

  /// Returns the playback speed for notification (media player).
  double? get playbackSpeed {
    return _playbackSpeed;
  }

  /// Constructs a [NotificationContent] object with various customization options.
  NotificationContent(
      {required int super.id,
      required String super.channelKey,
      super.title,
      super.body,
      super.groupKey,
      super.summary,
      super.icon,
      super.largeIcon,
      super.bigPicture,
      super.customSound,
      super.showWhen,
      super.wakeUpScreen,
      super.fullScreenIntent,
      super.criticalAlert,
      super.roundedLargeIcon,
      super.roundedBigPicture,
      super.autoDismissible,
      super.color,
      super.timeoutAfter,
      super.chronometer,
      super.backgroundColor,
      super.actionType,
      NotificationLayout notificationLayout = NotificationLayout.Default,
      super.payload,
      super.category,
      bool hideLargeIconOnExpand = false,
      bool locked = false,
      int? progress,
      int? badge,
      String? ticker,
      bool displayOnForeground = true,
      bool displayOnBackground = true,
      Duration? duration,
      NotificationPlayState? playState,
      double? playbackSpeed})
      : _hideLargeIconOnExpand = hideLargeIconOnExpand,
        _progress = progress,
        _ticker = ticker,
        _badge = badge,
        _notificationLayout = notificationLayout,
        _displayOnForeground = displayOnForeground,
        _displayOnBackground = displayOnBackground,
        _locked = locked,
        _duration = duration,
        _playState = playState,
        _playbackSpeed = playbackSpeed;

  /// Creates a [NotificationContent] instance from a map of data.
  @override
  NotificationContent? fromMap(Map<String, dynamic> mapData) {
    super.fromMap(mapData);
    _hideLargeIconOnExpand = AwesomeAssertUtils.extractValue<bool>(
        NOTIFICATION_HIDE_LARGE_ICON_ON_EXPAND, mapData);

    _progress =
        AwesomeAssertUtils.extractValue<int>(NOTIFICATION_PROGRESS, mapData);
    _badge = AwesomeAssertUtils.extractValue<int>(NOTIFICATION_BADGE, mapData);
    _ticker =
        AwesomeAssertUtils.extractValue<String>(NOTIFICATION_TICKER, mapData);
    _locked =
        AwesomeAssertUtils.extractValue<bool>(NOTIFICATION_LOCKED, mapData);
    _duration = AwesomeAssertUtils.extractValue<Duration>(
        NOTIFICATION_DURATION, mapData);
    _playState =
        NotificationPlayState.fromMap(mapData[NOTIFICATION_PLAY_STATE]);

    _playbackSpeed = AwesomeAssertUtils.extractValue<double>(
        NOTIFICATION_PLAYBACK_SPEED, mapData);

    _notificationLayout = AwesomeAssertUtils.extractEnum<NotificationLayout>(
        NOTIFICATION_LAYOUT, mapData, NotificationLayout.values);

    _displayOnForeground = AwesomeAssertUtils.extractValue<bool>(
        NOTIFICATION_DISPLAY_ON_FOREGROUND, mapData);

    _displayOnBackground = AwesomeAssertUtils.extractValue<bool>(
        NOTIFICATION_DISPLAY_ON_BACKGROUND, mapData);

    try {
      validate();
    } catch (e) {
      return null;
    }

    return this;
  }

  /// Converts the [NotificationContent] instance to a map.
  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> dataMap = super.toMap();

    dataMap = dataMap
      ..addAll({
        NOTIFICATION_HIDE_LARGE_ICON_ON_EXPAND: _hideLargeIconOnExpand,
        NOTIFICATION_PROGRESS: _progress,
        NOTIFICATION_BADGE: _badge,
        NOTIFICATION_TICKER: _ticker,
        NOTIFICATION_LOCKED: _locked,
        NOTIFICATION_LAYOUT: _notificationLayout?.name,
        NOTIFICATION_DISPLAY_ON_FOREGROUND: _displayOnForeground,
        NOTIFICATION_DISPLAY_ON_BACKGROUND: _displayOnBackground,
        NOTIFICATION_DURATION: _duration?.inSeconds,
        NOTIFICATION_PLAY_STATE: _playState?.toMap(),
        NOTIFICATION_PLAYBACK_SPEED: _playbackSpeed,
      });
    return dataMap;
  }

  /// Returns a string representation of the [NotificationContent] instance.
  @override
  String toString() {
    return toMap().toString().replaceAll(',', ',\n');
  }
}
