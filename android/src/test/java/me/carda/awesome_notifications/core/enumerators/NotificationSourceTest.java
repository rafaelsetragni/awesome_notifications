package me.carda.awesome_notifications.core.enumerators;

import org.junit.Test;

import static org.junit.Assert.*;

public class NotificationSourceTest {

    @Test
    public void testEnumOrder() {
        String errorMessage = "";

        assertEquals(errorMessage, 0, NotificationSource.Local.ordinal());
        assertEquals(errorMessage, 1, NotificationSource.Schedule.ordinal());
        assertEquals(errorMessage, 2, NotificationSource.ForegroundService.ordinal());
        assertEquals(errorMessage, 3, NotificationSource.Firebase.ordinal());
        assertEquals(errorMessage, 4, NotificationSource.OneSignal.ordinal());
    }
}