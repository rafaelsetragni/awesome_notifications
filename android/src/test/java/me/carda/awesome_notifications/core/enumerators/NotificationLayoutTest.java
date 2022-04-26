package me.carda.awesome_notifications.core.enumerators;

import org.junit.Test;

import static org.junit.Assert.*;

public class NotificationLayoutTest {

    @Test
    public void testEnumOrder() {
        String errorMessage = "";

        assertEquals(errorMessage, 0, NotificationLayout.Default.ordinal());
        assertEquals(errorMessage, 1, NotificationLayout.BigPicture.ordinal());
        assertEquals(errorMessage, 2, NotificationLayout.BigText.ordinal());
        assertEquals(errorMessage, 3, NotificationLayout.Inbox.ordinal());
        assertEquals(errorMessage, 4, NotificationLayout.ProgressBar.ordinal());
        assertEquals(errorMessage, 5, NotificationLayout.Messaging.ordinal());
        assertEquals(errorMessage, 6, NotificationLayout.MessagingGroup.ordinal());
        assertEquals(errorMessage, 7, NotificationLayout.MediaPlayer.ordinal());
    }
}