package me.carda.awesome_notifications.awesome_notifications_android_core.listeners;

import java.io.Serializable;
import java.util.Map;

public interface AwesomeEventListener {
    public void onNewAwesomeEvent(String eventType, Map<String, Object> content);
}
