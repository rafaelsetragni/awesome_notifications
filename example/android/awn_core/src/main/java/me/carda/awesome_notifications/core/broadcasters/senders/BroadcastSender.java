package me.carda.awesome_notifications.core.broadcasters.senders;

import android.content.Context;
import android.content.Intent;

import androidx.core.app.JobIntentService;

import org.checkerframework.checker.nullness.qual.NonNull;

import javax.annotation.Nullable;

import me.carda.awesome_notifications.core.AwesomeNotifications;
import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.broadcasters.receivers.AwesomeEventsReceiver;
import me.carda.awesome_notifications.core.builders.NotificationBuilder;
import me.carda.awesome_notifications.core.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.core.managers.ActionManager;
import me.carda.awesome_notifications.core.managers.CreatedManager;
import me.carda.awesome_notifications.core.managers.DismissedManager;
import me.carda.awesome_notifications.core.managers.DisplayedManager;
import me.carda.awesome_notifications.core.managers.LifeCycleManager;
import me.carda.awesome_notifications.core.managers.LostEventsManager;
import me.carda.awesome_notifications.core.models.returnedData.ActionReceived;
import me.carda.awesome_notifications.core.models.returnedData.NotificationReceived;

public class BroadcastSender {

    private static final String TAG = "BroadcastSender";

    // ************** SINGLETON PATTERN ***********************

    private static BroadcastSender instance;

    private BroadcastSender(){}
    public static BroadcastSender getInstance() {
        if (instance == null)
            instance = new BroadcastSender();
        return instance;
    }

    // ************** SINGLETON PATTERN ***********************

    private boolean isWithoutListenersAvailable(){
        return
            LifeCycleManager.getApplicationLifeCycle() == NotificationLifeCycle.Terminated ||
            AwesomeEventsReceiver.getInstance().isEmpty() ||
            !AwesomeEventsReceiver.getInstance().isReadyToReceiveEvents();
    }

    public void sendBroadcastNotificationCreated(
            @NonNull Context context,
            @Nullable NotificationReceived createdReceived
    ){
        if (createdReceived == null) return;
        try {

            if (isWithoutListenersAvailable()) {
                LostEventsManager
                        .getInstance()
                        .saveCreated(
                                context,
                                createdReceived);
            }
            else {
                AwesomeEventsReceiver
                        .getInstance()
                        .addNotificationEvent(
                                context,
                                Definitions.BROADCAST_CREATED_NOTIFICATION,
                                createdReceived);
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void sendBroadcastNotificationDisplayed(
            @NonNull Context context,
            @Nullable NotificationReceived displayedReceived
    ){
        if (displayedReceived == null) return;
        try {

            if (isWithoutListenersAvailable()) {
                LostEventsManager
                        .getInstance()
                        .saveDisplayed(
                                context,
                                displayedReceived);
            }
            else {
                AwesomeEventsReceiver
                        .getInstance()
                        .addNotificationEvent(
                                context,
                                Definitions.BROADCAST_DISPLAYED_NOTIFICATION,
                                displayedReceived);
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void sendBroadcastNotificationDismissed(
            @NonNull Context context,
            @Nullable ActionReceived dismissedReceived
    ){
        if (dismissedReceived == null) return;
        try {

            if (isWithoutListenersAvailable()) {
                LostEventsManager
                        .getInstance()
                        .saveDismissed(
                                context,
                                dismissedReceived);
            }
            else {
                AwesomeEventsReceiver
                        .getInstance()
                        .addAwesomeActionEvent(
                                context,
                                Definitions.BROADCAST_DISMISSED_NOTIFICATION,
                                dismissedReceived);
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void sendBroadcastDefaultAction(
            @NonNull Context context,
            @Nullable ActionReceived actionReceived,
            boolean onInitialization
    ){
        if (actionReceived == null) return;
        try {

            if(onInitialization){
                ActionManager
                        .getInstance()
                        .setInitialNotificationAction(
                                context,
                                actionReceived);
            }

            if(isWithoutListenersAvailable()) {
                ActionManager
                        .getInstance()
                        .saveAction(
                                context,
                                actionReceived);
            }
            else {
                AwesomeEventsReceiver
                        .getInstance()
                        .addAwesomeActionEvent(
                                context,
                                Definitions.BROADCAST_DEFAULT_ACTION,
                                actionReceived);
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void sendBroadcastSilentAction(
            @NonNull Context context,
            @Nullable ActionReceived actionReceived
    ){
        if (actionReceived == null) return;
        try {
            AwesomeEventsReceiver
                    .getInstance()
                    .addAwesomeActionEvent(
                            context,
                            Definitions.BROADCAST_SILENT_ACTION,
                            actionReceived);

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void sendBroadcastBackgroundAction(
            @NonNull Context context,
            @Nullable ActionReceived actionReceived
    ){
        if (actionReceived == null) return;
        try {
            AwesomeEventsReceiver
                    .getInstance()
                    .addAwesomeActionEvent(
                            context,
                            Definitions.BROADCAST_BACKGROUND_ACTION,
                            actionReceived);

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void enqueueSilentAction(
            @NonNull Context context,
            String previousAction,
            ActionReceived actionReceived,
            @Nullable Intent originalIntent
    ){
        if (AwesomeNotifications.backgroundServiceClass == null) return;

        Intent serviceIntent =
                NotificationBuilder
                        .getNewBuilder()
                        .buildNotificationIntentFromActionModel(
                                context,
                                originalIntent,
                                previousAction,
                                actionReceived,
                                AwesomeNotifications.backgroundServiceClass);

        JobIntentService.enqueueWork(
                context,
                AwesomeNotifications.backgroundServiceClass,
                42,
                serviceIntent);
    }

    public void enqueueSilentBackgroundAction(
            @NonNull Context context,
            String previousAction,
            @NonNull ActionReceived actionReceived,
            @Nullable Intent originalIntent
    ){
        Intent serviceIntent =
                NotificationBuilder
                        .getNewBuilder()
                        .buildNotificationIntentFromActionModel(
                                context,
                                originalIntent,
                                previousAction,
                                actionReceived,
                                AwesomeNotifications.backgroundServiceClass);

        JobIntentService.enqueueWork(
                context,
                AwesomeNotifications.backgroundServiceClass,
                42,
                serviceIntent);
    }
}
