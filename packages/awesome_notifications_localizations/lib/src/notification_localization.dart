import 'package:awesome_notifications/awesome_notifications.dart';

/// A set of localized strings for a notification — title, body, summary, large
/// icon, big picture and action button labels — for one language.
///
/// Provided through [AwesomeNotificationsLocalizations.createNotification]'s
/// `localizations` map (keyed by language code, e.g. "en", "pt-br"). The native
/// decorator picks the entry matching the current language at build time and
/// overwrites the corresponding content. Fields left null keep the original.
class NotificationLocalization {
  String? title;
  String? body;
  String? summary;
  String? largeIcon;
  String? bigPicture;
  Map<String, String>? buttonLabels;

  NotificationLocalization({
    this.title,
    this.body,
    this.summary,
    this.largeIcon,
    this.bigPicture,
    this.buttonLabels,
  });

  /// Parses [mapData] into a [NotificationLocalization], or null when empty.
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
            for (final MapEntry entry
                in (mapData[NOTIFICATION_BUTTON_LABELS] as Map).entries)
              entry.key.toString(): entry.value.toString()
          }
        : null;
    return this;
  }

  /// Serializes to a map (null/empty fields are omitted).
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
}
