package me.carda.awesome_notifications;

import android.content.Context;

import me.carda.awesome_notifications.core.services.BackgroundService;

public class DartBackgroundService extends BackgroundService {

    @Override
    public void initializeExternalPlugins(Context context) throws Exception {
        AwesomeNotificationsFlutterExtension.initialize();
    }
}
