package me.carda.awesome_notifications.awesome_notifications_core.broadcasters.receivers;

import android.annotation.TargetApi;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

import me.carda.awesome_notifications.awesome_notifications_core.AwesomeNotifications;
import me.carda.awesome_notifications.awesome_notifications_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_core.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.awesome_notifications_core.builders.NotificationBuilder;
import me.carda.awesome_notifications.awesome_notifications_core.broadcasters.senders.BroadcastSender;
import me.carda.awesome_notifications.awesome_notifications_core.managers.StatusBarManager;
import me.carda.awesome_notifications.awesome_notifications_core.models.returnedData.ActionReceived;

@TargetApi(Build.VERSION_CODES.CUPCAKE)
public class DismissedNotificationReceiver extends AwesomeBroadcastReceiver
{
    static String TAG = "DismissedNotificationReceiver";

    @Override
    public void onReceiveBroadcastEvent(Context context, Intent intent) {

        String action = intent.getAction();
        if (action != null && action.equals(Definitions.DISMISSED_NOTIFICATION)) {

            NotificationLifeCycle appLifeCycle =
                    AwesomeNotifications
                        .getApplicationLifeCycle();

            ActionReceived actionReceived
                    = NotificationBuilder
                            .getNewBuilder()
                            .buildNotificationActionFromIntent(
                                    context,
                                    intent,
                                    appLifeCycle);

            if(actionReceived == null)
                return;

            actionReceived.registerDismissedEvent(appLifeCycle);

            // In this case, the notification is always dismissed
            StatusBarManager
                .getInstance(context)
                .unregisterActiveNotification(actionReceived.id);


            BroadcastSender
                .sendBroadcastNotificationDismissed(context, actionReceived);
        }
    }
}
