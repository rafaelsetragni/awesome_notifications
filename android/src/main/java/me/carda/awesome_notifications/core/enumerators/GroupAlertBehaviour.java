package me.carda.awesome_notifications.core.enumerators;

import java.util.Locale;

public enum GroupAlertBehaviour implements SafeEnum {
    All("All"),
    Summary("Summary"),
    Children("Children");

    private final String safeName;
    GroupAlertBehaviour(final String safeName){
        this.safeName = safeName.toLowerCase(Locale.ENGLISH);
    }

    @Override
    public String getSafeName() {
        return this.safeName;
    }

    static GroupAlertBehaviour[] valueList = GroupAlertBehaviour.class.getEnumConstants();
    public static GroupAlertBehaviour getSafeEnum(String reference) {
        if (reference == null) return null;
        int stringLength = reference.length();
        if (stringLength == 0) return null;

        if(valueList == null) return null;
        for (GroupAlertBehaviour candidate : valueList) {
            if (candidate.getSafeName().equalsIgnoreCase(reference)) {
                return candidate;
            }
        }

//    public static GroupAlertBehaviour getSafeEnum(String name) {
//        if (name == null) return null;
//        int stringLength = name.length();
//        if (stringLength == 0) return null;
//        else if (SafeEnum.charMatches(name, stringLength, 0, 'c')){
//            return Children;
//        }
//        else if (SafeEnum.charMatches(name, stringLength, 0, 'a')){
//            return All;
//        }
//        else if (SafeEnum.charMatches(name, stringLength, 0, 's')){
//            return Summary;
//        }
        return null;
    }
}
