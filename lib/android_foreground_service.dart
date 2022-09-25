/// Provides mechanisms to start and stop an Android foreground service,
/// while utilizing [awesome_notifications.dart `NotificationModel`](https://pub.dev/documentation/awesome_notifications/latest/awesome_notifications/NotificationModel-class.html).
library android_foreground_service;

export 'src/enumerators/android_foreground_service_constants.dart';
export 'src/enumerators/foreground_service_type.dart';
export 'src/enumerators/foreground_start_mode.dart';
export 'src/android_foreground_service/android_foreground_service_web.dart'
    if (dart.library.io) 'src/android_foreground_service/android_foreground_service_core.dart';
