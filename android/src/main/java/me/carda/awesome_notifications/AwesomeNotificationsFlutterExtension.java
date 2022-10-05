package me.carda.awesome_notifications;

import android.content.Context;

import me.carda.awesome_notifications.core.AwesomeNotifications;
import me.carda.awesome_notifications.core.AwesomeNotificationsExtension;
import me.carda.awesome_notifications.core.background.BackgroundExecutor;
import me.carda.awesome_notifications.core.logs.Logger;

public class AwesomeNotificationsFlutterExtension extends AwesomeNotificationsExtension {
    private static final String TAG = "AwesomeNotificationsFlutterExtension";

    public static void initialize(){
        if(AwesomeNotifications.awesomeExtensions != null) return;

        AwesomeNotifications.actionReceiverClass = DartNotificationActionReceiver.class;
        AwesomeNotifications.dismissReceiverClass = DartDismissedNotificationReceiver.class;
        AwesomeNotifications.scheduleReceiverClass = DartScheduledNotificationReceiver.class;
        AwesomeNotifications.backgroundServiceClass = DartBackgroundService.class;

        AwesomeNotifications.awesomeExtensions = new AwesomeNotificationsFlutterExtension();

        if (AwesomeNotifications.debug)
            Logger.d(TAG, "Flutter extensions attached to Awesome Notification's core.");
    }

    @Override
    public void loadExternalExtensions(Context context) {
        FlutterBitmapUtils.extendCapabilities();
        BackgroundExecutor.setBackgroundExecutorClass(DartBackgroundExecutor.class);
    }
}