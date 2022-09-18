package me.carda.awesome_notifications.core.utils;

import java.security.SecureRandom;

public class IntegerUtils {

    public static Integer convertToInt(Object object){
        int intValue = 0;
        if(object != null) {

            if (object instanceof Number) {
                intValue = ((Number) object).intValue();
            } else
            if (object instanceof Enum) {
                intValue = ((Enum) object).ordinal();
            } else
            if (object instanceof String) {
                try {
                    intValue = Integer.parseInt((String) object);
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

    private static final SecureRandom random = new SecureRandom();
    public static int generateNextRandomId() {
        int randomValue = random.nextInt();
        return randomValue < 0 ? randomValue * -1 : randomValue;
    }
}
