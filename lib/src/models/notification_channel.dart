import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../definitions.dart';
import '../enumerators/default_ringtone_type.dart';
import '../enumerators/group_alert_behaviour.dart';
import '../enumerators/group_sort.dart';
import '../enumerators/media_source.dart';
import '../enumerators/notification_importance.dart';
import '../enumerators/notification_privacy.dart';
import '../exceptions/awesome_exception.dart';
import '../utils/assert_utils.dart';
import '../utils/bitmap_utils.dart';
import '../utils/string_utils.dart';
import 'model.dart';

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
      {required String this.channelKey,
      required String this.channelName,
      required String this.channelDescription,
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
    channelKey = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_CHANNEL_KEY, channelKey, String);
    channelName = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_CHANNEL_NAME, channelName, String);
    channelDescription = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_CHANNEL_DESCRIPTION, channelDescription, String);
    channelShowBadge = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_CHANNEL_SHOW_BADGE, channelShowBadge, bool);

    channelGroupKey = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_CHANNEL_GROUP_KEY, channelGroupKey, String);

    importance = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_IMPORTANCE, importance, NotificationImportance);
    playSound = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_PLAY_SOUND, playSound, bool);
    criticalAlerts = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_CHANNEL_CRITICAL_ALERTS, criticalAlerts, bool);
    soundSource = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_SOUND_SOURCE, soundSource, String);
    enableVibration = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_ENABLE_VIBRATION, enableVibration, bool);
    vibrationPattern = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_VIBRATION_PATTERN, vibrationPattern, Int64List);
    enableLights = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_ENABLE_LIGHTS, enableLights, bool);
    ledColor = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_LED_COLOR, ledColor, Color);
    ledOnMs = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_LED_ON_MS, ledOnMs, int);
    ledOffMs = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_LED_OFF_MS, ledOffMs, int);
    groupKey = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_GROUP_KEY, groupKey, String);
    groupSort = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_GROUP_SORT, groupSort, GroupSort);
    groupAlertBehavior = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_GROUP_ALERT_BEHAVIOR,
        groupAlertBehavior,
        GroupAlertBehavior);
    icon =
        AwesomeAssertUtils.getValueOrDefault(NOTIFICATION_ICON, icon, String);
    defaultColor = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_DEFAULT_COLOR, defaultColor, Color);
    locked =
        AwesomeAssertUtils.getValueOrDefault(NOTIFICATION_LOCKED, locked, bool);
    onlyAlertOnce = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_ONLY_ALERT_ONCE, onlyAlertOnce, bool);
    defaultPrivacy = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_DEFAULT_PRIVACY, defaultPrivacy, NotificationPrivacy);
    defaultRingtoneType = AwesomeAssertUtils.getValueOrDefault(
        NOTIFICATION_DEFAULT_RINGTONE_TYPE,
        defaultRingtoneType,
        DefaultRingtoneType);

    // For small icons, it's only allowed resource media types
    assert(AwesomeStringUtils.isNullOrEmpty(icon) ||
        AwesomeBitmapUtils().getMediaSource(icon!) == MediaSource.Resource);
  }

  @override
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
      NOTIFICATION_GROUP_SORT: groupSort?.name,
      NOTIFICATION_GROUP_ALERT_BEHAVIOR: groupAlertBehavior?.name,
      NOTIFICATION_DEFAULT_PRIVACY: defaultPrivacy?.name,
      NOTIFICATION_IMPORTANCE: importance?.name,
      NOTIFICATION_DEFAULT_RINGTONE_TYPE: defaultRingtoneType?.name,
      NOTIFICATION_LOCKED: locked,
      NOTIFICATION_CHANNEL_CRITICAL_ALERTS: criticalAlerts,
      NOTIFICATION_ONLY_ALERT_ONCE: onlyAlertOnce
    };
  }

  @override
  NotificationChannel fromMap(Map<String, dynamic> mapData) {
    channelKey = AwesomeAssertUtils.extractValue(
        NOTIFICATION_CHANNEL_KEY, mapData, String);
    channelName = AwesomeAssertUtils.extractValue(
        NOTIFICATION_CHANNEL_NAME, mapData, String);
    channelDescription = AwesomeAssertUtils.extractValue(
        NOTIFICATION_CHANNEL_DESCRIPTION, mapData, String);
    channelShowBadge = AwesomeAssertUtils.extractValue(
        NOTIFICATION_CHANNEL_SHOW_BADGE, mapData, bool);

    channelGroupKey = AwesomeAssertUtils.extractValue(
        NOTIFICATION_CHANNEL_GROUP_KEY, mapData, String);

    playSound =
        AwesomeAssertUtils.extractValue(NOTIFICATION_PLAY_SOUND, mapData, bool);
    soundSource = AwesomeAssertUtils.extractValue(
        NOTIFICATION_SOUND_SOURCE, mapData, String);

    enableVibration = AwesomeAssertUtils.extractValue(
        NOTIFICATION_ENABLE_VIBRATION, mapData, bool);
    vibrationPattern = AwesomeAssertUtils.extractValue(
        NOTIFICATION_VIBRATION_PATTERN, mapData, Int64List);
    enableLights = AwesomeAssertUtils.extractValue(
        NOTIFICATION_ENABLE_LIGHTS, mapData, bool);

    importance = AwesomeAssertUtils.extractEnum<NotificationImportance>(
        NOTIFICATION_IMPORTANCE, mapData, NotificationImportance.values);
    defaultPrivacy = AwesomeAssertUtils.extractEnum<NotificationPrivacy>(
        NOTIFICATION_DEFAULT_PRIVACY, mapData, NotificationPrivacy.values);
    defaultRingtoneType = AwesomeAssertUtils.extractEnum<DefaultRingtoneType>(
        NOTIFICATION_DEFAULT_RINGTONE_TYPE,
        mapData,
        DefaultRingtoneType.values);

    groupKey = AwesomeAssertUtils.extractValue(
        NOTIFICATION_GROUP_KEY, mapData, String);
    groupSort = AwesomeAssertUtils.extractEnum<GroupSort>(
        NOTIFICATION_GROUP_SORT, mapData, GroupSort.values);
    groupAlertBehavior = AwesomeAssertUtils.extractEnum<GroupAlertBehavior>(
        NOTIFICATION_GROUP_ALERT_BEHAVIOR, mapData, GroupAlertBehavior.values);

    icon = AwesomeAssertUtils.extractValue(NOTIFICATION_ICON, mapData, String);
    locked =
        AwesomeAssertUtils.extractValue(NOTIFICATION_LOCKED, mapData, bool);
    onlyAlertOnce = AwesomeAssertUtils.extractValue(
        NOTIFICATION_ONLY_ALERT_ONCE, mapData, bool);

    defaultColor = AwesomeAssertUtils.extractValue(
        NOTIFICATION_DEFAULT_COLOR, mapData, Color);
    ledColor =
        AwesomeAssertUtils.extractValue(NOTIFICATION_LED_COLOR, mapData, Color);

    ledOnMs =
        AwesomeAssertUtils.extractValue(NOTIFICATION_LED_ON_MS, mapData, int);
    ledOffMs =
        AwesomeAssertUtils.extractValue(NOTIFICATION_LED_OFF_MS, mapData, int);

    criticalAlerts = AwesomeAssertUtils.extractValue(
        NOTIFICATION_CHANNEL_CRITICAL_ALERTS, mapData, bool);

    return this;
  }

  @override
  void validate() {
    if (AwesomeAssertUtils.isNullOrEmptyOrInvalid(channelKey, String)) {
      throw const AwesomeNotificationsException(
          message: 'Property channelKey is requried');
    }
    if (AwesomeAssertUtils.isNullOrEmptyOrInvalid(channelName, String)) {
      throw const AwesomeNotificationsException(
          message: 'Property channelName is requried');
    }
    if (AwesomeAssertUtils.isNullOrEmptyOrInvalid(channelDescription, String)) {
      throw const AwesomeNotificationsException(
          message: 'Property channelDescription is requried');
    }
  }
}
