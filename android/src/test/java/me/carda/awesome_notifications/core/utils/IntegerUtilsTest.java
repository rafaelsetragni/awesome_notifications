package me.carda.awesome_notifications.core.utils;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import java.util.ArrayList;
import java.util.List;

import me.carda.awesome_notifications.core.TestEnum;

import static org.junit.Assert.*;

public class IntegerUtilsTest {

    @Before
    public void setUp() throws Exception {
    }

    @After
    public void tearDown() throws Exception {
    }

    @Test
    public void convertToInt() {
        assertEquals((Integer) 0, IntegerUtils.convertToInt(null));
        assertEquals((Integer) 3, IntegerUtils.convertToInt(3));

        assertEquals((Integer) 0, IntegerUtils.convertToInt("0"));
        assertEquals((Integer) 1, IntegerUtils.convertToInt("1"));
        assertEquals((Integer) (-1), IntegerUtils.convertToInt("-1"));

        assertEquals((Integer) 0, IntegerUtils.convertToInt(TestEnum.First));
        assertEquals((Integer) 1, IntegerUtils.convertToInt(TestEnum.Second));
        assertEquals((Integer) 2, IntegerUtils.convertToInt(TestEnum.Last));

        assertEquals((Integer) 0, IntegerUtils.convertToInt(0.0));
        assertEquals((Integer) 1, IntegerUtils.convertToInt(1.0));
        assertEquals((Integer) (-1), IntegerUtils.convertToInt(-1.0));
        assertEquals((Integer) 2, IntegerUtils.convertToInt(2.0));
        assertEquals((Integer) 2, IntegerUtils.convertToInt(2.4));
        assertEquals((Integer) 2, IntegerUtils.convertToInt(2.5));
        assertEquals((Integer) 2, IntegerUtils.convertToInt(2.6));
        assertEquals((Integer) 2, IntegerUtils.convertToInt(2.99));
    }

    @Test
    public void extractInteger() {
        assertEquals((Integer) 0, IntegerUtils.extractInteger(null, null));
        assertEquals((Integer) 3, IntegerUtils.extractInteger(3, null));
        assertEquals((Integer) 3, IntegerUtils.extractInteger(null, 3));

        assertEquals((Integer) 0, IntegerUtils.extractInteger(null, "0"));
        assertEquals((Integer) 1, IntegerUtils.extractInteger(null, "1"));
        assertEquals((Integer) (-1), IntegerUtils.extractInteger(null, "-1"));

        assertEquals((Integer) 0, IntegerUtils.extractInteger("0", 12));
        assertEquals((Integer) 1, IntegerUtils.extractInteger("1", 12));
        assertEquals((Integer) (-1), IntegerUtils.extractInteger("-1", 12));

        assertEquals((Integer) 0, IntegerUtils.extractInteger(TestEnum.First, -1));
        assertEquals((Integer) 1, IntegerUtils.extractInteger(TestEnum.Second, -1));
        assertEquals((Integer) 2, IntegerUtils.extractInteger(TestEnum.Last, -1));

        assertEquals((Integer) 0, IntegerUtils.extractInteger(null, TestEnum.First));
        assertEquals((Integer) 1, IntegerUtils.extractInteger(null, TestEnum.Second));
        assertEquals((Integer) 2, IntegerUtils.extractInteger(null, TestEnum.Last));

        assertEquals((Integer) 0, IntegerUtils.extractInteger(null, 0.0));
        assertEquals((Integer) 1, IntegerUtils.extractInteger(null, 1.0));
        assertEquals((Integer) (-1), IntegerUtils.extractInteger(null, -1.0));
        assertEquals((Integer) 2, IntegerUtils.extractInteger(null, 2.0));
        assertEquals((Integer) 2, IntegerUtils.extractInteger(null, 2.4));
        assertEquals((Integer) 2, IntegerUtils.extractInteger(null, 2.5));
        assertEquals((Integer) 2, IntegerUtils.extractInteger(null, 2.6));
        assertEquals((Integer) 2, IntegerUtils.extractInteger(null, 2.999));
        assertEquals((Integer) 2, IntegerUtils.extractInteger(null, 2.001));
    }

    @Test
    public void isBetween() {
        assertTrue("Value not considered between the test range", IntegerUtils.isBetween(0, -1, 1));
        assertTrue("Value not considered between the test range", IntegerUtils.isBetween(-1, -1, 1));
        assertTrue("Value not considered between the test range", IntegerUtils.isBetween(1, -1, 1));

        assertTrue("Value not considered between the test range", IntegerUtils.isBetween(0, -1, Integer.MAX_VALUE));
        assertTrue("Value not considered between the test range", IntegerUtils.isBetween(0, Integer.MIN_VALUE, 1));
        assertTrue("Value not considered between the test range", IntegerUtils.isBetween(0, Integer.MIN_VALUE, Integer.MAX_VALUE));

        assertTrue("Value not considered between the test range", IntegerUtils.isBetween(Integer.MIN_VALUE, Integer.MIN_VALUE, Integer.MIN_VALUE));
        assertTrue("Value not considered between the test range", IntegerUtils.isBetween(Integer.MAX_VALUE, Integer.MAX_VALUE, Integer.MAX_VALUE));

        assertFalse("Value is not between the test range", IntegerUtils.isBetween(-1, 0, 1));
        assertFalse("Value is not between the test range", IntegerUtils.isBetween(2, 0, 1));
        assertFalse("Value is not between the test range", IntegerUtils.isBetween(1, -1, 0));
    }

    @Test
    public void generateNextRandomId() {
        List uniqueValues = new ArrayList();

        // Maniac test!!!
        for (int position = 0; position < 10000; position++)
            uniqueValues.add(IntegerUtils.generateNextRandomId());

        assertFalse("Random values must not be generated twice", ListUtils.listHasDuplicates(uniqueValues));
    }
}