package me.carda.awesome_notifications.awesome_notifications_android_core.enumerators;

import android.app.Notification;

import org.junit.Test;

import static org.junit.Assert.*;

public class NotificationSourceTest {

    @Test
    public void testEnumOrder() {
        String errorMessage = "";

        assertEquals(errorMessage, 0, NotificationSource.Local.ordinal());
        assertEquals(errorMessage, 1, NotificationSource.Schedule.ordinal());
        assertEquals(errorMessage, 2, NotificationSource.Firebase.ordinal());
        assertEquals(errorMessage, 3, NotificationSource.OneSignal.ordinal());
    }
}