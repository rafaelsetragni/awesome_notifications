import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'android_foreground_service_constants.dart';
import '../definitions.dart'
    show
        CHANNEL_FLUTTER_PLUGIN,
        CHANNEL_METHOD_START_FOREGROUND,
        CHANNEL_METHOD_STOP_FOREGROUND;
import '../models/notification_content.dart';
import '../models/received_models/push_notification.dart';

/// Static helper class that provides methods to start and stop a foreground service.
///
/// On any platform other than Android, all methods in this class are no-ops and do nothing,
/// so it is safe to call them without a platform check.
class AndroidForegroundService {
  static const MethodChannel _channel =
      const MethodChannel(CHANNEL_FLUTTER_PLUGIN);

  /// Starts the foreground service with the given `notification`, whichs content must not be `null`.
  ///
  /// The notification can be updated by simply calling this method multiple times.
  ///
  /// Information on selecting a appropriate `startType` for your app's usecase should be taken from the
  /// official Android documentation, check [`Service.onStartCommand`](https://developer.android.com/reference/android/app/Service#onStartCommand(android.content.Intent,%20int,%20int)).
  ///
  /// The [`notifcation.content.locked`](https://pub.dev/documentation/awesome_notifications/latest/awesome_notifications/NotificationContent/locked.html)
  /// property will be forced to `true` to achive an ongoing
  /// notificaiton suitable for a foreground service. Also, [`notification.schedule`](https://pub.dev/documentation/awesome_notifications/latest/awesome_notifications/PushNotification/schedule.html)
  /// will be cleared, since the notifcation needs to be shown right away when the foreground service is started.
  ///
  /// If `foregroundServiceType` is set, [`Service.startForeground(int id, Notification notification, int foregroundServiceType)`](https://developer.android.com/reference/android/app/Service#startForeground(int,%20android.app.Notification,%20int))
  /// will be invoked , else  [`Service.startForeground(int id, Notification notification)`](https://developer.android.com/reference/android/app/Service#startForeground(int,%20android.app.Notification)) is used.
  /// On devices older than [`Build.VERSION_CODES.Q`](https://developer.android.com/reference/android/os/Build.VERSION_CODES#Q), `foregroundServiceType` will be ignored.
  /// Multiple type flags can be ORed together (using the `|` operator).
  /// Note that `foregroundServiceType` must be a subset of the `android:foregroundServiceType` defined in your `AndroidManifest.xml`!
  ///
  /// On any platform other than Android, this is a no-op and does nothing, so it is safe to call it without a platform check.
  static Future<void> startForeground(
      {required PushNotification notification,
      int startType = AndroidForegroundServiceConstants.startSticky,
      int? foregroundServiceType}) async {
    if (Platform.isAndroid) {
      NotificationContent? content = notification.content;
      if (content == null) {
        throw new ArgumentError(
            'The content of notification must not be null!');
      }
      notification.schedule = null;
      content.locked = true;
      await _channel.invokeMethod(CHANNEL_METHOD_START_FOREGROUND, {
        'notificationData': notification.toMap(),
        'startType': startType,
        'hasForegroundServiceType': foregroundServiceType != null,
        'foregroundServiceType': foregroundServiceType ?? 0
      });
    }
  }

  /// Stops a foreground service.
  ///
  /// If the foreground service was not started, this function
  /// will do nothing.
  ///
  /// It is sufficient to call this method once to stop the
  /// foreground service, even if [startForeground] was called
  /// multiple times.
  ///
  /// On any platform other than Android, this is a no-op and does nothing,
  /// so it is safe to call it without a platform check.
  static Future<void> stopForeground() async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod(CHANNEL_METHOD_STOP_FOREGROUND);
    }
  }

  /// The constructor is hidden since this class should not be instantiated.
  const AndroidForegroundService._();
}
