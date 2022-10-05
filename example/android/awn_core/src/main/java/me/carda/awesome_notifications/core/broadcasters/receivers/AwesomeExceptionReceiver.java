package me.carda.awesome_notifications.core.broadcasters.receivers;

import java.util.ArrayList;
import java.util.List;

import me.carda.awesome_notifications.core.AwesomeNotifications;
import me.carda.awesome_notifications.core.listeners.AwesomeExceptionListener;
import me.carda.awesome_notifications.core.logs.Logger;
import me.carda.awesome_notifications.core.utils.StringUtils;

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
        if(exceptionListeners.isEmpty()){
            exception.printStackTrace();
            return;
        }
        for (AwesomeExceptionListener listener : exceptionListeners)
            listener.onNewAwesomeException(exception);
    }
}
