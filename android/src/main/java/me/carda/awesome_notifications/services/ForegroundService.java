package me.carda.awesome_notifications.services;

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

import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.notifications.models.NotificationModel;
import me.carda.awesome_notifications.notifications.NotificationBuilder;

public class ForegroundService extends Service {

    private final NotificationBuilder builder;

    public ForegroundService() {
        super();
        this.builder = new NotificationBuilder();
    }

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
        StartParameter parameter = (StartParameter) intent.getSerializableExtra(StartParameter.EXTRA);
        NotificationModel notificationModel = new NotificationModel().fromMap(parameter.notificationData);

        int notificationId = notificationModel.content.id;
        Notification notification;

        try {
            notification = builder.createNotification(this, notificationModel);
        } catch (AwesomeNotificationException e) {
            throw new RuntimeException(e);
        }
        if (parameter.hasForegroundServiceType && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(notificationId, notification, parameter.foregroundServiceType);
        } else {
            startForeground(notificationId, notification);
        }
        return parameter.startMode;
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    // This class is used to transport parameters from the platform channel through an intent to the service
    public static class StartParameter implements Serializable {

        public final static String EXTRA = "me.carda.awesome_notifications.services.ForegroundService$StartParameter";

        // Explicitly use HashMap here since it is serializable
        public final HashMap<String, Object> notificationData;
        public final int startMode;
        public final boolean hasForegroundServiceType;
        public final int foregroundServiceType;

        public StartParameter(Map<String, Object> notificationData, int startMode, boolean hasForegroundServiceType, int foregroundServiceType) {
            if (notificationData instanceof HashMap) {
                this.notificationData = (HashMap<String, Object>) notificationData;
            } else {
                this.notificationData = new HashMap<>(notificationData);
            }
            this.startMode = startMode;
            this.hasForegroundServiceType = hasForegroundServiceType;
            this.foregroundServiceType = foregroundServiceType;
        }

        @Override
        public @NonNull
        String toString() {
            return "StartParameter{" +
                    "notificationData=" + notificationData +
                    ", startMode=" + startMode +
                    ", hasForegroundServiceType=" + hasForegroundServiceType +
                    ", foregroundServiceType=" + foregroundServiceType +
                    '}';
        }
    }

}
