package me.carda.awesome_notifications.awesome_notifications_core.threads;

import android.app.Notification;
import android.app.Service;
import android.content.Context;
import android.os.AsyncTask;
import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;

import java.lang.ref.WeakReference;

import me.carda.awesome_notifications.awesome_notifications_core.AwesomeNotifications;
import me.carda.awesome_notifications.awesome_notifications_core.broadcasters.senders.BroadcastSender;
import me.carda.awesome_notifications.awesome_notifications_core.builders.NotificationBuilder;
import me.carda.awesome_notifications.awesome_notifications_core.completion_handlers.ForegroundCompletionHandler;
import me.carda.awesome_notifications.awesome_notifications_core.enumerators.ForegroundServiceType;
import me.carda.awesome_notifications.awesome_notifications_core.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.awesome_notifications_core.enumerators.NotificationSource;
import me.carda.awesome_notifications.awesome_notifications_core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.awesome_notifications_core.models.NotificationModel;
import me.carda.awesome_notifications.awesome_notifications_core.models.returnedData.NotificationReceived;
import me.carda.awesome_notifications.awesome_notifications_core.services.ForegroundService;
import me.carda.awesome_notifications.awesome_notifications_core.utils.StringUtils;

public class NotificationForegroundSender extends NotificationThread<String, Void, NotificationModel> {

    public static String TAG = "NotificationSender";

    private final WeakReference<Context> wContextReference;

    private final NotificationBuilder notificationBuilder;
    private final ForegroundService.ForegroundServiceIntent foregroundServiceIntent;
    private final NotificationSource createdSource;
    private final NotificationLifeCycle appLifeCycle;
    private final ForegroundCompletionHandler foregroundCompletionHandler;

    private long startTime = 0L, endTime = 0L;

    private StringUtils stringUtils;

    public static void start(
            @NonNull Context applicationContext,
            @NonNull NotificationBuilder notificationBuilder,
            @NonNull ForegroundService.ForegroundServiceIntent foregroundServiceIntent,
            @NonNull NotificationLifeCycle appLifeCycle,
            @NonNull ForegroundCompletionHandler foregroundCompletionHandler
    ) throws AwesomeNotificationsException {

        if(foregroundServiceIntent.notificationModel == null)
            throw new AwesomeNotificationsException("Notification model is required");

        foregroundServiceIntent
                .notificationModel
                .validate(applicationContext);

        new NotificationForegroundSender(
            applicationContext,
            StringUtils.getInstance(),
            foregroundServiceIntent,
            notificationBuilder,
            appLifeCycle,
            foregroundCompletionHandler
        ).executeNotificationThread(
                foregroundServiceIntent.notificationModel);
    }

    private NotificationForegroundSender(
            Context context,
            StringUtils stringUtils,
            ForegroundService.ForegroundServiceIntent foregroundServiceIntent,
            NotificationBuilder notificationBuilder,
            NotificationLifeCycle appLifeCycle,
            ForegroundCompletionHandler foregroundCompletionHandler
    ) throws AwesomeNotificationsException {

        if(foregroundServiceIntent == null)
            throw new AwesomeNotificationsException("Foreground service intent is invalid");

        this.wContextReference = new WeakReference<>(context);
        this.foregroundServiceIntent = foregroundServiceIntent;
        this.foregroundCompletionHandler = foregroundCompletionHandler;
        this.notificationBuilder = notificationBuilder;
        this.appLifeCycle = appLifeCycle;
        this.createdSource = NotificationSource.ForegroundService;
        this.startTime = System.nanoTime();

        this.stringUtils = stringUtils;
    }

    /// AsyncTask METHODS BEGIN *********************************

    @Override
    protected NotificationModel doInBackground(String... parameters) {

        NotificationModel notificationModel
                = foregroundServiceIntent.notificationModel;

        try {

            notificationModel.content.registerCreatedEvent(appLifeCycle, createdSource);
            notificationModel.content.registerDisplayedEvent(appLifeCycle);

            if (
                stringUtils.isNullOrEmpty(notificationModel.content.title) &&
                stringUtils.isNullOrEmpty(notificationModel.content.body)
            )
                throw new AwesomeNotificationsException("A foreground service requires at least the title or body");

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
                        .createNewAndroidNotification(context, null, notificationModel);

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
