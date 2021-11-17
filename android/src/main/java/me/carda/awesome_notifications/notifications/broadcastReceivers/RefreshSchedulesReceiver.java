package me.carda.awesome_notifications.notifications.broadcastReceivers;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import me.carda.awesome_notifications.notifications.NotificationScheduler;

public class RefreshSchedulesReceiver extends BroadcastReceiver
{
    @Override
    public void onReceive(final Context context, Intent intent) {
        String action = intent.getAction();
        if (action != null) {
            NotificationScheduler.refreshScheduleNotifications(context);
        }
    }
}
