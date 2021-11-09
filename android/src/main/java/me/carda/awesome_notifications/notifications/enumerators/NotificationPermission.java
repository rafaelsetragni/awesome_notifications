package me.carda.awesome_notifications.notifications.enumerators;

public enum NotificationPermission {
    
    /**
     * [Alert] The ability to display alerts.
     */
    Alert,

    /**
     * [Sound] The ability to display alerts.
     */
    Sound,

    /**
     * [Badge] The ability to play sounds.
     */
    Badge,

    /**
     * [CriticalAlert] The ability to play sounds for critical alerts.
     */
    CriticalAlert,

    /**
     * [Provisional] The ability to post noninterrupting notifications provisionally to the Notification Center.
     */
    Provisional,

    /**
     * [Car] The ability to display notifications in a CarPlay environment.
     */
    Car
}
