import 'package:awesome_notifications/src/enumerators/notification_privacy.dart';
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
  bool? autoDismissable;
  Color? color;
  Color? backgroundColor;
  NotificationPrivacy? privacy;

  @Deprecated(
      'property name autoCancel is deprecated. Use autoDismissable instead.')
  bool? get autoCancel => autoDismissable;

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
      this.autoDismissable,
      this.color,
      this.backgroundColor,
      this.payload,
      this.customSound,
      bool? autoCancel}) {
    this.autoDismissable =
        this.autoDismissable != null ? this.autoDismissable : autoCancel;
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
    this.autoDismissable =
        AssertUtils.extractValue(NOTIFICATION_AUTO_DISMISSABLE, mapData, bool);

    this.privacy = AssertUtils.extractEnum<NotificationPrivacy>(
        NOTIFICATION_PRIVACY, mapData, NotificationPrivacy.values);

    int? colorValue =
        AssertUtils.extractValue(NOTIFICATION_COLOR, mapData, int);
    this.color = colorValue == null ? null : Color(colorValue);

    int? backgroundColorValue =
        AssertUtils.extractValue(NOTIFICATION_BACKGROUND_COLOR, mapData, int);
    this.backgroundColor =
        backgroundColorValue == null ? null : Color(backgroundColorValue);

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
      NOTIFICATION_AUTO_DISMISSABLE: autoDismissable,
      NOTIFICATION_PRIVACY: AssertUtils.toSimpleEnumString(privacy),
      NOTIFICATION_COLOR: color?.value,
      NOTIFICATION_BACKGROUND_COLOR: backgroundColor?.value
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
    assert(!AssertUtils.isNullOrEmptyOrInvalid(id, int));
    assert(!AssertUtils.isNullOrEmptyOrInvalid(channelKey, String));
  }
}
