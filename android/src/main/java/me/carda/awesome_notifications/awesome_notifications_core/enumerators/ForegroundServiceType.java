package me.carda.awesome_notifications.awesome_notifications_core.enumerators;

import android.content.pm.ServiceInfo;

// https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_CAMERA
public enum ForegroundServiceType {

    /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_NONE`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_NONE).
    none,
    /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_MANIFEST`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_MANIFEST).
    manifest,
    /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_DATA_SYNC).
    dataSync,
    /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK).
    mediaPlayback,
    /// Corresponds to [`Service.START_REDELIVER_INTENT`](https://developer.android.com/reference/android/app/Service#START_REDELIVER_INTENT).
    redeliveryIntent,
    /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_PHONE_CALL).
    phoneCall,
    /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE).
    connectedDevice,
    /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION).
    mediaProjection,
    /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_LOCATION).
    location,
    /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_CAMERA).
    camera,
    /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_MICROPHONE).
    microphone;

    public int toAndroidServiceType() {
        switch (this){
            case camera:            return ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA;
            case connectedDevice:   return ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE;
            case dataSync:          return ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC;
            case location:          return ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION;
            case manifest:          return ServiceInfo.FOREGROUND_SERVICE_TYPE_MANIFEST;
            case mediaPlayback:     return ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK;
            case mediaProjection:   return ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION;
            case microphone:        return ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE;
            case phoneCall:         return ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL;
            case none:
            default:
                return ServiceInfo.FOREGROUND_SERVICE_TYPE_NONE;
        }
    }
}
