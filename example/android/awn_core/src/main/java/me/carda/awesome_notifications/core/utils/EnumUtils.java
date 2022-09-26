package me.carda.awesome_notifications.core.utils;

public class EnumUtils {

    public static final String TAG = "EnumUtils";

    // ************** SINGLETON PATTERN ***********************

    protected static EnumUtils instance;

    protected EnumUtils(){}

    public static EnumUtils getInstance() {
        if (instance == null)
            instance = new EnumUtils();
        return instance;
    }

    // ********************************************************
/*
    public <T extends Enum<T>> String enumToString(
            @Nullable T enumeratorValue
    ){
        if (enumeratorValue == null) return null;
        return enumeratorValue.toString();
    }

    public <T extends Enum<T>> String enumToString(
            @Nullable T enumeratorValue,
            @Nullable T defaultValue
    ){
        if (enumeratorValue == null)
            return enumToString(defaultValue);
        else
            return enumToString(enumeratorValue);
    }

    public <T extends Enum<T>> SafeEnum<T> stringToEnum(
            @Nullable String text,
            @NonNull Class<Enum<T>> type
    ){
        Enum<T>[] valueList = type.getEnumConstants();
        if(valueList == null) return null;

        for (SafeEnum<T> candidate : valueList) {
            if (candidate.getSafeName().equalsIgnoreCase(text)) {
                return candidate;
            }
        }

        return null;
    }*/
}
