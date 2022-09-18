package me.carda.awesome_notifications.core.completion_handlers;

import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;

public interface BitmapCompletionHandler {
    public void handle(byte[] byteArray, AwesomeNotificationsException exception);
}
