package me.carda.awesome_notifications.core.utils;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public class CompareUtils {

    public static boolean assertEqualObjects(Object object1, Object object2){
        if(object1 == object2)
            return true;

        if(object1 == null || object2 == null)
            return false;

        if(object1.equals(object2))
            return true;

        if(object1 instanceof Number)
            if(object2 instanceof Number)
                return assertEqualNumbers(object1, object2);
            else
                return false;

        if(object1 instanceof List)
            if(object2 instanceof List)
                return assertEqualLists(object1, object2);
            else
                return false;

        if(object1 instanceof Map)
            if(object2 instanceof Map)
                return assertEqualMaps(object1, object2);
            else
                return false;

        return false;
    }

    public static boolean assertEqualNumbers(Object object1, Object object2) {
        if(!(object1 instanceof Number)) return false;
        if(!(object2 instanceof Number)) return false;

        BigDecimal b1 = BigDecimal.valueOf(((Number) object1).doubleValue());
        BigDecimal b2 = BigDecimal.valueOf(((Number) object2).doubleValue());
        return b1.compareTo(b2) == 0;
    }

    @SuppressWarnings("unchecked")
    public static boolean assertEqualMaps(Object object1, Object object2) {
        if(object1 == null || object2 == null)
            return false;

        if(!(object1 instanceof Map)) return false;
        if(!(object2 instanceof Map)) return false;

        Map<Object, Object> map1 = (Map<Object, Object>) object1;
        Map<Object, Object> map2 = (Map<Object, Object>) object2;

        if (map1.size() != map2.size())
            return false;

        for (Map.Entry<Object, Object> entry : map1.entrySet()) {
            Object key1 = entry.getKey();
            if (map2.containsKey(key1) && assertEqualObjects(entry.getValue(), map2.get(key1)))
                continue;
            return false;
        }

        return true;
    }

    @SuppressWarnings("unchecked")
    public static boolean assertEqualLists(Object object1, Object object2) {
        if(object1 == null || object2 == null)
            return false;

        if(!(object1 instanceof List)) return false;
        if(!(object2 instanceof List)) return false;

        List<Object> list1 = (List<Object>) object1;
        List<Object> list2 = (List<Object>) object2;

        if (list1.size() != list2.size())
            return false;

        List<Object> cloned = new ArrayList<>(list2);
        for(Object value1 : list1) {
            boolean foundEqual = false;
            for (Object value2 : cloned) {
                if (CompareUtils.assertEqualObjects(value1, value2)) {
                    foundEqual = true;
                    break;
                }
            }
            if(!foundEqual)
                return false;
            else
                cloned.remove(value1);
        }

        return true;
    }
}
