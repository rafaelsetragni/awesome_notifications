import 'package:awesome_notifications/src/models/received_models/received_notification.dart';

import '../../definitions.dart';
import '../../enumerators/notification_life_cycle.dart';
import '../../utils/assert_utils.dart';
import '../../utils/date_utils.dart';

/// All received details of a user action over a Notification
class ReceivedAction extends ReceivedNotification {
  /// The lifecycle state when the notification action was taken.
  NotificationLifeCycle? actionLifeCycle;

  /// The lifecycle state when the notification was dismissed by the user.
  NotificationLifeCycle? dismissedLifeCycle;

  /// The key of the button pressed by the user in the notification.
  String buttonKeyPressed = '';

  /// The text input received from the user if the notification had an input field.
  String buttonKeyInput = '';

  /// The date and time when the user action was taken.
  DateTime? actionDate;

  /// The date and time when the notification was dismissed by the user.
  DateTime? dismissedDate;

  ReceivedAction();

  /// Imports data from a serializable object.
  @override
  ReceivedAction fromMap(Map<String, dynamic> dataMap) {
    super.fromMap(dataMap);

    actionLifeCycle = AwesomeAssertUtils.extractEnum<NotificationLifeCycle>(
        NOTIFICATION_ACTION_LIFECYCLE, dataMap, NotificationLifeCycle.values);

    dismissedLifeCycle = AwesomeAssertUtils.extractEnum<NotificationLifeCycle>(
        NOTIFICATION_DISMISSED_LIFE_CYCLE,
        dataMap,
        NotificationLifeCycle.values);

    actionDate = AwesomeAssertUtils.extractValue<DateTime>(
        NOTIFICATION_ACTION_DATE, dataMap);
    dismissedDate = AwesomeAssertUtils.extractValue<DateTime>(
        NOTIFICATION_DISMISSED_DATE, dataMap);

    buttonKeyPressed = AwesomeAssertUtils.extractValue<String>(
        NOTIFICATION_BUTTON_KEY_PRESSED, dataMap);

    buttonKeyInput = AwesomeAssertUtils.extractValue<String>(
        NOTIFICATION_BUTTON_KEY_INPUT, dataMap);

    return this;
  }

  /// Exports all content into a serializable object
  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = super.toMap();
    return map
      ..addAll({
        NOTIFICATION_ACTION_DATE:
            AwesomeDateUtils.parseDateToString(actionDate),
        NOTIFICATION_DISMISSED_DATE:
            AwesomeDateUtils.parseDateToString(dismissedDate),
        NOTIFICATION_ACTION_LIFECYCLE: actionLifeCycle?.name,
        NOTIFICATION_DISMISSED_LIFE_CYCLE: dismissedLifeCycle?.name,
        NOTIFICATION_BUTTON_KEY_PRESSED: buttonKeyPressed,
        NOTIFICATION_BUTTON_KEY_INPUT: buttonKeyInput
      });
  }
}
