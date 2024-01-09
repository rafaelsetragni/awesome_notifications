import '../../android_foreground_service.dart';

/// Static helper class that contains all relevant
/// Android foreground service related constants.
@Deprecated(
  "Please, use ForegroundServiceType and ForegroundStartMode instead.",
)
class AndroidForegroundServiceConstants {
  /// The constructor is hidden since this class should not be instantiated.
  const AndroidForegroundServiceConstants._();

  /// Corresponds to [`Service.START_STICKY_COMPATIBILITY`](https://developer.android.com/reference/android/app/Service#START_STICKY_COMPATIBILITY).
  static const startStickyCompatibility = 0;

  /// Corresponds to [`Service.START_STICKY`](https://developer.android.com/reference/android/app/Service#START_STICKY).
  static const startSticky = 1;

  /// Corresponds to [`Service.START_NOT_STICKY`](https://developer.android.com/reference/android/app/Service#START_NOT_STICKY).
  static const startNotSticky = 2;

  /// Corresponds to [`Service.START_REDELIVER_INTENT`](https://developer.android.com/reference/android/app/Service#START_REDELIVER_INTENT).
  static const startRedeliverIntent = 3;

  /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_MANIFEST`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_MANIFEST).
  static const int foregroundServiceTypeManifest = -1;

  /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_NONE`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_NONE).
  static const int foregroundServiceTypeNone = 0;

  /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_DATA_SYNC).
  static const int foregroundServiceTypeDataSync = 1;

  /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK).
  static const int foregroundServiceTypeMediaPlayback = 2;

  /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_PHONE_CALL).
  static const int foregroundServiceTypePhoneCall = 4;

  /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_LOCATION).
  static const int foregroundServiceTypeLocation = 8;

  /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE).
  static const int foregroundServiceTypeConnectedDevice = 16;

  /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION).
  static const int foregroundServiceTypeMediaProjection = 32;

  /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_CAMERA).
  static const int foregroundServiceTypeCamera = 64;

  /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_MICROPHONE).
  static const int foregroundServiceTypeMicrophone = 128;

  static ForegroundStartMode startModeFromAndroidValues(int value) {
    switch (value) {
      case 0:
        return ForegroundStartMode.stickCompatibility;
      case 2:
        return ForegroundStartMode.notStick;
      case 3:
        return ForegroundStartMode.redeliverIntent;
      case 1:
      default:
        return ForegroundStartMode.stick;
    }
  }

  static ForegroundServiceType serviceTypeFromAndroidValues(int value) {
    switch (value) {
      case -1:
        return ForegroundServiceType.manifest;
      case 1:
        return ForegroundServiceType.dataSync;
      case 2:
        return ForegroundServiceType.mediaPlayback;
      case 4:
        return ForegroundServiceType.phoneCall;
      case 8:
        return ForegroundServiceType.location;
      case 16:
        return ForegroundServiceType.connectedDevice;
      case 32:
        return ForegroundServiceType.mediaProjection;
      case 64:
        return ForegroundServiceType.camera;
      case 128:
        return ForegroundServiceType.microphone;
      case 0:
      default:
        return ForegroundServiceType.none;
    }
  }
}
