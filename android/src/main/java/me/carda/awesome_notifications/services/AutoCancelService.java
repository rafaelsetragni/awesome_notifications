package me.carda.awesome_notifications.services;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;
import io.flutter.Log;

import androidx.annotation.Nullable;

public class AutoCancelService extends Service {

    String TAG = "ClearFromRecentService";

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
