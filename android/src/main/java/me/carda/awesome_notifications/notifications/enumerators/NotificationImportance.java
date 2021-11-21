package me.carda.awesome_notifications.notifications.enumerators;

import me.carda.awesome_notifications.utils.IntegerUtils;

public enum NotificationImportance {
    None,
    Min,
    Low,
    Default,
    High,
    Max;

    public static int toAndroidPriority(NotificationImportance importance){
        return Math.min(Math.max(IntegerUtils.extractInteger(importance) - 2, -2), 2);
    }

    public static int toAndroidImportance(NotificationImportance importance){
        return Math.min(Math.max(IntegerUtils.extractInteger(importance) - 2, -2), 2);
    }

    public static NotificationImportance fromAndroidPriority(int ordinal){
        return NotificationImportance.values()[ordinal+2];
    }

    public static NotificationImportance fromAndroidImportance(int ordinal){
        return NotificationImportance.values()[ordinal];
    }
}
