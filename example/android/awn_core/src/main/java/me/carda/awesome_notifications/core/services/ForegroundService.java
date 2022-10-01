package me.carda.awesome_notifications.core.services;

import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.IBinder;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.io.Serializable;
import java.util.HashMap;
import java.util.Map;

import me.carda.awesome_notifications.core.AwesomeNotifications;
import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.builders.NotificationBuilder;
import me.carda.awesome_notifications.core.completion_handlers.NotificationThreadCompletionHandler;
import me.carda.awesome_notifications.core.enumerators.ForegroundServiceType;
import me.carda.awesome_notifications.core.enumerators.ForegroundStartMode;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.logs.Logger;
import me.carda.awesome_notifications.core.managers.LifeCycleManager;
import me.carda.awesome_notifications.core.models.NotificationModel;
import me.carda.awesome_notifications.core.threads.NotificationForegroundSender;

public class ForegroundService extends Service {

    private static final String TAG = "ForegroundService";

    private static final Map<Integer, ForegroundService> serviceStack = new HashMap<>();
    private static final Map<Integer, ForegroundServiceIntent> serviceIntentStack = new HashMap<>();

    public static void startNewForegroundService(
        @NonNull Context applicationContext,
        @NonNull NotificationModel notificationModel,
        @NonNull ForegroundStartMode foregroundStartMode,
        @NonNull ForegroundServiceType foregroundServiceType
    ){
        ForegroundServiceIntent foregroundServiceIntent =
                new ForegroundServiceIntent(
                        notificationModel,
                        foregroundStartMode,
                        foregroundServiceType);

        int id = notificationModel.content.id;//IntegerUtils.generateNextRandomId();
        serviceIntentStack.put(id, foregroundServiceIntent);

        Intent intent = new Intent(applicationContext, ForegroundService.class);
        intent.putExtra(Definitions.AWESOME_FOREGROUND_ID, id);

        if (Build.VERSION.SDK_INT >=  Build.VERSION_CODES.O /*Android 8*/)
            applicationContext.startForegroundService(intent);
        else
            applicationContext.startService(intent);
    }


    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        int id = intent.getIntExtra(Definitions.AWESOME_FOREGROUND_ID, -1);
        ForegroundServiceIntent serviceIntent = serviceIntentStack.remove(id);

        if(!(id == -1 || serviceIntent == null)){

            final int notificationId = serviceIntent.notificationModel.content.id;
            ForegroundService foregroundService = serviceStack.remove(notificationId);
            if(foregroundService != null)
                foregroundService.stopSelf();

            serviceStack.put(notificationId, this);

            try {
                NotificationForegroundSender.start(
                        this,
                        NotificationBuilder.getNewBuilder(),
                        serviceIntent,
                        LifeCycleManager.getApplicationLifeCycle(),
                        new NotificationThreadCompletionHandler() {
                            @Override
                            public void handle(
                                    boolean success,
                                    @Nullable AwesomeNotificationsException exception) {
                                if(!success)
                                    serviceStack.remove(notificationId);
                            }
                        });
                return serviceIntent.startMode.toAndroidStartMode();

            } catch (AwesomeNotificationsException ignore) {
            }
        }

        stopSelf();
        return ForegroundStartMode.notStick.toAndroidStartMode();

    }

    public static boolean serviceIsRunning(
        @NonNull Integer notificationId
    ){
        return serviceStack.containsKey(notificationId);
    }

    public static void stop(
        @NonNull Integer notificationId
    ){
        ForegroundService foregroundService = serviceStack.remove(notificationId);
        if(foregroundService != null) {
            foregroundService.stopSelf();
            if(AwesomeNotifications.debug)
                Logger.d(TAG, "Foreground service "+ notificationId +" id stopped");
        }
        else {
            if(AwesomeNotifications.debug)
                Logger.d(TAG, "Foreground service "+ notificationId +" id not found");
        }
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    // This class is used to transport parameters from the platform channel through an intent to the service
    public static class ForegroundServiceIntent implements Serializable {

        // Explicitly use HashMap here since it is serializable
        public final NotificationModel notificationModel;
        public final ForegroundStartMode startMode;
        public final ForegroundServiceType foregroundServiceType;

        public ForegroundServiceIntent(
                @NonNull NotificationModel notificationModel,
                @NonNull ForegroundStartMode foregroundStartMode,
                @NonNull ForegroundServiceType foregroundServiceType
        ){
            this.notificationModel = notificationModel;
            this.startMode = foregroundStartMode;
            this.foregroundServiceType = foregroundServiceType;
        }

        @Override
        public @NonNull
        String toString() {
            return "StartParameter{" +
                    "notification=" + notificationModel +
                    ", startMode=" + startMode +
                    ", foregroundServiceType=" + foregroundServiceType +
                    '}';
        }
    }

}
