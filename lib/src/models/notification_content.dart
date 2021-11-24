import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/src/enumerators/notification_layout.dart';
import 'package:awesome_notifications/src/models/base_notification_content.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';
import 'package:flutter/material.dart';

/// Main content of notification
/// If notification has no [body] or [title], it will only be created, but not displayed to the user (background notification).
class NotificationContent extends BaseNotificationContent {
  bool? hideLargeIconOnExpand;
  int? progress;
  String? ticker;

  NotificationLayout? notificationLayout;

  bool? displayOnForeground;
  bool? displayOnBackground;

  bool? locked;

  NotificationContent(
      {required int id,
      required String channelKey,
      String? title,
      String? body,
      String? groupKey,
      String? summary,
      bool? showWhen,
      bool? wakeUpScreen,
      bool? fullScreenIntent,
      bool? criticalAlert,
      String? icon,
      String? largeIcon,
      String? bigPicture,
      String? customSound,
      bool? autoDismissible,
      Color? color,
      Color? backgroundColor,
      Map<String, String>? payload,
      NotificationCategory? category,
      this.notificationLayout,
      this.hideLargeIconOnExpand,
      this.locked,
      this.progress,
      this.ticker,
      this.displayOnForeground,
      this.displayOnBackground})
      : super(
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
            largeIcon: largeIcon,
            bigPicture: bigPicture,
            customSound: customSound,
            autoDismissible: autoDismissible,
            color: color,
            backgroundColor: backgroundColor);

  @override
  NotificationContent? fromMap(Map<String, dynamic> mapData) {
    super.fromMap(mapData);

    this.hideLargeIconOnExpand = AssertUtils.extractValue(
        NOTIFICATION_HIDE_LARGE_ICON_ON_EXPAND, mapData, bool);

    this.progress =
        AssertUtils.extractValue(NOTIFICATION_PROGRESS, mapData, int);
    this.ticker =
        AssertUtils.extractValue(NOTIFICATION_TICKER, mapData, String);
    this.locked = AssertUtils.extractValue(NOTIFICATION_LOCKED, mapData, bool);

    this.notificationLayout = AssertUtils.extractEnum(
        NOTIFICATION_LAYOUT, mapData, NotificationLayout.values);

    this.displayOnForeground = AssertUtils.extractValue(
        NOTIFICATION_DISPLAY_ON_FOREGROUND, mapData, bool);
    this.displayOnBackground = AssertUtils.extractValue(
        NOTIFICATION_DISPLAY_ON_BACKGROUND, mapData, bool);

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
        NOTIFICATION_HIDE_LARGE_ICON_ON_EXPAND: hideLargeIconOnExpand,
        NOTIFICATION_PROGRESS: progress,
        NOTIFICATION_TICKER: ticker,
        NOTIFICATION_LOCKED: locked,
        NOTIFICATION_LAYOUT: AssertUtils.toSimpleEnumString(notificationLayout),
        NOTIFICATION_DISPLAY_ON_FOREGROUND: displayOnForeground,
        NOTIFICATION_DISPLAY_ON_BACKGROUND: displayOnBackground,
      });
    return dataMap;
  }

  @override
  String toString() {
    return toMap().toString().replaceAll(',', ',\n');
  }
}
