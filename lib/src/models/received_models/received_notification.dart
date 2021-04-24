import 'package:awesome_notifications/src/enumerators/notification_life_cycle.dart';
import 'package:awesome_notifications/src/enumerators/notification_source.dart';
import 'package:awesome_notifications/src/models/basic_notification_content.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';

/// All received details of a notification created or displayed on the system
/// The data field
class ReceivedNotification extends BaseNotificationContent {
  NotificationLifeCycle? displayedLifeCycle;

  NotificationSource? createdSource;
  NotificationLifeCycle? createdLifeCycle;

  String? displayedDate;
  String? createdDate;

  ReceivedNotification fromMap(Map<String, dynamic> dataMap) {
    super.fromMap(dataMap);

    createdSource = AssertUtils.extractEnum<NotificationSource>(
        dataMap, 'createdSource', NotificationSource.values);
    createdLifeCycle = AssertUtils.extractEnum<NotificationLifeCycle>(
        dataMap, 'createdLifeCycle', NotificationLifeCycle.values);
    displayedLifeCycle = AssertUtils.extractEnum<NotificationLifeCycle>(
        dataMap, 'displayedLifeCycle', NotificationLifeCycle.values);
    displayedDate = AssertUtils.extractValue<String>(dataMap, 'displayedDate');
    createdDate = AssertUtils.extractValue<String>(dataMap, 'createdDate');

    return this;
  }

  /// Exports all content into a serializable object
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = super.toMap();
    return map
      ..addAll({
        'createdSource': AssertUtils.toSimpleEnumString(createdSource),
        'createdLifeCycle': AssertUtils.toSimpleEnumString(createdLifeCycle),
        'displayedLifeCycle':
            AssertUtils.toSimpleEnumString(displayedLifeCycle),
        'createdDate': createdDate,
        'displayedDate': displayedDate
      });
  }
}
