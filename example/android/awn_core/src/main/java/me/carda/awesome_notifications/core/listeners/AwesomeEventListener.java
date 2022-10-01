package me.carda.awesome_notifications.core.listeners;

import java.util.Map;

public interface AwesomeEventListener {
    public void onNewAwesomeEvent(String eventType, Map<String, Object> content);
}
