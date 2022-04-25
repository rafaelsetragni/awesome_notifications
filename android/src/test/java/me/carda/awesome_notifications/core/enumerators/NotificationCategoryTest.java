package me.carda.awesome_notifications.core.enumerators;

import org.junit.Test;

import static org.junit.Assert.*;

public class NotificationCategoryTest {

    @Test
    public void testEnumOrder() {
        String errorMessage = "";

        assertEquals(errorMessage, 0, NotificationCategory.Alarm.ordinal());
        assertEquals(errorMessage, 1, NotificationCategory.Call.ordinal());
        assertEquals(errorMessage, 2, NotificationCategory.Email.ordinal());
        assertEquals(errorMessage, 3, NotificationCategory.Error.ordinal());
        assertEquals(errorMessage, 4, NotificationCategory.Event.ordinal());
        assertEquals(errorMessage, 5, NotificationCategory.LocalSharing.ordinal());
        assertEquals(errorMessage, 6, NotificationCategory.Message.ordinal());
        assertEquals(errorMessage, 7, NotificationCategory.MissedCall.ordinal());
        assertEquals(errorMessage, 8, NotificationCategory.Navigation.ordinal());
        assertEquals(errorMessage, 9, NotificationCategory.Progress.ordinal());
        assertEquals(errorMessage, 10, NotificationCategory.Promo.ordinal());
        assertEquals(errorMessage, 11, NotificationCategory.Recommendation.ordinal());
        assertEquals(errorMessage, 12, NotificationCategory.Reminder.ordinal());
        assertEquals(errorMessage, 13, NotificationCategory.Service.ordinal());
        assertEquals(errorMessage, 14, NotificationCategory.Social.ordinal());
        assertEquals(errorMessage, 15, NotificationCategory.Status.ordinal());
        assertEquals(errorMessage, 16, NotificationCategory.StopWatch.ordinal());
        assertEquals(errorMessage, 17, NotificationCategory.Transport.ordinal());
        assertEquals(errorMessage, 18, NotificationCategory.Workout.ordinal());
    }

    @Test
    public void assertAndroidCategoryValues() {

        String errorMessage =
                "The respective value of NotificationCategory for Android native " +
                        "is not the same as expected following the official documentation";

        assertEquals(errorMessage, "alarm", NotificationCategory.Alarm.rawValue);
        assertEquals(errorMessage, "call", NotificationCategory.Call.rawValue);
        assertEquals(errorMessage, "email", NotificationCategory.Email.rawValue);
        assertEquals(errorMessage, "err", NotificationCategory.Error.rawValue);
        assertEquals(errorMessage, "event", NotificationCategory.Event.rawValue);
        assertEquals(errorMessage, "location_sharing", NotificationCategory.LocalSharing.rawValue);
        assertEquals(errorMessage, "msg", NotificationCategory.Message.rawValue);
        assertEquals(errorMessage, "missed_call" , NotificationCategory.MissedCall.rawValue);
        assertEquals(errorMessage, "navigation", NotificationCategory.Navigation.rawValue);
        assertEquals(errorMessage, "progress", NotificationCategory.Progress.rawValue);
        assertEquals(errorMessage, "promo", NotificationCategory.Promo.rawValue);
        assertEquals(errorMessage, "recommendation", NotificationCategory.Recommendation.rawValue);
        assertEquals(errorMessage, "reminder", NotificationCategory.Reminder.rawValue);
        assertEquals(errorMessage, "service", NotificationCategory.Service.rawValue);
        assertEquals(errorMessage, "social", NotificationCategory.Social.rawValue);
        assertEquals(errorMessage, "status", NotificationCategory.Status.rawValue);
        assertEquals(errorMessage, "stopwatch" , NotificationCategory.StopWatch.rawValue);
        assertEquals(errorMessage, "transport", NotificationCategory.Transport.rawValue);
        assertEquals(errorMessage, "workout", NotificationCategory.Workout.rawValue);

    }

}