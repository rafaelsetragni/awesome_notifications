package me.carda.awesome_notifications.core.listeners;

import me.carda.awesome_notifications.core.models.returnedData.NotificationReceived;

public interface AwesomeNotificationEventListener {
    public void onNewNotificationReceived(String eventName, NotificationReceived notificationReceived);
}
