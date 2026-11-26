package me.carda.awesome_notifications;

import android.content.Context;

import me.carda.awesome_notifications.core.broadcasters.receivers.DismissedNotificationReceiver;

public class DartDismissedNotificationReceiver extends DismissedNotificationReceiver {

    @Override
    public void initializeExternalPlugins(Context context) throws Exception {
        AwesomeNotificationsFlutterExtension.initialize();
    }
}
