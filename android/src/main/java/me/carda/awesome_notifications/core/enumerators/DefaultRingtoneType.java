package me.carda.awesome_notifications.core.enumerators;

public enum DefaultRingtoneType implements SafeEnum {
    Ringtone("Ringtone"),
    Notification("Notification"),
    Alarm("Alarm");

    private final String safeName;
    DefaultRingtoneType(final String safeName){
        this.safeName = safeName;
    }

    @Override
    public String getSafeName() {
        return safeName;
    }

    static DefaultRingtoneType[] valueList = DefaultRingtoneType.class.getEnumConstants();
    public static DefaultRingtoneType getSafeEnum(String reference) {
        if (reference == null) return null;
        int stringLength = reference.length();
        if (stringLength == 0) return null;

        if(valueList == null) return null;
        for (DefaultRingtoneType candidate : valueList) {
            if (candidate.getSafeName().equalsIgnoreCase(reference)) {
                return candidate;
            }
        }
//        if (name == null) return null;
//        int stringLength = name.length();
//        if (stringLength == 0) return null;
//        else if (SafeEnum.charMatches(name, stringLength, 0, 'n')){
//            return Notification;
//        }
//        else if (SafeEnum.charMatches(name, stringLength, 0, 'r')){
//            return Ringtone;
//        }
//        else if (SafeEnum.charMatches(name, stringLength, 0, 'a')){
//            return Alarm;
//        }
        return null;
    }
}
