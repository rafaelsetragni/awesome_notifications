package me.carda.awesome_notifications.awesome_notifications_android_core.broadcasters.receivers;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import me.carda.awesome_notifications.awesome_notifications_android_core.notifications.NotificationBuilder;
import me.carda.awesome_notifications.awesome_notifications_android_core.enumerators.ActionType;
import me.carda.awesome_notifications.awesome_notifications_android_core.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.awesome_notifications_android_core.managers.LifeCycleManager;
import me.carda.awesome_notifications.awesome_notifications_android_core.managers.StatusBarManager;
import me.carda.awesome_notifications.awesome_notifications_android_core.models.returnedData.ActionReceived;
import me.carda.awesome_notifications.awesome_notifications_android_core.broadcasters.senders.BroadcastSender;

public class NotificationActionReceiver extends BroadcastReceiver {

    @Override
    public void onReceive(final Context context, Intent intent) {

        NotificationLifeCycle appLifeCycle =
                LifeCycleManager
                    .getApplicationLifeCycle();

        ActionReceived actionReceived
            = NotificationBuilder
                .getInstance()
                .buildNotificationActionFromIntent(
                    context,
                    intent,
                    appLifeCycle);

        // This is not a valid notification intent
        if (actionReceived == null) return;

        boolean shouldAutoDismiss =
                        NotificationBuilder
                            .getInstance()
                            .notificationActionShouldAutoDismiss(actionReceived);

        if(shouldAutoDismiss)
            StatusBarManager
                .getInstance(context)
                .dismissNotification(actionReceived.id);
        else
            if (actionReceived.actionType != ActionType.KeepOnTop)
                StatusBarManager
                    .getInstance(context)
                    .closeStatusBar();

        try {

            switch (actionReceived.actionType){

                case Default:
                    if (appLifeCycle != NotificationLifeCycle.Foreground)
                        NotificationBuilder
                                .getInstance()
                                .forceBringAppToForeground(context);

                    BroadcastSender.sendBroadcastDefaultAction(
                            context,
                            actionReceived);
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
                                actionReceived);
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
                                actionReceived);
                    break;

                case SilentBackgroundAction:
                    BroadcastSender.enqueueSilentBackgroundAction(
                            context,
                            intent.getAction(),
                            actionReceived);
                    break;

                case DisabledAction:
                    if(shouldAutoDismiss)
                        BroadcastSender
                                .sendBroadcastNotificationDismissed(
                                        context,
                                        actionReceived);
                    break;
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
