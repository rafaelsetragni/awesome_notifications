package me.carda.awesome_notifications.core.enumerators;

import org.junit.Test;

import static org.junit.Assert.*;

public class NotificationLifeCycleTest {

    @Test
    public void testEnumOrder() {
        String errorMessage = "";

        assertEquals(errorMessage, 0, NotificationLifeCycle.Foreground.ordinal());
        assertEquals(errorMessage, 1, NotificationLifeCycle.Background.ordinal());
        assertEquals(errorMessage, 2, NotificationLifeCycle.AppKilled.ordinal());
    }
}