package me.carda.awesome_notifications.awesome_notifications_android_core.threads;

import android.app.ActivityManager;
import android.app.Notification;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;

import java.lang.ref.WeakReference;

import me.carda.awesome_notifications.awesome_notifications_android_core.AwesomeNotifications;
import me.carda.awesome_notifications.awesome_notifications_android_core.broadcasters.senders.BroadcastSender;
import me.carda.awesome_notifications.awesome_notifications_android_core.builders.NotificationBuilder;
import me.carda.awesome_notifications.awesome_notifications_android_core.completion_handlers.ForegroundCompletionHandler;
import me.carda.awesome_notifications.awesome_notifications_android_core.enumerators.ForegroundServiceType;
import me.carda.awesome_notifications.awesome_notifications_android_core.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.awesome_notifications_android_core.enumerators.NotificationSource;
import me.carda.awesome_notifications.awesome_notifications_android_core.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.awesome_notifications_android_core.models.NotificationModel;
import me.carda.awesome_notifications.awesome_notifications_android_core.models.returnedData.NotificationReceived;
import me.carda.awesome_notifications.awesome_notifications_android_core.services.ForegroundService;
import me.carda.awesome_notifications.awesome_notifications_android_core.utils.DateUtils;
import me.carda.awesome_notifications.awesome_notifications_android_core.utils.StringUtils;

public class NotificationForegroundSender extends AsyncTask<String, Void, NotificationModel> {

    public static String TAG = "NotificationSender";

    private final WeakReference<Context> wContextReference;

    private final NotificationBuilder notificationBuilder;
    private final ForegroundService.ForegroundServiceIntent foregroundServiceIntent;
    private final NotificationSource createdSource;
    private final NotificationLifeCycle appLifeCycle;
    private final ForegroundCompletionHandler foregroundCompletionHandler;

    private long startTime = 0L, endTime = 0L;

    public static void start(
            @NonNull Context applicationContext,
            @NonNull NotificationBuilder notificationBuilder,
            @NonNull ForegroundService.ForegroundServiceIntent foregroundServiceIntent,
            @NonNull NotificationLifeCycle appLifeCycle,
            @NonNull ForegroundCompletionHandler foregroundCompletionHandler
    ) throws AwesomeNotificationException {

        if(foregroundServiceIntent.notificationModel == null)
            throw new AwesomeNotificationException("Notification model is required");

        foregroundServiceIntent
                .notificationModel
                .validate(applicationContext);

        new NotificationForegroundSender(
            applicationContext,
            foregroundServiceIntent,
            notificationBuilder,
            appLifeCycle,
            foregroundCompletionHandler
        ).execute();
    }

    private NotificationForegroundSender(
            Context context,
            ForegroundService.ForegroundServiceIntent foregroundServiceIntent,
            NotificationBuilder notificationBuilder,
            NotificationLifeCycle appLifeCycle,
            ForegroundCompletionHandler foregroundCompletionHandler) throws AwesomeNotificationException {

        if(foregroundServiceIntent == null)
            throw new AwesomeNotificationException("Foreground service intent is invalid");

        this.wContextReference = new WeakReference<>(context);
        this.foregroundServiceIntent = foregroundServiceIntent;
        this.foregroundCompletionHandler = foregroundCompletionHandler;
        this.notificationBuilder = notificationBuilder;
        this.appLifeCycle = appLifeCycle;
        this.createdSource = NotificationSource.ForegroundService;
        this.startTime = System.nanoTime();
    }

    /// AsyncTask METHODS BEGIN *********************************

    @Override
    protected NotificationModel doInBackground(String... parameters) {

        NotificationModel notificationModel
                = foregroundServiceIntent.notificationModel;

        try {

            if(notificationModel.content.createdSource == null)
                notificationModel.content.createdSource = createdSource;

            if(notificationModel.content.createdLifeCycle == null)
                notificationModel.content.createdLifeCycle = appLifeCycle;

            if(notificationModel.content.displayedLifeCycle == null)
                notificationModel.content.displayedLifeCycle = appLifeCycle;

            notificationModel.content.displayedDate = DateUtils.getUTCDate();

            if (
                StringUtils.isNullOrEmpty(notificationModel.content.title) &&
                StringUtils.isNullOrEmpty(notificationModel.content.body)
            )
                throw new AwesomeNotificationException("A foreground service requires at least the title or body");

            return showForegroundNotification(wContextReference.get(), notificationModel);

        } catch (Exception e) {
            e.printStackTrace();
        }

        return null;
    }

    @Override
    protected void onPostExecute(NotificationModel notificationModel) {

        // Only broadcast if notificationModel is valid
        if(notificationModel != null){

            NotificationReceived receivedNotification = new NotificationReceived(notificationModel.content);
            receivedNotification.displayedLifeCycle = receivedNotification.displayedLifeCycle == null ?
                    appLifeCycle : receivedNotification.displayedLifeCycle;

            BroadcastSender.sendBroadcastNotificationCreated(
                wContextReference.get(),
                receivedNotification);


            BroadcastSender.sendBroadcastNotificationDisplayed(
                wContextReference.get(),
                receivedNotification);
        }

        this.foregroundCompletionHandler
                .handle(notificationModel);

        if(this.endTime == 0L)
            this.endTime = System.nanoTime();

        if(AwesomeNotifications.debug){
            long elapsed = (endTime - startTime)/1000000;
            Log.d(TAG, "Notification displayed in "+elapsed+"ms");
        }
    }

    /// AsyncTask METHODS END *********************************

    public NotificationModel showForegroundNotification(Context context, NotificationModel notificationModel) {

        try {

            NotificationLifeCycle lifeCycle = AwesomeNotifications.getApplicationLifeCycle();

            if(
                (lifeCycle == NotificationLifeCycle.AppKilled) ||
                (lifeCycle == NotificationLifeCycle.Foreground && notificationModel.content.displayOnForeground) ||
                (lifeCycle == NotificationLifeCycle.Background && notificationModel.content.displayOnBackground)
            ){

                Notification androidNotification = notificationBuilder
                        .createNewAndroidNotification(context, notificationModel);

                if (
                    androidNotification != null &&
                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
                    foregroundServiceIntent.foregroundServiceType != ForegroundServiceType.none
                ){
                    ((Service) context).startForeground(
                            notificationModel.content.id,
                            androidNotification,
                            foregroundServiceIntent.foregroundServiceType.toAndroidServiceType());
                } else {
                    ((Service) context).startForeground(
                            notificationModel.content.id,
                            androidNotification);
                }
            }

            return notificationModel;

        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }
}
