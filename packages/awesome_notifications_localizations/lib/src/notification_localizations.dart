import 'package:awesome_notifications/awesome_notifications.dart';

import 'notification_localization.dart';

/// Attaches per-language translations to a notification. Pass it to the core's
/// `createNotification` via `extensions`:
///
/// ```dart
/// await AwesomeNotifications().createNotification(
///   content: NotificationContent(/* ... */),
///   extensions: [
///     NotificationLocalizations({
///       'pt-br': NotificationLocalization(title: '...'),
///     }),
///   ],
/// );
/// ```
///
/// The notification is shown in the language set with
/// [AwesomeNotificationsLocalizations.setLocalization]; untranslated fields keep
/// the default content, and if the current language isn't in the map the default
/// is used.
class NotificationLocalizations implements NotificationExtension {
  /// Translations keyed by language code (e.g. `"en"`, `"pt-br"`).
  final Map<String, NotificationLocalization> localizations;

  const NotificationLocalizations(this.localizations);

  @override
  Map<String, dynamic> toMap() => {
        'localizations': {
          for (final entry in localizations.entries)
            entry.key: entry.value.toMap(),
        },
      };
}
