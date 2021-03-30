package me.carda.awesome_notifications.notifications.broadcastReceivers;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import me.carda.awesome_notifications.notifications.NotificationScheduler;

public class RefreshNotificationBootReceiver extends BroadcastReceiver
{
    @Override
    public void onReceive(final Context context, Intent intent) {
        String action = intent.getAction();
        if (action != null && (action.equals(android.content.Intent.ACTION_BOOT_COMPLETED)
                    || action.equals(Intent.ACTION_LOCKED_BOOT_COMPLETED)
                    || action.equals(Intent.ACTION_MY_PACKAGE_REPLACED)
                    || action.equals("android.intent.action.QUICKBOOT_POWERON")
                    || action.equals("com.htc.intent.action.QUICKBOOT_POWERON"))) {
            NotificationScheduler.refreshScheduleNotifications(context);
        }
    }
}
