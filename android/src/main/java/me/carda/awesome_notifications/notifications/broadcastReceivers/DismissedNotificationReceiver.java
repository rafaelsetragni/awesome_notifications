package me.carda.awesome_notifications.notifications.broadcastReceivers;

import android.annotation.TargetApi;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

import me.carda.awesome_notifications.AwesomeNotificationsPlugin;
import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.NotificationBuilder;
import me.carda.awesome_notifications.notifications.NotificationSender;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.notifications.managers.StatusBarManager;
import me.carda.awesome_notifications.notifications.models.returnedData.ActionReceived;

@TargetApi(Build.VERSION_CODES.CUPCAKE)
public class DismissedNotificationReceiver extends BroadcastReceiver
{
    static String TAG = "DismissedNotificationReceiver";

    @Override
    public void onReceive(Context context, Intent intent) {

        String action = intent.getAction();
        if (action != null && action.equals(Definitions.DISMISSED_NOTIFICATION)) {

            ActionReceived actionReceived
                    = NotificationBuilder.buildNotificationActionFromIntent(
                            context,
                            intent,
                            AwesomeNotificationsPlugin.appLifeCycle);

            if(actionReceived != null) {

                // In this case, the notification is always dismissed
                StatusBarManager
                    .getInstance(context)
                    .unregisterActiveNotification(actionReceived.id);

                NotificationSender.sendDismissedNotification(context, actionReceived);
            }
        }
    }
}
