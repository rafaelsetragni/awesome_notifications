library awesome_notifications_fcm;

import 'package:awesome_notifications_fcm/src/models/fcm_silent_data.dart';

export 'src/awesome_notifications_fcm_core.dart';
export 'src/models/fcm_silent_data.dart';
export 'src/exceptions/exceptions.dart';

/// Callback that receives a new FCM (or native APNs) registration token.
typedef PushTokenHandler = Future<void> Function(String token);

/// Callback that receives a silent (data-only) push message, delivered even when
/// the app is in background or terminated (runs in a dedicated Dart isolate).
typedef FcmSilentDataHandler = Future<void> Function(FcmSilentData silentData);
