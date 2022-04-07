package me.carda.awesome_notifications.awesome_notifications_core.completion_handlers;

import me.carda.awesome_notifications.awesome_notifications_core.exceptions.AwesomeNotificationsException;

public interface NotificationThreadCompletionHandler {
    public void handle(boolean success, AwesomeNotificationsException exception);
}
