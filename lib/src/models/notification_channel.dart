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

    this.channelKey = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_CHANNEL_KEY, this.channelKey, String);
    this.channelName = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_CHANNEL_NAME, this.channelName, String);
    this.channelDescription = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_CHANNEL_DESCRIPTION, this.channelDescription, String);
    this.channelShowBadge = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_CHANNEL_SHOW_BADGE, this.channelShowBadge, bool);

    this.channelGroupKey = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_CHANNEL_GROUP_KEY, this.channelGroupKey, String);

    this.importance = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_IMPORTANCE, this.importance, NotificationImportance);
    this.playSound = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_PLAY_SOUND, this.playSound, bool);
    this.criticalAlerts = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_CHANNEL_CRITICAL_ALERTS, this.criticalAlerts, bool);
    this.soundSource = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_SOUND_SOURCE, this.soundSource, String);
    this.enableVibration = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_ENABLE_VIBRATION, this.enableVibration, bool);
    this.vibrationPattern = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_VIBRATION_PATTERN, this.vibrationPattern, Int64List);
    this.enableLights = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_ENABLE_LIGHTS, this.enableLights, bool);
    this.ledColor = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_LED_COLOR, this.ledColor, Color);
    this.ledOnMs = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_LED_ON_MS, this.ledOnMs, int);
    this.ledOffMs = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_LED_OFF_MS, this.ledOffMs, int);
    this.groupKey = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_GROUP_KEY, this.groupKey, String);
    this.groupSort = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_GROUP_SORT, this.groupSort, GroupSort);
    this.groupAlertBehavior = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_GROUP_ALERT_BEHAVIOR,
        this.groupAlertBehavior,
        GroupAlertBehavior);
    this.icon = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_ICON, this.icon, String);
    this.defaultColor = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_DEFAULT_COLOR, this.defaultColor, Color);
    this.locked = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_LOCKED, this.locked, bool);
    this.onlyAlertOnce = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_ONLY_ALERT_ONCE, this.onlyAlertOnce, bool);
    this.defaultPrivacy = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_DEFAULT_PRIVACY, this.defaultPrivacy, NotificationPrivacy);
    this.defaultRingtoneType = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_DEFAULT_RINGTONE_TYPE,
        this.defaultRingtoneType,
        DefaultRingtoneType);

    // For small icons, it's only allowed resource media types
    assert(AwesomeStringUtils.isNullOrEmpty(icon) ||
        AwesomeBitmapUtils().getMediaSource(icon!) == MediaSource.Resource);
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
      NOTIFICATION_GROUP_SORT: AwesomeAssertUtils.toSimpleEnumString(groupSort),
      NOTIFICATION_GROUP_ALERT_BEHAVIOR:
          AwesomeAssertUtils.toSimpleEnumString(groupAlertBehavior),
      NOTIFICATION_DEFAULT_PRIVACY:
          AwesomeAssertUtils.toSimpleEnumString(defaultPrivacy),
      NOTIFICATION_IMPORTANCE:
          AwesomeAssertUtils.toSimpleEnumString(importance),
      NOTIFICATION_DEFAULT_RINGTONE_TYPE:
          AwesomeAssertUtils.toSimpleEnumString(defaultRingtoneType),
      NOTIFICATION_LOCKED: locked,
      NOTIFICATION_CHANNEL_CRITICAL_ALERTS: criticalAlerts,
      NOTIFICATION_ONLY_ALERT_ONCE: onlyAlertOnce
    };
  }

  NotificationChannel fromMap(Map<String, dynamic> dataMap) {
    this.channelKey = AwesomeAssertUtils.extractValue(
        NOTIFICATION_CHANNEL_KEY, dataMap, String);
    this.channelName = AwesomeAssertUtils.extractValue(
        NOTIFICATION_CHANNEL_NAME, dataMap, String);
    this.channelDescription = AwesomeAssertUtils.extractValue(
        NOTIFICATION_CHANNEL_DESCRIPTION, dataMap, String);
    this.channelShowBadge = AwesomeAssertUtils.extractValue(
        NOTIFICATION_CHANNEL_SHOW_BADGE, dataMap, bool);

    this.channelGroupKey = AwesomeAssertUtils.extractValue(
        NOTIFICATION_CHANNEL_GROUP_KEY, dataMap, String);

    this.playSound =
        AwesomeAssertUtils.extractValue(NOTIFICATION_PLAY_SOUND, dataMap, bool);
    this.soundSource = AwesomeAssertUtils.extractValue(
        NOTIFICATION_SOUND_SOURCE, dataMap, String);

    this.enableVibration = AwesomeAssertUtils.extractValue(
        NOTIFICATION_ENABLE_VIBRATION, dataMap, bool);
    this.vibrationPattern = AwesomeAssertUtils.extractValue(
        NOTIFICATION_VIBRATION_PATTERN, dataMap, Int64List);
    this.enableLights = AwesomeAssertUtils.extractValue(
        NOTIFICATION_ENABLE_LIGHTS, dataMap, bool);

    this.importance = AwesomeAssertUtils.extractEnum(
        NOTIFICATION_IMPORTANCE, dataMap, NotificationImportance.values);
    this.defaultPrivacy = AwesomeAssertUtils.extractEnum(
        NOTIFICATION_DEFAULT_PRIVACY, dataMap, NotificationPrivacy.values);
    this.defaultRingtoneType = AwesomeAssertUtils.extractEnum(
        NOTIFICATION_DEFAULT_RINGTONE_TYPE,
        dataMap,
        DefaultRingtoneType.values);

    this.groupKey = AwesomeAssertUtils.extractValue(
        NOTIFICATION_GROUP_KEY, dataMap, String);
    this.groupSort = AwesomeAssertUtils.extractEnum(
        NOTIFICATION_GROUP_SORT, dataMap, GroupSort.values);
    this.groupAlertBehavior = AwesomeAssertUtils.extractEnum(
        NOTIFICATION_GROUP_ALERT_BEHAVIOR, dataMap, GroupAlertBehavior.values);

    this.icon =
        AwesomeAssertUtils.extractValue(NOTIFICATION_ICON, dataMap, String);
    this.locked =
        AwesomeAssertUtils.extractValue(NOTIFICATION_LOCKED, dataMap, bool);
    this.onlyAlertOnce = AwesomeAssertUtils.extractValue(
        NOTIFICATION_ONLY_ALERT_ONCE, dataMap, bool);

    this.defaultColor = AwesomeAssertUtils.extractValue(
        NOTIFICATION_DEFAULT_COLOR, dataMap, Color);
    this.ledColor =
        AwesomeAssertUtils.extractValue(NOTIFICATION_LED_COLOR, dataMap, Color);

    this.ledOnMs =
        AwesomeAssertUtils.extractValue(NOTIFICATION_LED_ON_MS, dataMap, int);
    this.ledOffMs =
        AwesomeAssertUtils.extractValue(NOTIFICATION_LED_OFF_MS, dataMap, int);

    this.criticalAlerts = AwesomeAssertUtils.extractValue(
        NOTIFICATION_CHANNEL_CRITICAL_ALERTS, dataMap, bool);

    return this;
  }

  @override
  void validate() {
    if (AwesomeAssertUtils.isNullOrEmptyOrInvalid(channelKey, String))
      throw AwesomeNotificationsException(
          message: 'Property channelKey is requried');
    if (AwesomeAssertUtils.isNullOrEmptyOrInvalid(channelName, String))
      throw AwesomeNotificationsException(
          message: 'Property channelName is requried');
    if (AwesomeAssertUtils.isNullOrEmptyOrInvalid(channelDescription, String))
      throw AwesomeNotificationsException(
          message: 'Property channelDescription is requried');
  }
}
