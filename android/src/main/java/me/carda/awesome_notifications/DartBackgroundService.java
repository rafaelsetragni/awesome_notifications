package me.carda.awesome_notifications;

import android.content.Context;

import me.carda.awesome_notifications.core.services.AwesomeBackgroundService;

public class DartBackgroundService extends AwesomeBackgroundService {

    @Override
    public void initializeExternalPlugins(Context context) throws Exception {
        AwesomeNotificationsFlutterExtension.initialize();
    }
}
