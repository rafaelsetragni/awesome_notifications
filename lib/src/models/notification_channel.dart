import 'dart:typed_data';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/src/enumerators/default_ringtone_type.dart';
import 'package:awesome_notifications/src/enumerators/group_alert_behaviour.dart';
import 'package:awesome_notifications/src/enumerators/group_sort.dart';
import 'package:awesome_notifications/src/enumerators/media_source.dart';
import 'package:awesome_notifications/src/enumerators/notification_importance.dart';
import 'package:awesome_notifications/src/enumerators/notification_privacy.dart';
import 'package:awesome_notifications/src/exceptions/awesome_exception.dart';
import 'package:awesome_notifications/src/models/model.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';
import 'package:awesome_notifications/src/utils/bitmap_utils.dart';
import 'package:awesome_notifications/src/utils/string_utils.dart';
import 'package:flutter/material.dart';

/// A representation of default settings that applies to all notifications with same channel key
/// [soundSource] needs to be a native resource media type
class NotificationChannel extends Model {
  String? channelKey;
  String? channelName;
  String? channelDescription;
  bool? channelShowBadge;

  String? channelGroupKey;

  NotificationImportance? importance;

  bool? playSound;
  String? soundSource;
  DefaultRingtoneType? defaultRingtoneType;

  bool? enableVibration;
  Int64List? vibrationPattern;

  bool? enableLights;
  Color? ledColor;
  int? ledOnMs;
  int? ledOffMs;

  String? groupKey;
  GroupSort? groupSort;
  GroupAlertBehavior? groupAlertBehavior;

  NotificationPrivacy? defaultPrivacy;

  String? icon;
  Color? defaultColor;

  bool? locked;
  bool? onlyAlertOnce;
  bool? stayOnScreen = true;

  bool? criticalAlerts;

  NotificationChannel(
      {required String channelKey,
      required String channelName,
      required String channelDescription,
      this.channelGroupKey,
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
      this.defaultPrivacy,
      this.criticalAlerts})
      : super() {
    this.channelKey = channelKey;
    this.channelName = channelName;
    this.channelDescription = channelDescription;

    this.channelKey = AssertUtils.getValueOrDefault(
        NOTIFICATION_CHANNEL_KEY, this.channelKey, String);
    this.channelName = AssertUtils.getValueOrDefault(
        NOTIFICATION_CHANNEL_NAME, this.channelName, String);
    this.channelDescription = AssertUtils.getValueOrDefault(
        NOTIFICATION_CHANNEL_DESCRIPTION, this.channelDescription, String);
    this.channelShowBadge = AssertUtils.getValueOrDefault(
        NOTIFICATION_CHANNEL_SHOW_BADGE, this.channelShowBadge, bool);

    this.channelGroupKey = AssertUtils.getValueOrDefault(
        NOTIFICATION_CHANNEL_GROUP_KEY, this.channelGroupKey, String);

    this.importance = AssertUtils.getValueOrDefault(
        NOTIFICATION_IMPORTANCE, this.importance, NotificationImportance);
    this.playSound = AssertUtils.getValueOrDefault(
        NOTIFICATION_PLAY_SOUND, this.playSound, bool);
    this.criticalAlerts = AssertUtils.getValueOrDefault(
        NOTIFICATION_CHANNEL_CRITICAL_ALERTS, this.criticalAlerts, bool);
    this.soundSource = AssertUtils.getValueOrDefault(
        NOTIFICATION_SOUND_SOURCE, this.soundSource, String);
    this.enableVibration = AssertUtils.getValueOrDefault(
        NOTIFICATION_ENABLE_VIBRATION, this.enableVibration, bool);
    this.vibrationPattern = AssertUtils.getValueOrDefault(
        NOTIFICATION_VIBRATION_PATTERN, this.vibrationPattern, Int64List);
    this.enableLights = AssertUtils.getValueOrDefault(
        NOTIFICATION_ENABLE_LIGHTS, this.enableLights, bool);
    this.ledColor = AssertUtils.getValueOrDefault(
        NOTIFICATION_LED_COLOR, this.ledColor, Color);
    this.ledOnMs = AssertUtils.getValueOrDefault(
        NOTIFICATION_LED_ON_MS, this.ledOnMs, int);
    this.ledOffMs = AssertUtils.getValueOrDefault(
        NOTIFICATION_LED_OFF_MS, this.ledOffMs, int);
    this.groupKey = AssertUtils.getValueOrDefault(
        NOTIFICATION_GROUP_KEY, this.groupKey, String);
    this.groupSort = AssertUtils.getValueOrDefault(
        NOTIFICATION_GROUP_SORT, this.groupSort, GroupSort);
    this.groupAlertBehavior = AssertUtils.getValueOrDefault(
        NOTIFICATION_GROUP_ALERT_BEHAVIOR,
        this.groupAlertBehavior,
        GroupAlertBehavior);
    this.icon =
        AssertUtils.getValueOrDefault(NOTIFICATION_ICON, this.icon, String);
    this.defaultColor = AssertUtils.getValueOrDefault(
        NOTIFICATION_DEFAULT_COLOR, this.defaultColor, Color);
    this.locked =
        AssertUtils.getValueOrDefault(NOTIFICATION_LOCKED, this.locked, bool);
    this.onlyAlertOnce = AssertUtils.getValueOrDefault(
        NOTIFICATION_ONLY_ALERT_ONCE, this.onlyAlertOnce, bool);
    this.defaultPrivacy = AssertUtils.getValueOrDefault(
        NOTIFICATION_DEFAULT_PRIVACY, this.defaultPrivacy, NotificationPrivacy);
    this.defaultRingtoneType = AssertUtils.getValueOrDefault(
        NOTIFICATION_DEFAULT_RINGTONE_TYPE,
        this.defaultRingtoneType,
        DefaultRingtoneType);

    // For small icons, it's only allowed resource media types
    assert(StringUtils.isNullOrEmpty(icon) ||
        BitmapUtils().getMediaSource(icon!) == MediaSource.Resource);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      NOTIFICATION_ICON: icon,
      NOTIFICATION_CHANNEL_KEY: channelKey,
      NOTIFICATION_CHANNEL_NAME: channelName,
      NOTIFICATION_CHANNEL_DESCRIPTION: channelDescription,
      NOTIFICATION_CHANNEL_GROUP_KEY: channelGroupKey,
      NOTIFICATION_CHANNEL_SHOW_BADGE: channelShowBadge,
      NOTIFICATION_PLAY_SOUND: playSound,
      NOTIFICATION_SOUND_SOURCE: soundSource,
      NOTIFICATION_ENABLE_VIBRATION: enableVibration,
      NOTIFICATION_VIBRATION_PATTERN: vibrationPattern,
      NOTIFICATION_ENABLE_LIGHTS: enableLights,
      NOTIFICATION_DEFAULT_COLOR: defaultColor?.value,
      NOTIFICATION_LED_COLOR: ledColor?.value,
      NOTIFICATION_LED_ON_MS: ledOnMs,
      NOTIFICATION_LED_OFF_MS: ledOffMs,
      NOTIFICATION_GROUP_KEY: groupKey,
      NOTIFICATION_GROUP_SORT: AssertUtils.toSimpleEnumString(groupSort),
      NOTIFICATION_GROUP_ALERT_BEHAVIOR:
          AssertUtils.toSimpleEnumString(groupAlertBehavior),
      NOTIFICATION_DEFAULT_PRIVACY:
          AssertUtils.toSimpleEnumString(defaultPrivacy),
      NOTIFICATION_IMPORTANCE: AssertUtils.toSimpleEnumString(importance),
      NOTIFICATION_DEFAULT_RINGTONE_TYPE:
          AssertUtils.toSimpleEnumString(defaultRingtoneType),
      NOTIFICATION_LOCKED: locked,
      NOTIFICATION_CHANNEL_CRITICAL_ALERTS: criticalAlerts,
      NOTIFICATION_ONLY_ALERT_ONCE: onlyAlertOnce
    };
  }

  NotificationChannel fromMap(Map<String, dynamic> dataMap) {
    this.channelKey =
        AssertUtils.extractValue(NOTIFICATION_CHANNEL_KEY, dataMap, String);
    this.channelName =
        AssertUtils.extractValue(NOTIFICATION_CHANNEL_NAME, dataMap, String);
    this.channelDescription = AssertUtils.extractValue(
        NOTIFICATION_CHANNEL_DESCRIPTION, dataMap, String);
    this.channelShowBadge = AssertUtils.extractValue(
        NOTIFICATION_CHANNEL_SHOW_BADGE, dataMap, bool);

    this.channelGroupKey = AssertUtils.extractValue(
        NOTIFICATION_CHANNEL_GROUP_KEY, dataMap, String);

    this.playSound =
        AssertUtils.extractValue(NOTIFICATION_PLAY_SOUND, dataMap, bool);
    this.soundSource =
        AssertUtils.extractValue(NOTIFICATION_SOUND_SOURCE, dataMap, String);

    this.enableVibration =
        AssertUtils.extractValue(NOTIFICATION_ENABLE_VIBRATION, dataMap, bool);
    this.vibrationPattern = AssertUtils.extractValue(
        NOTIFICATION_VIBRATION_PATTERN, dataMap, Int64List);
    this.enableLights =
        AssertUtils.extractValue(NOTIFICATION_ENABLE_LIGHTS, dataMap, bool);

    this.importance = AssertUtils.extractEnum(
        NOTIFICATION_IMPORTANCE, dataMap, NotificationImportance.values);
    this.defaultPrivacy = AssertUtils.extractEnum(
        NOTIFICATION_DEFAULT_PRIVACY, dataMap, NotificationPrivacy.values);
    this.defaultRingtoneType = AssertUtils.extractEnum(
        NOTIFICATION_DEFAULT_RINGTONE_TYPE,
        dataMap,
        DefaultRingtoneType.values);

    this.groupKey =
        AssertUtils.extractValue(NOTIFICATION_GROUP_KEY, dataMap, String);
    this.groupSort = AssertUtils.extractEnum(
        NOTIFICATION_GROUP_SORT, dataMap, GroupSort.values);
    this.groupAlertBehavior = AssertUtils.extractEnum(
        NOTIFICATION_GROUP_ALERT_BEHAVIOR, dataMap, GroupAlertBehavior.values);

    this.icon = AssertUtils.extractValue(NOTIFICATION_ICON, dataMap, String);
    this.locked = AssertUtils.extractValue(NOTIFICATION_LOCKED, dataMap, bool);
    this.onlyAlertOnce =
        AssertUtils.extractValue(NOTIFICATION_ONLY_ALERT_ONCE, dataMap, bool);

    this.defaultColor =
        AssertUtils.extractValue(NOTIFICATION_DEFAULT_COLOR, dataMap, Color);
    this.ledColor =
        AssertUtils.extractValue(NOTIFICATION_LED_COLOR, dataMap, Color);

    this.ledOnMs =
        AssertUtils.extractValue(NOTIFICATION_LED_ON_MS, dataMap, int);
    this.ledOffMs =
        AssertUtils.extractValue(NOTIFICATION_LED_OFF_MS, dataMap, int);

    this.criticalAlerts = AssertUtils.extractValue(
        NOTIFICATION_CHANNEL_CRITICAL_ALERTS, dataMap, bool);

    return this;
  }

  @override
  void validate() {
    if (AssertUtils.isNullOrEmptyOrInvalid(channelKey, String))
      throw AwesomeNotificationsException(
          message: 'Property channelKey is requried');
    if (AssertUtils.isNullOrEmptyOrInvalid(channelName, String))
      throw AwesomeNotificationsException(
          message: 'Property channelName is requried');
    if (AssertUtils.isNullOrEmptyOrInvalid(channelDescription, String))
      throw AwesomeNotificationsException(
          message: 'Property channelDescription is requried');
  }
}
