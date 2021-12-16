import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/src/enumerators/notification_privacy.dart';
import 'package:awesome_notifications/src/exceptions/awesome_exception.dart';
import 'package:awesome_notifications/src/models/model.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';
import 'package:awesome_notifications/src/utils/bitmap_utils.dart';
import 'package:awesome_notifications/src/utils/html_utils.dart';
import 'package:flutter/material.dart';

import '../definitions.dart';

class BaseNotificationContent extends Model {
  int? id;
  String? channelKey;
  String? groupKey;
  String? title;
  String? body;
  String? summary;
  bool? showWhen;
  Map<String, String>? payload;
  String? icon;
  String? largeIcon;
  String? bigPicture;
  String? customSound;
  bool? autoDismissible;
  bool? wakeUpScreen;
  bool? fullScreenIntent;
  bool? criticalAlert;
  Color? color;
  Color? backgroundColor;
  NotificationPrivacy? privacy;
  NotificationCategory? category;

  String? displayedDate;
  String? createdDate;

  ActionType? actionType;
  NotificationSource? createdSource;

  NotificationLifeCycle? createdLifeCycle;
  NotificationLifeCycle? displayedLifeCycle;

  @Deprecated(
      'property name autoCancel is deprecated. Use autoDismissible instead.')
  bool? get autoCancel => autoDismissible;

  @Deprecated(
      'property name autoDismissable is deprecated. Use autoDismissible instead.')
  bool? get autoDismissable => autoDismissible;

  BaseNotificationContent(
      {required this.id,
      required this.channelKey,
      this.actionType,
      this.groupKey,
      this.title,
      this.body,
      this.summary,
      this.showWhen,
      this.icon,
      this.largeIcon,
      this.bigPicture,
      this.wakeUpScreen,
      this.fullScreenIntent,
      this.criticalAlert,
      this.category,
      this.autoDismissible,
      this.color,
      this.backgroundColor,
      this.payload,
      this.customSound,
      bool? autoCancel}) {
    this.autoDismissible =
        this.autoDismissible != null ? this.autoDismissible : autoCancel;
  }

  @override
  BaseNotificationContent? fromMap(Map<String, dynamic> mapData) {
    this.id = AssertUtils.extractValue(NOTIFICATION_ID, mapData, int);
    this.channelKey =
        AssertUtils.extractValue(NOTIFICATION_CHANNEL_KEY, mapData, String);
    this.groupKey =
        AssertUtils.extractValue(NOTIFICATION_GROUP_KEY, mapData, String);
    this.title = AssertUtils.extractValue(NOTIFICATION_TITLE, mapData, String);
    this.body = AssertUtils.extractValue(NOTIFICATION_BODY, mapData, String);
    this.summary =
        AssertUtils.extractValue(NOTIFICATION_SUMMARY, mapData, String);
    this.showWhen =
        AssertUtils.extractValue(NOTIFICATION_SHOW_WHEN, mapData, bool);
    this.icon = AssertUtils.extractValue(NOTIFICATION_ICON, mapData, String);
    this.largeIcon =
        AssertUtils.extractValue(NOTIFICATION_LARGE_ICON, mapData, String);
    this.bigPicture =
        AssertUtils.extractValue(NOTIFICATION_BIG_PICTURE, mapData, String);
    this.customSound =
        AssertUtils.extractValue(NOTIFICATION_CUSTOM_SOUND, mapData, String);
    this.wakeUpScreen =
        AssertUtils.extractValue(NOTIFICATION_WAKE_UP_SCREEN, mapData, bool);
    this.fullScreenIntent = AssertUtils.extractValue(
        NOTIFICATION_FULL_SCREEN_INTENT, mapData, bool);
    this.criticalAlert =
        AssertUtils.extractValue(NOTIFICATION_CRITICAL_ALERT, mapData, bool);
    this.autoDismissible =
        AssertUtils.extractValue(NOTIFICATION_AUTO_DISMISSIBLE, mapData, bool);

    this.actionType = AssertUtils.extractEnum<ActionType>(
        NOTIFICATION_ACTION_TYPE, mapData, ActionType.values);

    this.privacy = AssertUtils.extractEnum<NotificationPrivacy>(
        NOTIFICATION_PRIVACY, mapData, NotificationPrivacy.values);

    this.category = AssertUtils.extractEnum<NotificationCategory>(
        NOTIFICATION_CATEGORY, mapData, NotificationCategory.values);

    this.color = AssertUtils.extractValue(NOTIFICATION_COLOR, mapData, Color);
    this.backgroundColor =
        AssertUtils.extractValue(NOTIFICATION_BACKGROUND_COLOR, mapData, Color);

    this.payload =
        AssertUtils.extractMap<String, String>(mapData, NOTIFICATION_PAYLOAD);

    return this;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      NOTIFICATION_ID: id,
      NOTIFICATION_CHANNEL_KEY: channelKey,
      NOTIFICATION_GROUP_KEY: groupKey,
      NOTIFICATION_TITLE: title,
      NOTIFICATION_BODY: body,
      NOTIFICATION_SUMMARY: summary,
      NOTIFICATION_SHOW_WHEN: showWhen,
      NOTIFICATION_ICON: icon,
      NOTIFICATION_PAYLOAD: payload,
      NOTIFICATION_LARGE_ICON: largeIcon,
      NOTIFICATION_BIG_PICTURE: bigPicture,
      NOTIFICATION_CUSTOM_SOUND: customSound,
      NOTIFICATION_AUTO_DISMISSIBLE: autoDismissible,
      NOTIFICATION_PRIVACY: AssertUtils.toSimpleEnumString(privacy),
      NOTIFICATION_CATEGORY: AssertUtils.toSimpleEnumString(category),
      NOTIFICATION_ACTION_TYPE: AssertUtils.toSimpleEnumString(actionType),
      NOTIFICATION_COLOR: color?.value,
      NOTIFICATION_BACKGROUND_COLOR: backgroundColor?.value,
      NOTIFICATION_WAKE_UP_SCREEN: wakeUpScreen,
      NOTIFICATION_FULL_SCREEN_INTENT: fullScreenIntent,
      NOTIFICATION_CRITICAL_ALERT: criticalAlert,
    };
  }

  ImageProvider? get bigPictureImage {
    if (bigPicture?.isEmpty ?? true) return null;
    return BitmapUtils().getFromMediaPath(bigPicture!);
  }

  ImageProvider? get largeIconImage {
    if (largeIcon?.isEmpty ?? true) return null;
    return BitmapUtils().getFromMediaPath(largeIcon!);
  }

  String? get bigPicturePath {
    if (bigPicture?.isEmpty ?? true) return null;
    return BitmapUtils().cleanMediaPath(bigPicture!);
  }

  String? get largeIconPath {
    if (largeIcon?.isEmpty ?? true) return null;
    return BitmapUtils().cleanMediaPath(largeIcon!);
  }

  String? get titleWithoutHtml => HtmlUtils.removeAllHtmlTags(title)!;

  String? get bodyWithoutHtml => HtmlUtils.removeAllHtmlTags(body)!;

  @override
  void validate() {
    if (AssertUtils.isNullOrEmptyOrInvalid(id, int))
      throw AwesomeNotificationsException(message: 'Property id is requried');
    if (AssertUtils.isNullOrEmptyOrInvalid(channelKey, String))
      throw AwesomeNotificationsException(message: 'channelKey id is requried');
  }
}
