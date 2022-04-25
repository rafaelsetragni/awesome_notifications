package me.carda.awesome_notifications.core.utils;

import org.junit.Test;

import static org.junit.Assert.*;

public class BooleanUtilsTest {

    @Test
    public void getInstance() {
        BooleanUtils booleanUtils1 = BooleanUtils.getInstance();
        assertNotNull("", booleanUtils1);

        BooleanUtils booleanUtils2 = BooleanUtils.getInstance();
        assertNotNull("", booleanUtils2);

        assertEquals("", booleanUtils1, booleanUtils2);
    }

    @Test
    public void getValue() {
        assertFalse("Null boolean object must return false", BooleanUtils.getInstance().getValue(null));
        assertFalse("False boolean object must return false", BooleanUtils.getInstance().getValue(false));
        assertTrue("True boolean object must return true", BooleanUtils.getInstance().getValue(true));
    }

    @Test
    public void getValueOrDefault() {
        assertTrue("Null boolean object must return default", BooleanUtils.getInstance().getValueOrDefault(null, true));
        assertFalse("Null boolean object must return default", BooleanUtils.getInstance().getValueOrDefault(null, false));

        assertFalse("Null boolean object must return false if default was also null", BooleanUtils.getInstance().getValueOrDefault(null, null));

        assertTrue("True boolean object must return true", BooleanUtils.getInstance().getValueOrDefault(true, false));
        assertFalse("False boolean object must return false", BooleanUtils.getInstance().getValueOrDefault(false, true));
    }
}