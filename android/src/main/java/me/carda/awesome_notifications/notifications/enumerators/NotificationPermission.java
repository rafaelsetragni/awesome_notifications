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
     * [Vibration] The ability to vibrates the device.
     */
    Vibration,

    /**
     * [Lights] The ability to turn on alert lights on device.
     */
    Light,

    /**
     * [CriticalAlert] The ability to play sounds for critical alerts.
     */
    CriticalAlert,


    /**
     * [OverrideDnD] The ability to deactivate DnD when needs to show critical alerts.
     */
    OverrideDnD,

    /**
     * [Provisional] The ability to post noninterrupting notifications provisionally to the Notification Center.
     */
    Provisional,

    PreciseAlarms,
    FullScreenIntent,
    /**
     * [Car] The ability to display notifications in a CarPlay environment.
     */
    Car
}
