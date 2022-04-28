package me.carda.awesome_notifications.core.enumerators;

import android.app.Notification;

import androidx.annotation.Nullable;

public enum NotificationPrivacy implements SafeEnum {

    /**
     * Notification visibility: Do not reveal any part of this notification on a secure lockscreen.
     */
    Secret("Secret"),

    /**
     * Notification visibility: Show this notification on all lockscreens, but conceal sensitive or
     * private information on secure lockscreens.
     */
    Private("Private"),

    /**
     * Notification visibility: Show this notification on every lockscreens.
     */
    Public("Public");

    private final String safeName;
    NotificationPrivacy(final String safeName){
        this.safeName = safeName;
    }

    @Override
    public String getSafeName() {
        return safeName;
    }

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

    static NotificationPrivacy[] valueList = NotificationPrivacy.class.getEnumConstants();
    public static NotificationPrivacy getSafeEnum(String reference) {
        if (reference == null) return null;
        int stringLength = reference.length();
        if (stringLength == 0) return null;

//        if(valueList == null) return null;
//        for (NotificationPrivacy candidate : valueList) {
//            if (candidate.getSafeName().equalsIgnoreCase(reference)) {
//                return candidate;
//            }
//        }

        if (SafeEnum.charMatches(reference, stringLength, 0, 's')){
            return Secret;
        }
        if (SafeEnum.charMatches(reference, stringLength, 1, 'u')){
            return Public;
        }
        if (SafeEnum.charMatches(reference, stringLength, 1, 'r')){
            return Private;
        }
        return null;
    }
}
