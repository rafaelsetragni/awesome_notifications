package me.carda.awesome_notifications.core.enumerators;

import android.content.pm.ServiceInfo;
import java.util.Locale;

// https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_CAMERA
public enum ForegroundServiceType implements SafeEnum {

    /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_NONE`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_NONE).
    none("none"),
    /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_MANIFEST`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_MANIFEST).
    manifest("manifest"),
    /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_DATA_SYNC).
    dataSync("dataSync"),
    /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK).
    mediaPlayback("mediaPlayback"),
    /// Corresponds to [`Service.START_REDELIVER_INTENT`](https://developer.android.com/reference/android/app/Service#START_REDELIVER_INTENT).
    redeliveryIntent("redeliveryIntent"),
    /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_PHONE_CALL).
    phoneCall("phoneCall"),
    /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE).
    connectedDevice("connectedDevice"),
    /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION).
    mediaProjection("mediaProjection"),
    /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_LOCATION).
    location("location"),
    /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_CAMERA).
    camera("camera"),
    /// Corresponds to [`ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE`](https://developer.android.com/reference/android/content/pm/ServiceInfo#FOREGROUND_SERVICE_TYPE_MICROPHONE).
    microphone("microphone");

    private final String safeName;
    ForegroundServiceType(final String safeName){
        this.safeName = safeName.toLowerCase(Locale.ENGLISH);
    }

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

    @Override
    public String getSafeName() {
        return this.safeName;
    }

    static ForegroundServiceType[] valueList = ForegroundServiceType.class.getEnumConstants();
    public static ForegroundServiceType getSafeEnum(String reference) {
        if (reference == null) return null;
        int stringLength = reference.length();
        if (stringLength == 0) return null;

        if(valueList == null) return null;
        for (ForegroundServiceType candidate : valueList) {
            if (candidate.getSafeName().equalsIgnoreCase(reference)) {
                return candidate;
            }
        }
//        if (name == null) return null;
//        int stringLength = name.length();
//        if (stringLength == 0) return null;
//        if (SafeEnum.charMatches(name, stringLength, 0, 'p')){
//            return phoneCall;
//        }
//        else if (SafeEnum.charMatches(name, stringLength, 0, 'n')){
//            return none;
//        }
//        else if (SafeEnum.charMatches(name, stringLength, 0, 'c')){
//            if(SafeEnum.charMatches(name, stringLength, 1, 'a')) return camera;
//            return connectedDevice;
//        }
//        else if (SafeEnum.charMatches(name, stringLength, 0, 'm')){
//            if(SafeEnum.charMatches(name, stringLength, 1, 'i')) return microphone;
//            if(SafeEnum.charMatches(name, stringLength, 6, 'l')) return mediaPlayback;
//            if(SafeEnum.charMatches(name, stringLength, 6, 'r')) return mediaProjection;
//            return manifest;
//        }
//        else if (SafeEnum.charMatches(name, stringLength, 0, 'd')){
//            return dataSync;
//        }
//        else if (SafeEnum.charMatches(name, stringLength, 0, 'l')){
//            return location;
//        }
        return null;
    }
}
