package me.carda.awesome_notifications.awesome_notifications_android_core.completion_handlers;
import java.util.List;

import me.carda.awesome_notifications.awesome_notifications_android_core.models.NotificationModel;

public interface ForegroundCompletionHandler {
    public void handle(NotificationModel notificationModel);
}
