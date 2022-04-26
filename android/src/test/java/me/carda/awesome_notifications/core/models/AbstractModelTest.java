package me.carda.awesome_notifications.core.models;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.TestEnum;
import me.carda.awesome_notifications.core.TestModel;

import static org.junit.Assert.*;

public class AbstractModelTest {

    Map<String, Object> emptyMap;
    Map<String, Object> originalInitialValues;

    @Before
    public void setUp() throws Exception {
        emptyMap = new HashMap<String, Object>();
        Definitions.initialValues.clear();
    }

    @After
    public void tearDown() throws Exception {
        Definitions.initialValues.clear();
    }

    @Test
    public void getClone() {
    }

    @Test
    public void putDataOnMapObject() {
    }

    @Test
    public void serializeValue(){

        assertNull("Null values must return null", AbstractModel.serializeValue(null));

        assertEquals("String", AbstractModel.serializeValue("String"));
        assertEquals(1, AbstractModel.serializeValue(1));
        assertEquals(1.0, AbstractModel.serializeValue(1.0));
        assertEquals(emptyMap, AbstractModel.serializeValue(new TestModel()));

        assertEquals(
                Arrays.asList("test", 1, 1.0, "First", emptyMap),
                AbstractModel.serializeValue(
                        Arrays.asList("test", 1, 1.0, TestEnum.First, new TestModel())));

        HashMap<String, Object> testMap = new HashMap<String, Object>(){{
            put("test1", "test");
            put("test2", 1);
            put("test3", 1.0);
            put("test4", TestEnum.First);
            put("test5", new TestModel());
            put("test6", new HashMap<String, Object>(){{
                put("test7", "test");
            }});
        }};

        HashMap<String, Object> expectedMap = new HashMap<String, Object>(){{
            put("test1", "test");
            put("test2", 1);
            put("test3", 1.0);
            put("test4", "First");
            put("test5", emptyMap);
            put("test6", new HashMap<String, Object>(){{
                put("test7", "test");
            }});
        }};

        assertEquals(
                expectedMap,
                AbstractModel.serializeValue(testMap));
    }

    @Test
    public void serializeList(){
        assertNull("Null values must return null", AbstractModel.serializeList(null));
        assertNull("Empty values must return null", AbstractModel.serializeList(new ArrayList()));

        assertEquals(Arrays.asList("String"), AbstractModel.serializeValue(Arrays.asList("String")));
        assertEquals(Arrays.asList(1), AbstractModel.serializeValue(Arrays.asList(1)));
        assertEquals(Arrays.asList(1.0), AbstractModel.serializeValue(Arrays.asList(1.0)));
        assertEquals(Arrays.asList("First"), AbstractModel.serializeValue(Arrays.asList(TestEnum.First)));
        assertEquals(Arrays.asList(emptyMap), AbstractModel.serializeValue(Arrays.asList(new TestModel())));
        assertEquals(Arrays.asList(Arrays.asList(emptyMap)), AbstractModel.serializeValue(Arrays.asList(Arrays.asList(new TestModel()))));
    }

    @Test
    public void serializeMap(){
        assertNull("Null values must return null", AbstractModel.serializeMap(null));
        assertNull("Empty values must return null", AbstractModel.serializeMap(new HashMap<>()));

        HashMap<String, Object> testMap = new HashMap<String, Object>();
        HashMap<String, Object> expectMap = new HashMap<String, Object>();

        testMap.put("test", "String");
        assertEquals(testMap, AbstractModel.serializeMap(testMap));

        testMap.put("test", 1);
        assertEquals(testMap, AbstractModel.serializeMap(testMap));

        testMap.put("test", 1.0);
        assertEquals(testMap, AbstractModel.serializeMap(testMap));

        testMap.put("test", TestEnum.First);
        expectMap.put("test", "First");
        assertEquals(expectMap, AbstractModel.serializeMap(testMap));

        testMap.put("test", new TestModel());
        expectMap.put("test", new HashMap<>());
        assertEquals(expectMap, AbstractModel.serializeMap(testMap));
    }

    @Test
    public void onlyFromValidMap() {
        TestModel testModel = new TestModel();

        testModel.isValidModel = false;
        assertNull(testModel.onlyFromValidMap(null, emptyMap));

        testModel.isValidModel = true;
        assertNotNull(testModel.onlyFromValidMap(null, emptyMap));
    }

    @Test
    public void getValueOrDefault() {

        String exampleText = "abcdefghijklmnopqrstuvxwyzABCDEFGHIJKLMNOPQRSTUVXWYZ0123456789";

        assertNotNull("Definitions.initialValues is not defined since begin", Definitions.initialValues);

        AbstractModel.defaultValues.clear();
        Map<String, Object> testMap1 = new HashMap<String, Object>(){{ put("KEY", exampleText); }};
        assertEquals("Valid values without default must return the respective valid value",
                exampleText, AbstractModel.getValueOrDefault(testMap1, "KEY", String.class));

        AbstractModel.defaultValues.put("KEY", exampleText);
        Map<String, Object> testMap2 = new HashMap<String, Object>(){{ put("KEY", null); }};
        assertEquals("Null values with default must return the default value",
                exampleText, AbstractModel.getValueOrDefault(testMap2, "KEY", String.class));
    }

    @Test
    public void getEnumValueOrDefault() {

        Definitions.initialValues.put("testEnum", "First");
        assertEquals(
                "getEnumValueOrDefault fail to retrieve the first enum value",
                TestEnum.First, AbstractModel.getEnumValueOrDefault(
                new HashMap<String, Object>(){{ put("testEnum", "First"); }}, "testEnum", TestEnum.class, TestEnum.values()));

        Definitions.initialValues.put("testEnum", "Second");
        assertEquals(
                "getEnumValueOrDefault fail to retrieve the second enum value",
                TestEnum.Second, AbstractModel.getEnumValueOrDefault(
                new HashMap<String, Object>(){{ put("testEnum", "Second"); }}, "testEnum", TestEnum.class, TestEnum.values()));

        Definitions.initialValues.put("testEnum", "Last");
        assertEquals(
                "getEnumValueOrDefault fail to retrieve the last enum value",
                TestEnum.Last, AbstractModel.getEnumValueOrDefault(
                new HashMap<String, Object>(){{ put("testEnum", "Last"); }}, "testEnum", TestEnum.class, TestEnum.values()));

        Definitions.initialValues.remove("testEnum");
        assertEquals(
                "getEnumValueOrDefault fail to retrieve the first enum value without have a default",
                TestEnum.First, AbstractModel.getEnumValueOrDefault(
                    new HashMap<String, Object>(){{ put("testEnum", "First"); }}, "testEnum", TestEnum.class, TestEnum.values()));

        assertNull(
                "getEnumValueOrDefault fail to retrieve the null value for fields without default value",
                AbstractModel.getEnumValueOrDefault(
                        new HashMap<String, Object>(), "testEnum", TestEnum.class, TestEnum.values()));

        assertNull(
                "getEnumValueOrDefault fail to retrieve the null value for fields without default value",
                AbstractModel.getEnumValueOrDefault(
                        new HashMap<String, Object>(), "testEnum", TestEnum.class, TestEnum.values()));
    }
}