package me.carda.awesome_notifications.awesome_notifications_android_core.managers;

import android.app.Activity;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import androidx.lifecycle.Lifecycle;
import me.carda.awesome_notifications.awesome_notifications_android_core.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.awesome_notifications_android_core.listeners.AwesomeLifeCycleEventListener;

import static org.junit.Assert.*;

public class LifeCycleManagerTest {

    Activity testActivity;
    LifeCycleListenerTester listenerTester;

    class LifeCycleListenerTester implements AwesomeLifeCycleEventListener {

        public Lifecycle.State lastState;
        public Activity lastActivity;

        @Override
        public void onNewLifeCycleEvent(Lifecycle.State androidLifeCycleState, Activity activity) {
            lastState = androidLifeCycleState;
            lastActivity = activity;
        }
    }

    @Before
    public void setUp() {
        testActivity = new Activity();
        listenerTester =  new LifeCycleListenerTester();
    }

    @After
    public void tearDown() {
    }

    @Test
    public void getApplicationLifeCycle() {
        LifeCycleManager.appLifeCycle = NotificationLifeCycle.Foreground;
        assertEquals("LifeCycle was not corrected returned", NotificationLifeCycle.Foreground, LifeCycleManager.getApplicationLifeCycle());
        LifeCycleManager.appLifeCycle = NotificationLifeCycle.Background;
        assertEquals("LifeCycle was not corrected returned", NotificationLifeCycle.Background, LifeCycleManager.getApplicationLifeCycle());
        LifeCycleManager.appLifeCycle = NotificationLifeCycle.AppKilled;
        assertEquals("LifeCycle was not corrected returned", NotificationLifeCycle.AppKilled, LifeCycleManager.getApplicationLifeCycle());
    }

    @Test
    public void getInstance() {
        LifeCycleManager.instance = null;
        assertNotNull("Singleton instance returned null", LifeCycleManager.getInstance());
        assertNotNull("Singleton instance returned null", LifeCycleManager.getInstance());
    }

    @Test
    public void subscribe() {
        LifeCycleManager.instance = null;
        LifeCycleManager.getInstance().subscribe(listenerTester);
        assertTrue("Event listener was not subscribed", LifeCycleManager.getInstance().listeners.contains(listenerTester));
    }

    @Test
    public void unsubscribe() {
        LifeCycleManager.instance = null;
        LifeCycleManager.getInstance().unsubscribe(listenerTester);
        assertFalse("Event listener was not unsubscribed", LifeCycleManager.getInstance().listeners.contains(listenerTester));
    }

    @Test
    public void testNotify() {
        LifeCycleManager.instance = null;
        LifeCycleManager.getInstance().subscribe(listenerTester);

        LifeCycleManager.getInstance().notify(Lifecycle.State.INITIALIZED, testActivity);
        assertEquals("Notify method send invalid attributes to listeners", listenerTester.lastState, Lifecycle.State.INITIALIZED);
        assertEquals("Notify method send invalid attributes to listeners", listenerTester.lastActivity, testActivity);

        LifeCycleManager.getInstance().notify(Lifecycle.State.CREATED, testActivity);
        assertEquals("Notify method send invalid attributes to listeners", listenerTester.lastState, Lifecycle.State.CREATED);
        assertEquals("Notify method send invalid attributes to listeners", listenerTester.lastActivity, testActivity);

        LifeCycleManager.getInstance().notify(Lifecycle.State.STARTED, testActivity);
        assertEquals("Notify method send invalid attributes to listeners", listenerTester.lastState, Lifecycle.State.STARTED);
        assertEquals("Notify method send invalid attributes to listeners", listenerTester.lastActivity, testActivity);

        LifeCycleManager.getInstance().notify(Lifecycle.State.RESUMED, testActivity);
        assertEquals("Notify method send invalid attributes to listeners", listenerTester.lastState, Lifecycle.State.RESUMED);
        assertEquals("Notify method send invalid attributes to listeners", listenerTester.lastActivity, testActivity);

        LifeCycleManager.getInstance().notify(Lifecycle.State.DESTROYED, testActivity);
        assertEquals("Notify method send invalid attributes to listeners", listenerTester.lastState, Lifecycle.State.DESTROYED);
        assertEquals("Notify method send invalid attributes to listeners", listenerTester.lastActivity, testActivity);
    }

    @Test
    public void startListeners() {
    }

    @Test
    public void updateAppLifeCycle() {
    }

    @Test
    public void onActivityCreated() {
        LifeCycleManager.instance = null;
        LifeCycleManager.getInstance().onActivityCreated(testActivity, null);
        assertEquals("", NotificationLifeCycle.AppKilled, LifeCycleManager.getApplicationLifeCycle());

        LifeCycleManager.getInstance().updateAppLifeCycle(NotificationLifeCycle.Foreground, testActivity);
        assertEquals("", NotificationLifeCycle.Foreground, LifeCycleManager.getApplicationLifeCycle());
    }

    @Test
    public void onActivityStarted() {
        LifeCycleManager.instance = null;
        LifeCycleManager.getInstance().onActivityStarted(testActivity);
        assertEquals("", NotificationLifeCycle.AppKilled, LifeCycleManager.getApplicationLifeCycle());

        LifeCycleManager.getInstance().updateAppLifeCycle(NotificationLifeCycle.Foreground, testActivity);
        assertEquals("", NotificationLifeCycle.Foreground, LifeCycleManager.getApplicationLifeCycle());
    }

    @Test
    public void onActivityResumed() {
        LifeCycleManager.instance = null;
        LifeCycleManager.getInstance().onActivityResumed(testActivity);
        assertEquals("", NotificationLifeCycle.Foreground, LifeCycleManager.getApplicationLifeCycle());
    }

    @Test
    public void onActivityPaused() {
        LifeCycleManager.instance = null;
        LifeCycleManager.getInstance().onActivityPaused(testActivity);
        assertEquals("", NotificationLifeCycle.Foreground, LifeCycleManager.getApplicationLifeCycle());
    }

    @Test
    public void onActivityStopped() {
        LifeCycleManager.instance = null;
        LifeCycleManager.getInstance().onActivityStopped(testActivity);
        assertEquals("", NotificationLifeCycle.Background, LifeCycleManager.getApplicationLifeCycle());
    }

    @Test
    public void onActivitySaveInstanceState() {
        LifeCycleManager.instance = null;
        LifeCycleManager.getInstance().onActivitySaveInstanceState(testActivity, null);
        assertEquals("", NotificationLifeCycle.Background, LifeCycleManager.getApplicationLifeCycle());
    }

    @Test
    public void onActivityDestroyed() {
        LifeCycleManager.instance = null;
        LifeCycleManager.getInstance().onActivityDestroyed(testActivity);
        assertEquals("", NotificationLifeCycle.AppKilled, LifeCycleManager.getApplicationLifeCycle());
    }
}