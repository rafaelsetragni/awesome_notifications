package me.carda.awesome_notifications.awesome_notifications_android_core.observers;

import me.carda.awesome_notifications.awesome_notifications_android_core.models.returnedData.ActionReceived;

public interface AwesomeActionEventListener {
    public void onNewActionReceived(String eventName, ActionReceived actionReceived);
}
