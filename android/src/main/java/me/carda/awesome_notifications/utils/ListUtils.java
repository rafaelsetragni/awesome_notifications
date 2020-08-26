package me.carda.awesome_notifications.utils;

import java.util.List;

public class ListUtils {
    public static Boolean isNullOrEmpty(List<?> list){
        return list == null || list.isEmpty();
    }
}
