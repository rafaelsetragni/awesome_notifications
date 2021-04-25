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
  ReceivedNotification fromMap(Map<String, dynamic> dataMap) {
    super.fromMap(dataMap);

    actionLifeCycle = AssertUtils.extractEnum<NotificationLifeCycle>(
        dataMap, 'actionLifeCycle', NotificationLifeCycle.values);

    dismissedLifeCycle = AssertUtils.extractEnum(
        dataMap, 'dismissedLifeCycle', NotificationLifeCycle.values);

    actionDate = AssertUtils.extractValue<String>(dataMap, 'actionDate');
    dismissedDate = AssertUtils.extractValue<String>(dataMap, 'dismissedDate');

    buttonKeyPressed = AssertUtils.extractValue<String>(dataMap, 'actionKey') ?? '';
    buttonKeyInput = AssertUtils.extractValue<String>(dataMap, 'actionInput') ?? '';

    return this;
  }

  /// Exports all content into a serializable object
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = super.toMap();
    return map
      ..addAll({
        'actionDate': actionDate,
        'dismissedDate': dismissedDate,
        'actionLifeCycle': AssertUtils.toSimpleEnumString(actionLifeCycle),
        'dismissedLifeCycle':
            AssertUtils.toSimpleEnumString(dismissedLifeCycle),
        'buttonKeyPressed': buttonKeyPressed,
        'buttonKeyInput': buttonKeyInput
      });
  }
}
