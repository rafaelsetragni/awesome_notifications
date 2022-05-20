package me.carda.awesome_notifications.core.enumerators;


public enum NotificationSource implements SafeEnum {
    Local("Local"),
    Schedule("Schedule"),
    ForegroundService("ForegroundService"),
    Firebase("Firebase"),
    OneSignal("OneSignal"),
    CallKit("CallKit");

    private final String safeName;
    NotificationSource(final String safeName){
        this.safeName = safeName;
    }

    @Override
    public String getSafeName() {
        return safeName;
    }

    static NotificationSource[] valueList = NotificationSource.class.getEnumConstants();
    public static NotificationSource getSafeEnum(String reference) {
        if (reference == null) return null;
        int stringLength = reference.length();
        if (stringLength == 0) return null;

//        if(valueList == null) return null;
//        for (NotificationSource candidate : valueList) {
//            if (candidate.getSafeName().equalsIgnoreCase(reference)) {
//                return candidate;
//            }
//        }

        if (SafeEnum.charMatches(reference, stringLength, 0, 'l')){
            return Local;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'f')){
            if (SafeEnum.charMatches(reference, stringLength, 1, 'o')) return ForegroundService;
            return Firebase;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 's')){
            return Schedule;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'c')){
            return CallKit;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'o')){
            return OneSignal;
        }
        return null;
    }
}
