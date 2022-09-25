import 'dart:io' show Platform;

import 'package:flutter/services.dart';

import '../definitions.dart';
import '../enumerators/foreground_start_mode.dart';
import '../enumerators/foreground_service_type.dart';
import '../enumerators/android_foreground_service_constants.dart';
import '../models/notification_button.dart';
import '../models/notification_content.dart';
import '../models/notification_model.dart';
import '../utils/assert_utils.dart';

/// Static helper class that provides methods to start and stop a foreground service.
///
/// On any platform other than Android, all methods in this class are no-ops and do nothing,
/// so it is safe to call them without a platform check.
class AndroidForegroundService {
  static const MethodChannel _channel = MethodChannel(CHANNEL_FLUTTER_PLUGIN);

  /// Starts the foreground service with the given `notification`, which content must not be `null`.
  ///
  /// The notification can be updated by simply calling this method multiple times.
  ///
  /// Information on selecting a appropriate `startType` for your app's use case should be taken from the
  /// official Android documentation, check [`Service.onStartCommand`](https://developer.android.com/reference/android/app/Service#onStartCommand(android.content.Intent,%20int,%20int)).
  ///
  /// The [`notification.content.locked`](https://pub.dev/documentation/awesome_notifications/latest/awesome_notifications/NotificationContent/locked.html)
  /// property will be forced to `true` to archive an ongoing
  /// notification suitable for a foreground service. Also, [`notification.schedule`](https://pub.dev/documentation/awesome_notifications/latest/awesome_notifications/NotificationModel/schedule.html)
  /// will be cleared, since the notification needs to be shown right away when the foreground service is started.
  ///
  /// If `foregroundServiceType` is set, [`Service.startForeground(int id, Notification notification, int foregroundServiceType)`](https://developer.android.com/reference/android/app/Service#startForeground(int,%20android.app.Notification,%20int))
  /// will be invoked , else  [`Service.startForeground(int id, Notification notification)`](https://developer.android.com/reference/android/app/Service#startForeground(int,%20android.app.Notification)) is used.
  /// On devices older than [`Build.VERSION_CODES.Q`](https://developer.android.com/reference/android/os/Build.VERSION_CODES#Q), `foregroundServiceType` will be ignored.
  /// Multiple type flags can be ORed together (using the `|` operator).
  /// Note that `foregroundServiceType` must be a subset of the `android:foregroundServiceType` defined in your `AndroidManifest.xml`!
  ///
  /// On any platform other than Android, this is a no-op and does nothing, so it is safe to call it without a platform check.
  @Deprecated(
      "This method is deprecated. You should use startAndroidForegroundService instead.")
  static Future<void> startForeground(
      {required NotificationContent content,
      List<NotificationActionButton>? actionButtons,
      int startType = AndroidForegroundServiceConstants.startSticky,
      int? foregroundServiceType}) async {
    if (Platform.isAndroid) {
      startAndroidForegroundService(
        content: content,
        actionButtons: actionButtons,
        foregroundStartMode:
            AndroidForegroundServiceConstants.startModeFromAndroidValues(
                startType),
        foregroundServiceType:
            AndroidForegroundServiceConstants.serviceTypeFromAndroidValues(
                foregroundServiceType ?? 0),
      );
    }
  }

  /// Starts the foreground service with the given `notification`, which content must not be `null`.
  ///
  /// The notification can be updated by simply calling this method multiple times.
  ///
  /// Information on selecting a appropriate `startType` for your app's use case should be taken from the
  /// official Android documentation, check [`Service.onStartCommand`](https://developer.android.com/reference/android/app/Service#onStartCommand(android.content.Intent,%20int,%20int)).
  ///
  /// The [`notification.content.locked`](https://pub.dev/documentation/awesome_notifications/latest/awesome_notifications/NotificationContent/locked.html)
  /// property will be forced to `true` to archive an ongoing
  /// notification suitable for a foreground service. Also, [`notification.schedule`](https://pub.dev/documentation/awesome_notifications/latest/awesome_notifications/NotificationModel/schedule.html)
  /// will be cleared, since the notification needs to be shown right away when the foreground service is started.
  ///
  /// If `foregroundServiceType` is set, [`Service.startForeground(int id, Notification notification, int foregroundServiceType)`](https://developer.android.com/reference/android/app/Service#startForeground(int,%20android.app.Notification,%20int))
  /// will be invoked , else  [`Service.startForeground(int id, Notification notification)`](https://developer.android.com/reference/android/app/Service#startForeground(int,%20android.app.Notification)) is used.
  /// On devices older than [`Build.VERSION_CODES.Q`](https://developer.android.com/reference/android/os/Build.VERSION_CODES#Q), `foregroundServiceType` will be ignored.
  /// Multiple type flags can be ORed together (using the `|` operator).
  /// Note that `foregroundServiceType` must be a subset of the `android:foregroundServiceType` defined in your `AndroidManifest.xml`!
  ///
  /// On any platform other than Android, this is a no-op and does nothing, so it is safe to call it without a platform check.
  static Future<void> startAndroidForegroundService(
      {required NotificationContent content,
      List<NotificationActionButton>? actionButtons,
      ForegroundStartMode foregroundStartMode = ForegroundStartMode.stick,
      ForegroundServiceType foregroundServiceType =
          ForegroundServiceType.none}) async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod(CHANNEL_METHOD_START_FOREGROUND, {
        FOREGROUND_NOTIFICATION_MODEL:
            NotificationModel(content: content, actionButtons: actionButtons)
                .toMap(),
        FOREGROUND_START_MODE:
            AwesomeAssertUtils.toSimpleEnumString(foregroundStartMode),
        FOREGROUND_SERVICE_TYPE:
            AwesomeAssertUtils.toSimpleEnumString(foregroundServiceType)
      });
    }
  }

  /// Stops a foreground service.
  ///
  /// If the foreground service was not started, this function
  /// will do nothing.
  ///
  /// It is sufficient to call this method once to stop the
  /// foreground service, even if [startAndroidForegroundService] was called
  /// multiple times.
  ///
  /// On any platform other than Android, this is a no-op and does nothing,
  /// so it is safe to call it without a platform check.
  static Future<void> stopForeground(int id) async {
    if (Platform.isAndroid) {
      await _channel
          .invokeMethod(CHANNEL_METHOD_STOP_FOREGROUND, {NOTIFICATION_ID: id});
    }
  }

  /// The constructor is hidden since this class should not be instantiated.
  const AndroidForegroundService._();
}
