package me.carda.awesome_notifications.awesome_notifications_android_core.utils;

public class BooleanUtils {
    public static boolean getValue(Boolean booleanObject){
        return booleanObject != null && booleanObject;
    }
    public static boolean getValueOrDefault(Boolean booleanObject, Boolean defaultValue){
        return booleanObject == null ? getValue(defaultValue) : getValue(booleanObject);
    }
}
