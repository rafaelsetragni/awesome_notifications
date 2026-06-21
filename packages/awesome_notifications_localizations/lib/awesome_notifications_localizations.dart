/// Localizations (translation) decorator for awesome_notifications.
///
/// This package adds no Dart API: the public localization surface
/// (`setLocalization`, `getLocalization`, `NotificationContent.localizations`,
/// `NotificationLocalization`) already lives in the core. Adding this package as
/// a dependency registers a native content transformer + method handler into the
/// core, so notifications are translated at build time without the core knowing
/// about localization — validating the builder decorator seam.
library;

/// Marker for the localizations decorator. The native plugin auto-registers on
/// engine attach; this type only documents the package's presence.
class AwesomeNotificationsLocalizations {
  const AwesomeNotificationsLocalizations._();
}
