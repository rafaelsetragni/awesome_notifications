package me.carda.awesome_notifications.core.enumerators;

public enum LogLevel implements SafeEnum {
    none("none"),
    error("error"),
    warnings("warnings"),
    all("all");

    private final String safeName;
    LogLevel(final String safeName){
        this.safeName = safeName;
    }

    @Override
    public String getSafeName() {
        return this.safeName;
    }

    static LogLevel[] valueList = LogLevel.class.getEnumConstants();
    public static LogLevel getSafeEnum(String reference) {
        if (reference == null) return null;
        int stringLength = reference.length();
        if (stringLength == 0) return null;

//        if(valueList == null) return null;
//        for (LogLevel candidate : valueList) {
//            if (candidate.getSafeName().equalsIgnoreCase(reference)) {
//                return candidate;
//            }
//        }

        if (SafeEnum.charMatches(reference, stringLength, 0, 'n')){
            return none;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'a')){
            return all;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'e')){
            return error;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'w')){
            return warnings;
        }
        return null;
    }
}
