package me.carda.awesome_notifications.core.enumerators;

import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;

public enum NotificationImportance implements SafeEnum {
    None("None"),
    Min("Min"),
    Low("Low"),
    Default("Default"),
    High("High"),
    Max("Max");

    private final String safeName;
    NotificationImportance(final String safeName){
        this.safeName = safeName;
    }

    public static int toAndroidPriority(@Nullable NotificationImportance importance){
        switch (importance == null ? NotificationImportance.Default : importance){
            case None:
            case Min: return NotificationCompat.PRIORITY_MIN;
            case Low: return NotificationCompat.PRIORITY_LOW;
            case High: return NotificationCompat.PRIORITY_HIGH;
            case Max: return NotificationCompat.PRIORITY_MAX;
            case Default:
            default:
                return NotificationCompat.PRIORITY_DEFAULT;
        }
        //return Math.min(Math.max(IntegerUtils.extractInteger(importance) - 3, -2), 2);
    }

    public static int toAndroidImportance(@Nullable NotificationImportance importance){
        return importance == null ? NotificationImportance.Default.ordinal() : importance.ordinal();
    }

    public static NotificationImportance fromAndroidPriority(int ordinal){
        if(ordinal < -2) ordinal = -2;
        if(ordinal > 2) ordinal = 2;
        switch (ordinal){
            case NotificationCompat.PRIORITY_MIN: return NotificationImportance.Min;
            case NotificationCompat.PRIORITY_LOW: return NotificationImportance.Low;
            case NotificationCompat.PRIORITY_HIGH: return NotificationImportance.High;
            case NotificationCompat.PRIORITY_MAX: return NotificationImportance.Max;
            case NotificationCompat.PRIORITY_DEFAULT:
            default: return NotificationImportance.Default;
        }
        //return NotificationImportance.values()[Math.max(Math.min(ordinal + 3, 5), 0)];
    }

    public static NotificationImportance fromAndroidImportance(int ordinal){
        if(ordinal < 0) ordinal = 0;
        if(ordinal > 5) ordinal = 5;
        return NotificationImportance.values()[ordinal];
    }

    @Override
    public String getSafeName() {
        return safeName;
    }

    static NotificationImportance[] valueList = NotificationImportance.class.getEnumConstants();
    public static NotificationImportance getSafeEnum(String reference) {
        if (reference == null) return null;
        int stringLength = reference.length();
        if (stringLength == 0) return null;

//        if(valueList == null) return null;
//        for (NotificationImportance candidate : valueList) {
//            if (candidate.getSafeName().equalsIgnoreCase(reference)) {
//                return candidate;
//            }
//        }

        if (SafeEnum.charMatches(reference, stringLength, 0, 'h')){
            return High;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'd')){
            return Default;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'l')){
            return Low;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'm')){
            if (SafeEnum.charMatches(reference, stringLength, 1, 'a')) return Max;
            return Min;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'n')){
            return None;
        }
        return null;
    }
}
