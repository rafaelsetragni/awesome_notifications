package me.carda.awesome_notifications.awesome_notifications_android_core.observers;

import me.carda.awesome_notifications.awesome_notifications_android_core.models.returnedData.NotificationReceived;

public interface AwesomeNotificationEventListener {
    public void onNewNotificationReceived(String eventName, NotificationReceived notificationReceived);
}
