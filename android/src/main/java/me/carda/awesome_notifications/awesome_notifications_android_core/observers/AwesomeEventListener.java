package me.carda.awesome_notifications.awesome_notifications_android_core.observers;

import java.io.Serializable;

public interface AwesomeEventListener {
    public void onNewAwesomeEvent(String eventType, Serializable content);
}
