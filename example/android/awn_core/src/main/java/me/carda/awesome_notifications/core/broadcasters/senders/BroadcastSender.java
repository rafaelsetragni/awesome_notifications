package me.carda.awesome_notifications.core.broadcasters.senders;

import android.content.Context;
import android.content.Intent;

import androidx.core.app.JobIntentService;

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
import me.carda.awesome_notifications.core.models.returnedData.ActionReceived;
import me.carda.awesome_notifications.core.models.returnedData.NotificationReceived;

public class BroadcastSender {

    private static final String TAG = "BroadcastSender";

    private static boolean withoutListenersAvailable(){
        return
            LifeCycleManager.getApplicationLifeCycle() == NotificationLifeCycle.AppKilled ||
            AwesomeEventsReceiver.getInstance().isEmpty() ||
            !AwesomeEventsReceiver.getInstance().isReadyToReceiveEvents();
    }

    public static void sendBroadcastNotificationCreated(Context context, NotificationReceived notificationReceived){

        if (notificationReceived != null)
            try {

                if(withoutListenersAvailable()) {
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

                if(withoutListenersAvailable()) {
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

                if(withoutListenersAvailable()) {
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

    public static void sendBroadcastDefaultAction(Context context, ActionReceived actionReceived, boolean onInitialization){
        if (actionReceived != null)
            try {

                if(onInitialization){
                    ActionManager.setInitialNotificationAction(context, actionReceived);
                }

                if(withoutListenersAvailable()) {
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

    public static void enqueueSilentAction(Context context, String previousAction, ActionReceived actionReceived, Intent originalIntent){
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

    public static void enqueueSilentBackgroundAction(Context context, String previousAction, ActionReceived actionReceived, Intent originalIntent){

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
