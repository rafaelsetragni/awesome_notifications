package me.carda.awesome_notifications.awesome_notifications_core.enumerators;

import android.app.NotificationManager;

import org.junit.Test;

import androidx.core.app.NotificationCompat;

import static org.junit.Assert.*;

public class NotificationImportanceTest {

    @Test
    public void testEnumOrder() {
        String errorMessage = "";

        assertEquals(errorMessage, 0, NotificationImportance.None.ordinal());
        assertEquals(errorMessage, 1, NotificationImportance.Min.ordinal());
        assertEquals(errorMessage, 2, NotificationImportance.Low.ordinal());
        assertEquals(errorMessage, 3, NotificationImportance.Default.ordinal());
        assertEquals(errorMessage, 4, NotificationImportance.High.ordinal());
        assertEquals(errorMessage, 5, NotificationImportance.Max.ordinal());
    }

    @Test
    public void toAndroidPriority() {

        String errorMessage = "";

        assertEquals(errorMessage, NotificationCompat.PRIORITY_MIN, NotificationImportance.toAndroidPriority(NotificationImportance.None));
        assertEquals(errorMessage, NotificationCompat.PRIORITY_MIN, NotificationImportance.toAndroidPriority(NotificationImportance.Min));
        assertEquals(errorMessage, NotificationCompat.PRIORITY_LOW, NotificationImportance.toAndroidPriority(NotificationImportance.Low));
        assertEquals(errorMessage, NotificationCompat.PRIORITY_DEFAULT, NotificationImportance.toAndroidPriority(NotificationImportance.Default));
        assertEquals(errorMessage, NotificationCompat.PRIORITY_HIGH, NotificationImportance.toAndroidPriority(NotificationImportance.High));
        assertEquals(errorMessage, NotificationCompat.PRIORITY_MAX, NotificationImportance.toAndroidPriority(NotificationImportance.Max));

        assertEquals(errorMessage, NotificationCompat.PRIORITY_DEFAULT, NotificationImportance.toAndroidPriority(null));
    }

    @Test
    public void toAndroidImportance() {

        String errorMessage = "";

        assertEquals(errorMessage, NotificationManager.IMPORTANCE_NONE, NotificationImportance.toAndroidImportance(NotificationImportance.None));
        assertEquals(errorMessage, NotificationManager.IMPORTANCE_MIN, NotificationImportance.toAndroidImportance(NotificationImportance.Min));
        assertEquals(errorMessage, NotificationManager.IMPORTANCE_LOW, NotificationImportance.toAndroidImportance(NotificationImportance.Low));
        assertEquals(errorMessage, NotificationManager.IMPORTANCE_DEFAULT, NotificationImportance.toAndroidImportance(NotificationImportance.Default));
        assertEquals(errorMessage, NotificationManager.IMPORTANCE_HIGH, NotificationImportance.toAndroidImportance(NotificationImportance.High));
        assertEquals(errorMessage, NotificationManager.IMPORTANCE_MAX, NotificationImportance.toAndroidImportance(NotificationImportance.Max));

        assertEquals(errorMessage, NotificationManager.IMPORTANCE_DEFAULT, NotificationImportance.toAndroidImportance(null));
    }

    @Test
    public void fromAndroidPriority() {

        String errorMessage = "";

        assertEquals(errorMessage, NotificationImportance.Min, NotificationImportance.fromAndroidPriority(NotificationCompat.PRIORITY_MIN));
        assertEquals(errorMessage, NotificationImportance.Low, NotificationImportance.fromAndroidPriority(NotificationCompat.PRIORITY_LOW));
        assertEquals(errorMessage, NotificationImportance.Default, NotificationImportance.fromAndroidPriority(NotificationCompat.PRIORITY_DEFAULT));
        assertEquals(errorMessage, NotificationImportance.High, NotificationImportance.fromAndroidPriority(NotificationCompat.PRIORITY_HIGH));
        assertEquals(errorMessage, NotificationImportance.Max, NotificationImportance.fromAndroidPriority(NotificationCompat.PRIORITY_MAX));

        assertEquals(errorMessage, NotificationImportance.Min, NotificationImportance.fromAndroidPriority(-3));
        assertEquals(errorMessage, NotificationImportance.Max, NotificationImportance.fromAndroidPriority(3));
    }

    @Test
    public void fromAndroidImportance() {

        String errorMessage = "";

        assertEquals(errorMessage, NotificationImportance.None, NotificationImportance.fromAndroidImportance(NotificationManager.IMPORTANCE_NONE));
        assertEquals(errorMessage, NotificationImportance.Min, NotificationImportance.fromAndroidImportance(NotificationManager.IMPORTANCE_MIN));
        assertEquals(errorMessage, NotificationImportance.Low, NotificationImportance.fromAndroidImportance(NotificationManager.IMPORTANCE_LOW));
        assertEquals(errorMessage, NotificationImportance.Default, NotificationImportance.fromAndroidImportance(NotificationManager.IMPORTANCE_DEFAULT));
        assertEquals(errorMessage, NotificationImportance.High, NotificationImportance.fromAndroidImportance(NotificationManager.IMPORTANCE_HIGH));
        assertEquals(errorMessage, NotificationImportance.Max, NotificationImportance.fromAndroidImportance(NotificationManager.IMPORTANCE_MAX));

        assertEquals(errorMessage, NotificationImportance.None, NotificationImportance.fromAndroidImportance(-1));
        assertEquals(errorMessage, NotificationImportance.Max, NotificationImportance.fromAndroidImportance(6));
    }
}