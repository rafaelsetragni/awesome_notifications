import 'package:flutter/material.dart';

import '../definitions.dart';
import '../enumerators/action_type.dart';
import '../enumerators/notification_category.dart';
import '../enumerators/notification_layout.dart';
import '../utils/assert_utils.dart';
import 'base_notification_content.dart';

/// Main content of notification
/// If notification has no [body] or [title], it will only be created, but not displayed to the user (background notification).
class NotificationContent extends BaseNotificationContent {
  bool? _hideLargeIconOnExpand;
  int? _progress, _badge, _duration, _playState;
  String? _ticker;
  double? _playbackSpeed;

  NotificationLayout? _notificationLayout;

  bool? _displayOnForeground;
  bool? _displayOnBackground;

  bool? _locked;

  bool? get hideLargeIconOnExpand {
    return _hideLargeIconOnExpand;
  }

  int? get progress {
    return _progress;
  }

  int? get badge {
    return _badge;
  }

  String? get ticker {
    return _ticker;
  }

  NotificationLayout? get notificationLayout {
    return _notificationLayout;
  }

  bool? get displayOnForeground {
    return _displayOnForeground;
  }

  bool? get displayOnBackground {
    return _displayOnBackground;
  }

  bool? get locked {
    return _locked;
  }

  int? get duration {
    return _duration;
  }

  int? get playState {
    return _playState;
  }

  double? get playbackSpeed {
    return _playbackSpeed;
  }

  NotificationContent(
      {required int id,
      required String channelKey,
      String? title,
      String? body,
      String? groupKey,
      String? summary,
      String? icon,
      String? largeIcon,
      String? bigPicture,
      String? customSound,
      bool showWhen = true,
      bool wakeUpScreen = false,
      bool fullScreenIntent = false,
      bool criticalAlert = false,
      bool roundedLargeIcon = false,
      bool roundedBigPicture = false,
      bool autoDismissible = true,
      Color? color,
      Duration? timeoutAfter,
      Duration? chronometer,
      Color? backgroundColor,
      ActionType actionType = ActionType.Default,
      NotificationLayout notificationLayout = NotificationLayout.Default,
      Map<String, String?>? payload,
      NotificationCategory? category,
      bool hideLargeIconOnExpand = false,
      bool locked = false,
      int? progress,
      int? badge,
      String? ticker,
      bool displayOnForeground = true,
      bool displayOnBackground = true,
      int? duration,
      int? playState,
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
        _playbackSpeed = playbackSpeed,
        super(
            id: id,
            channelKey: channelKey,
            groupKey: groupKey,
            title: title,
            body: body,
            summary: summary,
            wakeUpScreen: wakeUpScreen,
            fullScreenIntent: fullScreenIntent,
            category: category,
            criticalAlert: criticalAlert,
            showWhen: showWhen,
            payload: payload,
            icon: icon,
            timeoutAfter: timeoutAfter,
            chronometer: chronometer,
            largeIcon: largeIcon,
            bigPicture: bigPicture,
            customSound: customSound,
            autoDismissible: autoDismissible,
            color: color,
            actionType: actionType,
            backgroundColor: backgroundColor,
            roundedBigPicture: roundedBigPicture,
            roundedLargeIcon: roundedLargeIcon);

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
    _duration =
        AwesomeAssertUtils.extractValue<int>(NOTIFICATION_DURATION, mapData);
    _playState =
        AwesomeAssertUtils.extractValue<int>(NOTIFICATION_PLAY_STATE, mapData);
    _playbackSpeed =
        AwesomeAssertUtils.extractValue<double>(NOTIFICATION_PLAYBACK_SPEED, mapData);

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
        NOTIFICATION_DURATION: _duration,
        NOTIFICATION_PLAY_STATE: _playState,
        NOTIFICATION_PLAYBACK_SPEED: _playbackSpeed,
      });
    return dataMap;
  }

  @override
  String toString() {
    return toMap().toString().replaceAll(',', ',\n');
  }
}
