package me.carda.awesome_notifications.notifications.enumerators;

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
    Public,
}
