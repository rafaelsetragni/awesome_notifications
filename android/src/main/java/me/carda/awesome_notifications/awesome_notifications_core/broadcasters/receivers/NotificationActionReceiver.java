package me.carda.awesome_notifications.awesome_notifications_core.broadcasters.receivers;

import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.util.Log;

import me.carda.awesome_notifications.awesome_notifications_core.AwesomeNotifications;
import me.carda.awesome_notifications.awesome_notifications_core.builders.NotificationBuilder;
import me.carda.awesome_notifications.awesome_notifications_core.enumerators.ActionType;
import me.carda.awesome_notifications.awesome_notifications_core.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.awesome_notifications_core.enumerators.NotificationSource;
import me.carda.awesome_notifications.awesome_notifications_core.managers.LifeCycleManager;
import me.carda.awesome_notifications.awesome_notifications_core.managers.StatusBarManager;
import me.carda.awesome_notifications.awesome_notifications_core.models.returnedData.ActionReceived;
import me.carda.awesome_notifications.awesome_notifications_core.broadcasters.senders.BroadcastSender;
import me.carda.awesome_notifications.awesome_notifications_core.services.ForegroundService;

public class NotificationActionReceiver extends AwesomeBroadcastReceiver {

    public static String TAG = "NotificationActionReceiver";

    @Override
    public void onReceiveBroadcastEvent(final Context context, Intent intent) {
        receiveActionIntent(context, intent);
    }

    public static void receiveActionIntent(final Context context, Intent intent){

        if(AwesomeNotifications.debug)
            Log.d(TAG, "New action received");

        NotificationBuilder notificationBuilder = NotificationBuilder.getNewBuilder();

        NotificationLifeCycle appLifeCycle
            = LifeCycleManager
                .getApplicationLifeCycle();

        ActionReceived actionReceived
            = notificationBuilder
                .buildNotificationActionFromIntent(
                    context,
                    intent,
                    appLifeCycle);

        // In case there is not a valid notification intent
        if (actionReceived == null) {
            if(AwesomeNotifications.debug)
                Log.e(TAG, "The action received do not contain any awesome notification data and was discarded");
            return;
        }

        if(actionReceived.actionType == ActionType.DismissAction)
            actionReceived.registerDismissedEvent(appLifeCycle);
        else
            actionReceived.registerUserActionEvent(appLifeCycle);

        boolean shouldAutoDismiss
                  = actionReceived.actionType == ActionType.DismissAction ||
                    notificationBuilder
                            .notificationActionShouldAutoDismiss(actionReceived);

        if(shouldAutoDismiss) {
            if (actionReceived.createdSource == NotificationSource.ForegroundService)
                ForegroundService
                        .stop(actionReceived.id);
            else
                StatusBarManager
                        .getInstance(context)
                        .dismissNotification(actionReceived.id);
        }
        else {
            if (actionReceived.actionType != ActionType.KeepOnTop)
                StatusBarManager
                        .getInstance(context)
                        .closeStatusBar(context);
        }

        try {

            switch (actionReceived.actionType){

                case Default:
                    BroadcastSender.sendBroadcastDefaultAction(
                            context,
                            actionReceived);

                    /*if (appLifeCycle != NotificationLifeCycle.Foreground)
                        notificationBuilder
                                .forceBringAppToForeground(context);*/
                    break;

                case KeepOnTop:
                    if (appLifeCycle != NotificationLifeCycle.AppKilled)
                        BroadcastSender.sendBroadcastBackgroundAction(
                                context,
                                actionReceived);
                    else
                        BroadcastSender.enqueueSilentAction(
                                context,
                                intent.getAction(),
                                actionReceived,
                                intent);
                    break;

                case SilentAction:
                    if (appLifeCycle != NotificationLifeCycle.AppKilled)
                        BroadcastSender.sendBroadcastSilentAction(
                                context,
                                actionReceived);
                    else
                        BroadcastSender.enqueueSilentAction(
                                context,
                                intent.getAction(),
                                actionReceived,
                                intent);
                    break;

                case SilentBackgroundAction:
                    BroadcastSender.enqueueSilentBackgroundAction(
                            context,
                            intent.getAction(),
                            actionReceived,
                            intent);
                    break;

                case DismissAction:
                    BroadcastSender
                            .sendBroadcastNotificationDismissed(
                                    context,
                                    actionReceived);
                    break;

                case DisabledAction:
                    break;
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
