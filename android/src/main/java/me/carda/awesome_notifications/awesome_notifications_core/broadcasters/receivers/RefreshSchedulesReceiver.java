package me.carda.awesome_notifications.awesome_notifications_core.broadcasters.receivers;

import android.content.Context;
import android.content.Intent;

import me.carda.awesome_notifications.awesome_notifications_core.threads.NotificationScheduler;

public class RefreshSchedulesReceiver extends AwesomeBroadcastReceiver
{
    @Override
    public void onReceiveBroadcastEvent(final Context context, Intent intent) {

        String action = intent.getAction();
        if (action != null) {
            NotificationScheduler.refreshScheduleNotifications(context);
        }
    }
}
