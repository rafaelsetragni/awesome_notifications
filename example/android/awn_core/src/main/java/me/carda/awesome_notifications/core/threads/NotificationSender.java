package me.carda.awesome_notifications.core.threads;

import android.app.Notification;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

import androidx.annotation.Nullable;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.List;

import me.carda.awesome_notifications.core.AwesomeNotifications;
import me.carda.awesome_notifications.core.broadcasters.senders.BroadcastSender;
import me.carda.awesome_notifications.core.builders.NotificationBuilder;
import me.carda.awesome_notifications.core.completion_handlers.NotificationThreadCompletionHandler;
import me.carda.awesome_notifications.core.enumerators.NotificationLayout;
import me.carda.awesome_notifications.core.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.core.enumerators.NotificationSource;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.core.exceptions.ExceptionFactory;
import me.carda.awesome_notifications.core.logs.Logger;
import me.carda.awesome_notifications.core.managers.ScheduleManager;
import me.carda.awesome_notifications.core.managers.StatusBarManager;
import me.carda.awesome_notifications.core.models.NotificationModel;
import me.carda.awesome_notifications.core.models.returnedData.NotificationReceived;
import me.carda.awesome_notifications.core.utils.IntegerUtils;
import me.carda.awesome_notifications.core.utils.StringUtils;

public class NotificationSender extends NotificationThread<NotificationReceived> {

    public static String TAG = "NotificationSender";

    private final WeakReference<Context> wContextReference;

    private final NotificationBuilder notificationBuilder;
    private final NotificationSource createdSource;
    private final NotificationLifeCycle appLifeCycle;
    private final Intent originalIntent;

    private NotificationModel notificationModel;
    private final NotificationThreadCompletionHandler threadCompletionHandler;

    private Boolean created = false;
    private Boolean displayed = false;

    private long startTime = 0L, endTime = 0L;

    private final StringUtils stringUtils;

    /// FACTORY METHODS BEGIN *********************************

    public static void send(
            Context context,
            NotificationBuilder notificationBuilder,
            NotificationLifeCycle appLifeCycle,
            NotificationModel notificationModel,
            NotificationThreadCompletionHandler threadCompletionHandler
    ) throws AwesomeNotificationsException {

        NotificationSender.send(
                context,
                notificationBuilder,
                notificationModel.content.createdSource,
                appLifeCycle,
                notificationModel,
                null,
                threadCompletionHandler);
    }

    public static void send(
        Context context,
        NotificationBuilder notificationBuilder,
        NotificationSource createdSource,
        NotificationLifeCycle appLifeCycle,
        NotificationModel notificationModel,
        Intent originalIntent,
        NotificationThreadCompletionHandler threadCompletionHandler
    ) throws AwesomeNotificationsException {

        if (notificationModel == null )
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Notification cannot be empty or null",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".sender.notificationModel");

        new NotificationSender(
            context,
            StringUtils.getInstance(),
            notificationBuilder,
            appLifeCycle,
            createdSource,
            notificationModel,
            originalIntent,
            threadCompletionHandler
        ).execute(notificationModel);
    }

    private NotificationSender(
            Context context,
            StringUtils stringUtils,
            NotificationBuilder notificationBuilder,
            NotificationLifeCycle appLifeCycle,
            NotificationSource createdSource,
            NotificationModel notificationModel,
            Intent originalIntent,
            NotificationThreadCompletionHandler threadCompletionHandler
    ){
        this.wContextReference = new WeakReference<>(context);
        this.notificationBuilder = notificationBuilder;
        this.createdSource = createdSource;
        this.appLifeCycle = appLifeCycle;
        this.notificationModel = notificationModel;
        this.originalIntent = originalIntent;
        this.threadCompletionHandler = threadCompletionHandler;

        this.startTime = System.nanoTime();
        this.stringUtils = stringUtils;
    }

    /// AsyncTask METHODS BEGIN *********************************

    @Override
    protected NotificationReceived doInBackground() throws Exception {
        if (notificationModel != null){

            created = notificationModel
                        .content
                        .registerCreatedEvent(
                            appLifeCycle,
                            createdSource);

            if (
                !stringUtils.isNullOrEmpty(notificationModel.content.title) ||
                !stringUtils.isNullOrEmpty(notificationModel.content.body)
            ){
                displayed = notificationModel
                        .content
                        .registerDisplayedEvent(
                                appLifeCycle);

                notificationModel = showNotification(
                        wContextReference.get(),
                        notificationModel,
                        originalIntent);
            }

            // Only save DisplayedMethods if notificationModel was created
            // and displayed successfully
            if(notificationModel != null)
                return new NotificationReceived(
                        notificationModel.content,
                        originalIntent);
        }

        return null;
    }

    @Override
    protected NotificationReceived onPostExecute(
            NotificationReceived receivedNotification
    ) throws AwesomeNotificationsException {

        // Only broadcast if notificationModel is valid
        if(receivedNotification != null){

            if(created) {
                ScheduleManager.cancelScheduleById(
                        wContextReference.get(),
                        String.valueOf(receivedNotification.id));

                BroadcastSender.sendBroadcastNotificationCreated(
                        wContextReference.get(),
                        receivedNotification);
            }

            if(displayed)
                BroadcastSender.sendBroadcastNotificationDisplayed(
                    wContextReference.get(),
                    receivedNotification);
        }

        if(this.endTime == 0L)
            this.endTime = System.nanoTime();

        if(AwesomeNotifications.debug){
            long elapsed = (endTime - startTime)/1000000;

            List<String> actionsTookList = new ArrayList<>();
            if(created) actionsTookList.add("created");
            if(displayed) actionsTookList.add("displayed");

            Logger.d(TAG, "Notification "+stringUtils.join(actionsTookList.iterator(), " and ")+" in "+elapsed+"ms");
        }

        return receivedNotification;
    }

    @Override
    protected void whenComplete(
            @Nullable NotificationReceived notificationReceived,
            @Nullable AwesomeNotificationsException exception
    ) throws AwesomeNotificationsException {
        if (threadCompletionHandler != null)
            threadCompletionHandler.handle(notificationReceived != null, exception);
    }

    /// AsyncTask METHODS END *********************************

    public NotificationModel showNotification(
            Context context,
            NotificationModel notificationModel,
            Intent originalIntent
    ) throws Exception {

        NotificationLifeCycle lifeCycle = AwesomeNotifications.getApplicationLifeCycle();

        boolean shouldDisplay = true;
        switch (lifeCycle){

            case Background:
                shouldDisplay = notificationModel.content.displayOnBackground;
                break;

            case Foreground:
                shouldDisplay = notificationModel.content.displayOnForeground;
                break;
        }

        if(shouldDisplay){

            Notification notification =
                    notificationBuilder
                        .createNewAndroidNotification(context, originalIntent, notificationModel);

            if(
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.N &&
                notificationModel.content.notificationLayout == NotificationLayout.Default &&
                StatusBarManager
                    .getInstance(context)
                    .isFirstActiveOnGroupKey(notificationModel.content.groupKey)
            ){
                NotificationModel pushSummary = _buildSummaryGroupNotification(notificationModel);
                Notification summaryNotification =
                        notificationBuilder
                                .createNewAndroidNotification(context, originalIntent, pushSummary);

                StatusBarManager
                    .getInstance(context)
                    .showNotificationOnStatusBar(context, pushSummary, summaryNotification);
            }

            StatusBarManager
                    .getInstance(context)
                    .showNotificationOnStatusBar(context, notificationModel, notification);
        }

        return notificationModel;
    }

    private NotificationModel _buildSummaryGroupNotification(NotificationModel original){

        NotificationModel pushSummary = notificationModel.ClonePush();

        pushSummary.content.id = IntegerUtils.generateNextRandomId();
        pushSummary.content.notificationLayout = NotificationLayout.Default;
        pushSummary.content.largeIcon = null;
        pushSummary.content.bigPicture = null;
        pushSummary.groupSummary = true;

        return  pushSummary;
    }
}
