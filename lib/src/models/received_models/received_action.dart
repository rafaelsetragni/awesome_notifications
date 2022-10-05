import 'package:awesome_notifications/src/models/received_models/received_notification.dart';

import '../../definitions.dart';
import '../../enumerators/notification_life_cycle.dart';
import '../../utils/assert_utils.dart';
import '../../utils/date_utils.dart';

/// All received details of a user action over a Notification
class ReceivedAction extends ReceivedNotification {
  NotificationLifeCycle? actionLifeCycle;
  NotificationLifeCycle? dismissedLifeCycle;

  String buttonKeyPressed = '';
  String buttonKeyInput = '';
  DateTime? actionDate;
  DateTime? dismissedDate;

  ReceivedAction();

  /// Imports data from a serializable object
  @override
  ReceivedAction fromMap(Map<String, dynamic> dataMap) {
    super.fromMap(dataMap);

    actionLifeCycle = AwesomeAssertUtils.extractEnum<NotificationLifeCycle>(
        NOTIFICATION_ACTION_LIFECYCLE, dataMap, NotificationLifeCycle.values);

    dismissedLifeCycle = AwesomeAssertUtils.extractEnum<NotificationLifeCycle>(
        NOTIFICATION_DISMISSED_LIFE_CYCLE,
        dataMap,
        NotificationLifeCycle.values);

    actionDate = AwesomeAssertUtils.extractValue(
        NOTIFICATION_ACTION_DATE, dataMap, DateTime);
    dismissedDate = AwesomeAssertUtils.extractValue(
        NOTIFICATION_DISMISSED_DATE, dataMap, DateTime);

    buttonKeyPressed = AwesomeAssertUtils.extractValue(
        NOTIFICATION_BUTTON_KEY_PRESSED, dataMap, String);

    buttonKeyInput = AwesomeAssertUtils.extractValue(
        NOTIFICATION_BUTTON_KEY_INPUT, dataMap, String);

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
