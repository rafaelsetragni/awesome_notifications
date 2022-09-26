package me.carda.awesome_notifications.core.enumerators;

import static android.app.Service.START_NOT_STICKY;
import static android.app.Service.START_REDELIVER_INTENT;
import static android.app.Service.START_STICKY;
import static android.app.Service.START_STICKY_COMPATIBILITY;

public enum ForegroundStartMode implements SafeEnum {

    stick("stick"),
    stickCompatibility("stickCompatibility"),
    notStick("notStick"),
    deliverIntent("deliverIntent");

    private final String safeName;
    ForegroundStartMode(final String safeName){
        this.safeName = safeName;
    }

    public int toAndroidStartMode() {
        switch (this){
            case notStick: return START_NOT_STICKY;
            case stickCompatibility: return START_STICKY_COMPATIBILITY;
            case deliverIntent: return START_REDELIVER_INTENT;
            case stick:
            default:
                return START_STICKY;
        }
    }

    @Override
    public String getSafeName() {
        return this.safeName;
    }

    static ForegroundStartMode[] valueList = ForegroundStartMode.class.getEnumConstants();
    public static ForegroundStartMode getSafeEnum(String reference) {
        if (reference == null) return null;
        int stringLength = reference.length();
        if (stringLength == 0) return null;

//        if(valueList == null) return null;
//        for (ForegroundStartMode candidate : valueList) {
//            if (candidate.getSafeName().equalsIgnoreCase(reference)) {
//                return candidate;
//            }
//        }

        if (SafeEnum.charMatches(reference, stringLength, 0, 's')){
            if(SafeEnum.charMatches(reference, stringLength, 5, 'c'))
                return stickCompatibility;
            return stick;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'n')){
            return notStick;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'd')){
            return deliverIntent;
        }
        return null;
    }
}
