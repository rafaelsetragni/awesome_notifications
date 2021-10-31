package me.carda.awesome_notifications.utils;

public class IntegerUtils {

    // Note: sometimes Json parser converts Integer into Double objects
    public static Integer extractInteger(Object object){
        return extractInteger(object, 0);
    }

    public static Integer convertToInt(Object object){
        Integer intValue = 0;
        if(object != null) {

            if (object instanceof Number) {
                intValue = ((Number) object).intValue();
            } else
            if (object instanceof Enum) {
                intValue = ((Enum) object).ordinal();
            } else
            if (object instanceof String) {
                try {
                    intValue = Integer.valueOf((String) object);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }
        return intValue;
    }

    public static Boolean isBetween(Integer value, Integer min, Integer max){
        return value >= min && value <= max;
    }

    // Note: sometimes Json parser converts Integer into Double objects
    public static Integer extractInteger(Object value, Object defaultValue){
        if(value == null){
            return convertToInt(defaultValue);
        }
        return convertToInt(value);
    }

    public static int generateNextRandomId() {
        int max = 2147483646;
        long tsLong = System.currentTimeMillis();
        return (int) (tsLong % max + 1);
    }
}
