package me.carda.awesome_notifications.utils;

public class StringUtils {
    public static Boolean isNullOrEmpty(String string){
        return string == null || string.trim().isEmpty();
    }
    public static String getValueOrDefault(String value, String defaultValue){
        return isNullOrEmpty(value) ? defaultValue : value;
    }
}
