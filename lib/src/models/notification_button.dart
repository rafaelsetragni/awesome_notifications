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

/// Represents a button to be displayed inside a notification.
/// Note: Since Android 7, icons are only displayed for Media Layout Notifications.
/// The [icon] must be a native resource media type.
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

  /// Returns the unique key identifier of the action button.
  String? get key {
    return _key;
  }

  /// Returns the label text of the action button.
  String? get label {
    return _label;
  }

  /// Returns the icon resource of the action button.
  String? get icon {
    return _icon;
  }

  /// Indicates whether the action button is enabled.
  bool? get enabled {
    return _enabled;
  }

  /// Indicates whether the action button requires input text.
  bool get requireInputText {
    return _requireInputText;
  }

  /// Determines if the notification should be dismissed automatically when the action button is pressed.
  bool? get autoDismissible {
    return _autoDismissible;
  }

  /// Indicates if the action button should be shown in the compact view of the notification.
  bool? get showInCompactView {
    return _showInCompactView;
  }

  /// Indicates if the action button represents a dangerous option or choice.
  bool? get isDangerousOption {
    return _isDangerousOption;
  }

  /// Returns the color of the action button.
  Color? get color {
    return _color;
  }

  /// Returns the type of action associated with the action button.
  ActionType? get actionType {
    return _actionType;
  }

  /// Constructs a [NotificationActionButton].
  ///
  /// [key]: Unique key identifier for the action button.
  /// [label]: Text label for the action button.
  /// [icon]: Icon resource for the action button.
  /// [enabled]: Indicates if the button is enabled.
  /// [requireInputText]: Requires input text when the button is pressed.
  /// [autoDismissible]: Automatically dismisses the notification when the button is pressed.
  /// [showInCompactView]: Shows the button in the compact view of the notification.
  /// [isDangerousOption]: Marks the button as representing a dangerous choice.
  /// [color]: Color of the button.
  /// [actionType]: Type of action associated with the button.
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

  /// Creates a [NotificationActionButton] instance from a map of data.
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

  /// Processes retrocompatibility for older versions of the action button.
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

  /// Adapts the input field type to require text based on the action type.
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

  /// Converts the [NotificationActionButton] instance to a map.
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

  /// Validates the properties of the action button.
  ///
  /// Throws an [AwesomeNotificationsException] if the key or label is missing or if the icon is not a native resource media type.
  @override
  void validate() {
    if (AwesomeAssertUtils.isNullOrEmptyOrInvalid(_key)) {
      throw const AwesomeNotificationsException(message: 'key id is required');
    }
    if (AwesomeAssertUtils.isNullOrEmptyOrInvalid(_label)) {
      throw const AwesomeNotificationsException(
          message: 'label id is required');
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
