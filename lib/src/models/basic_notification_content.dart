import 'package:flutter/material.dart';

import 'package:awesome_notifications/src/enumerators/notification_privacy.dart';

import 'package:awesome_notifications/src/models/model.dart';

import 'package:awesome_notifications/src/utils/assert_utils.dart';
import 'package:awesome_notifications/src/utils/bitmap_utils.dart';
import 'package:awesome_notifications/src/utils/html_utils.dart';

class BaseNotificationContent extends Model {
  int id;
  String channelKey;
  String title;
  String body;
  String summary;
  bool showWhen;
  Map<String, dynamic> payload;
  String largeIcon;
  String bigPicture;
  bool autoCancel;
  Color color;
  Color backgroundColor;
  NotificationPrivacy privacy;

  BaseNotificationContent({
    this.id,
    this.channelKey,
    this.title,
    this.body,
    this.summary,
    this.showWhen,
    this.largeIcon,
    this.bigPicture,
    this.autoCancel,
    this.color,
    this.backgroundColor,
    this.payload,
  });

  @override
  fromMap(Map<String, dynamic> mapData) {
    this.id = AssertUtils.extractValue<int>(mapData, 'id');
    this.channelKey = AssertUtils.extractValue<String>(mapData, 'channelKey');
    this.title = AssertUtils.extractValue<String>(mapData, 'title');
    this.body = AssertUtils.extractValue<String>(mapData, 'body');
    this.summary = AssertUtils.extractValue<String>(mapData, 'summary');
    this.showWhen = AssertUtils.extractValue<bool>(mapData, 'showWhen');
    this.payload = AssertUtils.extractMap<String, dynamic>(mapData, 'payload');
    this.largeIcon = AssertUtils.extractValue<String>(mapData, 'largeIcon');
    this.bigPicture = AssertUtils.extractValue<String>(mapData, 'bigPicture');
    this.autoCancel = AssertUtils.extractValue<bool>(mapData, 'autoCancel');
    this.privacy = AssertUtils.extractEnum<NotificationPrivacy>(
        mapData, 'privacy', NotificationPrivacy.values);

    int colorValue = AssertUtils.extractValue<int>(mapData, 'color');
    this.color = colorValue == null ? null : Color(colorValue);

    int backgroundColorValue =
        AssertUtils.extractValue<int>(mapData, 'backgroundColor');
    this.backgroundColor =
        backgroundColorValue == null ? null : Color(backgroundColorValue);

    return this;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'channelKey': channelKey,
      'title': title,
      'body': body,
      'summary': summary,
      'showWhen': showWhen,
      'payload': payload,
      'largeIcon': largeIcon,
      'bigPicture': bigPicture,
      'autoCancel': autoCancel,
      'privacy': AssertUtils.toSimpleEnumString(privacy),
      'color': color?.value,
      'backgroundColor': backgroundColor?.value
    };
  }

  ImageProvider get bigPictureImage {
    return BitmapUtils().getFromMediaPath(bigPicture);
  }

  ImageProvider get largeIconImage {
    return BitmapUtils().getFromMediaPath(largeIcon);
  }

  String get titleWithoutHtml => HtmlUtils.removeAllHtmlTags(title);
  String get bodyWithoutHtml => HtmlUtils.removeAllHtmlTags(body);

  @override
  void validate() {
    assert(!AssertUtils.isNullOrEmptyOrInvalid(id, int));
    assert(!AssertUtils.isNullOrEmptyOrInvalid(channelKey, String));
  }
}
