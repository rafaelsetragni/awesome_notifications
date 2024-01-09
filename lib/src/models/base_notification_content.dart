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
  Duration? _timeoutAfter;
  Duration? _chronometer;
  NotificationPrivacy? _privacy;
  NotificationCategory? _category;

  String? _titleLocKey, _bodyLocKey;
  List<String>? _titleLocArgs, _bodyLocArgs;

  DateTime? _displayedDate;
  DateTime? _createdDate;

  ActionType? _actionType;
  NotificationSource? _createdSource;

  NotificationLifeCycle? _createdLifeCycle;
  NotificationLifeCycle? _displayedLifeCycle;

  bool? _roundedLargeIcon;
  bool? _roundedBigPicture;

  /// Returns the id of the notification.
  int? get id => _id;

  /// Returns the channel key of the notification.
  String? get channelKey => _channelKey;

  /// Returns the group key of the notification.
  String? get groupKey => _groupKey;

  /// Returns the title of the notification.
  String? get title => _title;

  /// Returns the body text of the notification.
  String? get body => _body;

  /// Returns the title key used to translate the notification.
  String? get titleLockKey => _titleLocKey;

  /// Returns the body key used to translate the notification.
  String? get bodyLockKey => _bodyLocKey;

  /// Returns the args used to translate the notification title.
  List<String>? get titleLockArgs => _titleLocArgs;

  /// Returns the args used to translate the notification body.
  List<String>? get bodyLockArgs => _bodyLocArgs;

  /// Returns the summary of the notification.
  String? get summary => _summary;

  /// Returns whether the notification should show a timestamp.
  bool? get showWhen => _showWhen;

  /// Returns the custom payload of the notification.
  Map<String, String?>? get payload => _payload;

  /// Returns the icon of the notification.
  String? get icon => _icon;

  /// Returns the large icon of the notification.
  String? get largeIcon => _largeIcon;

  /// Returns the big picture of the notification.
  String? get bigPicture => _bigPicture;

  /// Returns the custom sound of the notification.
  String? get customSound => _customSound;

  /// Returns whether the notification is auto-dismissible.
  bool? get autoDismissible => _autoDismissible;

  /// Returns whether the notification should wake up the screen.
  bool? get wakeUpScreen => _wakeUpScreen;

  /// Returns whether the notification should use a full screen intent.
  bool? get fullScreenIntent => _fullScreenIntent;

  /// Returns whether the notification is a critical alert.
  bool? get criticalAlert => _criticalAlert;

  /// Returns the color of the notification.
  Color? get color => _color;

  /// Returns the duration after which the notification should be timed out.
  Duration? get timeoutAfter => _timeoutAfter;

  /// Returns the chronometer duration for the notification.
  Duration? get chronometer => _chronometer;

  /// Returns the background color of the notification.
  Color? get backgroundColor => _backgroundColor;

  /// Returns the privacy setting of the notification.
  NotificationPrivacy? get privacy => _privacy;

  /// Returns the category of the notification.
  NotificationCategory? get category => _category;

  /// Returns the action type of the notification.
  ActionType? get actionType => _actionType;

  /// Returns whether the large icon should be rounded.
  bool? get roundedLargeIcon => _roundedLargeIcon;

  /// Returns whether the big picture should be rounded.
  bool? get roundedBigPicture => _roundedBigPicture;

  /// Returns the date and time when the notification was displayed.
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
    'property name autoCancel is deprecated. Use autoDismissible instead.',
  )
  bool? get autoCancel => _autoDismissible;

  @Deprecated(
    'property name autoDismissable is deprecated. Use autoDismissible instead.',
  )
  bool? get autoDismissable => _autoDismissible;

  BaseNotificationContent({
    int? id,
    String? channelKey,
    String? groupKey,
    ActionType actionType = ActionType.Default,
    String? title,
    String? body,
    String? titleLocKey,
    String? bodyLocKey,
    List<String>? titleLocArgs,
    List<String>? bodyLocArgs,
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
    Duration? chronometer,
    Duration? timeoutAfter,
    Map<String, String?>? payload,
    String? customSound,
    bool roundedLargeIcon = false,
    bool roundedBigPicture = false,
    bool autoCancel = true,
  })  : _id = AwesomeAssertUtils.getValueOrDefault<int>(NOTIFICATION_ID, id),
        _channelKey = AwesomeAssertUtils.getValueOrDefault<String>(
          NOTIFICATION_CHANNEL_KEY,
          channelKey,
        ),
        _groupKey = AwesomeAssertUtils.getValueOrDefault<String>(
          NOTIFICATION_GROUP_KEY,
          groupKey,
        ),
        _actionType = AwesomeAssertUtils.getValueOrDefault<ActionType>(
          NOTIFICATION_ACTION_TYPE,
          actionType,
        ),
        _title = AwesomeAssertUtils.getValueOrDefault<String>(
          NOTIFICATION_TITLE,
          title,
        ),
        _body = AwesomeAssertUtils.getValueOrDefault<String>(
          NOTIFICATION_BODY,
          body,
        ),
        _titleLocKey = AwesomeAssertUtils.getValueOrDefault<String>(
          NOTIFICATION_TITLE_KEY,
          titleLocKey,
        ),
        _bodyLocKey = AwesomeAssertUtils.getValueOrDefault<String>(
          NOTIFICATION_BODY_KEY,
          bodyLocKey,
        ),
        _titleLocArgs = AwesomeAssertUtils.getValueOrDefault<List<String>>(
          NOTIFICATION_TITLE_ARGS,
          titleLocArgs,
        ),
        _bodyLocArgs = AwesomeAssertUtils.getValueOrDefault<List<String>>(
          NOTIFICATION_BODY_ARGS,
          bodyLocArgs,
        ),
        _summary = AwesomeAssertUtils.getValueOrDefault<String>(
          NOTIFICATION_SUMMARY,
          summary,
        ),
        _showWhen = AwesomeAssertUtils.getValueOrDefault<bool>(
          NOTIFICATION_SHOW_WHEN,
          showWhen,
        ),
        _icon = AwesomeAssertUtils.getValueOrDefault<String>(
          NOTIFICATION_ICON,
          icon,
        ),
        _largeIcon = AwesomeAssertUtils.getValueOrDefault<String>(
          NOTIFICATION_LARGE_ICON,
          largeIcon,
        ),
        _bigPicture = AwesomeAssertUtils.getValueOrDefault<String>(
          NOTIFICATION_BIG_PICTURE,
          bigPicture,
        ),
        _wakeUpScreen = AwesomeAssertUtils.getValueOrDefault<bool>(
          NOTIFICATION_WAKE_UP_SCREEN,
          wakeUpScreen,
        ),
        _fullScreenIntent = AwesomeAssertUtils.getValueOrDefault<bool>(
          NOTIFICATION_FULL_SCREEN_INTENT,
          fullScreenIntent,
        ),
        _criticalAlert = AwesomeAssertUtils.getValueOrDefault<bool>(
          NOTIFICATION_CRITICAL_ALERT,
          criticalAlert,
        ),
        _category = AwesomeAssertUtils.getValueOrDefault<NotificationCategory>(
          NOTIFICATION_CATEGORY,
          category,
        ),
        _color = AwesomeAssertUtils.getValueOrDefault<Color>(
          NOTIFICATION_COLOR,
          color,
        ),
        _backgroundColor = AwesomeAssertUtils.getValueOrDefault<Color>(
          NOTIFICATION_BACKGROUND_COLOR,
          backgroundColor,
        ),
        _chronometer = AwesomeAssertUtils.getValueOrDefault<Duration>(
          NOTIFICATION_CHRONOMETER,
          (chronometer?.inSeconds ?? -1) < 0 ? null : chronometer,
        ),
        _timeoutAfter = AwesomeAssertUtils.getValueOrDefault<Duration>(
          NOTIFICATION_TIMEOUT_AFTER,
          (timeoutAfter?.inSeconds ?? -1) < 0 ? null : timeoutAfter,
        ),
        _payload = AwesomeAssertUtils.getValueOrDefault<Map<String, String?>>(
          NOTIFICATION_PAYLOAD,
          payload,
        ),
        _customSound = AwesomeAssertUtils.getValueOrDefault<String>(
          NOTIFICATION_CUSTOM_SOUND,
          customSound,
        ),
        _roundedLargeIcon = AwesomeAssertUtils.getValueOrDefault<bool>(
          NOTIFICATION_ROUNDED_LARGE_ICON,
          roundedLargeIcon,
        ),
        _roundedBigPicture = AwesomeAssertUtils.getValueOrDefault<bool>(
          NOTIFICATION_ROUNDED_BIG_PICTURE,
          roundedBigPicture,
        ),
        _autoDismissible = AwesomeAssertUtils.getValueOrDefault<bool>(
          NOTIFICATION_AUTO_DISMISSIBLE,
          autoDismissible && autoCancel,
        );

  @override
  BaseNotificationContent? fromMap(Map<String, dynamic> mapData) {
    mapData = processRetroCompatibility(mapData);

    _id = AwesomeAssertUtils.extractValue<int>(NOTIFICATION_ID, mapData);
    _channelKey = AwesomeAssertUtils.extractValue<String>(
      NOTIFICATION_CHANNEL_KEY,
      mapData,
    );
    _groupKey = AwesomeAssertUtils.extractValue<String>(
      NOTIFICATION_GROUP_KEY,
      mapData,
    );
    _actionType = AwesomeAssertUtils.extractEnum<ActionType>(
      NOTIFICATION_ACTION_TYPE,
      mapData,
      ActionType.values,
    );
    _title =
        AwesomeAssertUtils.extractValue<String>(NOTIFICATION_TITLE, mapData);
    _body = AwesomeAssertUtils.extractValue<String>(NOTIFICATION_BODY, mapData);

    _titleLocKey = AwesomeAssertUtils.extractValue<String>(
      NOTIFICATION_TITLE_KEY,
      mapData,
    );
    _bodyLocKey =
        AwesomeAssertUtils.extractValue<String>(NOTIFICATION_BODY_KEY, mapData);

    _titleLocArgs = AwesomeAssertUtils.extractValue<List<String>>(
      NOTIFICATION_TITLE_ARGS,
      mapData,
    );
    _bodyLocArgs = AwesomeAssertUtils.extractValue<List<String>>(
      NOTIFICATION_BODY_ARGS,
      mapData,
    );

    _summary =
        AwesomeAssertUtils.extractValue<String>(NOTIFICATION_SUMMARY, mapData);
    _showWhen =
        AwesomeAssertUtils.extractValue<bool>(NOTIFICATION_SHOW_WHEN, mapData);
    _icon = AwesomeAssertUtils.extractValue<String>(NOTIFICATION_ICON, mapData);
    _largeIcon = AwesomeAssertUtils.extractValue<String>(
      NOTIFICATION_LARGE_ICON,
      mapData,
    );
    _bigPicture = AwesomeAssertUtils.extractValue<String>(
      NOTIFICATION_BIG_PICTURE,
      mapData,
    );
    _wakeUpScreen = AwesomeAssertUtils.extractValue<bool>(
      NOTIFICATION_WAKE_UP_SCREEN,
      mapData,
    );
    _fullScreenIntent = AwesomeAssertUtils.extractValue<bool>(
      NOTIFICATION_FULL_SCREEN_INTENT,
      mapData,
    );
    _criticalAlert = AwesomeAssertUtils.extractValue<bool>(
      NOTIFICATION_CRITICAL_ALERT,
      mapData,
    );
    _category = AwesomeAssertUtils.extractEnum<NotificationCategory>(
      NOTIFICATION_CATEGORY,
      mapData,
      NotificationCategory.values,
    );
    _color =
        AwesomeAssertUtils.extractValue<Color>(NOTIFICATION_COLOR, mapData);
    _backgroundColor = AwesomeAssertUtils.extractValue<Color>(
      NOTIFICATION_BACKGROUND_COLOR,
      mapData,
    );
    _chronometer = AwesomeAssertUtils.extractValue<Duration>(
      NOTIFICATION_CHRONOMETER,
      mapData,
    );
    _timeoutAfter = AwesomeAssertUtils.extractValue<Duration>(
      NOTIFICATION_TIMEOUT_AFTER,
      mapData,
    );
    _payload = AwesomeAssertUtils.extractMap<String, String?>(
      NOTIFICATION_PAYLOAD,
      mapData,
    );
    _customSound = AwesomeAssertUtils.extractValue<String>(
      NOTIFICATION_CUSTOM_SOUND,
      mapData,
    );
    _roundedLargeIcon = AwesomeAssertUtils.extractValue<bool>(
      NOTIFICATION_ROUNDED_LARGE_ICON,
      mapData,
    );
    _roundedBigPicture = AwesomeAssertUtils.extractValue<bool>(
      NOTIFICATION_ROUNDED_BIG_PICTURE,
      mapData,
    );
    _autoDismissible = AwesomeAssertUtils.extractValue<bool>(
      NOTIFICATION_AUTO_DISMISSIBLE,
      mapData,
    );

    return this;
  }

  @visibleForTesting
  Map<String, dynamic> processRetroCompatibility(Map<String, dynamic> dataMap) {
    if (dataMap.containsKey('autoCancel')) {
      developer.log(
        'autoCancel is now deprecated. Please use autoDismissible instead.',
      );
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
      NOTIFICATION_TITLE_KEY: _titleLocKey,
      NOTIFICATION_BODY_KEY: _bodyLocKey,
      NOTIFICATION_TITLE_ARGS: _titleLocArgs,
      NOTIFICATION_BODY_ARGS: _bodyLocArgs,
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
      NOTIFICATION_DISPLAYED_DATE: displayedDate,
      NOTIFICATION_CHRONOMETER: _chronometer?.inSeconds,
      NOTIFICATION_TIMEOUT_AFTER: _timeoutAfter?.inSeconds,
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
        message: 'Property id is required',
      );
    }
    if (AwesomeAssertUtils.isNullOrEmptyOrInvalid(_channelKey)) {
      throw const AwesomeNotificationsException(
        message: 'Channel Key is required',
      );
    }
  }
}
