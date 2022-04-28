package me.carda.awesome_notifications.core.enumerators;

import androidx.annotation.NonNull;

public enum NotificationCategory implements SafeEnum {
    Alarm("Alarm",  "alarm"),
    Call("Call", "call"),
    Email("Email", "email"),
    Error("Error", "err"),
    Event("Event", "event"),
    LocalSharing("LocalSharing", "location_sharing"),
    Message("Message", "msg"),
    MissedCall("MissedCall", "missed_call" ),
    Navigation("Navigation", "navigation"),
    Progress("Progress", "progress"),
    Promo("Promo", "promo"),
    Recommendation("Recommendation", "recommendation"),
    Reminder("Reminder", "reminder"),
    Service("Service", "service"),
    Social("Social", "social"),
    Status("Status", "status"),
    StopWatch("StopWatch", "stopwatch" ),
    Transport("Transport", "transport"),
    Workout("Workout", "workout");

    private final String safeName;
    public final String rawValue;
    NotificationCategory(@NonNull String safeName, @NonNull String rawValue) {
        this.safeName = safeName;
        this.rawValue = rawValue;
    }

    @Override
    public String getSafeName() {
        return safeName;
    }

    static NotificationCategory[] valueList = NotificationCategory.class.getEnumConstants();
    public static NotificationCategory getSafeEnum(String reference) {
        if (reference == null) return null;
        int stringLength = reference.length();
        if (stringLength == 0) return null;

        if(valueList == null) return null;
        for (NotificationCategory candidate : valueList) {
            if (candidate.getSafeName().equalsIgnoreCase(reference)) {
                return candidate;
            }
        }

//    public static NotificationCategory getSafeEnum(String name) {
//        if (name == null) return null;
//        int stringLength = name.length();
//        if (stringLength == 0) return null;
//        else if (SafeEnum.charMatches(name, stringLength, 0, 'a')){
//            return Alarm;
//        }
//        else if (SafeEnum.charMatches(name, stringLength, 0, 'c')){
//            return Call;
//        }
//        else if (SafeEnum.charMatches(name, stringLength, 0, 'm')){
//            if(SafeEnum.charMatches(name, stringLength, 1, 'e')) return Message;
//            return MissedCall;
//        }
//        else if (SafeEnum.charMatches(name, stringLength, 0, 'r')){
//            if(SafeEnum.charMatches(name, stringLength, 2, 'c')) return Recommendation;
//            return Reminder;
//        }
//        else if (SafeEnum.charMatches(name, stringLength, 0, 'l')){
//            return LocalSharing;
//        }
//        else if (SafeEnum.charMatches(name, stringLength, 0, 'n')){
//            return Navigation;
//        }
//        else if (SafeEnum.charMatches(name, stringLength, 0, 'p')){
//            if(SafeEnum.charMatches(name, stringLength, 3, 'g')) return Progress;
//            return Promo;
//        }
//        else if (SafeEnum.charMatches(name, stringLength, 0, 'e')){
//            if(SafeEnum.charMatches(name, stringLength, 1, 'm')) return Email;
//            if(SafeEnum.charMatches(name, stringLength, 6, 'r')) return Error;
//            return Event;
//        }
//        else if (SafeEnum.charMatches(name, stringLength, 0, 's')){
//            if(SafeEnum.charMatches(name, stringLength, 1, 'e')) return Service;
//            if(SafeEnum.charMatches(name, stringLength, 2, 'c')) return Social;
//            if(SafeEnum.charMatches(name, stringLength, 1, 't')) return Status;
//            return StopWatch;
//        }
//        else if (SafeEnum.charMatches(name, stringLength, 0, 'w')){
//            return Workout;
//        }
//        else if (SafeEnum.charMatches(name, stringLength, 0, 't')){
//            return Transport;
//        }
        return null;
    }
}
