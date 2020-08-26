package android.src.main.test.java.me.carda.awesome_notifications.utils;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import static org.junit.Assert.*;


public class IntegerUtilsTest {

    enum TestEnum {
        Test0,
        Test1,
        Test2
    }

    @Before
    public void setUp() throws Exception {
    }

    @After
    public void tearDown() throws Exception {
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

        assertEquals((Integer) 0, IntegerUtils.extractInteger(TestEnum.Test0, -1));
        assertEquals((Integer) 1, IntegerUtils.extractInteger(TestEnum.Test1, -1));
        assertEquals((Integer) 2, IntegerUtils.extractInteger(TestEnum.Test2, -1));

        assertEquals((Integer) 0, IntegerUtils.extractInteger(null, TestEnum.Test0));
        assertEquals((Integer) 1, IntegerUtils.extractInteger(null, TestEnum.Test1));
        assertEquals((Integer) 2, IntegerUtils.extractInteger(null, TestEnum.Test2));

        assertEquals((Integer) 0, IntegerUtils.extractInteger(null, 0.0));
        assertEquals((Integer) 1, IntegerUtils.extractInteger(null, 1.0));
        assertEquals((Integer) (-1), IntegerUtils.extractInteger(null, -1.0));
        assertEquals((Integer) 2, IntegerUtils.extractInteger(null, 2.0));
        assertEquals((Integer) 2, IntegerUtils.extractInteger(null, 2.4));
        assertEquals((Integer) 2, IntegerUtils.extractInteger(null, 2.5));
        assertEquals((Integer) 2, IntegerUtils.extractInteger(null, 2.6));
        assertEquals((Integer) 2, IntegerUtils.extractInteger(null, 2.99));
    }

    @Test
    public void testExtractInteger() {
    }
}