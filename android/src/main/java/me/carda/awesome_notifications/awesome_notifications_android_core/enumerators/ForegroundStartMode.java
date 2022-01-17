package me.carda.awesome_notifications.awesome_notifications_android_core.enumerators;

import static android.app.Service.START_NOT_STICKY;
import static android.app.Service.START_REDELIVER_INTENT;
import static android.app.Service.START_STICKY;

public enum ForegroundStartMode {

    stick,
    notStick,
    deliverIntent;

    public int toAndroidStartMode() {
        switch (this){
            case notStick: return START_NOT_STICKY;
            case deliverIntent: return START_REDELIVER_INTENT;
            case stick:
            default:
                return START_STICKY;
        }
    }
}
