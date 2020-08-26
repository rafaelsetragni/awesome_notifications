package android.src.main.test.java.me.carda.awesome_notifications.utils;

import org.junit.Test;

import java.util.HashMap;
import java.util.Map;

import static org.junit.Assert.*;

public class MapUtilsTest {

    @Test
    public void isNullOrEmptyKey() {

        Map<String, Object> testMap = new HashMap<>();
        assertTrue(MapUtils.isNullOrEmptyKey(null, "testNullKey"));
        assertTrue(MapUtils.isNullOrEmptyKey(testMap, "testNullKey"));

        testMap.put("testNullKey", null);
        assertTrue(MapUtils.isNullOrEmptyKey(testMap, "testNullKey2"));
        assertTrue(MapUtils.isNullOrEmptyKey(testMap, "testNullKey"));

        testMap.put("testIntegerKey", 1);
        assertFalse(MapUtils.isNullOrEmptyKey(testMap, "testIntegerKey"));

        testMap.put("testEmptyString", "");
        assertTrue(MapUtils.isNullOrEmptyKey(testMap, "testEmptyString"));

        testMap.put("testStringKey", "test");
        assertFalse(MapUtils.isNullOrEmptyKey(testMap, "testStringKey"));

        testMap.put("testMapKey", new HashMap<>());
        assertTrue(MapUtils.isNullOrEmptyKey(testMap, "testMapKey"));

        testMap.put("testMapKey2", testMap);
        assertFalse(MapUtils.isNullOrEmptyKey(testMap, "testMapKey2"));
    }

    @Test
    public void extractValue() {

        Map<String, Object> testMap = new HashMap<>();

        testMap.put("testNullKey", null);
        testMap.put("testIntegerKey", 1);
        assertEquals(null, MapUtils.extractValue(testMap, "testNullKey", Integer.class).orNull());
        assertEquals((Integer)0, MapUtils.extractValue(testMap, "testNullKey", Integer.class).or(0));
        assertEquals((Integer)1, MapUtils.extractValue(testMap, "testIntegerKey", Integer.class).or(0));

        testMap.put("testDoubleKey", 1.0);
        assertEquals((Integer)1, MapUtils.extractValue(testMap, "testDoubleKey", Integer.class).or(0));
        assertEquals((Double)1.0, MapUtils.extractValue(testMap, "testDoubleKey", Double.class).or(0.0));
        assertEquals((Double)1.0, MapUtils.extractValue(testMap, "testIntegerKey", Double.class).or(0.0));

        testMap.put("testEmptyValue", "");
        testMap.put("testStringKey", "test");
        assertEquals("default", MapUtils.extractValue(testMap, "testNullKey", String.class).or("default"));
        assertEquals("default", MapUtils.extractValue(testMap, "testEmptyValue", String.class).or("default"));
        assertEquals("test", MapUtils.extractValue(testMap, "testStringKey", String.class).or("default"));

        Map<String, Object> emptyHashObject = new HashMap<>();
        testMap.put("testEmptyMapKey", emptyHashObject);
        testMap.put("testMapKey", testMap);
        assertEquals(null, MapUtils.extractValue(testMap, "testNullKey", Map.class).orNull());
        assertEquals(null, MapUtils.extractValue(testMap, "testStringKey", Map.class).orNull());
        assertEquals(new HashMap<>(), MapUtils.extractValue(testMap, "testNullKey", Map.class).or(new HashMap<>()));
        assertEquals(new HashMap<>(), MapUtils.extractValue(testMap, "testEmptyMapKey", Map.class).or(new HashMap<>()));
        assertEquals(testMap, MapUtils.extractValue(testMap, "testMapKey", Map.class).or(new HashMap<>()));
    }
}