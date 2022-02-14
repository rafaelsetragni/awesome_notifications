package me.carda.awesome_notifications.awesome_notifications_core.enumerators;

import android.app.Notification;

import org.junit.Test;

import static org.junit.Assert.*;

public class NotificationPrivacyTest {

    @Test
    public void testEnumOrder() {
        String errorMessage = "";

        assertEquals(errorMessage, 0, NotificationPrivacy.Secret.ordinal());
        assertEquals(errorMessage, 1, NotificationPrivacy.Private.ordinal());
        assertEquals(errorMessage, 2, NotificationPrivacy.Public.ordinal());
    }

    @Test
    public void testRespectiveAndroidValues(){
        String errorMessage = "";

        assertEquals(errorMessage, Notification.VISIBILITY_PUBLIC, NotificationPrivacy.toAndroidPrivacy(NotificationPrivacy.Public));
        assertEquals(errorMessage, Notification.VISIBILITY_PRIVATE, NotificationPrivacy.toAndroidPrivacy(NotificationPrivacy.Private));
        assertEquals(errorMessage, Notification.VISIBILITY_SECRET, NotificationPrivacy.toAndroidPrivacy(NotificationPrivacy.Secret));
        assertEquals(errorMessage, Notification.VISIBILITY_PRIVATE, NotificationPrivacy.toAndroidPrivacy(null));
    }
}