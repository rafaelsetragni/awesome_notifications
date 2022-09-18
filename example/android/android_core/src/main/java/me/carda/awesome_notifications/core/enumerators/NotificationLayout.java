package me.carda.awesome_notifications.core.enumerators;

public enum NotificationLayout implements SafeEnum {
    Default("Default"),
    BigPicture("BigPicture"),
    BigText("BigText"),
    Inbox("Inbox"),
    ProgressBar("ProgressBar"),
    Messaging("Messaging"),
    MessagingGroup("MessagingGroup"),
    MediaPlayer("MediaPlayer");

    private final String safeName;
    NotificationLayout(final String safeName){
        this.safeName = safeName;
    }

    @Override
    public String getSafeName() {
        return safeName;
    }

    static NotificationLayout[] valueList = NotificationLayout.class.getEnumConstants();
    public static NotificationLayout getSafeEnum(String reference) {
        if (reference == null) return null;
        int stringLength = reference.length();
        if (stringLength == 0) return null;

//        if(valueList == null) return null;
//        for (NotificationLayout candidate : valueList) {
//            if (candidate.getSafeName().equalsIgnoreCase(reference)) {
//                return candidate;
//            }
//        }

        if (SafeEnum.charMatches(reference, stringLength, 0, 'd')){
            return Default;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'b')){
            if(SafeEnum.charMatches(reference, stringLength, 3, 'p')) return BigPicture;
            return BigText;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'm')){
            if(SafeEnum.charMatches(reference, stringLength, 2, 'd')) return MediaPlayer;
            if(SafeEnum.charMatches(reference, stringLength, 9, 'g')) return MessagingGroup;
            return Messaging;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'i')){
            return Inbox;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'p')){
            return ProgressBar;
        }
        return null;
    }
}

