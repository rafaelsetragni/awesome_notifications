package me.carda.awesome_notifications.awesome_notifications_android_core.broadcasters.receivers;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import me.carda.awesome_notifications.awesome_notifications_android_core.AwesomeNotifications;
import me.carda.awesome_notifications.awesome_notifications_android_core.exceptions.AwesomeNotificationException;

public abstract class AwesomeBroadcastReceiver extends BroadcastReceiver {

    public abstract void onReceiveBroadcastEvent(Context context, Intent intent);

    @Override
    public void onReceive(Context context, Intent intent) {
        try {
            AwesomeNotifications.loadAwesomeExtensions(context);
            onReceiveBroadcastEvent(context, intent);
        } catch (AwesomeNotificationException e) {
            e.printStackTrace();
        }
    }
}
