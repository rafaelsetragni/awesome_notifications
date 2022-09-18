package me.carda.awesome_notifications.core.enumerators;

import java.util.Locale;

public enum GroupSort implements SafeEnum {
    Asc("Asc"),
    Desc("Desc");

    private final String safeName;
    GroupSort(final String safeName){
        this.safeName = safeName.toLowerCase(Locale.ENGLISH);
    }

    @Override
    public String getSafeName() {
        return safeName;
    }

    static GroupSort[] valueList = GroupSort.class.getEnumConstants();
    public static GroupSort getSafeEnum(String reference) {
        if (reference == null) return null;
        int stringLength = reference.length();
        if (stringLength == 0) return null;

//        if(valueList == null) return null;
//        for (GroupSort candidate : valueList) {
//            if (candidate.getSafeName().equalsIgnoreCase(reference)) {
//                return candidate;
//            }
//        }

        if (SafeEnum.charMatches(reference, stringLength, 0, 'a')){
            return Asc;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'd')){
            return Desc;
        }
        return null;
    }
}
