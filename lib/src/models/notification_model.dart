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
  NotificationContent? _content;
  NotificationSchedule? _schedule;
  List<NotificationActionButton>? _actionButtons;

  NotificationContent? get content {
    return _content;
  }

  NotificationSchedule? get schedule {
    return _schedule;
  }

  List<NotificationActionButton>? get actionButtons {
    return _actionButtons;
  }

  NotificationModel(
      {NotificationContent? content,
      NotificationSchedule? schedule,
      List<NotificationActionButton>? actionButtons})
      : _content = content,
        _schedule = schedule,
        _actionButtons = actionButtons;

  /// Imports data from a serializable object
  @override
  NotificationModel? fromMap(Map<String, dynamic> mapData) {
    try {
      assert(mapData.containsKey(NOTIFICATION_CONTENT) &&
          mapData[NOTIFICATION_CONTENT] is Map);

      Map<String, dynamic> contentData =
          Map<String, dynamic>.from(mapData[NOTIFICATION_CONTENT]);

      _content =
          NotificationContent(id: 0, channelKey: '').fromMap(contentData);
      if (_content == null) return null;

      _content!.validate();

      if (mapData.containsKey(NOTIFICATION_SCHEDULE)) {
        Map<String, dynamic> scheduleData =
            Map<String, dynamic>.from(mapData[NOTIFICATION_SCHEDULE]);

        if (scheduleData.containsKey(NOTIFICATION_SCHEDULE_INTERVAL)) {
          _schedule = NotificationInterval(interval: 0).fromMap(scheduleData);
        } else {
          _schedule = NotificationCalendar().fromMap(scheduleData);
        }
        _schedule?.validate();
      }

      if (mapData.containsKey(NOTIFICATION_BUTTONS)) {
        _actionButtons = [];
        List<dynamic> actionButtonsData =
            List<dynamic>.from(mapData[NOTIFICATION_BUTTONS]);

        for (dynamic buttonData in actionButtonsData) {
          Map<String, dynamic> actionButtonData =
              Map<String, dynamic>.from(buttonData);

          NotificationActionButton button =
              NotificationActionButton(label: '', key: '')
                  .fromMap(actionButtonData) as NotificationActionButton;
          button.validate();

          _actionButtons!.add(button);
        }
        assert(_actionButtons!.isNotEmpty);
      }
    } catch (e) {
      return null;
    }

    return this;
  }

  /// Exports all content into a serializable object
  @override
  Map<String, dynamic> toMap() {
    List<Map<String, dynamic>> actionButtonsData = [];
    if (_actionButtons != null) {
      for (NotificationActionButton button in _actionButtons!) {
        Map<String, dynamic> data = button.toMap();
        if (data.isNotEmpty) actionButtonsData.add(data);
      }
    }
    return {
      'content': _content?.toMap() ?? {},
      'schedule': _schedule?.toMap() ?? {},
      'actionButtons': actionButtonsData.isEmpty ? null : actionButtonsData
    };
  }

  @override

  /// Validates if the models has all the requirements to be considerated valid
  void validate() {
    if (_content == null) {
      throw const AwesomeNotificationsException(
          message: 'content is required.');
    }
  }
}
