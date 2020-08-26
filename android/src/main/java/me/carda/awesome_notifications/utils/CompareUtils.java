package me.carda.awesome_notifications.utils;

public class CompareUtils {

    public static Boolean assertEqualObjects(Object object1, Object object2){
        if(object1 == object2) return true;
        if(object1 == null || object2 == null) return false;
        if(object1.getClass() != object2.getClass()) return false;
        if(!object1.getClass().isPrimitive() && object1.equals(object2)) return true;
        return false;
    }
}
