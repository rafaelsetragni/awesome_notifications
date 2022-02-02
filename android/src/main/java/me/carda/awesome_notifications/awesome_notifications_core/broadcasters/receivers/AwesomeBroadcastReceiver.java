package me.carda.awesome_notifications.awesome_notifications_core.broadcasters.receivers;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import me.carda.awesome_notifications.awesome_notifications_core.AwesomeNotifications;
import me.carda.awesome_notifications.awesome_notifications_core.exceptions.AwesomeNotificationsException;

public abstract class AwesomeBroadcastReceiver extends BroadcastReceiver {

    public abstract void onReceiveBroadcastEvent(Context context, Intent intent);

    @Override
    public void onReceive(Context context, Intent intent) {
        try {
            AwesomeNotifications.loadAwesomeExtensions(context);
            onReceiveBroadcastEvent(context, intent);
        } catch (AwesomeNotificationsException e) {
            e.printStackTrace();
        }
    }
}
