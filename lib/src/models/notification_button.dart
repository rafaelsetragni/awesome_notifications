import 'dart:ui';

import 'package:awesome_notifications/src/definitions.dart';
import 'package:awesome_notifications/src/enumerators/action_type.dart';
import 'package:awesome_notifications/src/enumerators/media_source.dart';
import 'package:awesome_notifications/src/exceptions/awesome_exception.dart';
import 'package:awesome_notifications/src/models/model.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';
import 'package:awesome_notifications/src/utils/bitmap_utils.dart';
import 'package:awesome_notifications/src/utils/string_utils.dart';

/// Notification button to display inside a notification.
/// Since Android 7, icons are displayed only for Media Layout Notifications
/// [icon] must be a native resource media type
class NotificationActionButton extends Model {
  String? key;
  String? label;
  String? icon;
  bool? enabled;
  bool requireInputText;
  bool? autoDismissible;
  bool? showInCompactView;
  bool? isDangerousOption;
  Color? color;
  ActionType? actionType;

  NotificationActionButton(
      {required String key,
      required String label,
      this.icon,
      this.enabled,
      this.requireInputText = false,
      this.autoDismissible,
      this.showInCompactView,
      this.isDangerousOption,
      this.color,
      this.actionType = ActionType.Default}) {
    this.key = key;
    this.label = label;

    // Adapting input type to 0.7.0 pattern
    _adaptInputFieldToRequireText();
  }

  void _adaptInputFieldToRequireText() {
    if(this.actionType == ActionType.InputField){
      this.requireInputText = true;
      this.actionType = ActionType.SilentAction;
    }
  }

  @override
  NotificationActionButton? fromMap(Map<String, dynamic> dataMap) {
    key = AwesomeAssertUtils.extractValue(NOTIFICATION_KEY, dataMap, String);
    icon = AwesomeAssertUtils.extractValue(NOTIFICATION_ICON, dataMap, String);
    label =
        AwesomeAssertUtils.extractValue(NOTIFICATION_BUTTON_LABEL, dataMap, String);
    enabled = AwesomeAssertUtils.extractValue(NOTIFICATION_ENABLED, dataMap, bool);
    requireInputText = AwesomeAssertUtils.extractValue(NOTIFICATION_REQUIRE_INPUT_TEXT, dataMap, bool);
    autoDismissible =
        AwesomeAssertUtils.extractValue(NOTIFICATION_AUTO_DISMISSIBLE, dataMap, bool);
    showInCompactView = AwesomeAssertUtils.extractValue(
        NOTIFICATION_SHOW_IN_COMPACT_VIEW, dataMap, bool);
    isDangerousOption = AwesomeAssertUtils.extractValue(
        NOTIFICATION_IS_DANGEROUS_OPTION, dataMap, bool);
    actionType = AwesomeAssertUtils.extractEnum(
        NOTIFICATION_ACTION_TYPE, dataMap, ActionType.values);

    color = AwesomeAssertUtils.extractValue(NOTIFICATION_COLOR, dataMap, Color);

    return this;
  }

  @override
  Map<String, dynamic> toMap() {
    _adaptInputFieldToRequireText();

    return {
      NOTIFICATION_KEY: key,
      NOTIFICATION_ICON: icon,
      NOTIFICATION_BUTTON_LABEL: label,
      NOTIFICATION_ENABLED: enabled,
      NOTIFICATION_REQUIRE_INPUT_TEXT: requireInputText,
      NOTIFICATION_AUTO_DISMISSIBLE: autoDismissible,
      NOTIFICATION_SHOW_IN_COMPACT_VIEW: showInCompactView,
      NOTIFICATION_IS_DANGEROUS_OPTION: isDangerousOption,
      NOTIFICATION_ACTION_TYPE: AwesomeAssertUtils.toSimpleEnumString(actionType),
      NOTIFICATION_COLOR: color?.value
    };
  }

  @override
  void validate() {
    if (AwesomeAssertUtils.isNullOrEmptyOrInvalid(key, String))
      throw AwesomeNotificationsException(message: 'key id is requried');
    if (AwesomeAssertUtils.isNullOrEmptyOrInvalid(label, String))
      throw AwesomeNotificationsException(message: 'label id is requried');
    if (AwesomeAssertUtils.isNullOrEmptyOrInvalid(autoDismissible, bool))
      throw AwesomeNotificationsException(
          message: 'autoDismissible id is requried');
    if (AwesomeAssertUtils.isNullOrEmptyOrInvalid(showInCompactView, bool))
      throw AwesomeNotificationsException(
          message: 'showInCompactView id is requried');

    // For action buttons, it's only allowed resource media types
    if (!AwesomeStringUtils.isNullOrEmpty(icon) &&
        AwesomeBitmapUtils().getMediaSource(icon!) != MediaSource.Resource)
      throw AwesomeNotificationsException(
          message:
              'icons for action buttons must be a native resource media type');
  }
}
