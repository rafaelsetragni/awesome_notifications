package me.carda.android_awn_core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Round-trip tests for the map <-> JSON serializer that carries a notification
 * through PendingIntent extras. Uses the real org.json (a test dependency).
 */
class JsonUtilsTest {
    private val json = JsonUtils.getInstance()

    @Test fun roundTripsScalars() {
        val model = mapOf("id" to 1, "title" to "Hi", "flag" to true)
        val out = json.fromJson(json.toJson(model))
        assertEquals(1, out["id"])
        assertEquals("Hi", out["title"])
        assertEquals(true, out["flag"])
    }

    @Test fun roundTripsNestedMapAndList() {
        val model = mapOf(
            "content" to mapOf("a" to "b", "n" to 2),
            "list" to listOf(1, 2, mapOf("x" to "y"))
        )
        val out = json.fromJson(json.toJson(model))
        assertEquals(mapOf("a" to "b", "n" to 2), out["content"])
        assertEquals(listOf(1, 2, mapOf("x" to "y")), out["list"])
    }

    @Test fun preservesNullValues() {
        val out = json.fromJson(json.toJson(mapOf("maybe" to null)))
        assertTrue(out.containsKey("maybe"))
        assertNull(out["maybe"])
    }
}
