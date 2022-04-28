package me.carda.awesome_notifications.core.enumerators;


public enum NotificationSource implements SafeEnum {
    Local("Local"),
    Schedule("Schedule"),
    ForegroundService("ForegroundService"),
    Firebase("Firebase");

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

        if(valueList == null) return null;
        for (NotificationSource candidate : valueList) {
            if (candidate.getSafeName().equalsIgnoreCase(reference)) {
                return candidate;
            }
        }

//    public static NotificationSource getSafeEnum(String name) {
//        if (name == null) return null;
//        int stringLength = name.length();
//        if (stringLength == 0) return null;
//
//        else if (SafeEnum.charMatches(name, stringLength, 0, 'l')){
//            return Local;
//        }
//        else if (SafeEnum.charMatches(name, stringLength, 0, 'f')){
//            if (SafeEnum.charMatches(name, stringLength, 1, 'o')) return ForegroundService;
//            return Firebase;
//        }
//        else if (SafeEnum.charMatches(name, stringLength, 0, 's')){
//            return Schedule;
//        }
        return null;
    }
}
