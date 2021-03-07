import 'package:awesome_notifications/src/enumerators/notification_layout.dart';
import 'package:awesome_notifications/src/enumerators/notification_life_cycle.dart';
import 'package:awesome_notifications/src/enumerators/notification_source.dart';
import 'package:awesome_notifications/src/models/basic_notification_content.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';
import 'package:flutter/material.dart';

/// Main content of notification
/// If notification has no [body] or [title], it will only be created, but not displayed to the user (background notification).
class NotificationContent extends BaseNotificationContent {
  bool hideLargeIconOnExpand;
  int progress;
  String ticker;

  NotificationLifeCycle displayedLifeCycle;

  NotificationSource createdSource;
  NotificationLifeCycle createdLifeCycle;

  NotificationLayout notificationLayout;

  bool displayOnForeground;
  bool displayOnBackground;

  String createdDate;
  String displayedDate;

  bool locked;

  NotificationContent({
      int id,
      String channelKey,
      String title,
      String body,
      String summary,
      bool showWhen,
      String icon,
      String largeIcon,
      String bigPicture,
      String customSound,
      bool autoCancel,
      Color color,
      Color backgroundColor,
      Map<String, String> payload,
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
            title: title,
            body: body,
            summary: summary,
            showWhen: showWhen,
            payload: payload,
            icon: icon,
            largeIcon: largeIcon,
            bigPicture: bigPicture,
            customSound: customSound,
            autoCancel: autoCancel,
            color: color,
            backgroundColor: backgroundColor);

  @override
  fromMap(Map<String, dynamic> mapData) {
    super.fromMap(mapData);

    this.hideLargeIconOnExpand =
        AssertUtils.extractValue(mapData, 'hideLargeIconOnExpand');
    this.progress = AssertUtils.extractValue(mapData, 'progress');
    this.ticker = AssertUtils.extractValue(mapData, 'ticker');
    this.locked = AssertUtils.extractValue(mapData, 'locked');

    this.notificationLayout = AssertUtils.extractEnum(
        mapData, 'notificationLayout', NotificationLayout.values);

    this.displayedLifeCycle = AssertUtils.extractEnum(
        mapData, 'displayedLifeCycle', NotificationLifeCycle.values);

    this.createdSource = AssertUtils.extractEnum(
        mapData, 'createdSource', NotificationSource.values);
    this.createdLifeCycle = AssertUtils.extractEnum(
        mapData, 'createdLifeCycle', NotificationLifeCycle.values);

    this.createdDate = AssertUtils.extractValue<String>(mapData, 'createdDate');

    this.displayOnForeground = AssertUtils.extractValue<bool>(mapData, 'displayOnForeground');
    this.displayOnBackground = AssertUtils.extractValue<bool>(mapData, 'displayOnBackground');

    this.displayedDate =
        AssertUtils.extractValue<String>(mapData, 'displayedDate');

    return this;
  }

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> dataMap = super.toMap();

    List<dynamic> actionButtonList = [];

    dataMap = dataMap
      ..addAll({
        'hideLargeIconOnExpand': hideLargeIconOnExpand,
        'progress': progress,
        'ticker': ticker,
        'locked': locked,
        'actionButtons': actionButtonList.length > 0 ? actionButtonList : null,
        'notificationLayout':
            AssertUtils.toSimpleEnumString(notificationLayout),
        'createdSource': AssertUtils.toSimpleEnumString(createdSource),
        'createdLifeCycle': AssertUtils.toSimpleEnumString(createdLifeCycle),
        'displayedLifeCycle':
            AssertUtils.toSimpleEnumString(displayedLifeCycle),
        'displayOnForeground': displayOnForeground,
        'displayOnBackground': displayOnBackground,
        'createdDate': createdDate,
        'displayedDate': displayedDate,
      });
    return dataMap;
  }

  @override
  String toString() {
    return toMap().toString().replaceAll(',', ',\n');
  }
}
