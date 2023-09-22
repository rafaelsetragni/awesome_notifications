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
      {required this.channelKey,
      required this.channelName,
      required this.channelDescription,
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
    channelKey = AwesomeAssertUtils.getValueOrDefault<String>(
        NOTIFICATION_CHANNEL_KEY, channelKey);
    channelName = AwesomeAssertUtils.getValueOrDefault<String>(
        NOTIFICATION_CHANNEL_NAME, channelName);
    channelDescription = AwesomeAssertUtils.getValueOrDefault<String>(
        NOTIFICATION_CHANNEL_DESCRIPTION, channelDescription);
    channelShowBadge = AwesomeAssertUtils.getValueOrDefault<bool>(
        NOTIFICATION_CHANNEL_SHOW_BADGE, channelShowBadge);

    channelGroupKey = AwesomeAssertUtils.getValueOrDefault<String>(
        NOTIFICATION_CHANNEL_GROUP_KEY, channelGroupKey);

    importance = AwesomeAssertUtils.getValueOrDefault<NotificationImportance>(
        NOTIFICATION_IMPORTANCE, importance);
    playSound = AwesomeAssertUtils.getValueOrDefault<bool>(
        NOTIFICATION_PLAY_SOUND, playSound);
    criticalAlerts = AwesomeAssertUtils.getValueOrDefault<bool>(
        NOTIFICATION_CHANNEL_CRITICAL_ALERTS, criticalAlerts);
    soundSource = AwesomeAssertUtils.getValueOrDefault<String>(
        NOTIFICATION_SOUND_SOURCE, soundSource);
    enableVibration = AwesomeAssertUtils.getValueOrDefault<bool>(
        NOTIFICATION_ENABLE_VIBRATION, enableVibration);
    vibrationPattern = AwesomeAssertUtils.getValueOrDefault<Int64List>(
        NOTIFICATION_VIBRATION_PATTERN, vibrationPattern);
    enableLights = AwesomeAssertUtils.getValueOrDefault<bool>(
        NOTIFICATION_ENABLE_LIGHTS, enableLights);
    ledColor = AwesomeAssertUtils.getValueOrDefault<Color>(
        NOTIFICATION_LED_COLOR, ledColor);
    ledOnMs = AwesomeAssertUtils.getValueOrDefault<int>(
        NOTIFICATION_LED_ON_MS, ledOnMs);
    ledOffMs = AwesomeAssertUtils.getValueOrDefault<int>(
        NOTIFICATION_LED_OFF_MS, ledOffMs);
    groupKey = AwesomeAssertUtils.getValueOrDefault<String>(
        NOTIFICATION_GROUP_KEY, groupKey);
    groupSort = AwesomeAssertUtils.getValueOrDefault<GroupSort>(
        NOTIFICATION_GROUP_SORT, groupSort);
    groupAlertBehavior =
        AwesomeAssertUtils.getValueOrDefault<GroupAlertBehavior>(
            NOTIFICATION_GROUP_ALERT_BEHAVIOR, groupAlertBehavior);
    icon = AwesomeAssertUtils.getValueOrDefault(NOTIFICATION_ICON, icon);
    defaultColor = AwesomeAssertUtils.getValueOrDefault<Color>(
        NOTIFICATION_DEFAULT_COLOR, defaultColor);
    locked =
        AwesomeAssertUtils.getValueOrDefault<bool>(NOTIFICATION_LOCKED, locked);
    onlyAlertOnce = AwesomeAssertUtils.getValueOrDefault<bool>(
        NOTIFICATION_ONLY_ALERT_ONCE, onlyAlertOnce);
    defaultPrivacy = AwesomeAssertUtils.getValueOrDefault<NotificationPrivacy>(
        NOTIFICATION_DEFAULT_PRIVACY, defaultPrivacy);
    defaultRingtoneType =
        AwesomeAssertUtils.getValueOrDefault<DefaultRingtoneType>(
            NOTIFICATION_DEFAULT_RINGTONE_TYPE, defaultRingtoneType);

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
    channelKey = AwesomeAssertUtils.extractValue<String>(
        NOTIFICATION_CHANNEL_KEY, mapData);
    channelName = AwesomeAssertUtils.extractValue<String>(
        NOTIFICATION_CHANNEL_NAME, mapData);
    channelDescription = AwesomeAssertUtils.extractValue<String>(
        NOTIFICATION_CHANNEL_DESCRIPTION, mapData);
    channelShowBadge = AwesomeAssertUtils.extractValue<bool>(
        NOTIFICATION_CHANNEL_SHOW_BADGE, mapData);

    channelGroupKey = AwesomeAssertUtils.extractValue<String>(
        NOTIFICATION_CHANNEL_GROUP_KEY, mapData);

    playSound =
        AwesomeAssertUtils.extractValue<bool>(NOTIFICATION_PLAY_SOUND, mapData);
    soundSource = AwesomeAssertUtils.extractValue<String>(
        NOTIFICATION_SOUND_SOURCE, mapData);

    enableVibration = AwesomeAssertUtils.extractValue<bool>(
        NOTIFICATION_ENABLE_VIBRATION, mapData);
    vibrationPattern = AwesomeAssertUtils.extractValue<Int64List>(
        NOTIFICATION_VIBRATION_PATTERN, mapData);
    enableLights = AwesomeAssertUtils.extractValue<bool>(
        NOTIFICATION_ENABLE_LIGHTS, mapData);

    importance = AwesomeAssertUtils.extractEnum<NotificationImportance>(
        NOTIFICATION_IMPORTANCE, mapData, NotificationImportance.values);
    defaultPrivacy = AwesomeAssertUtils.extractEnum<NotificationPrivacy>(
        NOTIFICATION_DEFAULT_PRIVACY, mapData, NotificationPrivacy.values);
    defaultRingtoneType = AwesomeAssertUtils.extractEnum<DefaultRingtoneType>(
        NOTIFICATION_DEFAULT_RINGTONE_TYPE,
        mapData,
        DefaultRingtoneType.values);

    groupKey = AwesomeAssertUtils.extractValue<String>(
        NOTIFICATION_GROUP_KEY, mapData);
    groupSort = AwesomeAssertUtils.extractEnum<GroupSort>(
        NOTIFICATION_GROUP_SORT, mapData, GroupSort.values);
    groupAlertBehavior = AwesomeAssertUtils.extractEnum<GroupAlertBehavior>(
        NOTIFICATION_GROUP_ALERT_BEHAVIOR, mapData, GroupAlertBehavior.values);

    icon = AwesomeAssertUtils.extractValue<String>(NOTIFICATION_ICON, mapData);
    locked =
        AwesomeAssertUtils.extractValue<bool>(NOTIFICATION_LOCKED, mapData);
    onlyAlertOnce = AwesomeAssertUtils.extractValue<bool>(
        NOTIFICATION_ONLY_ALERT_ONCE, mapData);

    defaultColor = AwesomeAssertUtils.extractValue<Color>(
        NOTIFICATION_DEFAULT_COLOR, mapData);
    ledColor =
        AwesomeAssertUtils.extractValue<Color>(NOTIFICATION_LED_COLOR, mapData);

    ledOnMs =
        AwesomeAssertUtils.extractValue<int>(NOTIFICATION_LED_ON_MS, mapData);
    ledOffMs =
        AwesomeAssertUtils.extractValue<int>(NOTIFICATION_LED_OFF_MS, mapData);

    criticalAlerts = AwesomeAssertUtils.extractValue<bool>(
        NOTIFICATION_CHANNEL_CRITICAL_ALERTS, mapData);

    return this;
  }

  @override
  void validate() {
    if (AwesomeAssertUtils.isNullOrEmptyOrInvalid(channelKey)) {
      throw const AwesomeNotificationsException(
          message: 'Property channelKey is required');
    }
    if (AwesomeAssertUtils.isNullOrEmptyOrInvalid(channelName)) {
      throw const AwesomeNotificationsException(
          message: 'Property channelName is required');
    }
    if (AwesomeAssertUtils.isNullOrEmptyOrInvalid(channelDescription)) {
      throw const AwesomeNotificationsException(
          message: 'Property channelDescription is required');
    }
  }
}
