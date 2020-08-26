package me.carda.awesome_notifications.utils;

public class BooleanUtils {
    public static boolean getValue(Boolean booleanObject){
        return booleanObject != null && booleanObject.booleanValue();
    }
    public static boolean getValueOrDefault(Boolean booleanObject, Boolean defaultValue){
        return booleanObject == null ? getValue(defaultValue) : getValue(booleanObject);
    }
}
