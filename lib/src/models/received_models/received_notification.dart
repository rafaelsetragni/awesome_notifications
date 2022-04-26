import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/src/models/base_notification_content.dart';

/// All received details of a notification created or displayed on the system
/// The data field
class ReceivedNotification extends BaseNotificationContent {
  ReceivedNotification fromMap(Map<String, dynamic> dataMap) {
    super.fromMap(dataMap);

    createdDate = AwesomeAssertUtils.extractValue(
        NOTIFICATION_CREATED_DATE, dataMap, DateTime);

    displayedDate = AwesomeAssertUtils.extractValue(
        NOTIFICATION_DISPLAYED_DATE, dataMap, DateTime);

    createdSource = AwesomeAssertUtils.extractEnum<NotificationSource>(
        NOTIFICATION_CREATED_SOURCE, dataMap, NotificationSource.values);

    createdLifeCycle = AwesomeAssertUtils.extractEnum<NotificationLifeCycle>(
        NOTIFICATION_CREATED_LIFECYCLE, dataMap, NotificationLifeCycle.values);

    displayedLifeCycle = AwesomeAssertUtils.extractEnum<NotificationLifeCycle>(
        NOTIFICATION_DISPLAYED_LIFECYCLE,
        dataMap,
        NotificationLifeCycle.values);

    return this;
  }

  /// Exports all content into a serializable object
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = super.toMap();
    return map
      ..addAll({
        NOTIFICATION_CREATED_SOURCE: createdSource?.name,
        NOTIFICATION_CREATED_LIFECYCLE: createdLifeCycle?.name,
        NOTIFICATION_DISPLAYED_LIFECYCLE: displayedLifeCycle?.name,
        NOTIFICATION_CREATED_DATE:
            AwesomeDateUtils.parseDateToString(createdDate),
        NOTIFICATION_DISPLAYED_DATE:
            AwesomeDateUtils.parseDateToString(displayedDate),
      });
  }
}
