package me.carda.awesome_notifications.core.managers;

import androidx.annotation.NonNull;
import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.LifecycleObserver;
import androidx.lifecycle.OnLifecycleEvent;
import androidx.lifecycle.ProcessLifecycleOwner;

import java.util.ArrayList;
import java.util.List;

import me.carda.awesome_notifications.core.AwesomeNotifications;
import me.carda.awesome_notifications.core.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.core.listeners.AwesomeLifeCycleEventListener;
import me.carda.awesome_notifications.core.logs.Logger;

public class LifeCycleManager implements LifecycleObserver {

    private static final String TAG = "LifeCycleManager";

    protected static NotificationLifeCycle appLifeCycle = NotificationLifeCycle.AppKilled;
    public static NotificationLifeCycle getApplicationLifeCycle(){
        return appLifeCycle;
    }

    // ************** SINGLETON PATTERN ***********************

    static LifeCycleManager instance;

    private LifeCycleManager(){
    }

    public static LifeCycleManager getInstance() {
        if (instance == null) {
            instance = new LifeCycleManager();
        }
        return instance;
    }

    // ************** OBSERVER PATTERN ************************

    List<AwesomeLifeCycleEventListener> listeners = new ArrayList<>();

    public LifeCycleManager subscribe(@NonNull AwesomeLifeCycleEventListener listener) {
        listeners.add(listener);
        return this;
    }

    public LifeCycleManager unsubscribe(@NonNull AwesomeLifeCycleEventListener listener) {
        listeners.remove(listener);
        return this;
    }

    public void notify(@NonNull NotificationLifeCycle lifeCycle) {
        for (AwesomeLifeCycleEventListener listener : listeners)
            listener.onNewLifeCycleEvent(lifeCycle);
    }

    // ********************************************************

    boolean hasStarted = false;
    public void startListeners(){
        if(hasStarted) return;
        hasStarted = true;

        ProcessLifecycleOwner.get().getLifecycle().addObserver(this);

        if(AwesomeNotifications.debug)
            Logger.d(TAG, "LiceCycleManager listener successfully attached to Android");
    }

    public void stopListeners(){
        if(!hasStarted) return;
        hasStarted = false;
        ProcessLifecycleOwner.get().getLifecycle().removeObserver(this);

        if(AwesomeNotifications.debug)
            Logger.d(TAG, "LiceCycleManager listener successfully removed from Android");
    }

    boolean hasGoneForeground = false;
    public void updateAppLifeCycle(NotificationLifeCycle lifeCycle){
        if(appLifeCycle == lifeCycle)
            return;

        hasGoneForeground =
                hasGoneForeground ||
                appLifeCycle == NotificationLifeCycle.Foreground;

        appLifeCycle = lifeCycle;
        notify(appLifeCycle);

        if(AwesomeNotifications.debug)
            Logger.d(TAG, "App is now "+lifeCycle);
    }

    @OnLifecycleEvent(Lifecycle.Event.ON_CREATE)
    public void onCreated() {
        updateAppLifeCycle(
                hasGoneForeground ?
                        NotificationLifeCycle.Background :
                        NotificationLifeCycle.AppKilled);
    }

    boolean wasNotCreated = true;
    @OnLifecycleEvent(Lifecycle.Event.ON_START)
    public void onStarted() {
        updateAppLifeCycle(
                hasGoneForeground ?
                        NotificationLifeCycle.Background :
                        NotificationLifeCycle.AppKilled);
    }

    @OnLifecycleEvent(Lifecycle.Event.ON_RESUME)
    public void onResumed() {
        updateAppLifeCycle(
                NotificationLifeCycle.Foreground);
    }

    @OnLifecycleEvent(Lifecycle.Event.ON_PAUSE)
    public void onPaused() {
        updateAppLifeCycle(
                NotificationLifeCycle.Foreground);
    }

    @OnLifecycleEvent(Lifecycle.Event.ON_STOP)
    public void onStopped() {
        updateAppLifeCycle(
                NotificationLifeCycle.Background);
    }

    @OnLifecycleEvent(Lifecycle.Event.ON_DESTROY)
    public void onDestroyed() {
        updateAppLifeCycle(
                NotificationLifeCycle.AppKilled);
    }

}
