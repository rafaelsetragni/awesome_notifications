package me.carda.awesome_notifications.notifications.handlers;
import java.util.List;

public interface PermissionCompletionHandler {
    public void handle(List<String> missingPermissions);
}
