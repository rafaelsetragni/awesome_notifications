package me.carda.awesome_notifications.core.utils;

import org.junit.Test;

import static org.junit.Assert.*;

public class StringUtilsTest {

    public enum TestEnum {
        First,
        Second,
        Last
    }

    @Test
    public void isNullOrEmpty() {
        assertEquals("Nullable string value must be considered empty.", true, StringUtils.isNullOrEmpty(null));
        assertEquals("Nullable string value must be considered empty.", true, StringUtils.isNullOrEmpty(""));
        assertEquals("String with only white spaces must be considered empty.", true, StringUtils.isNullOrEmpty(" "));
        assertEquals("Not empty string must not be considered empty.", false, StringUtils.isNullOrEmpty("a"));
    }

    @Test
    public void getValueOrDefault() {
        assertEquals("If value is null or empty, the default value must be returned.", "default", StringUtils.getValueOrDefault(null, "default"));
        assertEquals("If value is null or empty, the value must be returned.", "default", StringUtils.getValueOrDefault("", "default"));
        assertEquals("If value is null or empty, the value must be returned.", "default", StringUtils.getValueOrDefault(" ", "default"));
        assertEquals("If value is not null or empty, the value must be returned.", "value", StringUtils.getValueOrDefault("value", "default"));
    }

    @Test
    public void digestString() {
        assertEquals("If value is null or empty, the empty string MD5 must be returned.", "d41d8cd98f00b204e9800998ecf8427e", StringUtils.digestString(null));
        assertEquals("If value is null or empty, the empty string MD5 must be returned.", "d41d8cd98f00b204e9800998ecf8427e", StringUtils.digestString(""));
        assertEquals("Invalid MD5 was returned.", "d67c5cbf5b01c9f91932e3b8def5e5f8", StringUtils.digestString("test string"));
    }

    @Test
    public void getEnumFromString() {
        assertEquals("null values must not be converted", null, StringUtils.getEnumFromString(TestEnum.class, null));
        assertEquals("Enum value successfully converted", TestEnum.First, StringUtils.getEnumFromString(TestEnum.class, "First"));
        assertEquals("Enum value successfully converted", TestEnum.Second, StringUtils.getEnumFromString(TestEnum.class, "Second"));
        assertEquals("Enum value successfully converted", TestEnum.Last, StringUtils.getEnumFromString(TestEnum.class, "Last"));
        assertEquals("invalid values must not be converted", null, StringUtils.getEnumFromString(TestEnum.class, "Invalid"));
        assertEquals("Enum value must be case sensitive", null, StringUtils.getEnumFromString(TestEnum.class, "last"));
    }
}