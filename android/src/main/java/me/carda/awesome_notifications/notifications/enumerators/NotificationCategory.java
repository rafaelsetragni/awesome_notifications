package me.carda.awesome_notifications.notifications.enumerators;

public enum NotificationCategory {
    Alarm("alarm"),
    Call("call"),
    Email("email"),
    Error("err"),
    Event("event"),
    LocalSharing("location_sharing"),
    Message("msg"),
    MissedCall("missed_call" ),
    Navigation("navigation"),
    Progress("progress"),
    Promo("promo"),
    Recommendation("recommendation"),
    Reminder("reminder"),
    Service("service"),
    Social("social"),
    Status("status"),
    StopWatch("stopwatch" ),
    Transport("transport"),
    Workout("workout");

    public final String rawValue;

    NotificationCategory(String s) {
        rawValue = s;
    }
}
