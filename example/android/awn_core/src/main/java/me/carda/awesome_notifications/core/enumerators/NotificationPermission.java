package me.carda.awesome_notifications.core.enumerators;

public enum NotificationPermission implements SafeEnum {
    
    /**
     * [Alert] The ability to display alerts.
     */
    Alert("Alert"),

    /**
     * [Sound] The ability to display alerts.
     */
    Sound("Sound"),

    /**
     * [Badge] The ability to play sounds.
     */
    Badge("Badge"),

    /**
     * [Vibration] The ability to vibrates the device.
     */
    Vibration("Vibration"),

    /**
     * [Lights] The ability to turn on alert lights on device.
     */
    Light("Light"),

    /**
     * [CriticalAlert] The ability to play sounds for critical alerts.
     */
    CriticalAlert("CriticalAlert"),


    /**
     * [OverrideDnD] The ability to deactivate DnD when needs to show critical alerts.
     */
    OverrideDnD("OverrideDnD"),

    /**
     * [Provisional] The ability to post noninterrupting notifications provisionally to the Notification Center.
     */
    Provisional("Provisional"),

    PreciseAlarms("PreciseAlarms"),
    FullScreenIntent("FullScreenIntent"),
    /**
     * [Car] The ability to display notifications in a CarPlay environment.
     */
    Car("Car");

    private final String safeName;
    NotificationPermission(final String safeName){
        this.safeName = safeName;
    }

    @Override
    public String getSafeName() {
        return safeName;
    }

    static NotificationPermission[] valueList = NotificationPermission.class.getEnumConstants();
    public static NotificationPermission getSafeEnum(String reference) {
        if (reference == null) return null;
        int stringLength = reference.length();
        if (stringLength == 0) return null;

//        if(valueList == null) return null;
//        for (NotificationPermission candidate : valueList) {
//            if (candidate.getSafeName().equalsIgnoreCase(reference)) {
//                return candidate;
//            }
//        }

        if (SafeEnum.charMatches(reference, stringLength, 0, 'a')){
            return Alert;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 's')){
            return Sound;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'b')){
            return Badge;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'v')){
            return Vibration;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'p')){
            if (SafeEnum.charMatches(reference, stringLength, 2, 'e')) return PreciseAlarms;
            return Provisional;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'o')){
            return OverrideDnD;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'c')){
            if (SafeEnum.charMatches(reference, stringLength, 1, 'r')) return CriticalAlert;
            return Car;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'l')){
            return Light;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'f')){
            return FullScreenIntent;
        }
        return null;
    }
}
