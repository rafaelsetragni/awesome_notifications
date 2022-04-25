package me.carda.awesome_notifications.core.listeners;

import me.carda.awesome_notifications.core.models.returnedData.ActionReceived;

public interface AwesomeActionEventListener {
    public void onNewActionReceived(String eventName, ActionReceived actionReceived);
}
