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

/// Represents default settings applied to all notifications sharing the same channel key.
/// Note: The [soundSource] needs to be a native resource media type.
class NotificationChannel extends Model {
  /// Unique identifier for the notification channel.
  String? channelKey;

  /// Name of the notification channel.
  String? channelName;

  /// Description of the notification channel.
  String? channelDescription;

  /// Indicates whether to show a badge for notifications in this channel.
  bool? channelShowBadge;

  /// Key for the channel group this channel belongs to.
  String? channelGroupKey;

  /// The importance level for notifications in this channel.
  NotificationImportance? importance;

  /// Indicates whether to play a sound for notifications in this channel.
  bool? playSound;

  /// The sound resource to play for notifications in this channel.
  String? soundSource;

  /// Default ringtone type for notifications in this channel.
  DefaultRingtoneType? defaultRingtoneType;

  /// Indicates whether to enable vibration for notifications in this channel.
  bool? enableVibration;

  /// Vibration pattern for notifications in this channel.
  Int64List? vibrationPattern;

  /// Indicates whether to enable LED lights for notifications in this channel.
  bool? enableLights;

  /// The color of the LED light for notifications in this channel.
  Color? ledColor;

  /// Duration in milliseconds for which the LED light is on.
  int? ledOnMs;

  /// Duration in milliseconds for which the LED light is off.
  int? ledOffMs;

  /// Key for grouping notifications in this channel.
  String? groupKey;

  /// Sort order for grouped notifications.
  GroupSort? groupSort;

  /// Alert behavior for grouped notifications.
  GroupAlertBehavior? groupAlertBehavior;

  /// Default privacy level for notifications in this channel.
  NotificationPrivacy? defaultPrivacy;

  /// Icon for notifications in this channel.
  String? icon;

  /// Default color for notifications in this channel.
  Color? defaultColor;

  /// Indicates whether this channel is locked (cannot be modified or deleted by the user).
  bool? locked;

  /// Indicates whether to alert only once for notifications in this channel.
  bool? onlyAlertOnce;

  /// Indicates whether notifications in this channel are critical alerts.
  bool? criticalAlerts;

  /// Constructs a [NotificationChannel].
  ///
  /// [channelKey]: Unique identifier for the channel.
  /// [channelName]: Name of the channel.
  /// [channelDescription]: Description of the channel.
  /// [channelShowBadge]: Indicates whether to show a badge for notifications in this channel.
  /// [importance]: The importance level for notifications in this channel.
  /// [playSound]: Indicates whether to play a sound for notifications in this channel.
  /// [soundSource]: The sound resource to play for notifications in this channel.
  /// [defaultRingtoneType]: Default ringtone type for notifications in this channel.
  /// [enableVibration]: Indicates whether to enable vibration for notifications in this channel.
  /// [vibrationPattern]: Vibration pattern for notifications in this channel.
  /// [enableLights]: Indicates whether to enable LED lights for notifications in this channel.
  /// [ledColor]: The color of the LED light for notifications in this channel.
  /// [ledOnMs]: Duration in milliseconds for which the LED light is on.
  /// [ledOffMs]: Duration in milliseconds for which the LED light is off.
  /// [groupKey]: Key for grouping notifications in this channel.
  /// [groupSort]: Sort order for grouped notifications.
  /// [groupAlertBehavior]: Alert behavior for grouped notifications.
  /// [defaultPrivacy]: Default privacy level for notifications in this channel.
  /// [icon]: Icon for notifications in this channel.
  /// [defaultColor]: Default color for notifications in this channel.
  /// [locked]: Indicates whether this channel is locked (cannot be modified or deleted by the user).
  /// [onlyAlertOnce]: Indicates whether to alert only once for notifications in this channel.
  /// [criticalAlerts]: Indicates whether notifications in this channel are critical alerts.
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

  /// Converts the [NotificationChannel] instance to a map.
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

  /// Creates a [NotificationChannel] instance from a map of data.
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

  /// Validates the properties of the notification channel.
  ///
  /// Throws an [AwesomeNotificationsException] if the channelKey, channelName, or channelDescription is missing.
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
