package me.carda.awesome_notifications.awesome_notifications_android_core.broadcasters.receivers;

import android.annotation.SuppressLint;
import android.content.Context;
import android.util.Log;

import java.util.ArrayList;
import java.util.List;

import me.carda.awesome_notifications.awesome_notifications_android_core.AwesomeNotifications;
import me.carda.awesome_notifications.awesome_notifications_android_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_android_core.listeners.AwesomeActionEventListener;
import me.carda.awesome_notifications.awesome_notifications_android_core.listeners.AwesomeNotificationEventListener;
import me.carda.awesome_notifications.awesome_notifications_android_core.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.awesome_notifications_android_core.models.returnedData.ActionReceived;
import me.carda.awesome_notifications.awesome_notifications_android_core.models.returnedData.NotificationReceived;
import me.carda.awesome_notifications.awesome_notifications_android_core.utils.StringUtils;

public class AwesomeEventsReceiver {

    public static String TAG = "AwesomeIntentFiltersReceiver";

    // ************** SINGLETON PATTERN ***********************

    @SuppressLint("StaticFieldLeak")
    private static AwesomeEventsReceiver instance;

    private AwesomeEventsReceiver(){
    }

    public static AwesomeEventsReceiver getInstance() {
        if (instance == null)
            instance = new AwesomeEventsReceiver();
        return instance;
    }

    // ********************************************************

    /// **************  OBSERVER PATTERN  *********************

    static List<AwesomeNotificationEventListener> notificationEventListeners = new ArrayList<>();
    public AwesomeEventsReceiver subscribeOnNotificationEvents(AwesomeNotificationEventListener listener) {
        notificationEventListeners.add(listener);
        return this;
    }
    public AwesomeEventsReceiver unsubscribeOnNotificationEvents(AwesomeNotificationEventListener listener) {
        notificationEventListeners.remove(listener);
        return this;
    }
    private void notifyNotificationEvent(String eventName, NotificationReceived notificationReceived) {
        for (AwesomeNotificationEventListener listener : notificationEventListeners)
            listener.onNewNotificationReceived(eventName, notificationReceived);
    }

    // ********************************************************

    static List<AwesomeActionEventListener> notificationActionListeners = new ArrayList<>();
    public AwesomeEventsReceiver subscribeOnActionEvents(AwesomeActionEventListener listener) {
        notificationActionListeners.add(listener);
        return this;
    }
    public AwesomeEventsReceiver unsubscribeOnActionEvents(AwesomeActionEventListener listener) {
        notificationActionListeners.remove(listener);
        return this;
    }
    private void notifyActionEvent(String eventName, ActionReceived actionReceived) {
        for (AwesomeActionEventListener listener : notificationActionListeners)
            listener.onNewActionReceived(eventName, actionReceived);
    }

    // ********************************************************

    public void addAwesomeNotificationEvent(Context context, String eventName, NotificationReceived notificationReceived){

        if(notificationEventListeners.isEmpty())
            return;

        try {
            switch (eventName) {

                case Definitions.BROADCAST_CREATED_NOTIFICATION:
                    onBroadcastNotificationCreated(context, notificationReceived);
                    return;

                case Definitions.BROADCAST_DISPLAYED_NOTIFICATION:
                    onBroadcastNotificationDisplayed(context, notificationReceived);
                    return;

                default:
                    if (AwesomeNotifications.debug)
                        Log.d(TAG, "Received unknown notification event: " + (
                                StringUtils.isNullOrEmpty(eventName) ? "empty" : eventName));

            }
        } catch (Exception e) {
            if (AwesomeNotifications.debug)
                Log.d(TAG, String.format("%s", e.getMessage()));
            e.printStackTrace();
        }
    }

    public void addAwesomeActionEvent(Context context, String eventName, ActionReceived actionReceived){

        try {
            switch (eventName) {

                case Definitions.BROADCAST_DEFAULT_ACTION:
                    onBroadcastDefaultActionNotification(context, actionReceived);
                    return;

                case Definitions.BROADCAST_DISMISSED_NOTIFICATION:
                    onBroadcastNotificationDismissed(context, actionReceived);
                    return;

                case Definitions.BROADCAST_SILENT_ACTION:
                    onBroadcastSilentActionNotification(context, actionReceived);
                    return;

                case Definitions.BROADCAST_BACKGROUND_ACTION:
                    onBroadcastBackgroundActionNotification(context, actionReceived);
                    return;

                default:
                    if (AwesomeNotifications.debug)
                        Log.d(TAG, "Received unknown action event: " + (
                                StringUtils.isNullOrEmpty(eventName) ? "empty" : eventName));

            }
        } catch (Exception e) {
            if (AwesomeNotifications.debug)
                Log.d(TAG, String.format("%s", e.getMessage()));
            e.printStackTrace();
        }
    }

    /// ***********************************

    private void onBroadcastNotificationCreated(Context context, NotificationReceived notificationReceived) throws AwesomeNotificationException {
        try {
            notificationReceived.validate(context);

            if (AwesomeNotifications.debug)
                Log.d(TAG, "Notification created");

            notifyNotificationEvent(Definitions.CHANNEL_METHOD_NOTIFICATION_CREATED, notificationReceived);

        } catch (Exception e) {
            throw new AwesomeNotificationException(e.getMessage());
        }
    }

    private void onBroadcastNotificationDisplayed(Context context, NotificationReceived notificationReceived) throws AwesomeNotificationException {
        try {
            notificationReceived.validate(context);

            if (AwesomeNotifications.debug)
                Log.d(TAG, "Notification displayed");

            notifyNotificationEvent(Definitions.CHANNEL_METHOD_NOTIFICATION_DISPLAYED, notificationReceived);

        } catch (Exception e) {
            throw new AwesomeNotificationException(e.getMessage());
        }
    }

    private void onBroadcastDefaultActionNotification(Context context, ActionReceived actionReceived) {
        try {
            actionReceived.validate(context);

            if(AwesomeNotifications.debug)
                Log.d(TAG, "Notification action received");

            notifyActionEvent(Definitions.CHANNEL_METHOD_DEFAULT_ACTION, actionReceived);

        } catch (Exception e) {
            if(AwesomeNotifications.debug)
                Log.d(TAG, String.format("%s", e.getMessage()));
            e.printStackTrace();
        }
    }

    private void onBroadcastNotificationDismissed(Context context, ActionReceived actionReceived) throws AwesomeNotificationException {
        try {
            actionReceived.validate(context);

            if (AwesomeNotifications.debug)
                Log.d(TAG, "Notification dismissed");

            notifyActionEvent(Definitions.CHANNEL_METHOD_NOTIFICATION_DISMISSED, actionReceived);

        } catch (Exception e) {
            throw new AwesomeNotificationException(e.getMessage());
        }
    }

    private void onBroadcastSilentActionNotification(Context context, ActionReceived actionReceived) {
        try {
            actionReceived.validate(context);

            if(AwesomeNotifications.debug)
                Log.d(TAG, "Notification silent action received");

            notifyActionEvent(Definitions.CHANNEL_METHOD_SILENT_ACTION, actionReceived);

        } catch (Exception e) {
            if(AwesomeNotifications.debug)
                Log.d(TAG, String.format("%s", e.getMessage()));
            e.printStackTrace();
        }
    }

    private void onBroadcastBackgroundActionNotification(Context context, ActionReceived actionReceived) throws AwesomeNotificationException {
        try {
            actionReceived.validate(context);

            if (AwesomeNotifications.debug)
                Log.d(TAG, "Notification action received");

            notifyActionEvent(Definitions.CHANNEL_METHOD_SILENT_ACTION, actionReceived);

        } catch (Exception e) {
            throw new AwesomeNotificationException(e.getMessage());
        }
    }
}
