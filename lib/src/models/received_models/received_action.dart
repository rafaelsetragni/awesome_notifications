import 'package:awesome_notifications/src/enumerators/notification_life_cycle.dart';
import 'package:awesome_notifications/src/models/received_models/received_notification.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';

class ReceivedAction extends ReceivedNotification {

  NotificationLifeCycle actionLifeCycle;
  String buttonKeyPressed = '';
  String buttonKeyInput = '';
  String actionDate;

  ReceivedAction();

  ReceivedNotification fromMap(Map<String, dynamic> dataMap) {
    super.fromMap(dataMap);

    actionLifeCycle  = AssertUtils.extractEnum<NotificationLifeCycle>(dataMap, 'actionLifeCycle', NotificationLifeCycle.values);

    actionDate       = AssertUtils.extractValue<String>(dataMap, 'actionDate');

    buttonKeyPressed = AssertUtils.extractValue<String>(dataMap, 'actionKey');
    buttonKeyInput   = AssertUtils.extractValue<String>(dataMap, 'actionInput');

    return this;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = super.toMap();
    return map..addAll({
      'actionDate': actionDate,
      'actionLifeCycle': AssertUtils.toSimpleEnumString(actionLifeCycle),
      'buttonKeyPressed': buttonKeyPressed,
      'buttonKeyInput': buttonKeyInput
    });

  }
}