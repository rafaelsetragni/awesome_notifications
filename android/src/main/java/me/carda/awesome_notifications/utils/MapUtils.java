package me.carda.awesome_notifications.utils;

import io.flutter.Log;

import com.google.common.base.Optional;
import com.google.common.primitives.Doubles;
import com.google.common.primitives.Floats;
import com.google.common.primitives.Longs;
import com.google.common.primitives.Shorts;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class MapUtils {

    private static String TAG = "MapUtils";

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
            Log.d(TAG,"Argument is not a type of " + Optional.class.getSimpleName());
        }

        return Optional.absent();
    }

    @SuppressWarnings("unchecked")
    public static <T> Optional<T> extractValue(Map map, String key, Class<T> expectedClass){
        if(MapUtils.isNullOrEmptyKey(map, key))
            return Optional.absent();

        try {

            Object value = map.get(key);

            if(Number.class.isAssignableFrom(expectedClass)){
                String expectedClassName = expectedClass.getSimpleName().toLowerCase();

                // Hexadecimal color conversion
                if(expectedClassName.equals("long") && value instanceof String){
                    Pattern pattern = Pattern.compile("(0x|#)(\\w{2})?(\\w{6})", Pattern.CASE_INSENSITIVE);
                    Matcher matcher = pattern.matcher((String) value);

                    // 0x000000 hexadecimal color conversion
                    if(matcher.find()) {
                        String transparency = matcher.group(1);
                        String textValue = (transparency == null ? "FF" : transparency) + matcher.group(2);
                        Long finalValue = 0L;
                        if(!StringUtils.isNullOrEmpty(textValue)){
                            finalValue += Long.parseLong(textValue, 16);
                        }
                        return Optional.of(expectedClass.cast(finalValue));
                    }
                }

                if(value instanceof Number){
                    switch (expectedClassName){
                        case "integer": value = ((Number)value).intValue();     break;
                        case "double":  value = ((Number)value).doubleValue();  break;
                        case "float":   value = ((Number)value).floatValue();   break;
                        case "long":    value = ((Number)value).longValue();    break;
                        case "short":   value = ((Number)value).shortValue();   break;
                        case "byte":    value = ((Number)value).byteValue();    break;
                    }
                }
            }

            if(value instanceof List && expectedClass.isArray()){
                switch (expectedClass.getComponentType().getSimpleName().toLowerCase()){
                    case "double":  value = Doubles.toArray((List)value);  break;
                    case "long":    value = Longs.toArray((List)value);   break;
                    case "short":   value = Shorts.toArray((List)value);   break;
                    case "integer":
                    case "byte":
                    case "float":   value = Floats.toArray((List)value);   break;
                }
                return Optional.of(expectedClass.cast(value));
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
            Log.d(TAG, key + " is not a type of " + Optional.class.getSimpleName());
        }

        return Optional.absent();
    }

}
