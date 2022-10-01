package me.carda.awesome_notifications.core.threads;

import android.app.Notification;
import android.app.Service;
import android.content.Context;
import android.os.Build;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.lang.ref.WeakReference;

import me.carda.awesome_notifications.core.AwesomeNotifications;
import me.carda.awesome_notifications.core.broadcasters.senders.BroadcastSender;
import me.carda.awesome_notifications.core.builders.NotificationBuilder;
import me.carda.awesome_notifications.core.completion_handlers.NotificationThreadCompletionHandler;
import me.carda.awesome_notifications.core.enumerators.ForegroundServiceType;
import me.carda.awesome_notifications.core.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.core.enumerators.NotificationSource;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.core.exceptions.ExceptionFactory;
import me.carda.awesome_notifications.core.logs.Logger;
import me.carda.awesome_notifications.core.models.NotificationModel;
import me.carda.awesome_notifications.core.models.returnedData.NotificationReceived;
import me.carda.awesome_notifications.core.services.ForegroundService;
import me.carda.awesome_notifications.core.utils.StringUtils;

public class NotificationForegroundSender extends NotificationThread<NotificationModel> {

    public static String TAG = "NotificationSender";

    private final WeakReference<Context> wContextReference;

    private final NotificationBuilder notificationBuilder;
    private final ForegroundService.ForegroundServiceIntent foregroundServiceIntent;
    private final NotificationSource createdSource;
    private final NotificationLifeCycle appLifeCycle;
    private final NotificationThreadCompletionHandler threadCompletionHandler;

    private long startTime = 0L, endTime = 0L;

    private final StringUtils stringUtils;

    public static void start(
            @NonNull Context applicationContext,
            @NonNull NotificationBuilder notificationBuilder,
            @NonNull ForegroundService.ForegroundServiceIntent foregroundServiceIntent,
            @NonNull NotificationLifeCycle appLifeCycle,
            @NonNull NotificationThreadCompletionHandler threadCompletionHandler
    ) throws AwesomeNotificationsException {

        if(foregroundServiceIntent.notificationModel == null)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Notification model is required",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".foreground.notificationModel");

        foregroundServiceIntent
                .notificationModel
                .validate(applicationContext);

        new NotificationForegroundSender(
            applicationContext,
            StringUtils.getInstance(),
            foregroundServiceIntent,
            notificationBuilder,
            appLifeCycle,
            threadCompletionHandler
        ).execute(
                foregroundServiceIntent.notificationModel);
    }

    private NotificationForegroundSender(
            Context context,
            StringUtils stringUtils,
            ForegroundService.ForegroundServiceIntent foregroundServiceIntent,
            NotificationBuilder notificationBuilder,
            NotificationLifeCycle appLifeCycle,
            NotificationThreadCompletionHandler threadCompletionHandler
    ) throws AwesomeNotificationsException {

        if(foregroundServiceIntent == null)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Foreground service intent is invalid",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".foreground.intent");

        this.wContextReference = new WeakReference<>(context);
        this.foregroundServiceIntent = foregroundServiceIntent;
        this.threadCompletionHandler = threadCompletionHandler;
        this.notificationBuilder = notificationBuilder;
        this.appLifeCycle = appLifeCycle;
        this.createdSource = NotificationSource.ForegroundService;
        this.startTime = System.nanoTime();

        this.stringUtils = stringUtils;
    }

    /// AsyncTask METHODS BEGIN *********************************

    @Override
    protected NotificationModel doInBackground() throws Exception {

        NotificationModel notificationModel
                = foregroundServiceIntent.notificationModel;

        notificationModel.content.registerCreatedEvent(appLifeCycle, createdSource);
        notificationModel.content.registerDisplayedEvent(appLifeCycle);

        if (
            stringUtils.isNullOrEmpty(notificationModel.content.title) &&
            stringUtils.isNullOrEmpty(notificationModel.content.body)
        )
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "A foreground service requires at least the title or body",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".foreground.intent");

        return showForegroundNotification(wContextReference.get(), notificationModel);
    }

    @Override
    protected NotificationModel onPostExecute(
            NotificationModel notificationModel
    ) throws AwesomeNotificationsException {

        // Only broadcast if notificationModel is valid
        if(notificationModel != null){

            NotificationReceived receivedNotification =
                    new NotificationReceived(
                            notificationModel.content,
                            null);

            receivedNotification.displayedLifeCycle = receivedNotification.displayedLifeCycle == null ?
                    appLifeCycle : receivedNotification.displayedLifeCycle;

            BroadcastSender.sendBroadcastNotificationCreated(
                    wContextReference.get(),
                    receivedNotification);


            BroadcastSender.sendBroadcastNotificationDisplayed(
                    wContextReference.get(),
                    receivedNotification);
        }

        if(this.endTime == 0L)
            this.endTime = System.nanoTime();

        if(AwesomeNotifications.debug){
            long elapsed = (endTime - startTime)/1000000;
            Logger.d(TAG, "Notification displayed in "+elapsed+"ms");
        }

        return notificationModel;
    }

    @Override
    protected void whenComplete(
            @Nullable NotificationModel notificationModel,
            @Nullable AwesomeNotificationsException exception
    ) throws AwesomeNotificationsException {
        if (threadCompletionHandler != null)
            threadCompletionHandler.handle(notificationModel != null, exception);
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
