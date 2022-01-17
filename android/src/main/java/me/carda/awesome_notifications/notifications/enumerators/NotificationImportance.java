package me.carda.awesome_notifications.notifications.enumerators;

import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;
import me.carda.awesome_notifications.utils.IntegerUtils;

public enum NotificationImportance {
    None,
    Min,
    Low,
    Default,
    High,
    Max;

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
}
