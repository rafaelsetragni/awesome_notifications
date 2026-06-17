import '../../awesome_notifications.dart';
import 'model.dart';

/// A model class that represents a set of localized strings for a notification,
/// including the title, body, summary, large icon, big picture, and button labels.
///
/// This class is used to provide localized strings for a notification. The [title]
/// and [body] fields are used to specify the main text of the notification, while
/// the [summary] field is used to provide a brief summary or additional context.
/// The [largeIcon] and [bigPicture] fields can be used to specify images or icons
/// that are displayed alongside the notification text, and the [buttonLabels] field
/// can be used to provide localized labels for the action buttons that are associated
/// with the notification.
class NotificationLocalization extends Model {
  String? title;
  String? body;
  String? summary;
  String? largeIcon;
  String? bigPicture;
  Map<String, String>? buttonLabels;

  /// Creates a new instance of the `NotificationLocalization` class. If any of
  /// the respective parameters is set to null, the original content is preserved.
  ///
  /// The optional [title] parameter is a string that represents the title of the
  /// notification.
  ///
  /// The optional [body] parameter is a string that represents the body text of
  /// the notification.
  ///
  /// The optional [summary] parameter is a string that represents a brief summary,
  /// subtitle or additional context for the notification.
  ///
  /// The optional [largeIcon] parameter is a string that represents the name or
  /// path of an image file that should be used as the large icon for the notification,
  /// for cases where the image contains some text that also needs translation.
  ///
  /// The optional [bigPicture] parameter is a string that represents the name or
  /// path of an image file that should be used as the big picture for the notification,
  /// for cases where the image contains some text that also needs translation.
  ///
  /// The optional [buttonLabels] parameter is a map that contains the localized
  /// labels for the action buttons that are associated with the notification.
  NotificationLocalization({
    this.title,
    this.body,
    this.summary,
    this.largeIcon,
    this.bigPicture,
    this.buttonLabels,
  });

  /// Parses the input [mapData] into a new [NotificationLocalization] instance.
  ///
  /// The [mapData] parameter is a [Map] that represents the data to be parsed.
  ///
  /// This method returns a [NotificationLocalization] instance that contains
  /// the parsed data. If the [mapData] parameter is null, empty or invalid,
  /// this method will return `null`.
  @override
  NotificationLocalization? fromMap(Map<String, dynamic> mapData) {
    if (mapData.isEmpty) return null;

    title =
        AwesomeAssertUtils.extractValue<String>(NOTIFICATION_TITLE, mapData);
    body = AwesomeAssertUtils.extractValue<String>(NOTIFICATION_BODY, mapData);
    summary =
        AwesomeAssertUtils.extractValue<String>(NOTIFICATION_SUMMARY, mapData);
    largeIcon = AwesomeAssertUtils.extractValue<String>(
        NOTIFICATION_LARGE_ICON, mapData);
    bigPicture = AwesomeAssertUtils.extractValue<String>(
        NOTIFICATION_BIG_PICTURE, mapData);

    buttonLabels = mapData[NOTIFICATION_BUTTON_LABELS] is Map
        ? {
            for (MapEntry entry
                in (mapData[NOTIFICATION_BUTTON_LABELS] as Map).entries)
              entry.key.toString(): entry.value.toString()
          }
        : null;
    return this;
  }

  /// Converts the current instance of [NotificationLocalization] to a [Map] instance.
  ///
  /// This method returns a [Map] instance that contains the converted data. If
  /// a field has a null value, it will not be added to the map. Finally, it
  /// returns the created map.
  @override
  Map<String, dynamic> toMap() => {
        if (title?.isNotEmpty ?? false) NOTIFICATION_TITLE: title,
        if (body?.isNotEmpty ?? false) NOTIFICATION_BODY: body,
        if (summary?.isNotEmpty ?? false) NOTIFICATION_SUMMARY: summary,
        if (bigPicture?.isNotEmpty ?? false)
          NOTIFICATION_BIG_PICTURE: bigPicture,
        if (largeIcon?.isNotEmpty ?? false) NOTIFICATION_LARGE_ICON: largeIcon,
        if (buttonLabels?.isNotEmpty ?? false)
          NOTIFICATION_BUTTON_LABELS: buttonLabels,
      };

  /// Validates the notification localization settings.
  @override
  void validate() {}
}
