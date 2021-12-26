package me.carda.awesome_notifications.awesome_notifications_android_core.managers;

import android.app.Activity;
import android.app.Application;
import android.app.Application.ActivityLifecycleCallbacks;

import android.content.Context;
import android.os.Bundle;

import java.util.ArrayList;
import java.util.List;

import androidx.annotation.NonNull;
import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.ProcessLifecycleOwner;

import me.carda.awesome_notifications.awesome_notifications_android_core.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.awesome_notifications_android_core.observers.AwesomeLifeCycleEventListener;

public class LifeCycleManager implements ActivityLifecycleCallbacks {

    protected static NotificationLifeCycle appLifeCycle = NotificationLifeCycle.AppKilled;
    public static NotificationLifeCycle getApplicationLifeCycle(){
        return appLifeCycle;
    }

    // ************** SINGLETON PATTERN ***********************

    static LifeCycleManager instance;

    private LifeCycleManager(){
    }

    public static LifeCycleManager getInstance() {
        if (instance == null)
            instance = new LifeCycleManager();
        return instance;
    }

    // ********************************************************

    // ************** OBSERVER PATTERN ***********************

    List<AwesomeLifeCycleEventListener> listeners = new ArrayList<>();

    public LifeCycleManager subscribe(@NonNull AwesomeLifeCycleEventListener listener) {
        listeners.add(listener);
        return this;
    }

    public LifeCycleManager unsubscribe(@NonNull AwesomeLifeCycleEventListener listener) {
        listeners.remove(listener);
        return this;
    }

    public void notify(@NonNull Lifecycle.State eventType, @NonNull Activity activity) {
        for (AwesomeLifeCycleEventListener listener : listeners)
            listener.onNewLifeCycleEvent(eventType, activity);
    }

    // ********************************************************

    boolean hasNotStarted = true;
    public void startListeners(Context applicationContext){
        if(hasNotStarted) {
            hasNotStarted = false;
            ((Application) applicationContext).registerActivityLifecycleCallbacks(this);
        }
    }

    private boolean hasGoneForeground = false;
    private NotificationLifeCycle oldLifeCycle = null;
    public void updateAppLifeCycle(NotificationLifeCycle lifeCycle, Activity activity){

        Lifecycle.State state =
                ProcessLifecycleOwner
                        .get()
                        .getLifecycle()
                        .getCurrentState();

        appLifeCycle = lifeCycle;

        if (appLifeCycle == NotificationLifeCycle.Foreground)
            hasGoneForeground = true;

        if(oldLifeCycle != appLifeCycle){
            oldLifeCycle = appLifeCycle;
            notify(state, activity);
        }
    }

    @Override
    public void onActivityCreated(Activity activity, Bundle savedInstanceState) {
        updateAppLifeCycle(
                hasGoneForeground ?
                        NotificationLifeCycle.Background :
                        NotificationLifeCycle.AppKilled,
                activity);
    }

    @Override
    public void onActivityStarted(Activity activity) {
        updateAppLifeCycle(
                hasGoneForeground ?
                        NotificationLifeCycle.Background :
                        NotificationLifeCycle.AppKilled,
                activity);
    }

    @Override
    public void onActivityResumed(Activity activity) {
        updateAppLifeCycle(NotificationLifeCycle.Foreground, activity);
    }

    @Override
    public void onActivityPaused(Activity activity) {
        updateAppLifeCycle(NotificationLifeCycle.Foreground, activity);
    }

    @Override
    public void onActivityStopped(Activity activity) {
        updateAppLifeCycle(NotificationLifeCycle.Background, activity);
    }

    @Override
    public void onActivitySaveInstanceState(Activity activity, Bundle outState) {
        updateAppLifeCycle(NotificationLifeCycle.Background, activity);
    }

    @Override
    public void onActivityDestroyed(Activity activity) {
        updateAppLifeCycle(NotificationLifeCycle.AppKilled, activity);
    }
}
