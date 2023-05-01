import 'dart:developer' as developer;
import 'package:flutter/material.dart';

import '../definitions.dart';
import '../enumerators/action_type.dart';
import '../enumerators/notification_category.dart';
import '../enumerators/notification_life_cycle.dart';
import '../enumerators/notification_privacy.dart';
import '../enumerators/notification_source.dart';
import '../exceptions/awesome_exception.dart';
import '../utils/assert_utils.dart';
import '../utils/bitmap_utils.dart';
import '../utils/html_utils.dart';
import 'model.dart';

class BaseNotificationContent extends Model {
  int? _id;
  String? _channelKey;
  String? _groupKey;
  String? _title;
  String? _body;
  String? _summary;
  bool? _showWhen;
  Map<String, String?>? _payload;
  String? _icon;
  String? _largeIcon;
  String? _bigPicture;
  String? _customSound;
  bool? _autoDismissible;
  bool? _wakeUpScreen;
  bool? _fullScreenIntent;
  bool? _criticalAlert;
  Color? _color;
  Color? _backgroundColor;
  int? _timeoutAfter;
  NotificationPrivacy? _privacy;
  NotificationCategory? _category;

  DateTime? _displayedDate;
  DateTime? _createdDate;

  ActionType? _actionType;
  NotificationSource? _createdSource;

  NotificationLifeCycle? _createdLifeCycle;
  NotificationLifeCycle? _displayedLifeCycle;

  bool? _roundedLargeIcon;
  bool? _roundedBigPicture;

  int? get id => _id;
  String? get channelKey => _channelKey;
  String? get groupKey => _groupKey;
  String? get title => _title;
  String? get body => _body;
  String? get summary => _summary;
  bool? get showWhen => _showWhen;
  Map<String, String?>? get payload => _payload;
  String? get icon => _icon;
  String? get largeIcon => _largeIcon;
  String? get bigPicture => _bigPicture;
  String? get customSound => _customSound;
  bool? get autoDismissible => _autoDismissible;
  bool? get wakeUpScreen => _wakeUpScreen;
  bool? get fullScreenIntent => _fullScreenIntent;
  bool? get criticalAlert => _criticalAlert;
  Color? get color => _color;
  int? get timeoutAfter => _timeoutAfter;
  Color? get backgroundColor => _backgroundColor;
  NotificationPrivacy? get privacy => _privacy;
  NotificationCategory? get category => _category;
  ActionType? get actionType => _actionType;
  bool? get roundedLargeIcon => _roundedLargeIcon;
  bool? get roundedBigPicture => _roundedBigPicture;

  DateTime? get displayedDate {
    return _displayedDate;
  }

  @visibleForTesting
  @protected
  set privacy(newValue) {
    _privacy = newValue;
  }

  @visibleForTesting
  @protected
  set actionType(newValue) {
    _actionType = newValue;
  }

  @visibleForTesting
  @protected
  set displayedDate(newValue) {
    _displayedDate = newValue;
  }

  DateTime? get createdDate {
    return _createdDate;
  }

  @visibleForTesting
  @protected
  set createdDate(newValue) {
    _createdDate = newValue;
  }

  NotificationSource? get createdSource {
    return _createdSource;
  }

  @visibleForTesting
  @protected
  set createdSource(newValue) {
    _createdSource = newValue;
  }

  NotificationLifeCycle? get createdLifeCycle {
    return _createdLifeCycle;
  }

  @visibleForTesting
  @protected
  set createdLifeCycle(newValue) {
    _createdLifeCycle = newValue;
  }

  NotificationLifeCycle? get displayedLifeCycle {
    return _displayedLifeCycle;
  }

  @visibleForTesting
  @protected
  set displayedLifeCycle(newValue) {
    _displayedLifeCycle = newValue;
  }

  @Deprecated(
      'property name autoCancel is deprecated. Use autoDismissible instead.')
  bool? get autoCancel => _autoDismissible;

  @Deprecated(
      'property name autoDismissable is deprecated. Use autoDismissible instead.')
  bool? get autoDismissable => _autoDismissible;

  BaseNotificationContent(
      {int? id,
      String? channelKey,
      String? groupKey,
      ActionType actionType = ActionType.Default,
      String? title,
      String? body,
      String? summary,
      bool showWhen = true,
      String? icon,
      String? largeIcon,
      String? bigPicture,
      bool wakeUpScreen = false,
      bool fullScreenIntent = false,
      bool criticalAlert = false,
      NotificationCategory? category,
      bool autoDismissible = true,
      Color? color,
      Color? backgroundColor,
      int? timeoutAfter,
      Map<String, String?>? payload,
      String? customSound,
      bool roundedLargeIcon = false,
      bool roundedBigPicture = false,
      bool autoCancel = true})
      : _id = AwesomeAssertUtils.getValueOrDefault<int>(NOTIFICATION_ID, id),
        _channelKey = AwesomeAssertUtils.getValueOrDefault<String>(
            NOTIFICATION_CHANNEL_KEY, channelKey),
        _groupKey = AwesomeAssertUtils.getValueOrDefault<String>(
            NOTIFICATION_GROUP_KEY, groupKey),
        _actionType = AwesomeAssertUtils.getValueOrDefault<ActionType>(
            NOTIFICATION_ACTION_TYPE, actionType),
        _title = AwesomeAssertUtils.getValueOrDefault<String>(
            NOTIFICATION_TITLE, title),
        _body = AwesomeAssertUtils.getValueOrDefault<String>(
            NOTIFICATION_BODY, body),
        _summary = AwesomeAssertUtils.getValueOrDefault<String>(
            NOTIFICATION_SUMMARY, summary),
        _showWhen = AwesomeAssertUtils.getValueOrDefault<bool>(
            NOTIFICATION_SHOW_WHEN, showWhen),
        _icon = AwesomeAssertUtils.getValueOrDefault<String>(
            NOTIFICATION_ICON, icon),
        _largeIcon = AwesomeAssertUtils.getValueOrDefault<String>(
            NOTIFICATION_LARGE_ICON, largeIcon),
        _bigPicture = AwesomeAssertUtils.getValueOrDefault<String>(
            NOTIFICATION_BIG_PICTURE, bigPicture),
        _wakeUpScreen = AwesomeAssertUtils.getValueOrDefault<bool>(
            NOTIFICATION_WAKE_UP_SCREEN, wakeUpScreen),
        _fullScreenIntent = AwesomeAssertUtils.getValueOrDefault<bool>(
            NOTIFICATION_FULL_SCREEN_INTENT, fullScreenIntent),
        _criticalAlert = AwesomeAssertUtils.getValueOrDefault<bool>(
            NOTIFICATION_CRITICAL_ALERT, criticalAlert),
        _category = AwesomeAssertUtils.getValueOrDefault<NotificationCategory>(
            NOTIFICATION_CATEGORY, category),
        _color = AwesomeAssertUtils.getValueOrDefault<Color>(
            NOTIFICATION_COLOR, color),
        _backgroundColor = AwesomeAssertUtils.getValueOrDefault<Color>(
            NOTIFICATION_BACKGROUND_COLOR, backgroundColor),
        _timeoutAfter = AwesomeAssertUtils.getValueOrDefault<int>(
            NOTIFICATION_TIMEOUT_AFTER,
            (timeoutAfter ?? 0) < 1 ? null : timeoutAfter),
        _payload = AwesomeAssertUtils.getValueOrDefault<Map<String, String?>>(
            NOTIFICATION_PAYLOAD, payload),
        _customSound = AwesomeAssertUtils.getValueOrDefault<String>(
            NOTIFICATION_CUSTOM_SOUND, customSound),
        _roundedLargeIcon = AwesomeAssertUtils.getValueOrDefault<bool>(
            NOTIFICATION_ROUNDED_LARGE_ICON, roundedLargeIcon),
        _roundedBigPicture = AwesomeAssertUtils.getValueOrDefault<bool>(
            NOTIFICATION_ROUNDED_BIG_PICTURE, roundedBigPicture),
        _autoDismissible = AwesomeAssertUtils.getValueOrDefault<bool>(
            NOTIFICATION_AUTO_DISMISSIBLE, autoDismissible && autoCancel);

  @override
  BaseNotificationContent? fromMap(Map<String, dynamic> mapData) {
    mapData = processRetroCompatibility(mapData);

    _id = AwesomeAssertUtils.extractValue<int>(NOTIFICATION_ID, mapData);
    _channelKey = AwesomeAssertUtils.extractValue<String>(
        NOTIFICATION_CHANNEL_KEY, mapData);
    _groupKey = AwesomeAssertUtils.extractValue<String>(
        NOTIFICATION_GROUP_KEY, mapData);
    _actionType = AwesomeAssertUtils.extractValue<ActionType>(
        NOTIFICATION_ACTION_TYPE, mapData);
    _title =
        AwesomeAssertUtils.extractValue<String>(NOTIFICATION_TITLE, mapData);
    _body = AwesomeAssertUtils.extractValue<String>(NOTIFICATION_BODY, mapData);
    _summary =
        AwesomeAssertUtils.extractValue<String>(NOTIFICATION_SUMMARY, mapData);
    _showWhen =
        AwesomeAssertUtils.extractValue<bool>(NOTIFICATION_SHOW_WHEN, mapData);
    _icon = AwesomeAssertUtils.extractValue<String>(NOTIFICATION_ICON, mapData);
    _largeIcon = AwesomeAssertUtils.extractValue<String>(
        NOTIFICATION_LARGE_ICON, mapData);
    _bigPicture = AwesomeAssertUtils.extractValue<String>(
        NOTIFICATION_BIG_PICTURE, mapData);
    _wakeUpScreen = AwesomeAssertUtils.extractValue<bool>(
        NOTIFICATION_WAKE_UP_SCREEN, mapData);
    _fullScreenIntent = AwesomeAssertUtils.extractValue<bool>(
        NOTIFICATION_FULL_SCREEN_INTENT, mapData);
    _criticalAlert = AwesomeAssertUtils.extractValue<bool>(
        NOTIFICATION_CRITICAL_ALERT, mapData);
    _category = AwesomeAssertUtils.extractEnum<NotificationCategory>(
        NOTIFICATION_CATEGORY, mapData, NotificationCategory.values);
    _color =
        AwesomeAssertUtils.extractValue<Color>(NOTIFICATION_COLOR, mapData);
    _backgroundColor = AwesomeAssertUtils.extractValue<Color>(
        NOTIFICATION_BACKGROUND_COLOR, mapData);
    _timeoutAfter = AwesomeAssertUtils.extractValue<int>(
        NOTIFICATION_TIMEOUT_AFTER, mapData);
    _payload = AwesomeAssertUtils.extractMap<String, String?>(
        NOTIFICATION_PAYLOAD, mapData);
    _customSound = AwesomeAssertUtils.extractValue<String>(
        NOTIFICATION_CUSTOM_SOUND, mapData);
    _roundedLargeIcon = AwesomeAssertUtils.extractValue<bool>(
        NOTIFICATION_ROUNDED_LARGE_ICON, mapData);
    _roundedBigPicture = AwesomeAssertUtils.extractValue<bool>(
        NOTIFICATION_ROUNDED_BIG_PICTURE, mapData);
    _autoDismissible = AwesomeAssertUtils.extractValue<bool>(
        NOTIFICATION_AUTO_DISMISSIBLE, mapData);

    _timeoutAfter = (_timeoutAfter ?? 0) < 1 ? null : _timeoutAfter;

    return this;
  }

  @visibleForTesting
  Map<String, dynamic> processRetroCompatibility(Map<String, dynamic> dataMap) {
    if (dataMap.containsKey('autoCancel')) {
      developer.log(
          'autoCancel is now deprecated. Please use autoDismissible instead.');
      dataMap[NOTIFICATION_AUTO_DISMISSIBLE] =
          AwesomeAssertUtils.extractValue<bool>('autoCancel', dataMap);
    }
    for (MapEntry<String, dynamic> entry in dataMap.entries) {
      if (entry.value == 'AppKilled') {
        developer
            .log('AppKilled is now deprecated. Please use Terminated instead.');
        dataMap[entry.key] = NotificationLifeCycle.Terminated.name;
      }
    }
    return dataMap;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      NOTIFICATION_ID: _id,
      NOTIFICATION_CHANNEL_KEY: _channelKey,
      NOTIFICATION_GROUP_KEY: _groupKey,
      NOTIFICATION_TITLE: _title,
      NOTIFICATION_BODY: _body,
      NOTIFICATION_SUMMARY: _summary,
      NOTIFICATION_SHOW_WHEN: _showWhen,
      NOTIFICATION_ICON: _icon,
      NOTIFICATION_PAYLOAD: _payload,
      NOTIFICATION_LARGE_ICON: _largeIcon,
      NOTIFICATION_BIG_PICTURE: _bigPicture,
      NOTIFICATION_CUSTOM_SOUND: _customSound,
      NOTIFICATION_AUTO_DISMISSIBLE: _autoDismissible,
      NOTIFICATION_PRIVACY: _privacy?.name,
      NOTIFICATION_CATEGORY: _category?.name,
      NOTIFICATION_ACTION_TYPE: _actionType?.name,
      NOTIFICATION_COLOR: _color?.value,
      NOTIFICATION_BACKGROUND_COLOR: _backgroundColor?.value,
      NOTIFICATION_WAKE_UP_SCREEN: _wakeUpScreen,
      NOTIFICATION_FULL_SCREEN_INTENT: _fullScreenIntent,
      NOTIFICATION_CRITICAL_ALERT: _criticalAlert,
      NOTIFICATION_TIMEOUT_AFTER: _timeoutAfter,
      NOTIFICATION_ROUNDED_LARGE_ICON: _roundedLargeIcon,
      NOTIFICATION_ROUNDED_BIG_PICTURE: _roundedBigPicture,
      NOTIFICATION_CREATED_SOURCE: createdSource?.name,
      NOTIFICATION_CREATED_LIFECYCLE: createdLifeCycle?.name,
      NOTIFICATION_DISPLAYED_LIFECYCLE: displayedLifeCycle?.name,
      NOTIFICATION_CREATED_DATE: createdDate,
      NOTIFICATION_DISPLAYED_DATE: displayedDate
    };
  }

  ImageProvider? get bigPictureImage {
    if (_bigPicture?.isEmpty ?? true) return null;
    return AwesomeBitmapUtils().getFromMediaPath(_bigPicture!);
  }

  ImageProvider? get largeIconImage {
    if (_largeIcon?.isEmpty ?? true) return null;
    return AwesomeBitmapUtils().getFromMediaPath(_largeIcon!);
  }

  String? get bigPicturePath {
    if (_bigPicture?.isEmpty ?? true) return null;
    return AwesomeBitmapUtils().cleanMediaPath(_bigPicture!);
  }

  String? get largeIconPath {
    if (_largeIcon?.isEmpty ?? true) return null;
    return AwesomeBitmapUtils().cleanMediaPath(_largeIcon!);
  }

  String? get titleWithoutHtml => AwesomeHtmlUtils.removeAllHtmlTags(_title);

  String? get bodyWithoutHtml => AwesomeHtmlUtils.removeAllHtmlTags(_body);

  @override
  void validate() {
    if (AwesomeAssertUtils.isNullOrEmptyOrInvalid(_id)) {
      throw const AwesomeNotificationsException(
          message: 'Property id is required');
    }
    if (AwesomeAssertUtils.isNullOrEmptyOrInvalid(_channelKey)) {
      throw const AwesomeNotificationsException(
          message: 'Channel Key is required');
    }
  }
}
