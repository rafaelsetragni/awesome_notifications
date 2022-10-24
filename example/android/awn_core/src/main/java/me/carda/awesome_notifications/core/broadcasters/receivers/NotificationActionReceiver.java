package me.carda.awesome_notifications.core.broadcasters.receivers;

import android.content.Context;
import android.content.Intent;

import me.carda.awesome_notifications.core.AwesomeNotifications;
import me.carda.awesome_notifications.core.broadcasters.senders.BroadcastSender;
import me.carda.awesome_notifications.core.builders.NotificationBuilder;
import me.carda.awesome_notifications.core.enumerators.ActionType;
import me.carda.awesome_notifications.core.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.core.enumerators.NotificationSource;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.logs.Logger;
import me.carda.awesome_notifications.core.managers.LifeCycleManager;
import me.carda.awesome_notifications.core.managers.StatusBarManager;
import me.carda.awesome_notifications.core.models.returnedData.ActionReceived;
import me.carda.awesome_notifications.core.services.ForegroundService;
import me.carda.awesome_notifications.core.utils.StringUtils;

public abstract class NotificationActionReceiver extends AwesomeBroadcastReceiver {

    public static String TAG = "NotificationActionReceiver";

    @Override
    public void onReceiveBroadcastEvent(final Context context, Intent intent) throws Exception {
        receiveActionIntent(context, intent);
    }

    public static void receiveActionIntent(final Context context, Intent intent) throws Exception {
        receiveActionIntent(context, intent, false);
    }

    public static void receiveActionIntent(final Context context, Intent intent, boolean onInitialization) throws Exception {

        if(AwesomeNotifications.debug)
            Logger.d(TAG, "New action received");

        NotificationBuilder notificationBuilder = NotificationBuilder.getNewBuilder();

        NotificationLifeCycle appLifeCycle
            = LifeCycleManager
                .getApplicationLifeCycle();

        ActionReceived actionReceived = null;
        try {
            actionReceived = notificationBuilder
                .buildNotificationActionFromIntent(
                    context,
                    intent,
                    appLifeCycle);
        } catch (AwesomeNotificationsException e) {
            e.printStackTrace();
        }

        // In case there is not a valid notification intent
        if (actionReceived == null) {
            if(AwesomeNotifications.debug)
                Logger.w(
                        TAG,
                        "The action received do not contain any awesome " +
                        "notification data and was discarded");
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
                        .dismissNotification(context, actionReceived.id);
        }
        else {
            if (
                StringUtils.getInstance().isNullOrEmpty(actionReceived.buttonKeyInput) &&
                actionReceived.actionType != ActionType.KeepOnTop
            )
                StatusBarManager
                        .getInstance(context)
                        .closeStatusBar(context);
        }

        try {

            switch (actionReceived.actionType){

                case Default:
                    BroadcastSender.sendBroadcastDefaultAction(
                            context,
                            actionReceived,
                            onInitialization);
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
