package me.carda.awesome_notifications.core.managers;

import android.content.Context;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import androidx.test.InstrumentationRegistry;

import static org.junit.Assert.*;

public class StatusBarManagerTest {

    Context context;

    @Before
    public void setUp() throws Exception {
        context = InstrumentationRegistry.getTargetContext();
    }

    @After
    public void tearDown() throws Exception {
    }

    @Test
    public void getInstance() {
        StatusBarManager instance1 = StatusBarManager.getInstance(context);
        assertNotNull("getInstance does not returned the singleton reference", instance1);

        StatusBarManager instance2 = StatusBarManager.getInstance(context);
        assertNotNull("getInstance does not returned the singleton reference", instance1);
        assertEquals("The singleton implementation does not guarantee the same instances for every call", instance1, instance2);

        for(int counter = 0; counter < 10; counter++)
            assertEquals(
                    "The singleton implementation does not guarantee the same instances for every call",
                    instance2, StatusBarManager.getInstance(context));
    }

    @Test
    public void closeStatusBar() {
        //StatusBarManager.
    }

    @Test
    public void showNotificationOnStatusBar() {
    }

    @Test
    public void dismissNotification() {
    }

    @Test
    public void dismissNotificationsByChannelKey() {
    }

    @Test
    public void dismissNotificationsByGroupKey() {
    }

    @Test
    public void dismissAllNotifications() {
    }

    @Test
    public void isFirstActiveOnGroupKey() {
    }

    @Test
    public void isFirstActiveOnChannelKey() {
    }

    @Test
    public void unregisterActiveNotification() {
    }

    @Test
    public void unregisterActiveGroupKey() {
    }

    @Test
    public void getAndroidNotificationById() {
    }

    @Test
    public void getAllAndroidActiveNotificationsByChannelKey() {
    }

    @Test
    public void getAllAndroidActiveNotificationsByGroupKey() {
    }
}