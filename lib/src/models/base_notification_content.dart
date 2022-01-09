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

  bool? roundedLargeIcon;
  bool? roundedBigPicture;

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
      this.roundedLargeIcon,
      this.roundedBigPicture,
      bool? autoCancel}) {
    this.autoDismissible =
        this.autoDismissible != null ? this.autoDismissible : autoCancel;
  }

  @override
  BaseNotificationContent? fromMap(Map<String, dynamic> mapData) {
    this.id = AwesomeAssertUtils.extractValue(NOTIFICATION_ID, mapData, int);
    this.channelKey = AwesomeAssertUtils.extractValue(
        NOTIFICATION_CHANNEL_KEY, mapData, String);
    this.groupKey = AwesomeAssertUtils.extractValue(
        NOTIFICATION_GROUP_KEY, mapData, String);
    this.title =
        AwesomeAssertUtils.extractValue(NOTIFICATION_TITLE, mapData, String);
    this.body =
        AwesomeAssertUtils.extractValue(NOTIFICATION_BODY, mapData, String);
    this.summary =
        AwesomeAssertUtils.extractValue(NOTIFICATION_SUMMARY, mapData, String);
    this.showWhen =
        AwesomeAssertUtils.extractValue(NOTIFICATION_SHOW_WHEN, mapData, bool);
    this.icon =
        AwesomeAssertUtils.extractValue(NOTIFICATION_ICON, mapData, String);
    this.largeIcon = AwesomeAssertUtils.extractValue(
        NOTIFICATION_LARGE_ICON, mapData, String);
    this.bigPicture = AwesomeAssertUtils.extractValue(
        NOTIFICATION_BIG_PICTURE, mapData, String);
    this.customSound = AwesomeAssertUtils.extractValue(
        NOTIFICATION_CUSTOM_SOUND, mapData, String);
    this.wakeUpScreen = AwesomeAssertUtils.extractValue(
        NOTIFICATION_WAKE_UP_SCREEN, mapData, bool);
    this.fullScreenIntent = AwesomeAssertUtils.extractValue(
        NOTIFICATION_FULL_SCREEN_INTENT, mapData, bool);
    this.criticalAlert = AwesomeAssertUtils.extractValue(
        NOTIFICATION_CRITICAL_ALERT, mapData, bool);
    this.autoDismissible = AwesomeAssertUtils.extractValue(
        NOTIFICATION_AUTO_DISMISSIBLE, mapData, bool);

    this.privacy = AwesomeAssertUtils.extractEnum<NotificationPrivacy>(
        NOTIFICATION_PRIVACY, mapData, NotificationPrivacy.values);

    this.category = AwesomeAssertUtils.extractEnum<NotificationCategory>(
        NOTIFICATION_CATEGORY, mapData, NotificationCategory.values);

    this.color =
        AwesomeAssertUtils.extractValue(NOTIFICATION_COLOR, mapData, Color);
    this.backgroundColor = AwesomeAssertUtils.extractValue(
        NOTIFICATION_BACKGROUND_COLOR, mapData, Color);

    this.payload = AwesomeAssertUtils.extractMap<String, String>(
        mapData, NOTIFICATION_PAYLOAD);

    this.roundedLargeIcon = AwesomeAssertUtils.extractValue(
        NOTIFICATION_ROUNDED_LARGE_ICON, mapData, bool);
    this.roundedBigPicture = AwesomeAssertUtils.extractValue(
        NOTIFICATION_ROUNDED_BIG_PICTURE, mapData, bool);

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
      NOTIFICATION_PRIVACY: AwesomeAssertUtils.toSimpleEnumString(privacy),
      NOTIFICATION_CATEGORY: AwesomeAssertUtils.toSimpleEnumString(category),
      NOTIFICATION_COLOR: color?.value,
      NOTIFICATION_BACKGROUND_COLOR: backgroundColor?.value,
      NOTIFICATION_WAKE_UP_SCREEN: wakeUpScreen,
      NOTIFICATION_FULL_SCREEN_INTENT: fullScreenIntent,
      NOTIFICATION_CRITICAL_ALERT: criticalAlert,
      NOTIFICATION_ROUNDED_LARGE_ICON: roundedLargeIcon,
      NOTIFICATION_ROUNDED_BIG_PICTURE: roundedBigPicture
    };
  }

  ImageProvider? get bigPictureImage {
    if (bigPicture?.isEmpty ?? true) return null;
    return AwesomeBitmapUtils().getFromMediaPath(bigPicture!);
  }

  ImageProvider? get largeIconImage {
    if (largeIcon?.isEmpty ?? true) return null;
    return AwesomeBitmapUtils().getFromMediaPath(largeIcon!);
  }

  String? get bigPicturePath {
    if (bigPicture?.isEmpty ?? true) return null;
    return AwesomeBitmapUtils().cleanMediaPath(bigPicture!);
  }

  String? get largeIconPath {
    if (largeIcon?.isEmpty ?? true) return null;
    return AwesomeBitmapUtils().cleanMediaPath(largeIcon!);
  }

  String? get titleWithoutHtml => AwesomeHtmlUtils.removeAllHtmlTags(title)!;

  String? get bodyWithoutHtml => AwesomeHtmlUtils.removeAllHtmlTags(body)!;

  @override
  void validate() {
    if (AwesomeAssertUtils.isNullOrEmptyOrInvalid(id, int))
      throw AwesomeNotificationsException(message: 'Property id is requried');
    if (AwesomeAssertUtils.isNullOrEmptyOrInvalid(channelKey, String))
      throw AwesomeNotificationsException(message: 'channelKey id is requried');
  }
}
