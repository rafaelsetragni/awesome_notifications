import 'package:awesome_notifications/src/definitions.dart';
import 'package:awesome_notifications/src/exceptions/awesome_notifications_exception.dart';
import 'package:awesome_notifications/src/models/model.dart';
import 'package:awesome_notifications/src/models/notification_action_button.dart';
import 'package:awesome_notifications/src/models/notification_content.dart';
import 'package:awesome_notifications/src/models/notification_schedule.dart';

/// A model class representing a single notification instance.
///
/// The [NotificationModel] class encapsulates all the information needed to
/// display a single notification, including the notification's content,
/// schedule, and action buttons.
///
/// Scheduling is provided by an opt-in decorator package: the core keeps the
/// abstract [NotificationSchedule] slot (so serialization stays polymorphic and
/// the public API is preserved), but it does not know the concrete schedule
/// types. To reconstruct a concrete schedule from a map (e.g. when listing
/// scheduled notifications), the scheduling decorator registers
/// [scheduleDecoder]. When no decoder is registered, the schedule slot is left
/// untouched during deserialization.
class NotificationModel extends Model {
  /// Decodes a serialized schedule into a concrete [NotificationSchedule].
  ///
  /// Registered by the scheduling decorator package. The core never sets this.
  static NotificationSchedule? Function(Map<String, dynamic> scheduleData)?
      scheduleDecoder;

  NotificationContent? _content;
  NotificationSchedule? _schedule;
  List<NotificationActionButton>? _actionButtons;

  /// The content of the notification.
  NotificationContent? get content => _content;

  /// The schedule to display the notification.
  NotificationSchedule? get schedule => _schedule;

  /// The action buttons for the notification.
  List<NotificationActionButton>? get actionButtons => _actionButtons;

  /// Creates a new instance of the [NotificationModel] class with the given
  /// content, schedule, and action buttons.
  NotificationModel({
    NotificationContent? content,
    NotificationSchedule? schedule,
    List<NotificationActionButton>? actionButtons,
  })  : _content = content,
        _schedule = schedule,
        _actionButtons = actionButtons;

  /// Imports data from a serializable object
  @override
  NotificationModel? fromMap(Map<String, dynamic> mapData) {
    try {
      _content = _extractContentFromMap(mapData);
      _schedule = _extractScheduleFromMap(mapData);
      _actionButtons = _extractButtonsFromMap(mapData);
    } catch (e) {
      return null;
    }
    return this;
  }

  NotificationContent _extractContentFromMap(Map<String, dynamic> mapData) {
    assert(mapData[NOTIFICATION_CONTENT] is Map);

    NotificationContent? content = NotificationContent(id: 0, channelKey: '')
        .fromMap(Map<String, dynamic>.from(mapData[NOTIFICATION_CONTENT]));
    assert(content != null);

    return content!..validate();
  }

  NotificationSchedule? _extractScheduleFromMap(Map<String, dynamic> mapData) {
    if (mapData[NOTIFICATION_SCHEDULE] is! Map) return null;
    if (mapData[NOTIFICATION_SCHEDULE].isEmpty) return null;
    // Concrete schedule decoding lives in the scheduling decorator package.
    if (scheduleDecoder == null) return null;

    Map<String, dynamic> scheduleData =
        Map<String, dynamic>.from(mapData[NOTIFICATION_SCHEDULE]);

    return scheduleDecoder!(scheduleData)?..validate();
  }

  List<NotificationActionButton>? _extractButtonsFromMap(
      Map<String, dynamic> mapData) {
    if (mapData[NOTIFICATION_BUTTONS] is! List) return null;
    if (mapData[NOTIFICATION_BUTTONS].isEmpty) return null;

    List<NotificationActionButton> finalList = [];
    for (dynamic buttonData in mapData[NOTIFICATION_BUTTONS]) {
      NotificationActionButton? actionButton =
          NotificationActionButton(label: '', key: '')
              .fromMap(Map<String, dynamic>.from(buttonData))
            ?..validate();
      if (actionButton == null) continue;
      finalList.add(actionButton);
    }

    return finalList;
  }

  /// Exports all content into a serializable object
  @override
  Map<String, dynamic> toMap() => {
        NOTIFICATION_CONTENT: _content?.toMap() ?? {},
        if (_schedule != null) NOTIFICATION_SCHEDULE: _schedule!.toMap(),
        if (_actionButtons?.isNotEmpty ?? false)
          NOTIFICATION_BUTTONS: [
            for (NotificationActionButton button in _actionButtons!)
              button.toMap()
          ],
      };

  @override

  /// Validates if the models has all the requirements to be considered valid
  void validate() {
    if (_content == null) {
      throw const AwesomeNotificationsException(
          message: 'content is required.');
    }
  }
}
