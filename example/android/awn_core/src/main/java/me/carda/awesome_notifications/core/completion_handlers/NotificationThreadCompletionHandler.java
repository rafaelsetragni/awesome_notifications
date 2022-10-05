package me.carda.awesome_notifications.core.completion_handlers;

import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;

public interface NotificationThreadCompletionHandler {
    public void handle(boolean success, AwesomeNotificationsException exception) throws AwesomeNotificationsException;
}
