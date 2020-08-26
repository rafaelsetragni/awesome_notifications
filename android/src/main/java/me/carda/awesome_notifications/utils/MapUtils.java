package me.carda.awesome_notifications.utils;

import com.google.common.base.Optional;

import java.util.Map;

public class MapUtils {

    private static String TAG = "NotificationParser";

    public static Boolean isNullOrEmptyKey(Map map, String key){

        if(map == null || map.isEmpty() || !map.containsKey(key))
            return true;

        Object value = map.get(key);

        if(value == null) return true;

        if (value instanceof String){
            if(((String) value).isEmpty()) return true;
        }

        if (value instanceof Map<?,?>){
            if(((Map<?,?>) value).isEmpty()) return true;
        }

        return false;
    }

    public static Boolean isNullOrEmpty(Map map){
        return map == null || map.isEmpty();
    }

    public static <T> Optional<T> extractArgument(Object object, Class<T> expectedClass){
        if(object == null)
            return Optional.absent();

        try {
            if(expectedClass.isInstance(object)){
                return Optional.of(expectedClass.cast(object));
            }
        }
        catch (Exception e){
            System.out.println(TAG + ": Argument is not a type of " + Optional.class.getSimpleName());
        }

        return Optional.absent();
    }

    public static <T> Optional<T> extractValue(Map map, String key, Class<T> expectedClass){
        if(MapUtils.isNullOrEmptyKey(map, key))
            return Optional.absent();

        try {

            Object value = map.get(key);

            if(Number.class.isAssignableFrom(expectedClass)){
                if(value instanceof Number){
                    switch (expectedClass.getSimpleName()){
                        case "Integer": value = ((Number)value).intValue();     break;
                        case "Double":  value = ((Number)value).doubleValue();  break;
                        case "Float":   value = ((Number)value).floatValue();   break;
                        case "Long":    value = ((Number)value).longValue();    break;
                        case "Short":   value = ((Number)value).shortValue();   break;
                        case "Byte":    value = ((Number)value).byteValue();    break;
                    }
                }
            }

            if(expectedClass.isInstance(value)){
                return Optional.of(expectedClass.cast(value));
            }

            // TODO REGRESSION TO PRIMITIVES. IS NOT SO NECESSARY, DUE MAPS AND GSON DO NOT USE THEN. ITS A OVERKILL SOLUTION
            /*if(expectedClass.isPrimitive()) {
                Class objectClass = value.getClass();
                if (!objectClass.isPrimitive()) {
                    Class primitiveObjectClass = (Class) objectClass.getField("TYPE").get(null);
                    if(expectedClass.equals(primitiveObjectClass)){
                        primitiveObjectClass.
                        return Optional.of(T.cast(value));
                    }
                }
            }*/
        }
        catch (Exception e){
            System.out.println(TAG + ": " + key + " is not a type of " + Optional.class.getSimpleName());
        }

        return Optional.absent();
    }

}
