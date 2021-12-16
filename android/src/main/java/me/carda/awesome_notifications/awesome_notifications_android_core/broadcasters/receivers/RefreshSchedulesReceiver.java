package me.carda.awesome_notifications.awesome_notifications_android_core.broadcasters.receivers;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import me.carda.awesome_notifications.awesome_notifications_android_core.notifications.NotificationScheduler;

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
