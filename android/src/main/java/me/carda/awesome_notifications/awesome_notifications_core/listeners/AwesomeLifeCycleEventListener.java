package me.carda.awesome_notifications.awesome_notifications_core.listeners;

import android.app.Activity;

import androidx.lifecycle.Lifecycle;

public interface AwesomeLifeCycleEventListener {
    public void onNewLifeCycleEvent(Lifecycle.State AndroidLifeCycleState, Activity activity);
}
