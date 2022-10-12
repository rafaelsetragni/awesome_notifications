package me.carda.awesome_notifications.core.utils;

import static org.junit.Assert.*;

import android.util.ArrayMap;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class MapUtilsTest {

    @Before
    public void setUp() throws Exception {
    }

    @After
    public void tearDown() throws Exception {
    }

    @Test
    public void isNullOrEmptyKey() {
    }

    @Test
    public void isNullOrEmpty() {
    }

    @Test
    public void extractArgument() {
    }

    @Test
    public void extractValue() {
    }

    @Test
    public void deepMerge() {
        Map<String, Object> test1 = new HashMap<String, Object>() {{
            put("title", "title 1");
            put("body", "body 1");
            put("payload", new HashMap<String, String>() {{
                put("key 1", "value 1");
                put("key 2", "value 2");
            }});
            put("actionButtons", Arrays.asList(
                    new HashMap<String, String>() {{
                        put("Button 1", "label 1");
                    }},
                    new HashMap<String, String>() {{
                        put("Button 2", "label 2");
                    }}
            ));
        }};
        Map<String, Object> test2 = new HashMap<String, Object>() {{
            put("title", "Modified 1");
            put("body", "body 1");
            put("payload", new HashMap<String, String>() {{
                put("key 1", "value 1");
                put("key 2", "modified 2");
                put("key 3", "value 3");
            }});
            put("actionButtons", Arrays.asList(
                    new HashMap<String, String>() {{
                        put("Button 1", "label test");
                    }}
            ));
        }};

        assertNotNull(MapUtils.deepMerge(test1, null));
        assertNotNull(MapUtils.deepMerge(null, test2));

        Map<String, Object> result = MapUtils.deepMerge(test1, test2);

        assertNotNull(result);
        assertEquals("Modified 1", result.get("title"));
        assertEquals("body 1", result.get("body"));
        assertEquals("value 1", ((Map) result.get("payload")).get("key 1"));
        assertEquals("modified 2", ((Map) result.get("payload")).get("key 2"));
        assertEquals("value 3", ((Map) result.get("payload")).get("key 3"));
        assertNotNull(result.get("actionButtons"));
        assertEquals(1, ((List) result.get("actionButtons")).size());

    }
}