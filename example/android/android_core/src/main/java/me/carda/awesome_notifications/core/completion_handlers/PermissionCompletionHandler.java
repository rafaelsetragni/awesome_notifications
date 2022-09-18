package me.carda.awesome_notifications.core.completion_handlers;
import java.util.List;

public interface PermissionCompletionHandler {
    public void handle(List<String> missingPermissions);
}
