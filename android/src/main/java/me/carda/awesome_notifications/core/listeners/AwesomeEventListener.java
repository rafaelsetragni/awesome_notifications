package me.carda.awesome_notifications.core.listeners;

import java.util.Map;
import java.io.Serializable;

public interface AwesomeEventListener {
    public void onNewAwesomeEvent(String eventType, Map<String, Object> content);
}
