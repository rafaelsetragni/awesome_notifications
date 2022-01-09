import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/src/enumerators/notification_life_cycle.dart';
import 'package:awesome_notifications/src/enumerators/notification_source.dart';
import 'package:awesome_notifications/src/models/base_notification_content.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';

/// All received details of a notification created or displayed on the system
/// The data field
class ReceivedNotification extends BaseNotificationContent {
  ReceivedNotification() : super(channelKey: null, id: null);

  ReceivedNotification fromMap(Map<String, dynamic> dataMap) {
    super.fromMap(dataMap);

    createdDate = AwesomeAssertUtils.extractValue(
        NOTIFICATION_CREATED_DATE, dataMap, String);

    displayedDate = AwesomeAssertUtils.extractValue(
        NOTIFICATION_DISPLAYED_DATE, dataMap, String);

    createdSource = AwesomeAssertUtils.extractEnum(
        NOTIFICATION_CREATED_SOURCE, dataMap, NotificationSource.values);

    createdLifeCycle = AwesomeAssertUtils.extractEnum(
        NOTIFICATION_CREATED_LIFECYCLE, dataMap, NotificationLifeCycle.values);
    displayedLifeCycle = AwesomeAssertUtils.extractEnum(
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
        NOTIFICATION_CREATED_SOURCE:
            AwesomeAssertUtils.toSimpleEnumString(createdSource),
        NOTIFICATION_CREATED_LIFECYCLE:
            AwesomeAssertUtils.toSimpleEnumString(createdLifeCycle),
        NOTIFICATION_DISPLAYED_LIFECYCLE:
            AwesomeAssertUtils.toSimpleEnumString(displayedLifeCycle),
        NOTIFICATION_CREATED_DATE: createdDate,
        NOTIFICATION_DISPLAYED_DATE: displayedDate
      });
  }
}
