package me.carda.awesome_notifications.awesome_notifications_core.listeners;

import me.carda.awesome_notifications.awesome_notifications_core.models.returnedData.NotificationReceived;

public interface AwesomeNotificationEventListener {
    public void onNewNotificationReceived(String eventName, NotificationReceived notificationReceived);
}
