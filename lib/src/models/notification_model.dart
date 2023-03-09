import 'package:awesome_notifications/src/definitions.dart';
import 'package:awesome_notifications/src/exceptions/awesome_exception.dart';
import 'package:awesome_notifications/src/models/model.dart';
import 'package:awesome_notifications/src/models/notification_android_crontab.dart';
import 'package:awesome_notifications/src/models/notification_button.dart';
import 'package:awesome_notifications/src/models/notification_calendar.dart';
import 'package:awesome_notifications/src/models/notification_content.dart';
import 'package:awesome_notifications/src/models/notification_interval.dart';
import 'package:awesome_notifications/src/models/notification_localization.dart';
import 'package:awesome_notifications/src/models/notification_schedule.dart';

/// A model class representing a single notification instance.
///
/// The [NotificationModel] class encapsulates all the information needed to
/// display a single notification, including the notification's content, schedule,
/// action buttons, and localizations. Each instance of the class represents a
/// single notification that can be displayed to the user.
class NotificationModel extends Model {
  NotificationContent? _content;
  NotificationSchedule? _schedule;
  List<NotificationActionButton>? _actionButtons;
  Map<String, NotificationLocalization>? _localizations;

  /// The content of the notification.
  NotificationContent? get content => _content;

  /// The schedule to display the notification.
  NotificationSchedule? get schedule => _schedule;

  /// The action buttons for the notification.
  List<NotificationActionButton>? get actionButtons => _actionButtons;

  /// The localizations for the notification.
  Map<String, NotificationLocalization>? get localizations => _localizations;

  /// Creates a new instance of the [NotificationModel] class with the given
  /// content, schedule, action buttons, and localizations.
  NotificationModel({
    NotificationContent? content,
    NotificationSchedule? schedule,
    List<NotificationActionButton>? actionButtons,
    Map<String, NotificationLocalization>? localizations,
  })  : _content = content,
        _schedule = schedule,
        _actionButtons = actionButtons,
        _localizations = localizations;

  /// Imports data from a serializable object
  @override
  NotificationModel? fromMap(Map<String, dynamic> mapData) {
    try {
      _content = _extractContentFromMap(mapData);
      _schedule = _extractScheduleFromMap(mapData);
      _actionButtons = _extractButtonsFromMap(mapData);
      _localizations = _extractLocalizationsFromMap(mapData);
    } catch (e) {
      return null;
    }
    return this;
  }

  NotificationContent _extractContentFromMap(Map<String, dynamic> mapData) {
    assert(mapData[NOTIFICATION_CONTENT] is Map);

    NotificationContent? content =
        NotificationContent(id: 0, channelKey: '')
            .fromMap(Map<String, dynamic>.from(mapData[NOTIFICATION_CONTENT]));
    assert (content != null);

    return content!..validate();
  }

  NotificationSchedule? _extractScheduleFromMap(Map<String, dynamic> mapData) {
    if (mapData[NOTIFICATION_SCHEDULE] is! Map) return null;
    if (mapData[NOTIFICATION_SCHEDULE].isEmpty) return null;

    Map<String, dynamic> scheduleData =
        Map<String, dynamic>.from(Map<String, dynamic>.from(mapData[NOTIFICATION_SCHEDULE]));

    if (scheduleData.containsKey(NOTIFICATION_SCHEDULE_INTERVAL)) {
      return NotificationInterval(interval: 0).fromMap(scheduleData)?..validate();
    }

    if (
      scheduleData.containsKey(NOTIFICATION_CRONTAB_EXPRESSION) ||
      scheduleData.containsKey(NOTIFICATION_PRECISE_SCHEDULES)
    ) {
      return NotificationAndroidCrontab().fromMap(scheduleData)?..validate();
    }

    return NotificationCalendar().fromMap(scheduleData)?..validate();
  }

  List<NotificationActionButton>? _extractButtonsFromMap(Map<String, dynamic> mapData) {
    if (mapData[NOTIFICATION_BUTTONS] is! List) return null;
    if (mapData[NOTIFICATION_BUTTONS].isEmpty) return null;

    return (<dynamic>[
      for (dynamic buttonData in mapData[NOTIFICATION_BUTTONS])
        NotificationActionButton(label: '', key: '')
            .fromMap(Map<String, dynamic>.from(buttonData))?..validate()
    ]..removeWhere((element) => element == null)) as List<NotificationActionButton>;
  }

  Map<String, NotificationLocalization>? _extractLocalizationsFromMap(Map<String, dynamic> mapData) {
    if (mapData[NOTIFICATION_LOCALIZATIONS] is! Map<String, dynamic>) return null;
    if (mapData[NOTIFICATION_LOCALIZATIONS].isEmpty) return null;

    return (
      <String, dynamic>{
      for (MapEntry<String, dynamic> entry in mapData[NOTIFICATION_LOCALIZATIONS].entries)
        if (entry.value is Map<String, dynamic>)
          entry.key: NotificationLocalization().fromMap(entry.value)?..validate()
      }..removeWhere((key, value) => value == null)
    ) as Map<String, NotificationLocalization>;
  }

  /// Exports all content into a serializable object
  @override
  Map<String, dynamic> toMap() => {
      NOTIFICATION_CONTENT: _content?.toMap() ?? {},
      if (_schedule != null)
        NOTIFICATION_SCHEDULE: _schedule!.toMap(),
      if (_actionButtons?.isNotEmpty ?? false)
        NOTIFICATION_BUTTONS: [
          for (NotificationActionButton button in _actionButtons!)
            button.toMap()
        ],
      if (_localizations?.isNotEmpty ?? false)
        NOTIFICATION_LOCALIZATIONS: {
            for (MapEntry<String, NotificationLocalization> localization in _localizations!.entries)
              localization.key: localization.value.toMap()
        },
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
