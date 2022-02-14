package me.carda.awesome_notifications.awesome_notifications_core.enumerators;

import org.junit.Test;

import static org.junit.Assert.*;

public class DefaultRingtoneTypeTest {

    @Test
    public void testEnumOrder() {
        String errorMessage = "";

        assertEquals(errorMessage, 0, DefaultRingtoneType.Ringtone.ordinal());
        assertEquals(errorMessage, 1, DefaultRingtoneType.Notification.ordinal());
        assertEquals(errorMessage, 2, DefaultRingtoneType.Alarm.ordinal());
    }
}