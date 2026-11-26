package me.carda.awesome_notifications;

import android.content.Context;

import me.carda.awesome_notifications.core.broadcasters.receivers.RefreshSchedulesReceiver;

public class DartRefreshSchedulesReceiver extends RefreshSchedulesReceiver {

    @Override
    public void initializeExternalPlugins(Context context) throws Exception {
        AwesomeNotificationsFlutterExtension.initialize();
    }
}
