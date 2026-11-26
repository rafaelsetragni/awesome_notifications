/// Multi-language support for awesome_notifications.
///
/// Attach per-language translations to a notification with
/// [NotificationLocalizations] (passed to the core's `createNotification` via
/// `extensions`), and choose the language with
/// [AwesomeNotificationsLocalizations.setLocalization].
library;

import 'package:flutter/foundation.dart';
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

  /// Whether translation exists on this platform (Android, iOS, macOS, Windows
  /// and Linux; web is in progress). Elsewhere [setLocalization]
  /// answers false and [getLocalization] an empty code, instead of throwing.
  static bool get isPlatformSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);

  /// Sets the language notifications are translated into (null = system default).
  Future<bool> setLocalization({required String? languageCode}) async {
    if (!isPlatformSupported) return false;
    final result =
        await _channel.invokeMethod<bool>('setLocalization', languageCode);
    return result ?? false;
  }

  /// The current language code used for translation.
  Future<String> getLocalization() async {
    if (!isPlatformSupported) return '';
    final result = await _channel.invokeMethod<String>('getLocalization');
    return result ?? '';
  }
}
