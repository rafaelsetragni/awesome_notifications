package me.carda.awesome_notifications.awesome_notifications_core.managers;

import android.app.Activity;
import android.app.Application;
import android.app.Application.ActivityLifecycleCallbacks;

import android.content.Context;
import android.os.Bundle;
import android.util.Log;

import java.util.ArrayList;
import java.util.List;

import androidx.annotation.NonNull;
import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.ProcessLifecycleOwner;

import me.carda.awesome_notifications.awesome_notifications_core.AwesomeNotifications;
import me.carda.awesome_notifications.awesome_notifications_core.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.awesome_notifications_core.listeners.AwesomeLifeCycleEventListener;

public class LifeCycleManager implements ActivityLifecycleCallbacks {

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

    // ********************************************************

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

            if(AwesomeNotifications.debug)
                Log.d(TAG, "LiceCycleManager listener successfully attached to Android");
        }
    }

    private boolean wasNotCreated = true;
    private boolean hasGoneForeground = false;

    private NotificationLifeCycle oldLifeCycle = null;
    private Lifecycle.State oldLifeState = null;
    public void updateAppLifeCycle(NotificationLifeCycle lifeCycle, Lifecycle.State state, Activity activity){

        appLifeCycle = lifeCycle;

        if (appLifeCycle == NotificationLifeCycle.Foreground)
            hasGoneForeground = true;

        if(AwesomeNotifications.debug)
            Log.d(TAG, "Android lifeCycle: "+state);

        if(oldLifeCycle != lifeCycle || oldLifeState != state){
            oldLifeCycle = lifeCycle;
            oldLifeState = state;
            notify(state, activity);

            if(AwesomeNotifications.debug)
                Log.d(TAG, "App is now "+lifeCycle);
        }
    }

    @Override
    public void onActivityCreated(Activity activity, Bundle savedInstanceState) {
        updateAppLifeCycle(
                hasGoneForeground ?
                        NotificationLifeCycle.Background :
                        NotificationLifeCycle.AppKilled,
                Lifecycle.State.CREATED,
                activity);
    }

    @Override
    public void onActivityStarted(Activity activity) {
        if(wasNotCreated){
            wasNotCreated = false;
            updateAppLifeCycle(
                    NotificationLifeCycle.AppKilled,
                    Lifecycle.State.CREATED,
                    activity);
        }

        updateAppLifeCycle(
                hasGoneForeground ?
                        NotificationLifeCycle.Background :
                        NotificationLifeCycle.AppKilled,
                Lifecycle.State.STARTED,
                activity);
    }

    @Override
    public void onActivityResumed(Activity activity) {
        updateAppLifeCycle(
                NotificationLifeCycle.Foreground,
                Lifecycle.State.RESUMED,
                activity);
    }

    @Override
    public void onActivityPaused(Activity activity) {
        updateAppLifeCycle(
                NotificationLifeCycle.Foreground,
                Lifecycle.State.STARTED,
                activity);
    }

    @Override
    public void onActivityStopped(Activity activity) {
        updateAppLifeCycle(
                NotificationLifeCycle.Background,
                Lifecycle.State.CREATED,
                activity);
    }

    @Override
    public void onActivityDestroyed(Activity activity) {
        updateAppLifeCycle(
                NotificationLifeCycle.AppKilled,
                Lifecycle.State.DESTROYED,
                activity);
    }

    @Override
    public void onActivitySaveInstanceState(Activity activity, Bundle outState) {
        Lifecycle.State state =
                ProcessLifecycleOwner
                        .get()
                        .getLifecycle()
                        .getCurrentState();

        updateAppLifeCycle(
                NotificationLifeCycle.Background,
                state,
                activity);
    }
}
