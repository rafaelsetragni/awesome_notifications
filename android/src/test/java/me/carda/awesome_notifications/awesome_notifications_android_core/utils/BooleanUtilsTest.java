package me.carda.awesome_notifications.awesome_notifications_android_core.utils;

import org.junit.Test;

import static org.junit.Assert.*;

public class BooleanUtilsTest {

    @Test
    public void getValue() {
        assertFalse("Null boolean object must return false", BooleanUtils.getValue(null));
        assertFalse("False boolean object must return false", BooleanUtils.getValue(false));
        assertTrue("True boolean object must return true", BooleanUtils.getValue(true));
    }

    @Test
    public void getValueOrDefault() {
        assertEquals("Null boolean object must return default", true, BooleanUtils.getValueOrDefault(null, true));
        assertEquals("Null boolean object must return default", false, BooleanUtils.getValueOrDefault(null, false));

        assertEquals("Null boolean object must return false if default was also null", false, BooleanUtils.getValueOrDefault(null, null));

        assertEquals("True boolean object must return true", true, BooleanUtils.getValueOrDefault(true, false));
        assertEquals("False boolean object must return false", false, BooleanUtils.getValueOrDefault(false, true));
    }
}