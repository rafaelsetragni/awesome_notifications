package me.carda.awesome_notifications.awesome_notifications_core.broadcasters.receivers;

import android.content.Context;

import androidx.annotation.NonNull;

import java.util.ArrayList;
import java.util.List;

import me.carda.awesome_notifications.awesome_notifications_core.AwesomeNotifications;
import me.carda.awesome_notifications.awesome_notifications_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.awesome_notifications_core.listeners.AwesomeActionEventListener;
import me.carda.awesome_notifications.awesome_notifications_core.listeners.AwesomeExceptionListener;
import me.carda.awesome_notifications.awesome_notifications_core.listeners.AwesomeNotificationEventListener;
import me.carda.awesome_notifications.awesome_notifications_core.logs.Logger;
import me.carda.awesome_notifications.awesome_notifications_core.models.returnedData.ActionReceived;
import me.carda.awesome_notifications.awesome_notifications_core.models.returnedData.NotificationReceived;
import me.carda.awesome_notifications.awesome_notifications_core.utils.StringUtils;

public class AwesomeExceptionReceiver {

    public static String TAG = "AwesomeEventsReceiver";

    // ************** SINGLETON PATTERN ***********************

    private static AwesomeExceptionReceiver instance;

    private AwesomeExceptionReceiver(StringUtils stringUtils){
        this.stringUtils = stringUtils;
    }

    public static AwesomeExceptionReceiver getInstance() {
        if (instance == null)
            instance = new AwesomeExceptionReceiver(
                    StringUtils.getInstance());
        return instance;
    }

    public boolean isEmpty(){
        return exceptionListeners.isEmpty();
    }

    // ********************************************************

    protected final StringUtils stringUtils;

    /// **************  OBSERVER PATTERN  *********************

    private final List<AwesomeExceptionListener> exceptionListeners = new ArrayList<>();
    public AwesomeExceptionReceiver subscribeOnNotificationEvents(AwesomeExceptionListener listener) {
        exceptionListeners.add(listener);

        if(AwesomeNotifications.debug)
            Logger.d(TAG, listener.getClass().getSimpleName() + " subscribed to receive exception events");

        return this;
    }
    public AwesomeExceptionReceiver unsubscribeOnNotificationEvents(AwesomeExceptionListener listener) {
        exceptionListeners.remove(listener);

        if(AwesomeNotifications.debug)
            Logger.d(TAG, listener.getClass().getSimpleName() + " unsubscribed from exception events");

        return this;
    }
    public void notifyNewException(String className, Exception exception) {
        Logger.e(className, exception.getLocalizedMessage());
        for (AwesomeExceptionListener listener : exceptionListeners)
            listener.onNewAwesomeException(exception);
    }
}
