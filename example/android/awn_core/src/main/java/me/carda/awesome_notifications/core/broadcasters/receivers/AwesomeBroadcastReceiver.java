package me.carda.awesome_notifications.core.broadcasters.receivers;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import me.carda.awesome_notifications.core.AwesomeNotifications;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.core.exceptions.ExceptionFactory;

public abstract class AwesomeBroadcastReceiver extends BroadcastReceiver {
    private static final String TAG = "AwesomeBroadcastReceiver";

    public abstract void onReceiveBroadcastEvent(Context context, Intent intent) throws Exception;
    public abstract void initializeExternalPlugins(Context context) throws Exception;

    @Override
    public void onReceive(Context context, Intent intent) {
        try {
            initializeExternalPlugins(context);
            AwesomeNotifications.initialize(context);
            onReceiveBroadcastEvent(context, intent);
        } catch (AwesomeNotificationsException e) {
            e.printStackTrace();
        } catch (Exception e) {
            ExceptionFactory
                .getInstance()
                .registerNewAwesomeException(
                        TAG,
                        ExceptionCode.CODE_UNKNOWN_EXCEPTION,
                        ExceptionCode.DETAILED_UNEXPECTED_ERROR+"."+e.getClass().getSimpleName(),
                        e);
        }
    }
}
