package me.carda.awesome_notifications.awesome_notifications_core.completion_handlers;
import java.util.List;

public interface PermissionCompletionHandler {
    public void handle(List<String> missingPermissions);
}
