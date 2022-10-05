package me.carda.awesome_notifications;

import android.content.Context;

import me.carda.awesome_notifications.core.broadcasters.receivers.NotificationActionReceiver;

public class DartNotificationActionReceiver extends NotificationActionReceiver {
    @Override
    public void initializeExternalPlugins(Context context) throws Exception {
        AwesomeNotificationsFlutterExtension.initialize();
    }
}
