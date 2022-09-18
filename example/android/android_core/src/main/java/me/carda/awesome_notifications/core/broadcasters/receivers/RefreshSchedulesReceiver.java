package me.carda.awesome_notifications.core.broadcasters.receivers;

import android.content.Context;
import android.content.Intent;

import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.threads.NotificationScheduler;

public abstract class RefreshSchedulesReceiver extends AwesomeBroadcastReceiver
{
    @Override
    public void onReceiveBroadcastEvent(
            final Context context, Intent intent
    ) throws AwesomeNotificationsException {

        String action = intent.getAction();
        if (action != null) {
            NotificationScheduler.refreshScheduledNotifications(context);
        }
    }
}
