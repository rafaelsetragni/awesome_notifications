import 'dart:developer' as developer;
import 'dart:ui';

import 'package:awesome_notifications/src/definitions.dart';
import 'package:awesome_notifications/src/enumerators/action_type.dart';
import 'package:awesome_notifications/src/enumerators/media_source.dart';
import 'package:awesome_notifications/src/exceptions/awesome_exception.dart';
import 'package:awesome_notifications/src/models/model.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';
import 'package:awesome_notifications/src/utils/bitmap_utils.dart';
import 'package:awesome_notifications/src/utils/string_utils.dart';
import 'package:flutter/foundation.dart';

/// Notification button to display inside a notification.
/// Since Android 7, icons are displayed only for Media Layout Notifications
/// [icon] must be a native resource media type
class NotificationActionButton extends Model {
  String? _key;
  String? _label;
  String? _icon;
  bool? _enabled;
  bool _requireInputText;
  bool? _autoDismissible;
  bool? _showInCompactView;
  bool? _isDangerousOption;
  Color? _color;
  ActionType? _actionType;

  String? get key {
    return _key;
  }

  String? get label {
    return _label;
  }

  String? get icon {
    return _icon;
  }

  bool? get enabled {
    return _enabled;
  }

  bool get requireInputText {
    return _requireInputText;
  }

  bool? get autoDismissible {
    return _autoDismissible;
  }

  bool? get showInCompactView {
    return _showInCompactView;
  }

  bool? get isDangerousOption {
    return _isDangerousOption;
  }

  Color? get color {
    return _color;
  }

  ActionType? get actionType {
    return _actionType;
  }

  NotificationActionButton(
      {required String key,
      required String label,
      String? icon,
      bool enabled = true,
      bool requireInputText = false,
      bool autoDismissible = true,
      bool showInCompactView = false,
      bool isDangerousOption = false,
      Color? color,
      ActionType actionType = ActionType.Default})
      : _key = key,
        _label = label,
        _icon = icon,
        _enabled = enabled,
        _requireInputText = requireInputText,
        _autoDismissible = autoDismissible,
        _showInCompactView = showInCompactView,
        _isDangerousOption = isDangerousOption,
        _color = color,
        _actionType = actionType {
    // Adapting input type to 0.7.0 pattern
    adaptInputFieldToRequireText();
  }

  @override
  NotificationActionButton? fromMap(Map<String, dynamic> mapData) {
    processRetroCompatibility(mapData);
    _key = AwesomeAssertUtils.extractValue<String>(NOTIFICATION_KEY, mapData);
    _icon = AwesomeAssertUtils.extractValue<String>(NOTIFICATION_ICON, mapData);
    _label = AwesomeAssertUtils.extractValue<String>(
        NOTIFICATION_BUTTON_LABEL, mapData);
    _enabled =
        AwesomeAssertUtils.extractValue<bool>(NOTIFICATION_ENABLED, mapData);
    _requireInputText = AwesomeAssertUtils.extractValue<bool>(
        NOTIFICATION_REQUIRE_INPUT_TEXT, mapData);
    _autoDismissible = AwesomeAssertUtils.extractValue<bool>(
        NOTIFICATION_AUTO_DISMISSIBLE, mapData);
    _showInCompactView = AwesomeAssertUtils.extractValue<bool>(
        NOTIFICATION_SHOW_IN_COMPACT_VIEW, mapData);
    _isDangerousOption = AwesomeAssertUtils.extractValue<bool>(
        NOTIFICATION_IS_DANGEROUS_OPTION, mapData);
    _actionType = AwesomeAssertUtils.extractEnum<ActionType>(
        NOTIFICATION_ACTION_TYPE, mapData, ActionType.values);

    _color =
        AwesomeAssertUtils.extractValue<Color>(NOTIFICATION_COLOR, mapData);

    return this;
  }

  @visibleForTesting
  void processRetroCompatibility(Map<String, dynamic> dataMap) {
    if (dataMap.containsKey("autoCancel")) {
      developer
          .log("autoCancel is deprecated. Please use autoDismissible instead.");
      dataMap[NOTIFICATION_AUTO_DISMISSIBLE] =
          AwesomeAssertUtils.extractValue<bool>('autoCancel', dataMap);
    }

    if (dataMap.containsKey("buttonType")) {
      developer.log("buttonType is deprecated. Please use actionType instead.");
      _actionType = AwesomeAssertUtils.extractEnum<ActionType>(
          "buttonType", dataMap, ActionType.values);
    }

    adaptInputFieldToRequireText();
  }

  @visibleForTesting
  void adaptInputFieldToRequireText() {
    // ignore: deprecated_member_use_from_same_package
    if (_actionType == ActionType.InputField) {
      developer.log(
          "InputField is deprecated. Please use requireInputText instead.");
      _requireInputText = true;
      _actionType = ActionType.SilentAction;
    }
  }

  @override
  Map<String, dynamic> toMap() {
    adaptInputFieldToRequireText();

    return {
      NOTIFICATION_KEY: _key,
      NOTIFICATION_ICON: _icon,
      NOTIFICATION_BUTTON_LABEL: _label,
      NOTIFICATION_ENABLED: _enabled,
      NOTIFICATION_REQUIRE_INPUT_TEXT: _requireInputText,
      NOTIFICATION_AUTO_DISMISSIBLE: _autoDismissible,
      NOTIFICATION_SHOW_IN_COMPACT_VIEW: _showInCompactView,
      NOTIFICATION_IS_DANGEROUS_OPTION: _isDangerousOption,
      NOTIFICATION_ACTION_TYPE: _actionType?.name,
      NOTIFICATION_COLOR: _color?.value
    };
  }

  @override
  void validate() {
    if (AwesomeAssertUtils.isNullOrEmptyOrInvalid(_key)) {
      throw const AwesomeNotificationsException(message: 'key id is requried');
    }
    if (AwesomeAssertUtils.isNullOrEmptyOrInvalid(_label)) {
      throw const AwesomeNotificationsException(
          message: 'label id is requried');
    }

    // For action buttons, it's only allowed resource media types
    if (!AwesomeStringUtils.isNullOrEmpty(_icon) &&
        AwesomeBitmapUtils().getMediaSource(_icon!) != MediaSource.Resource) {
      throw const AwesomeNotificationsException(
          message:
              'icons for action buttons must be a native resource media type');
    }
  }
}
