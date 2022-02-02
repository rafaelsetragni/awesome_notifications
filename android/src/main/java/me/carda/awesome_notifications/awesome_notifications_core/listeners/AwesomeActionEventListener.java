package me.carda.awesome_notifications.awesome_notifications_core.listeners;

import me.carda.awesome_notifications.awesome_notifications_core.models.returnedData.ActionReceived;

public interface AwesomeActionEventListener {
    public void onNewActionReceived(String eventName, ActionReceived actionReceived);
}
