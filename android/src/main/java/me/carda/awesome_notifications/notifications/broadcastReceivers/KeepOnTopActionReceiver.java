package me.carda.awesome_notifications.notifications.broadcastReceivers;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import me.carda.awesome_notifications.AwesomeNotificationsPlugin;
import me.carda.awesome_notifications.BroadcastSender;
import me.carda.awesome_notifications.notifications.NotificationBuilder;
import me.carda.awesome_notifications.notifications.enumerators.ActionButtonType;
import me.carda.awesome_notifications.notifications.managers.StatusBarManager;
import me.carda.awesome_notifications.notifications.models.NotificationModel;
import me.carda.awesome_notifications.notifications.models.returnedData.ActionReceived;

public class KeepOnTopActionReceiver extends BroadcastReceiver {

    @Override
    public void onReceive(final Context context, Intent intent) {

        ActionReceived actionReceived
            = NotificationBuilder.buildNotificationActionFromIntent(
                    context,
                    intent,
                    AwesomeNotificationsPlugin.appLifeCycle);

        if (actionReceived != null) {

            if(NotificationBuilder.notificationActionShouldAutoDismiss(actionReceived))
                StatusBarManager
                    .getInstance(context)
                    .dismissNotification(actionReceived.id);

            if (actionReceived.actionButtonType == ActionButtonType.DisabledAction)
                return;

            try {

                BroadcastSender.SendBroadcastKeepOnTopAction(
                    context,
                    actionReceived
                );

            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}
