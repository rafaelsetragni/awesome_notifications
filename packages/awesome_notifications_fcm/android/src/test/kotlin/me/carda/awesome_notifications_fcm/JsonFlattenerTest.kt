package me.carda.awesome_notifications_fcm

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class JsonFlattenerTest {

    @Test
    fun `reconstructs nested objects from dot notation`() {
        val decoded = JsonFlattener.decode(
            mapOf(
                "content.id" to "1",
                "content.title" to "Hi",
                "content.channelKey" to "push"
            )
        )
        @Suppress("UNCHECKED_CAST")
        val content = decoded["content"] as Map<String, Any?>
        assertEquals("1", content["id"])
        assertEquals("Hi", content["title"])
        assertEquals("push", content["channelKey"])
    }

    @Test
    fun `turns contiguous numeric keys into a list`() {
        val decoded = JsonFlattener.decode(
            mapOf(
                "actionButtons.0.key" to "YES",
                "actionButtons.1.key" to "NO"
            )
        )
        @Suppress("UNCHECKED_CAST")
        val buttons = decoded["actionButtons"] as List<Map<String, Any?>>
        assertEquals(2, buttons.size)
        assertEquals("YES", buttons[0]["key"])
        assertEquals("NO", buttons[1]["key"])
    }

    @Test
    fun `keeps flat scalar keys untouched`() {
        val decoded = JsonFlattener.decode(mapOf("foo" to "bar"))
        assertEquals("bar", decoded["foo"])
    }

    @Test
    fun `non-contiguous numeric keys stay a map`() {
        val decoded = JsonFlattener.decode(
            mapOf("x.0" to "a", "x.2" to "b")
        )
        assertTrue(decoded["x"] is Map<*, *>)
    }

    @Test
    fun `turns boolean strings into booleans`() {
        val decoded = JsonFlattener.decode(
            mapOf("content.displayOnForeground" to "true", "content.locked" to "false")
        )
        @Suppress("UNCHECKED_CAST")
        val content = decoded["content"] as Map<String, Any?>
        assertEquals(true, content["displayOnForeground"])
        assertEquals(false, content["locked"])
    }

    @Test
    fun `drops null strings`() {
        val decoded = JsonFlattener.decode(
            mapOf("content.title" to "Hi", "content.privacy" to "null")
        )
        @Suppress("UNCHECKED_CAST")
        val content = decoded["content"] as Map<String, Any?>
        assertFalse(content.containsKey("privacy"))
        assertEquals("Hi", content["title"])
    }

    @Test
    fun `keeps numeric strings as strings`() {
        val decoded = JsonFlattener.decode(mapOf("content.id" to "42"))
        @Suppress("UNCHECKED_CAST")
        assertEquals("42", (decoded["content"] as Map<String, Any?>)["id"])
    }
}
