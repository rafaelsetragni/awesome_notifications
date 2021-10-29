import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/src/enumerators/notification_life_cycle.dart';
import 'package:awesome_notifications/src/models/received_models/received_notification.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';

/// All received details of a user action over a Notification
class ReceivedAction extends ReceivedNotification {
  NotificationLifeCycle? actionLifeCycle;
  NotificationLifeCycle? dismissedLifeCycle;
  String buttonKeyPressed = '';
  String buttonKeyInput = '';
  String? actionDate;
  String? dismissedDate;

  ReceivedAction();

  /// Imports data from a serializable object
  ReceivedAction fromMap(Map<String, dynamic> dataMap) {
    super.fromMap(dataMap);

    actionLifeCycle = AssertUtils.extractEnum(
        NOTIFICATION_ACTION_LIFECYCLE, dataMap, NotificationLifeCycle.values);

    dismissedLifeCycle = AssertUtils.extractEnum(
        NOTIFICATION_DISMISSED_LIFE_CYCLE,
        dataMap,
        NotificationLifeCycle.values);

    actionDate =
        AssertUtils.extractValue(NOTIFICATION_ACTION_DATE, dataMap, String);
    dismissedDate =
        AssertUtils.extractValue(NOTIFICATION_DISMISSED_DATE, dataMap, String);

    buttonKeyPressed = AssertUtils.extractValue(
        NOTIFICATION_BUTTON_KEY_PRESSED, dataMap, String);

    buttonKeyInput = AssertUtils.extractValue(
        NOTIFICATION_BUTTON_KEY_INPUT, dataMap, String);

    return this;
  }

  /// Exports all content into a serializable object
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = super.toMap();
    return map
      ..addAll({
        NOTIFICATION_ACTION_DATE: actionDate,
        NOTIFICATION_DISMISSED_DATE: dismissedDate,
        NOTIFICATION_ACTION_LIFECYCLE:
            AssertUtils.toSimpleEnumString(actionLifeCycle),
        NOTIFICATION_DISMISSED_LIFE_CYCLE:
            AssertUtils.toSimpleEnumString(dismissedLifeCycle),
        NOTIFICATION_BUTTON_KEY_PRESSED: buttonKeyPressed,
        NOTIFICATION_BUTTON_KEY_INPUT: buttonKeyInput
      });
  }
}
