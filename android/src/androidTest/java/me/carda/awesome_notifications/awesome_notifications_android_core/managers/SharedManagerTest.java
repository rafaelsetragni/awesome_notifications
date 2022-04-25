package me.carda.awesome_notifications.core.managers;

import static org.junit.Assert.*;

import android.content.Context;

import androidx.test.InstrumentationRegistry;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import java.util.HashMap;
import java.util.Map;

import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.models.AbstractModel;
import me.carda.awesome_notifications.core.utils.StringUtils;

public class SharedManagerTest {

    public class TestModel extends AbstractModel {

        public Integer testInt;
        public Boolean testBoolean;
        public Double testDouble;
        public Float testFloat;
        public String testString;

        public TestModel(){
            super(stringUtils);
        }

        @Override
        public AbstractModel fromMap(Map<String, Object> arguments) {
            testInt     = getValueOrDefault(arguments, "testInt",       Integer.class);
            testBoolean = getValueOrDefault(arguments, "testBoolean",   Boolean.class);
            testDouble  = getValueOrDefault(arguments, "testDouble",    Double.class);
            testFloat   = getValueOrDefault(arguments, "testFloat",     Float.class);
            testString  = getValueOrDefault(arguments, "testString",    String.class);
            return this;
        }

        @Override
        public Map<String, Object> toMap() {
            return new HashMap<String, Object>(){{
                put("testInt", testInt);
                put("testBoolean", testBoolean);
                put("testDouble", testDouble);
                put("testFloat", testFloat);
                put("testString", testString);
            }};
        }

        @Override
        public String toJson() {
            return templateToJson();
        }

        @Override
        public TestModel fromJson(String json){
            return (TestModel) super.templateFromJson(json);
        }

        @Override
        public void validate(Context context) throws AwesomeNotificationsException {

        }
    }

    SharedManager<TestModel> sharedManager;

    Map<String, Object> originalInitialValues;

    @Before
    public void setUp() throws Exception {
        sharedManager = new SharedManager<>(
                StringUtils.getInstance(),
                "SharedManagerTest",
                TestModel.class,
                "TestModel");

        originalInitialValues = Definitions.initialValues;
        Definitions.initialValues.clear();
    }

    @After
    public void tearDown() throws Exception {
        Definitions.initialValues.putAll(originalInitialValues);
        sharedManager = null;
    }

    @Test
    public void testGetAndSetOnSharedManager() {
        Context context = InstrumentationRegistry.getTargetContext();

        testGetSetSharedManager(context, null, null, null, null, null);

        testGetSetSharedManager(context, 0, true, 0.0f, 0.0, "test");

        testGetSetSharedManager(context, Integer.MAX_VALUE, true, Float.MAX_VALUE, Double.MAX_VALUE,
                "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt " +
                        "ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco " +
                        "laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate " +
                        "velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non " +
                        "proident, sunt in culpa qui officia deserunt mollit anim id est laborum.");

        testGetSetSharedManager(context, Integer.MIN_VALUE, false, Float.MIN_VALUE, Double.MIN_VALUE,"");
    }

    private void testGetSetSharedManager(Context context, Integer testInt, Boolean testBoolean, Float testFloat, Double testDouble, String testString) {
        TestModel testModel = new TestModel();
        testModel.testInt = testInt;
        testModel.testBoolean = testBoolean;
        testModel.testFloat = testFloat;
        testModel.testDouble = testDouble;
        testModel.testString = testString;

        assertEquals("TestModel could not be correctly stored in SharedManager",
                true, sharedManager.set(context, "AndroidTest", "0", testModel));

        TestModel testModelRecovered = sharedManager.get(context, "AndroidTest", "0");

        assertNotNull("TestModel could not be recovered from SharedManager", testModelRecovered);

        if(testInt == null)
            assertNull("Integer values could not be recovered from SharedManager", testModelRecovered.testInt);
        else
            assertEquals("Integer values could not be recovered from SharedManager", testModel.testInt, testModelRecovered.testInt);

        if(testBoolean == null)
            assertNull("Boolean values could not be recovered from SharedManager", testModelRecovered.testBoolean);
        else
            assertEquals("Boolean values could not be recovered from SharedManager", testModel.testBoolean, testModelRecovered.testBoolean);

        if(testFloat == null)
            assertNull("Float values could not be recovered from SharedManager", testModelRecovered.testFloat);
        else
            assertEquals("Float values could not be recovered from SharedManager", testModel.testFloat, testModelRecovered.testFloat);

        if(testDouble == null)
            assertNull("Double values could not be recovered from SharedManager", testModelRecovered.testDouble);
        else
            assertEquals("Double values could not be recovered from SharedManager", testModel.testDouble, testModelRecovered.testDouble);

        if(testString == null)
            assertNull("String values could not be recovered from SharedManager", testModelRecovered.testString);
        else
            assertEquals("String values could not be recovered from SharedManager", testModel.testString,     testModelRecovered.testString);
    }

    @Test
    public void remove() {
    }

    @Test
    public void getAllObjects() {
    }

    @Test
    public void commit() {
    }
}