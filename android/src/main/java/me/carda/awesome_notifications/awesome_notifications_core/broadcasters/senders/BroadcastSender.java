package me.carda.awesome_notifications.awesome_notifications_core.broadcasters.senders;

import android.content.Context;
import android.content.Intent;

import androidx.core.app.JobIntentService;
import me.carda.awesome_notifications.awesome_notifications_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_core.builders.NotificationBuilder;
import me.carda.awesome_notifications.awesome_notifications_core.broadcasters.receivers.AwesomeEventsReceiver;
import me.carda.awesome_notifications.awesome_notifications_core.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.awesome_notifications_core.managers.ActionManager;
import me.carda.awesome_notifications.awesome_notifications_core.managers.DismissedManager;
import me.carda.awesome_notifications.awesome_notifications_core.managers.CreatedManager;
import me.carda.awesome_notifications.awesome_notifications_core.managers.DisplayedManager;
import me.carda.awesome_notifications.awesome_notifications_core.managers.LifeCycleManager;
import me.carda.awesome_notifications.awesome_notifications_core.models.returnedData.ActionReceived;
import me.carda.awesome_notifications.awesome_notifications_core.models.returnedData.NotificationReceived;
import me.carda.awesome_notifications.awesome_notifications_core.services.BackgroundService;

public class BroadcastSender {

    private static final String TAG = "BroadcastSender";

    public static void sendBroadcastNotificationCreated(Context context, NotificationReceived notificationReceived){

        if (notificationReceived != null)
            try {

                if(LifeCycleManager.getApplicationLifeCycle() == NotificationLifeCycle.AppKilled) {
                    CreatedManager.saveCreated(context, notificationReceived);
                    CreatedManager.commitChanges(context);
                }
                else {
                    AwesomeEventsReceiver
                            .getInstance()
                            .addNotificationEvent(
                                    context,
                                    Definitions.BROADCAST_CREATED_NOTIFICATION,
                                    notificationReceived);
                }

            } catch (Exception e) {
                e.printStackTrace();
            }
    }

    public static void sendBroadcastNotificationDisplayed(Context context, NotificationReceived notificationReceived){

        if (notificationReceived != null)
            try {

                if(LifeCycleManager.getApplicationLifeCycle() == NotificationLifeCycle.AppKilled) {
                    DisplayedManager.saveDisplayed(context, notificationReceived);
                    DisplayedManager.commitChanges(context);
                }
                else {
                    AwesomeEventsReceiver
                            .getInstance()
                            .addNotificationEvent(
                                    context,
                                    Definitions.BROADCAST_DISPLAYED_NOTIFICATION,
                                    notificationReceived);
                }

            } catch (Exception e) {
                e.printStackTrace();
            }
    }

    public static void sendBroadcastNotificationDismissed(Context context, ActionReceived actionReceived){
        if (actionReceived != null)
            try {

                if(LifeCycleManager.getApplicationLifeCycle() == NotificationLifeCycle.AppKilled) {
                    DismissedManager.saveDismissed(context, actionReceived);
                    DismissedManager.commitChanges(context);
                }
                else {
                    AwesomeEventsReceiver
                            .getInstance()
                            .addAwesomeActionEvent(
                                    context,
                                    Definitions.BROADCAST_DISMISSED_NOTIFICATION,
                                    actionReceived);
                }

            } catch (Exception e) {
                e.printStackTrace();
            }
    }

    public static void sendBroadcastDefaultAction(Context context, ActionReceived actionReceived){
        if (actionReceived != null)
            try {

                if(LifeCycleManager.getApplicationLifeCycle() == NotificationLifeCycle.AppKilled) {
                    ActionManager.saveAction(context, actionReceived);
                    ActionManager.commitChanges(context);
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

    public static void sendBroadcastSilentAction(Context context, ActionReceived actionReceived){
        if (actionReceived != null)
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

    public static void sendBroadcastBackgroundAction(Context context, ActionReceived actionReceived){

        if (actionReceived != null)
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

    public static void enqueueSilentAction(Context context, String previousAction, ActionReceived actionReceived){

        Intent serviceIntent =
                NotificationBuilder
                        .getNewBuilder()
                        .buildNotificationIntentFromActionModel(
                                context,
                                previousAction,
                                actionReceived,
                                BackgroundService.class);

        JobIntentService.enqueueWork(
                context,
                BackgroundService.class,
                42,
                serviceIntent);
    }

    public static void enqueueSilentBackgroundAction(Context context, String previousAction, ActionReceived actionReceived){

        Intent serviceIntent =
                NotificationBuilder
                        .getNewBuilder()
                        .buildNotificationIntentFromActionModel(
                                context,
                                previousAction,
                                actionReceived,
                                BackgroundService.class);

        JobIntentService.enqueueWork(
                context,
                BackgroundService.class,
                42,
                serviceIntent);
    }
}
