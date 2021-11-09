import 'package:awesome_notifications/src/definitions.dart';
import 'package:awesome_notifications/src/exceptions/awesome_exception.dart';
import 'package:awesome_notifications/src/models/model.dart';
import 'package:awesome_notifications/src/models/notification_button.dart';
import 'package:awesome_notifications/src/models/notification_calendar.dart';
import 'package:awesome_notifications/src/models/notification_content.dart';
import 'package:awesome_notifications/src/models/notification_interval.dart';
import 'package:awesome_notifications/src/models/notification_schedule.dart';

/// Reference Model to create a new notification
/// [schedule] and [actionButtons] are optional
class NotificationModel extends Model {
  NotificationContent? content;
  NotificationSchedule? schedule;
  List<NotificationActionButton>? actionButtons;

  NotificationModel({required this.content, this.schedule, this.actionButtons});

  /// Imports data from a serializable object
  NotificationModel? fromMap(Map<String, dynamic> mapData) {
    try {
      assert(mapData.containsKey(NOTIFICATION_CONTENT) &&
          mapData[NOTIFICATION_CONTENT] is Map);

      Map<String, dynamic> contentData =
          Map<String, dynamic>.from(mapData[NOTIFICATION_CONTENT]);

      this.content =
          NotificationContent(id: 0, channelKey: '').fromMap(contentData);
      if (content == null) return null;

      this.content!.validate();

      if (mapData.containsKey(NOTIFICATION_SCHEDULE)) {
        Map<String, dynamic> scheduleData =
            Map<String, dynamic>.from(mapData[NOTIFICATION_SCHEDULE]);

        if (scheduleData.containsKey(NOTIFICATION_SCHEDULE_INTERVAL)) {
          schedule = NotificationInterval(interval: 0).fromMap(scheduleData);
        } else {
          schedule = NotificationCalendar().fromMap(scheduleData);
        }
        schedule?.validate();
      }

      if (mapData.containsKey(NOTIFICATION_BUTTONS)) {
        actionButtons = [];
        List<dynamic> actionButtonsData =
            List<dynamic>.from(mapData[NOTIFICATION_BUTTONS]);

        for (dynamic buttonData in actionButtonsData) {
          Map<String, dynamic> actionButtonData =
              Map<String, dynamic>.from(buttonData);

          NotificationActionButton button =
              NotificationActionButton(label: '', key: '')
                  .fromMap(actionButtonData) as NotificationActionButton;
          button.validate();

          actionButtons!.add(button);
        }
        assert(actionButtons!.isNotEmpty);
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
      for (NotificationActionButton button in actionButtons!) {
        Map<String, dynamic> data = button.toMap();
        if (data.isNotEmpty) actionButtonsData.add(data);
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
    if (content == null)
      throw AwesomeNotificationsException(message: 'content is required.');
  }
}
