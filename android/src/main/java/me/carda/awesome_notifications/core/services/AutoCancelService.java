package me.carda.awesome_notifications.core.services;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;
import me.carda.awesome_notifications.core.logs.Logger;

import androidx.annotation.Nullable;

public class AutoCancelService extends Service {

    String TAG = "AutoCancelService";

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    public void onTaskRemoved(Intent rootIntent) {
        Logger.d(TAG, "TASK END");
        //unregister listeners
        //do any other cleanup if required

        //stop service
        stopSelf();
    }

}
