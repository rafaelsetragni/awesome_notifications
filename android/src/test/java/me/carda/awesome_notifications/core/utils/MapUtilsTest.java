package me.carda.awesome_notifications.core.utils;

import org.junit.Assert;
import org.junit.Test;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.Assert.*;

public class MapUtilsTest {

    @Test
    public void testIsNullOrEmptyKey() {

        Map<String, Object> testMap = new HashMap<>();

        assertTrue("Not map objects must return true", MapUtils.isNullOrEmptyKey(null, "testNullKey"));
        assertTrue("Empty maps must return true", MapUtils.isNullOrEmptyKey(testMap, "testNullKey"));

        testMap.put("testNullKey", null);
        assertTrue("Invalid keys must return true", MapUtils.isNullOrEmptyKey(testMap, "testNullKey2"));
        assertTrue("Valid keys with null values must return true", MapUtils.isNullOrEmptyKey(testMap, "testNullKey"));

        testMap.put("testIntegerKey", 1);
        assertFalse("Valid keys with valid values must return false", MapUtils.isNullOrEmptyKey(testMap, "testIntegerKey"));

        testMap.put("testEmptyString", "");
        assertTrue("Valid keys with empty string values must return true", MapUtils.isNullOrEmptyKey(testMap, "testEmptyString"));

        testMap.put("testStringKey", "test");
        assertFalse("Valid keys with not empty string values must return false", MapUtils.isNullOrEmptyKey(testMap, "testStringKey"));

        testMap.put("testListKey", new ArrayList<>());
        assertTrue("Valid keys with empty list values must return true", MapUtils.isNullOrEmptyKey(testMap, "testMapKey"));

        testMap.put("testMapKey", new HashMap<>());
        assertTrue("Valid keys with empty map values must return true", MapUtils.isNullOrEmptyKey(testMap, "testMapKey"));
    }

    @Test
    public void testExtractValue() {
        List<Integer> testList = new ArrayList<>();
        Map<String, Object> testMap = new HashMap<>();

        testMap.put("testIntegerKey", 1);
        testMap.put("testStringKey", "1");

        assertNull("Null values must return null", MapUtils.extractArgument(null, String.class).orNull());
        assertNull("Not matched type values must return null", MapUtils.extractArgument("1", Integer.class).orNull());

        assertEquals("Match type values must return respective value", "", MapUtils.extractArgument("", String.class).orNull());
        assertNotEquals("Match type values must return respective value", "", MapUtils.extractArgument(" ", String.class).orNull());
        assertEquals("Match type values must return respective value", "1", MapUtils.extractArgument("1", String.class).orNull());

        assertEquals("Match type values must return respective value", new Integer(1), MapUtils.extractArgument(1, Integer.class).orNull());
        assertEquals("Match type values must return respective value", new Double(1.0), MapUtils.extractArgument(1.0, Double.class).orNull());

        assertEquals("Match type values must return respective value", testMap, MapUtils.extractArgument(testMap, Map.class).orNull());
        assertEquals("Match type values must return respective value", testList, MapUtils.extractArgument(testList, List.class).orNull());
    }

    @Test
    public void testIsNullOrEmpty() {
        assertTrue("Null values must return true", MapUtils.isNullOrEmpty(null));
        assertTrue("Empty maps must return true", MapUtils.isNullOrEmpty(new HashMap<>()));

        Map<String, Object> testMap = new HashMap<>();
        testMap.put("testIntegerKey", 1);
        assertFalse("Not empty maps must return false", MapUtils.isNullOrEmpty(testMap));
    }

    @Test
    public void extractValue() {

        Map<String, Object> testMap = new HashMap<>();

        testMap.put("testNullKey", null);
        testMap.put("testIntegerKey", 1);

        assertNull("Map values with null must return null", MapUtils.extractValue(testMap, "testNullKey", Integer.class).orNull());

        assertEquals("Map values with null must return default value if default was defined", (Integer)0, MapUtils.extractValue(testMap, "testNullKey", Integer.class).or(0));
        assertEquals("Map values with valid value must return respective value", (Integer)1, MapUtils.extractValue(testMap, "testIntegerKey", Integer.class).or(0));

        testMap.put("testDoubleKey", 1.0);
        assertEquals("Integer map values must return respective value preserving type", (Integer)1, MapUtils.extractValue(testMap, "testDoubleKey", Integer.class).or(0));
        assertEquals("Double map values must return respective value preserving type", (Double)1.0, MapUtils.extractValue(testMap, "testDoubleKey", Double.class).or(0.0));
        assertEquals("Integer map values must return Double if double was required", (Double)1.0, MapUtils.extractValue(testMap, "testIntegerKey", Double.class).or(0.0));

        testMap.put("testLongKey", 1L);
        testMap.put("testFloatKey", 1.0f);
        testMap.put("testByteKey", (byte) 1);
        testMap.put("testShortKey", (byte) 1);

        assertEquals("Float map values must return Float if float was required", (Float)1.0f, MapUtils.extractValue(testMap, "testFloatKey", Float.class).or(0.0f));
        assertEquals("Long map values must return Long if long was required", Long.valueOf(1), MapUtils.extractValue(testMap, "testLongKey", Long.class).or(Long.valueOf(0)));
        assertEquals("Byte map values must return Byte if byte was required", Byte.valueOf((byte)1), MapUtils.extractValue(testMap, "testByteKey", Byte.class).or((byte) 0));
        assertEquals("Short map values must return Short if short was required", Short.valueOf((short)1), MapUtils.extractValue(testMap, "testShortKey", Short.class).or((short) 0));

        testMap.put("testEmptyValue", "");
        testMap.put("testStringKey", "test");
        assertEquals("Value map as empty string must return default", "default", MapUtils.extractValue(testMap, "testEmptyValue", String.class).or("default"));
        assertEquals("Value map with a not empty string must return the respective string", "test", MapUtils.extractValue(testMap, "testStringKey", String.class).or("default"));

        Map<String, Object> emptyHashObject = new HashMap<>();
        testMap.put("testEmptyMapKey", emptyHashObject);
        testMap.put("testMapKey", testMap);

        assertNull("Null values must return null if default was not defined", MapUtils.extractValue(testMap, "testNullKey", Map.class).orNull());
        assertNull("Null values must return null if default was not defined", MapUtils.extractValue(testMap, "testStringKey", Map.class).orNull());

        assertEquals("Null values must return default if default was defined", new HashMap<>(), MapUtils.extractValue(testMap, "testNullKey", Map.class).or(new HashMap<>()));
        assertEquals("Empty values must return default if default was defined", new HashMap<>(), MapUtils.extractValue(testMap, "testEmptyMapKey", Map.class).or(new HashMap<>()));
        assertEquals("Not empty values must return the value if default was defined", testMap, MapUtils.extractValue(testMap, "testMapKey", Map.class).or(new HashMap<>()));

        testMap.put("testColorKey", "0x000000");
        assertEquals("Not empty values must return the value if default was defined", Long.valueOf(0xFF000000 & 0xffffffffL), MapUtils.extractValue(testMap, "testColorKey", Long.class).orNull());
        testMap.put("testColorKey", "#000000");
        assertEquals("Not empty values must return the value if default was defined", Long.valueOf(0xFF000000 & 0xffffffffL), MapUtils.extractValue(testMap, "testColorKey", Long.class).orNull());
        testMap.put("testColorKey", "#00000000");
        assertEquals("Not empty values must return the value if default was defined", Long.valueOf(0L), MapUtils.extractValue(testMap, "testColorKey", Long.class).orNull());


        testMap.put("testListKey", Arrays.asList(0,1,2,3));
        Assert.assertArrayEquals(
                new double[]{0.0,1.0,2.0,3.0},
                MapUtils.extractValue(testMap, "testListKey", double[].class).orNull(),
                0);

        Assert.assertArrayEquals(
                new long[]{0L,1L,2L,3L},
                MapUtils.extractValue(testMap, "testListKey", long[].class).orNull());

        Assert.assertArrayEquals(
                new float[]{0.0f,1.0f,2.0f,3.0f},
                MapUtils.extractValue(testMap, "testListKey", float[].class).orNull(),
                0);

        Assert.assertArrayEquals(
                new short[]{0,1,2,3},
                MapUtils.extractValue(testMap, "testListKey", short[].class).orNull());

        Assert.assertArrayEquals(
                new byte[]{0,1,2,3},
                MapUtils.extractValue(testMap, "testListKey", byte[].class).orNull());

        Assert.assertArrayEquals(
                new int[]{0,1,2,3},
                MapUtils.extractValue(testMap, "testListKey", int[].class).orNull());

    }
}