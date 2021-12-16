package me.carda.awesome_notifications.awesome_notifications_android_core.services;

import android.app.ActivityManager;
import android.app.Notification;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.IBinder;

import androidx.annotation.NonNull;

import java.io.Serializable;
import java.util.HashMap;
import java.util.Map;

import me.carda.awesome_notifications.awesome_notifications_android_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_android_core.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.awesome_notifications_android_core.models.NotificationModel;
import me.carda.awesome_notifications.awesome_notifications_android_core.notifications.NotificationBuilder;

public class ForegroundService extends Service {

    private static Map<Integer, ForegroundServiceIntent> serviceStack = new HashMap<>();

    public static boolean isForegroundServiceRunning(Context context) {
        ActivityManager manager = (ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);

        for (ActivityManager.RunningServiceInfo service : manager.getRunningServices(Integer.MAX_VALUE))
            if (ForegroundService.class.getName().equals(service.service.getClassName()))
                if (service.foreground)
                    return true;

        return false;
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        int foregroundId = intent.getIntExtra(Definitions.AWESOME_FOREGROUND_ID, -1);
        ForegroundServiceIntent foregroundServiceIntent = serviceStack.get(foregroundId);
        assert foregroundServiceIntent != null;

        try {
            NotificationModel notificationModel = foregroundServiceIntent.notificationModel;
            Notification androidNotification;

            androidNotification =
                    NotificationBuilder
                            .getInstance()
                            .createNewAndroidNotification(this, notificationModel);

            if (foregroundServiceIntent.hasForegroundServiceType && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(foregroundId, androidNotification, foregroundServiceIntent.foregroundServiceType);
            } else {
                startForeground(foregroundId, androidNotification);
            }
        } catch (AwesomeNotificationException e) {
            e.printStackTrace();
        }

        return foregroundServiceIntent.startMode;
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    // This class is used to transport parameters from the platform channel through an intent to the service
    public static class ForegroundServiceIntent implements Serializable {

        // Explicitly use HashMap here since it is serializable
        public final NotificationModel notificationModel;
        public final int startMode;
        public final boolean hasForegroundServiceType;
        public final int foregroundServiceType;

        public ForegroundServiceIntent(
                @NonNull NotificationModel notificationModel,
                int startMode,
                boolean hasForegroundServiceType,
                int foregroundServiceType) {

            this.notificationModel = notificationModel;
            this.startMode = startMode;
            this.hasForegroundServiceType = hasForegroundServiceType;
            this.foregroundServiceType = foregroundServiceType;
        }

        @Override
        public @NonNull
        String toString() {
            return "StartParameter{" +
                    "notification=" + notificationModel.toString() +
                    ", startMode=" + startMode +
                    ", hasForegroundServiceType=" + hasForegroundServiceType +
                    ", foregroundServiceType=" + foregroundServiceType +
                    '}';
        }
    }

}
