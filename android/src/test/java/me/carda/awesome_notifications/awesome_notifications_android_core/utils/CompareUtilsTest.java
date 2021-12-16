package me.carda.awesome_notifications.awesome_notifications_android_core.utils;

import org.junit.Test;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;

import static org.junit.Assert.*;

public class CompareUtilsTest {

    @Test
    public void assertEqualObjects() {

        assertTrue("null references are equal", CompareUtils.assertEqualObjects(null, null));

        assertTrue("primitive objects with equal values must return true", CompareUtils.assertEqualObjects(1,1));
        assertTrue("primitive objects and Number values with equal values must return true", CompareUtils.assertEqualObjects(new Integer(1),1));
        assertTrue("primitive objects and Number values with equal values must return true", CompareUtils.assertEqualObjects(1,new Integer(1)));
        assertTrue("Number objects with equal values must return true", CompareUtils.assertEqualObjects(new Double(1.0),new Integer(1)));
        assertTrue("String objects with equal values must return true", CompareUtils.assertEqualObjects("test","test"));

        assertFalse("primitive objects with unequal values must return false", CompareUtils.assertEqualObjects(1,0));
        assertFalse("null is never equal to an object and must return false", CompareUtils.assertEqualObjects("null",null));
        assertFalse("null is never equal to an object and must return false", CompareUtils.assertEqualObjects(null,"null"));
        assertFalse("String objects with different values must return false", CompareUtils.assertEqualObjects("test1","test2"));
    }

    @Test
    public void assertEqualNumbers(){

        assertTrue("Equal number values must be considered equal", CompareUtils.assertEqualNumbers(new Integer(1), new Double(1.000)));
        assertTrue("Equal number values must be considered equal", CompareUtils.assertEqualNumbers(new Integer(1), new Double(0.25*4)));
        assertTrue("Equal number values must be considered equal", CompareUtils.assertEqualNumbers(new Integer(1), new AtomicLong(1)));

        assertFalse("Different number values must be considered not equal", CompareUtils.assertEqualNumbers(new Integer(1), new Integer(2)));
        assertFalse("Different number values must be considered not equal", CompareUtils.assertEqualNumbers(new Integer(1), new Double(2.0)));

        assertFalse("Different number values must be considered not equal", CompareUtils.assertEqualNumbers(new Integer(1), new Double(Double.MAX_VALUE)));
        assertFalse("Different number values must be considered not equal", CompareUtils.assertEqualNumbers(new Integer(1), new Double(Double.MIN_VALUE)));
        assertFalse("Different number values must be considered not equal", CompareUtils.assertEqualNumbers(new Integer(1), new Double(1.000001)));
    }

    @Test
    public void assertEqualLists(){
        List<Object> objectList1 = Arrays.asList(
            1,
            "test1",
            null,
            2.0,
            1.0,
            null,
            Arrays.asList(1, "test2"));

        List<Object> objectList2 = new ArrayList(objectList1);

        assertTrue("Equal lists must be considered equal", CompareUtils.assertEqualLists(objectList1, objectList2));

        objectList2.remove("test1");
        objectList2.add("test1");
        assertTrue("Equal lists must be considered equal", CompareUtils.assertEqualLists(objectList1, objectList2));

        objectList2.remove("test1");
        objectList2.add("test2");
        assertFalse("Different lists must be considered equal", CompareUtils.assertEqualLists(objectList1, objectList2));

        objectList2.remove("test2");
        assertFalse("Different lists must be considered not equal", CompareUtils.assertEqualLists(objectList1, objectList2));
    }

    @Test
    public void assertEqualMap() {
        Map<Object, Object> objectMap1 = new HashMap<Object, Object>() {{
            put("key1", "value1");
            put("key2", "value2");
            put("key3", 1);
            put("key4", 1.0);
            put("key5", null);
            put("key6", Arrays.asList(1, "test2"));
        }};

        Map<Object, Object> objectMap2 = new HashMap<Object, Object>() {{
            put("key1", "value1");
            put("key2", "value2");
            put("key3", 1.0);
            put("key4", 1);
            put("key5", null);
            put("key6", Arrays.asList(1.0, "test2"));
        }};

        assertTrue("Equal maps must be considered equal", CompareUtils.assertEqualMaps(objectMap1, objectMap2));

        objectMap2.put("key2", "value3");
        assertFalse("Different maps must be considered not equal", CompareUtils.assertEqualMaps(objectMap1, objectMap2));
        objectMap2.put("key2", "value2");

        objectMap2.remove("key4");
        assertFalse("Different maps must be considered not equal", CompareUtils.assertEqualMaps(objectMap1, objectMap2));
    }
}