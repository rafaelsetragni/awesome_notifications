import 'package:awesome_notifications/src/definitions.dart';
import 'package:awesome_notifications/src/exceptions/awesome_notifications_exception.dart';
import 'package:awesome_notifications/src/models/model.dart';
import 'package:awesome_notifications/src/models/notification_action_button.dart';
import 'package:awesome_notifications/src/models/notification_content.dart';

/// A model class representing a single notification instance.
///
/// The [NotificationModel] class encapsulates the information the core needs to
/// display a single notification: its content and action buttons. Optional
/// add-on data (scheduling, localizations, …) is attached at creation time via
/// `createNotification(extensions: [...])` and rides in the serialized map as
/// sibling keys the core does not interpret — so the core stays feature-agnostic.
class NotificationModel extends Model {
  NotificationContent? _content;
  List<NotificationActionButton>? _actionButtons;

  /// The content of the notification.
  NotificationContent? get content => _content;

  /// The action buttons for the notification.
  List<NotificationActionButton>? get actionButtons => _actionButtons;

  /// Creates a new instance of the [NotificationModel] class with the given
  /// content and action buttons.
  NotificationModel({
    NotificationContent? content,
    List<NotificationActionButton>? actionButtons,
  })  : _content = content,
        _actionButtons = actionButtons;

  /// Imports data from a serializable object
  @override
  NotificationModel? fromMap(Map<String, dynamic> mapData) {
    try {
      _content = _extractContentFromMap(mapData);
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
