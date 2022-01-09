import 'dart:ui';

import 'package:awesome_notifications/src/definitions.dart';
import 'package:awesome_notifications/src/enumerators/action_button_type.dart';
import 'package:awesome_notifications/src/enumerators/media_source.dart';
import 'package:awesome_notifications/src/exceptions/awesome_exception.dart';
import 'package:awesome_notifications/src/models/model.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';
import 'package:awesome_notifications/src/utils/bitmap_utils.dart';
import 'package:awesome_notifications/src/utils/string_utils.dart';

/// Notification button to display inside a notification.
/// Since Android 7, icons are displayed only for Media Layout Notifications
/// [icon] must be a native resource media type
///
/// [buttonType] could be classified in 4 types:
///
/// [ActionButtonType.Default]: after user taps, the notification bar is closed and an action event is fired.
/// [ActionButtonType.InputField]: after user taps, a input text field is displayed to capture input by the user.
/// [ActionButtonType.DisabledAction]: after user taps, the notification bar is closed, but the respective action event is not fired.
/// [ActionButtonType.KeepOnTop]: after user taps, the notification bar is not closed, but an action event is fired.
class NotificationActionButton extends Model {
  String? key;
  String? label;
  String? icon;
  bool? enabled;
  bool? autoDismissible;
  bool? showInCompactView;
  bool? isDangerousOption;
  Color? color;
  ActionButtonType? buttonType;

  NotificationActionButton(
      {required String key,
      required String label,
      this.icon,
      this.enabled,
      this.autoDismissible,
      this.showInCompactView,
      this.isDangerousOption,
      this.color,
      this.buttonType = ActionButtonType.Default}) {
    this.key = key;
    this.label = label;
  }

  @override
  NotificationActionButton? fromMap(Map<String, dynamic> dataMap) {
    key = AwesomeAssertUtils.extractValue(NOTIFICATION_KEY, dataMap, String);
    icon = AwesomeAssertUtils.extractValue(NOTIFICATION_ICON, dataMap, String);
    label = AwesomeAssertUtils.extractValue(
        NOTIFICATION_BUTTON_LABEL, dataMap, String);
    enabled =
        AwesomeAssertUtils.extractValue(NOTIFICATION_ENABLED, dataMap, bool);
    autoDismissible = AwesomeAssertUtils.extractValue(
        NOTIFICATION_AUTO_DISMISSIBLE, dataMap, bool);
    showInCompactView = AwesomeAssertUtils.extractValue(
        NOTIFICATION_SHOW_IN_COMPACT_VIEW, dataMap, bool);
    isDangerousOption = AwesomeAssertUtils.extractValue(
        NOTIFICATION_IS_DANGEROUS_OPTION, dataMap, bool);
    buttonType = AwesomeAssertUtils.extractEnum(
        NOTIFICATION_BUTTON_TYPE, dataMap, ActionButtonType.values);

    color = AwesomeAssertUtils.extractValue(NOTIFICATION_COLOR, dataMap, Color);

    return this;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      NOTIFICATION_KEY: key,
      NOTIFICATION_ICON: icon,
      NOTIFICATION_BUTTON_LABEL: label,
      NOTIFICATION_ENABLED: enabled,
      NOTIFICATION_AUTO_DISMISSIBLE: autoDismissible,
      NOTIFICATION_SHOW_IN_COMPACT_VIEW: showInCompactView,
      NOTIFICATION_IS_DANGEROUS_OPTION: isDangerousOption,
      NOTIFICATION_BUTTON_TYPE:
          AwesomeAssertUtils.toSimpleEnumString(buttonType),
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
