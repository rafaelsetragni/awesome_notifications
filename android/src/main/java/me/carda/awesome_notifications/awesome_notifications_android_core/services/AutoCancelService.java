package me.carda.awesome_notifications.awesome_notifications_android_core.services;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;
import android.util.Log;

import androidx.annotation.Nullable;

public class AutoCancelService extends Service {

    String TAG = "AutoCancelService";

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    public void onTaskRemoved(Intent rootIntent) {
        Log.e(TAG, "TASK END");
        //unregister listeners
        //do any other cleanup if required

        //stop service
        stopSelf();
    }

}
