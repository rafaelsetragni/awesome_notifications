/// Multi-language support for awesome_notifications.
///
/// Attach per-language translations to a notification with
/// [NotificationLocalizations] (passed to the core's `createNotification` via
/// `extensions`), and choose the language with
/// [AwesomeNotificationsLocalizations.setLocalization].
library;

import 'package:flutter/services.dart';

export 'src/notification_localization.dart';
export 'src/notification_localizations.dart';

/// Controls the language notifications are translated into.
///
/// Notifications themselves are created with the core
/// `AwesomeNotifications().createNotification(..., extensions: [
/// NotificationLocalizations({...})])`.
class AwesomeNotificationsLocalizations {
  static const MethodChannel _channel = MethodChannel('awesome_notifications');

  static final AwesomeNotificationsLocalizations _instance =
      AwesomeNotificationsLocalizations._();
  factory AwesomeNotificationsLocalizations() => _instance;
  AwesomeNotificationsLocalizations._();

  /// Sets the language notifications are translated into (null = system default).
  Future<bool> setLocalization({required String? languageCode}) async {
    final result =
        await _channel.invokeMethod<bool>('setLocalization', languageCode);
    return result ?? false;
  }

  /// The current language code used for translation.
  Future<String> getLocalization() async {
    final result = await _channel.invokeMethod<String>('getLocalization');
    return result ?? '';
  }
}
