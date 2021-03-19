import 'dart:typed_data';

import 'package:awesome_notifications/src/enumerators/default_ringtone_type.dart';
import 'package:awesome_notifications/src/enumerators/group_alert_behaviour.dart';
import 'package:awesome_notifications/src/enumerators/group_sort.dart';
import 'package:awesome_notifications/src/enumerators/media_source.dart';
import 'package:awesome_notifications/src/enumerators/notification_importance.dart';
import 'package:awesome_notifications/src/enumerators/notification_privacy.dart';
import 'package:awesome_notifications/src/models/model.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';
import 'package:awesome_notifications/src/utils/bitmap_utils.dart';
import 'package:awesome_notifications/src/utils/string_utils.dart';
import 'package:flutter/material.dart';

/// A representation of default settings that applies to all notifications with same channel key
/// [soundSource] needs to be a native resource media type
class NotificationChannel extends Model {
  String channelKey;
  String channelName;
  String channelDescription;
  bool channelShowBadge;

  NotificationImportance importance;

  bool playSound;
  String soundSource;
  DefaultRingtoneType defaultRingtoneType;

  bool enableVibration;
  Int64List vibrationPattern;

  bool enableLights;
  Color ledColor;
  int ledOnMs;
  int ledOffMs;

  String groupKey;
  GroupSort groupSort;
  GroupAlertBehavior groupAlertBehavior;

  NotificationPrivacy defaultPrivacy;

  String icon;
  Color defaultColor;

  bool locked;
  bool onlyAlertOnce;

  NotificationChannel(
      {Key key,
      this.channelKey,
      this.channelName,
      this.channelDescription,
      this.channelShowBadge,
      this.importance,
      this.playSound,
      this.soundSource,
      this.defaultRingtoneType,
      this.enableVibration,
      this.vibrationPattern,
      this.enableLights,
      this.ledColor,
      this.ledOnMs,
      this.ledOffMs,
      this.groupKey,
      this.groupSort,
      this.groupAlertBehavior,
      this.icon,
      this.defaultColor,
      this.locked,
      this.onlyAlertOnce,
      this.defaultPrivacy})
      : super() {
    this.channelKey =
        AssertUtils.getValueOrDefault('channelKey', this.channelKey, String);
    this.channelName =
        AssertUtils.getValueOrDefault('channelName', this.channelName, String);
    this.channelDescription = AssertUtils.getValueOrDefault(
        'channelDescription', this.channelDescription, String);
    this.channelShowBadge = AssertUtils.getValueOrDefault(
        'channelShowBadge', this.channelShowBadge, bool);
    this.importance = AssertUtils.getValueOrDefault(
        'importance', this.importance, NotificationImportance);
    this.playSound =
        AssertUtils.getValueOrDefault('playSound', this.playSound, bool);
    this.soundSource =
        AssertUtils.getValueOrDefault('soundSource', this.soundSource, String);
    this.enableVibration = AssertUtils.getValueOrDefault(
        'enableVibration', this.enableVibration, bool);
    this.vibrationPattern = AssertUtils.getValueOrDefault(
        'vibrationPattern', this.vibrationPattern, Int64List);
    this.enableLights =
        AssertUtils.getValueOrDefault('enableLights', this.enableLights, bool);
    this.ledColor =
        AssertUtils.getValueOrDefault('ledColor', this.ledColor, Color);
    this.ledOnMs = AssertUtils.getValueOrDefault('ledOnMs', this.ledOnMs, int);
    this.ledOffMs =
        AssertUtils.getValueOrDefault('ledOffMs', this.ledOffMs, int);
    this.groupKey =
        AssertUtils.getValueOrDefault('groupKey', this.groupKey, String);
    this.groupSort =
        AssertUtils.getValueOrDefault('groupSort', this.groupSort, GroupSort);
    this.groupAlertBehavior = AssertUtils.getValueOrDefault(
        'groupAlertBehavior', this.groupAlertBehavior, GroupAlertBehavior);
    this.icon = AssertUtils.getValueOrDefault('icon', this.icon, String);
    this.defaultColor =
        AssertUtils.getValueOrDefault('defaultColor', this.defaultColor, Color);
    this.locked = AssertUtils.getValueOrDefault('locked', this.locked, bool);
    this.onlyAlertOnce = AssertUtils.getValueOrDefault(
        'onlyAlertOnce', this.onlyAlertOnce, bool);
    this.defaultPrivacy = AssertUtils.getValueOrDefault(
        'defaultPrivacy', this.defaultPrivacy, NotificationPrivacy);
    this.defaultRingtoneType = AssertUtils.getValueOrDefault(
        'defaultRingtoneType', this.defaultRingtoneType, DefaultRingtoneType);

    // For small icons, it's only allowed resource media types
    assert(StringUtils.isNullOrEmpty(icon) ||
        BitmapUtils().getMediaSource(icon) == MediaSource.Resource);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'icon': icon,
      'channelKey': channelKey,
      'channelName': channelName,
      'channelDescription': channelDescription,
      'channelShowBadge': channelShowBadge,
      'importance': AssertUtils.toSimpleEnumString(importance),
      'playSound': playSound,
      'soundSource': soundSource,
      'enableVibration': enableVibration,
      'vibrationPattern': vibrationPattern,
      'enableLights': enableLights,
      'defaultColor': defaultColor?.value,
      'ledColor': ledColor?.value,
      'ledOnMs': ledOnMs,
      'ledOffMs': ledOffMs,
      'groupKey': groupKey,
      'groupSort': AssertUtils.toSimpleEnumString(groupSort),
      'groupAlertBehavior': AssertUtils.toSimpleEnumString(groupAlertBehavior),
      'defaultPrivacy': AssertUtils.toSimpleEnumString(defaultPrivacy),
      'defaultRingtoneType':
          AssertUtils.toSimpleEnumString(defaultRingtoneType),
      'locked': locked,
      'onlyAlertOnce': onlyAlertOnce
    };
  }

  NotificationChannel fromMap(Map<String, dynamic> dataMap) {
    this.channelKey = AssertUtils.extractValue(dataMap, 'channelKey');
    this.channelName = AssertUtils.extractValue(dataMap, 'channelName');
    this.channelDescription =
        AssertUtils.extractValue(dataMap, 'channelDescription');
    this.channelShowBadge =
        AssertUtils.extractValue(dataMap, 'channelShowBadge');
    this.importance = AssertUtils.extractEnum(
        dataMap, 'importance', NotificationImportance.values);
    this.playSound = AssertUtils.extractValue(dataMap, 'playSound');
    this.soundSource = AssertUtils.extractValue(dataMap, 'soundPath');
    this.enableVibration = AssertUtils.extractValue(dataMap, 'enableVibration');
    this.vibrationPattern =
        AssertUtils.extractValue(dataMap, 'vibrationPattern');
    this.enableLights = AssertUtils.extractValue(dataMap, 'enableLights');
    this.groupKey = AssertUtils.extractValue(dataMap, 'groupKey');
    this.groupSort =
        AssertUtils.extractEnum(dataMap, 'groupSort', GroupSort.values);
    this.groupAlertBehavior = AssertUtils.extractEnum(
        dataMap, 'groupAlertBehavior', GroupAlertBehavior.values);
    this.defaultPrivacy = AssertUtils.extractEnum(
        dataMap, 'defaultPrivacy', NotificationPrivacy.values);
    this.defaultRingtoneType = AssertUtils.extractEnum(
        dataMap, 'defaultRingtoneType', DefaultRingtoneType.values);
    this.icon = AssertUtils.extractValue(dataMap, 'icon');
    this.locked = AssertUtils.extractValue(dataMap, 'locked');
    this.onlyAlertOnce = AssertUtils.extractValue(dataMap, 'onlyAlertOnce');

    int defaultColorValue = AssertUtils.extractValue(dataMap, 'defaultColor');
    this.defaultColor = defaultColor == null ? null : Color(defaultColorValue);

    int ledColorValue = AssertUtils.extractValue(dataMap, 'ledColor');
    this.ledColor = defaultColor == null ? null : Color(ledColorValue);

    this.ledOnMs = AssertUtils.extractValue(dataMap, 'ledOnMs');
    this.ledOffMs = AssertUtils.extractValue(dataMap, 'ledOffMs');

    return this;
  }

  @override
  void validate() {
    assert(!AssertUtils.isNullOrEmptyOrInvalid(channelKey, String));
    assert(!AssertUtils.isNullOrEmptyOrInvalid(channelName, String));
    assert(!AssertUtils.isNullOrEmptyOrInvalid(channelDescription, String));
  }
}
