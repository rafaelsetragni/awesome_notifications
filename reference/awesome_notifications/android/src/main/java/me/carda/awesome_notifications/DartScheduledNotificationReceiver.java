package me.carda.awesome_notifications;

import android.content.Context;

import me.carda.awesome_notifications.core.broadcasters.receivers.ScheduledNotificationReceiver;

public class DartScheduledNotificationReceiver extends ScheduledNotificationReceiver {
    @Override
    public void initializeExternalPlugins(Context context) throws Exception {
        AwesomeNotificationsFlutterExtension.initialize();
    }
}
