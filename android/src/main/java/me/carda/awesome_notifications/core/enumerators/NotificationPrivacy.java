package me.carda.awesome_notifications.core.enumerators;

import android.app.Notification;

import androidx.annotation.Nullable;

public enum NotificationPrivacy {

    /**
     * Notification visibility: Do not reveal any part of this notification on a secure lockscreen.
     */
    Secret,

    /**
     * Notification visibility: Show this notification on all lockscreens, but conceal sensitive or
     * private information on secure lockscreens.
     */
    Private,

    /**
     * Notification visibility: Show this notification on every lockscreens.
     */
    Public;

    public static int toAndroidPrivacy(@Nullable NotificationPrivacy importance){
        switch (importance == null ? NotificationPrivacy.Private : importance){
            case Secret:
                return Notification.VISIBILITY_SECRET;
            case Public:
                return Notification.VISIBILITY_PUBLIC;
            case Private:
            default:
                return Notification.VISIBILITY_PRIVATE;
        }
    }
}
