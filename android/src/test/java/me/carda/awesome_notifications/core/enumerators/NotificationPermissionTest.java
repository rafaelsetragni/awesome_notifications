package me.carda.awesome_notifications.core.enumerators;

import org.junit.Test;

import static org.junit.Assert.*;

public class NotificationPermissionTest {

    @Test
    public void testEnumOrder() {
        String errorMessage = "";

        assertEquals(errorMessage, 0, NotificationPermission.Alert.ordinal());
        assertEquals(errorMessage, 1, NotificationPermission.Sound.ordinal());
        assertEquals(errorMessage, 2, NotificationPermission.Badge.ordinal());
        assertEquals(errorMessage, 3, NotificationPermission.Vibration.ordinal());
        assertEquals(errorMessage, 4, NotificationPermission.Light.ordinal());
        assertEquals(errorMessage, 5, NotificationPermission.CriticalAlert.ordinal());
        assertEquals(errorMessage, 6, NotificationPermission.OverrideDnD.ordinal());
        assertEquals(errorMessage, 7, NotificationPermission.Provisional.ordinal());
        assertEquals(errorMessage, 8, NotificationPermission.PreciseAlarms.ordinal());
        assertEquals(errorMessage, 9, NotificationPermission.FullScreenIntent.ordinal());
        assertEquals(errorMessage, 10, NotificationPermission.Car.ordinal());
    }
}