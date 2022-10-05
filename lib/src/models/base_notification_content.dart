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
  Color? get backgroundColor => _backgroundColor;
  NotificationPrivacy? get privacy => _privacy;
  NotificationCategory? get category => _category;
  ActionType? get actionType => _actionType;
  bool? get roundedLargeIcon => _roundedLargeIcon;
  bool? get roundedBigPicture => _roundedBigPicture;

  DateTime? get displayedDate {
    return _displayedDate;
  }

  @protected
  set displayedDate(newValue) {
    _displayedDate = newValue;
  }

  DateTime? get createdDate {
    return _createdDate;
  }

  @protected
  set createdDate(newValue) {
    _createdDate = newValue;
  }

  NotificationSource? get createdSource {
    return _createdSource;
  }

  @protected
  set createdSource(newValue) {
    _createdSource = newValue;
  }

  NotificationLifeCycle? get createdLifeCycle {
    return _createdLifeCycle;
  }

  @protected
  set createdLifeCycle(newValue) {
    _createdLifeCycle = newValue;
  }

  NotificationLifeCycle? get displayedLifeCycle {
    return _displayedLifeCycle;
  }

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
      Map<String, String?>? payload,
      String? customSound,
      bool roundedLargeIcon = false,
      bool roundedBigPicture = false,
      bool autoCancel = true})
      : _id = id,
        _channelKey = channelKey,
        _groupKey = groupKey,
        _actionType = actionType,
        _title = title,
        _body = body,
        _summary = summary,
        _showWhen = showWhen,
        _icon = icon,
        _largeIcon = largeIcon,
        _bigPicture = bigPicture,
        _wakeUpScreen = wakeUpScreen,
        _fullScreenIntent = fullScreenIntent,
        _criticalAlert = criticalAlert,
        _category = category,
        _color = color,
        _backgroundColor = backgroundColor,
        _payload = payload,
        _customSound = customSound,
        _roundedLargeIcon = roundedLargeIcon,
        _roundedBigPicture = roundedBigPicture,
        _autoDismissible = autoDismissible && autoCancel;

  @override
  BaseNotificationContent? fromMap(Map<String, dynamic> mapData) {
    _processRetroCompatibility(mapData);

    _id = AwesomeAssertUtils.extractValue(NOTIFICATION_ID, mapData, int);
    _channelKey = AwesomeAssertUtils.extractValue(
        NOTIFICATION_CHANNEL_KEY, mapData, String);
    _groupKey = AwesomeAssertUtils.extractValue(
        NOTIFICATION_GROUP_KEY, mapData, String);

    _title =
        AwesomeAssertUtils.extractValue(NOTIFICATION_TITLE, mapData, String);
    _body = AwesomeAssertUtils.extractValue(NOTIFICATION_BODY, mapData, String);
    _summary =
        AwesomeAssertUtils.extractValue(NOTIFICATION_SUMMARY, mapData, String);
    _showWhen =
        AwesomeAssertUtils.extractValue(NOTIFICATION_SHOW_WHEN, mapData, bool);
    _icon = AwesomeAssertUtils.extractValue(NOTIFICATION_ICON, mapData, String);
    _largeIcon = AwesomeAssertUtils.extractValue(
        NOTIFICATION_LARGE_ICON, mapData, String);
    _bigPicture = AwesomeAssertUtils.extractValue(
        NOTIFICATION_BIG_PICTURE, mapData, String);
    _customSound = AwesomeAssertUtils.extractValue(
        NOTIFICATION_CUSTOM_SOUND, mapData, String);

    _wakeUpScreen = AwesomeAssertUtils.extractValue(
        NOTIFICATION_WAKE_UP_SCREEN, mapData, bool);
    _fullScreenIntent = AwesomeAssertUtils.extractValue(
        NOTIFICATION_FULL_SCREEN_INTENT, mapData, bool);
    _criticalAlert = AwesomeAssertUtils.extractValue(
        NOTIFICATION_CRITICAL_ALERT, mapData, bool);
    _autoDismissible = AwesomeAssertUtils.extractValue(
        NOTIFICATION_AUTO_DISMISSIBLE, mapData, bool);

    _roundedLargeIcon = AwesomeAssertUtils.extractValue(
        NOTIFICATION_ROUNDED_LARGE_ICON, mapData, bool);
    _roundedBigPicture = AwesomeAssertUtils.extractValue(
        NOTIFICATION_ROUNDED_BIG_PICTURE, mapData, bool);

    _actionType = AwesomeAssertUtils.extractEnum<ActionType>(
        NOTIFICATION_ACTION_TYPE, mapData, ActionType.values);
    _privacy = AwesomeAssertUtils.extractEnum<NotificationPrivacy>(
        NOTIFICATION_PRIVACY, mapData, NotificationPrivacy.values);
    _category = AwesomeAssertUtils.extractEnum<NotificationCategory>(
        NOTIFICATION_CATEGORY, mapData, NotificationCategory.values);

    _color =
        AwesomeAssertUtils.extractValue(NOTIFICATION_COLOR, mapData, Color);
    _backgroundColor = AwesomeAssertUtils.extractValue(
        NOTIFICATION_BACKGROUND_COLOR, mapData, Color);

    _payload = AwesomeAssertUtils.extractMap<String, String?>(
        mapData, NOTIFICATION_PAYLOAD);

    return this;
  }

  void _processRetroCompatibility(Map<String, dynamic> dataMap) {
    if (dataMap.containsKey("autoCancel")) {
      developer
          .log("autoCancel is deprecated. Please use autoDismissible instead.");
      _autoDismissible =
          AwesomeAssertUtils.extractValue("autoCancel", dataMap, bool);
    }
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

  String? get titleWithoutHtml => AwesomeHtmlUtils.removeAllHtmlTags(_title)!;

  String? get bodyWithoutHtml => AwesomeHtmlUtils.removeAllHtmlTags(_body)!;

  @override
  void validate() {
    if (AwesomeAssertUtils.isNullOrEmptyOrInvalid(_id, int)) {
      throw const AwesomeNotificationsException(
          message: 'Property id is required');
    }
    if (AwesomeAssertUtils.isNullOrEmptyOrInvalid(_channelKey, String)) {
      throw const AwesomeNotificationsException(
          message: 'Channel Key is required');
    }
  }
}
