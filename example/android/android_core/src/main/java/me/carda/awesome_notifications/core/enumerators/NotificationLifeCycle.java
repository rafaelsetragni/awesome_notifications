package me.carda.awesome_notifications.core.enumerators;

public enum NotificationLifeCycle implements SafeEnum {
    Foreground("Foreground"),
    Background("Background"),
    AppKilled("AppKilled");

    private final String safeName;
    NotificationLifeCycle(final String safeName){
        this.safeName = safeName;
    }

    @Override
    public String getSafeName() {
        return safeName;
    }

    static NotificationLifeCycle[] valueList = NotificationLifeCycle.class.getEnumConstants();
    public static NotificationLifeCycle getSafeEnum(String reference) {
        if (reference == null) return null;
        int stringLength = reference.length();
        if (stringLength == 0) return null;

//        if(valueList == null) return null;
//        for (NotificationLifeCycle candidate : valueList) {
//            if (candidate.getSafeName().equalsIgnoreCase(reference)) {
//                return candidate;
//            }
//        }

        if (SafeEnum.charMatches(reference, stringLength, 0, 'a')){
            return AppKilled;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'f')){
            return Foreground;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'b')){
            return Background;
        }
        return null;
    }
}
