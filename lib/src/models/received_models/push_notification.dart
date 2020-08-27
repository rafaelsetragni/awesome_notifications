import 'package:awesome_notifications/src/models/model.dart';
import 'package:awesome_notifications/src/models/notification_button.dart';
import 'package:awesome_notifications/src/models/notification_content.dart';
import 'package:awesome_notifications/src/models/notification_schedule.dart';

/// Reference Model to create a new notification
/// [schedule] and [actionButtons] are optional
class PushNotification extends Model {
  NotificationContent content;
  NotificationSchedule schedule;
  List<NotificationActionButton> actionButtons;

  PushNotification({this.content, this.schedule, this.actionButtons});

  /// Imports data from a serializable object
  PushNotification fromMap(Map<String, dynamic> mapData) {
    try {
      assert(mapData.containsKey('content') && mapData['content'] is Map);

      Map<String, dynamic> contentData =
          Map<String, dynamic>.from(mapData['content']);

      content = NotificationContent().fromMap(contentData);
      content.validate();

      if (mapData.containsKey('schedule')) {
        Map<String, dynamic> scheduleData =
            Map<String, dynamic>.from(mapData['schedule']);

        schedule = NotificationSchedule().fromMap(scheduleData);
        schedule.validate();
      }

      if (mapData.containsKey('actionButtons')) {
        actionButtons = List<NotificationActionButton>();
        List<Object> actionButtonsData =
            List<Object>.from(mapData['actionButtons']);

        for (Object buttonData in actionButtonsData) {
          Map<String, dynamic> actionButtonData =
              Map<String, dynamic>.from(buttonData);

          NotificationActionButton button =
              NotificationActionButton().fromMap(actionButtonData);
          button.validate();

          actionButtons.add(button);
        }
        assert(actionButtons.isNotEmpty);
      }
    } catch (e) {
      return null;
    }

    return this;
  }

  /// Exports all content into a serializable object
  Map<String, dynamic> toMap() {
    List<Map<String, dynamic>> actionButtonsData = [];
    if (actionButtons != null) {
      for (NotificationActionButton button in actionButtons) {
        Map<String, dynamic> data = button.toMap();
        if (data != null && data.isNotEmpty) actionButtonsData.add(data);
      }
    }
    return {
      'content': content?.toMap() ?? {},
      'schedule': schedule?.toMap() ?? {},
      'actionButtons': actionButtonsData.isEmpty ? null : actionButtonsData
    };
  }

  @override
  /// Validates if the models has all the requirements to be considerated valid
  void validate() {
    assert(content != null);
  }
}
