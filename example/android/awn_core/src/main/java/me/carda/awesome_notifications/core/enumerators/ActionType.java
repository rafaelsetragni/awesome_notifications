package me.carda.awesome_notifications.core.enumerators;

public enum ActionType implements SafeEnum {
    Default("Default"),
    DisabledAction("DisabledAction"),
    KeepOnTop("KeepOnTop"),
    SilentAction("SilentAction"),
    SilentBackgroundAction("SilentBackgroundAction"),
    DismissAction("DismissAction"),
    @Deprecated
    InputField("InputField");

    private final String safeName;
    ActionType(final String safeName){
        this.safeName = safeName;
    }

    @Override
    public String getSafeName() {
        return safeName;
    }

    static ActionType[] valueList = ActionType.class.getEnumConstants();
    public static ActionType getSafeEnum(String reference) {
        if (reference == null) return null;
        int stringLength = reference.length();
        if (stringLength == 0) return null;

//        if(valueList == null) return null;
//        for (ActionType candidate : valueList) {
//            if (candidate.getSafeName().equalsIgnoreCase(reference)) {
//                return candidate;
//            }
//        }

        if (SafeEnum.charMatches(reference, stringLength, 0, 'd')){
            if(SafeEnum.charMatches(reference, stringLength, 1, 'e')) return Default;
            if(SafeEnum.charMatches(reference, stringLength, 3, 'a')) return DisabledAction;
            return DismissAction;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 's')){
            if(SafeEnum.charMatches(reference, stringLength, 6, 'a')) return SilentAction;
            return SilentBackgroundAction;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'k')){
            return KeepOnTop;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'i')){
            return InputField;
        }
        return null;
    }
}
