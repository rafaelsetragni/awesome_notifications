import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/src/enumerators/notification_layout.dart';
import 'package:awesome_notifications/src/enumerators/notification_life_cycle.dart';
import 'package:awesome_notifications/src/enumerators/notification_source.dart';
import 'package:awesome_notifications/src/models/basic_notification_content.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';
import 'package:flutter/material.dart';

/// Main content of notification
/// If notification has no [body] or [title], it will only be created, but not displayed to the user (background notification).
class NotificationContent extends BaseNotificationContent {
  bool? hideLargeIconOnExpand;
  int? progress;
  String? ticker;

  NotificationLifeCycle? displayedLifeCycle;

  NotificationSource? createdSource;
  NotificationLifeCycle? createdLifeCycle;

  NotificationLayout? notificationLayout;

  bool? displayOnForeground;
  bool? displayOnBackground;

  String? createdDate;
  String? displayedDate;

  bool? locked;

  NotificationContent(
      {required int id,
      required String channelKey,
      String? title,
      String? body,
      String? groupKey,
      String? summary,
      bool? showWhen,
      String? icon,
      String? largeIcon,
      String? bigPicture,
      String? customSound,
      bool? autoDismissable,
      Color? color,
      Color? backgroundColor,
      Map<String, String>? payload,
      this.notificationLayout,
      this.hideLargeIconOnExpand,
      this.locked,
      this.progress,
      this.ticker,
      this.createdSource,
      this.createdLifeCycle,
      this.displayedLifeCycle,
      this.createdDate,
      this.displayOnForeground,
      this.displayOnBackground,
      this.displayedDate})
      : super(
            id: id,
            channelKey: channelKey,
            groupKey: groupKey,
            title: title,
            body: body,
            summary: summary,
            showWhen: showWhen,
            payload: payload,
            icon: icon,
            largeIcon: largeIcon,
            bigPicture: bigPicture,
            customSound: customSound,
            autoDismissable: autoDismissable,
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

    this.displayedLifeCycle = AssertUtils.extractEnum(
        NOTIFICATION_DISPLAYED_LIFECYCLE,
        mapData,
        NotificationLifeCycle.values);

    this.createdSource = AssertUtils.extractEnum(
        NOTIFICATION_CREATED_SOURCE, mapData, NotificationSource.values);
    this.createdLifeCycle = AssertUtils.extractEnum(
        NOTIFICATION_CREATED_LIFECYCLE, mapData, NotificationLifeCycle.values);

    this.createdDate =
        AssertUtils.extractValue(NOTIFICATION_CREATED_DATE, mapData, String);

    this.displayOnForeground = AssertUtils.extractValue(
        NOTIFICATION_DISPLAY_ON_FOREGROUND, mapData, bool);
    this.displayOnBackground = AssertUtils.extractValue(
        NOTIFICATION_DISPLAY_ON_BACKGROUND, mapData, bool);

    this.displayedDate =
        AssertUtils.extractValue(NOTIFICATION_DISPLAYED_DATE, mapData, String);

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
        NOTIFICATION_CREATED_SOURCE:
            AssertUtils.toSimpleEnumString(createdSource),
        NOTIFICATION_CREATED_LIFECYCLE:
            AssertUtils.toSimpleEnumString(createdLifeCycle),
        NOTIFICATION_DISPLAYED_LIFECYCLE:
            AssertUtils.toSimpleEnumString(displayedLifeCycle),
        NOTIFICATION_DISPLAY_ON_FOREGROUND: displayOnForeground,
        NOTIFICATION_DISPLAY_ON_BACKGROUND: displayOnBackground,
        NOTIFICATION_CREATED_DATE: createdDate,
        NOTIFICATION_DISPLAYED_DATE: displayedDate,
      });
    return dataMap;
  }

  @override
  String toString() {
    return toMap().toString().replaceAll(',', ',\n');
  }
}
