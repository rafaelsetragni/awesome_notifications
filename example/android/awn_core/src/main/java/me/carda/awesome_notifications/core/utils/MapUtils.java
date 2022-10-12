package me.carda.awesome_notifications.core.utils;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.google.common.base.Optional;
import com.google.common.primitives.Bytes;
import com.google.common.primitives.Doubles;
import com.google.common.primitives.Floats;
import com.google.common.primitives.Ints;
import com.google.common.primitives.Longs;
import com.google.common.primitives.Shorts;

import java.util.Calendar;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.TimeZone;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import me.carda.awesome_notifications.core.logs.Logger;

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

        if (value instanceof List<?>){
            return ((List<?>) value).isEmpty();
        }

        return false;
    }

    public static Boolean isNullOrEmpty(Map map){
        return map == null || map.isEmpty();
    }

    public static <T> Optional<T> extractArgument(
            @Nullable Object object,
            @NonNull Class<T> expectedClass){
        if(object == null)
            return Optional.absent();

        try {
            if(expectedClass.isInstance(object)){
                return Optional.of(expectedClass.cast(object));
            }
        }
        catch (Exception e){
            Logger.d(TAG,"Argument is not a type of " + Optional.class.getSimpleName());
        }

        return Optional.absent();
    }

    @SuppressWarnings("unchecked")
    public static <T> Optional<T> extractValue(Map map, String key, Class<T> expectedClass){
        if(MapUtils.isNullOrEmptyKey(map, key))
            return Optional.absent();

        try {

            Object value = map.get(key);

            if(expectedClass == TimeZone.class){
                if(value == null)
                    return Optional.absent();

                if (!(value instanceof String))
                    return Optional.absent();

                TimeZone finalTimeZone =
                        TimeZoneUtils
                            .getInstance()
                            .getValidTimeZone((String) value);

                if(finalTimeZone == null)
                    return Optional.absent();

                return Optional.fromNullable(expectedClass.cast(finalTimeZone));
            }

            if(expectedClass == Calendar.class){
                if(value == null)
                    return Optional.absent();

                Calendar finalCalendar =
                        CalendarUtils
                                .getInstance()
                                .calendarFromString((String) value);

                return Optional.fromNullable(expectedClass.cast(finalCalendar));
            }

            if(Number.class.isAssignableFrom(expectedClass)){

                // Hexadecimal color conversion
                if(expectedClass == Long.class && value instanceof String){
                    Pattern pattern = Pattern.compile("(0x|#)(\\w{2})?(\\w{6})", Pattern.CASE_INSENSITIVE);
                    Matcher matcher = pattern.matcher((String) value);

                    // 0x000000 hexadecimal color conversion
                    if(matcher.find()) {
                        String transparency = matcher.group(2);
                        String textValue = (transparency == null ? "FF" : transparency) + matcher.group(3);
                        long finalValue = 0L;
                        if(!StringUtils.getInstance().isNullOrEmpty(textValue)){
                            finalValue += Long.parseLong(textValue, 16);
                        }
                        return Optional.fromNullable(expectedClass.cast(finalValue));
                    }
                }

                if(value instanceof Number){
                    String expectedClassName = expectedClass.getSimpleName().toLowerCase();
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
                String expectedClassName = expectedClass.getSimpleName().toLowerCase();
                switch (expectedClassName){
                    case "double[]":  value = Doubles.toArray((List)value);  break;
                    case "long[]":    value = Longs.toArray((List)value);   break;
                    case "short[]":   value = Shorts.toArray((List)value);   break;
                    case "int[]":     value = Ints.toArray((List)value);   break;
                    case "byte[]":    value = Bytes.toArray((List)value);   break;
                    case "float[]":   value = Floats.toArray((List)value);   break;
                }
                return Optional.fromNullable(expectedClass.cast(value));
            }

            if(expectedClass.isInstance(value)){
                return Optional.fromNullable(expectedClass.cast(value));
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
            Logger.d(TAG, key + " is not a type of " + Optional.class.getSimpleName());
        }

        return Optional.absent();
    }

    // This is fancier than Map.putAll(Map)
    @SuppressWarnings("rawtypes")
    public static Map deepMerge(@Nullable Map original, @Nullable Map newMap) {
        if (original == null) {
            if (newMap == null) return null;
            return new HashMap<>(newMap);
        }
        if (newMap == null) return new HashMap<>(original);

        original = new HashMap<>(original);
        for (Object key : newMap.keySet()) {
            if (newMap.get(key) instanceof Map && original.get(key) instanceof Map) {
                Map originalChild = (Map) original.get(key);
                Map newChild = (Map) newMap.get(key);
                original.put(key, deepMerge(originalChild, newChild));
            } else {
                original.put(key, newMap.get(key));
            }
        }
        return original;
    }

}
