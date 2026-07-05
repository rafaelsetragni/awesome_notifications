package me.carda.android_awn_core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Pure-logic tests for the small type/string helpers. */
class StringUtilsTest {
    private val strings = StringUtils.getInstance()

    @Test fun nullIsEmpty() = assertTrue(strings.isNullOrEmpty(null))
    @Test fun emptyIsEmpty() = assertTrue(strings.isNullOrEmpty(""))
    @Test fun whitespaceIsEmpty() = assertTrue(strings.isNullOrEmpty("   "))
    @Test fun textIsNotEmpty() = assertFalse(strings.isNullOrEmpty("hi"))
}

class MapUtilsTest {
    private val maps = MapUtils.getInstance()

    @Test fun getIntFromInt() = assertEquals(3, maps.getInt(3))
    @Test fun getIntFromLong() = assertEquals(3, maps.getInt(3L))
    @Test fun getIntFromDouble() = assertEquals(3, maps.getInt(3.9))
    @Test fun getIntFromNumericString() = assertEquals(42, maps.getInt("42"))
    @Test fun getIntFromNonNumericStringIsNull() = assertNull(maps.getInt("x"))
    @Test fun getIntFromNullIsNull() = assertNull(maps.getInt(null))

    @Test fun getStringFromString() = assertEquals("a", maps.getString("a"))
    @Test fun getStringFromNonStringIsNull() = assertNull(maps.getString(7))

    @Test fun getBoolFromBool() = assertEquals(true, maps.getBool(true))
    @Test fun getBoolFromNonZeroNumber() = assertEquals(true, maps.getBool(1))
    @Test fun getBoolFromZeroNumber() = assertEquals(false, maps.getBool(0))
    @Test fun getBoolFromStringIsNull() = assertNull(maps.getBool("true"))
}
