package me.carda.awesome_notifications.awesome_notifications_core.listeners;

import android.app.Activity;

import androidx.lifecycle.Lifecycle;

import me.carda.awesome_notifications.awesome_notifications_core.enumerators.NotificationLifeCycle;

public interface AwesomeLifeCycleEventListener {
    public void onNewLifeCycleEvent(NotificationLifeCycle lifeCycle);
}
