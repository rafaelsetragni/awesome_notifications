package me.carda.awesome_notifications.core.listeners;

import me.carda.awesome_notifications.core.enumerators.NotificationLifeCycle;

public interface AwesomeLifeCycleEventListener {
    public void onNewLifeCycleEvent(NotificationLifeCycle lifeCycle);
}
