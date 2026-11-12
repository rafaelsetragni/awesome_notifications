package me.carda.awesome_notifications_fcm

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class FcmJsonTest {

    @Test
    fun `parses a json object string`() {
        val obj = FcmJson.parseObjectOrNull("{\"a\":1,\"b\":\"x\"}")!!
        assertEquals(1, obj["a"])
        assertEquals("x", obj["b"])
    }

    @Test
    fun `parses a json array string`() {
        val list = FcmJson.parseListOrNull("[{\"k\":\"v\"}]")!!
        assertEquals(1, list.size)
        @Suppress("UNCHECKED_CAST")
        assertEquals("v", (list[0] as Map<String, Any?>)["k"])
    }

    @Test
    fun `returns null for blank or malformed input`() {
        assertNull(FcmJson.parseObjectOrNull(null))
        assertNull(FcmJson.parseObjectOrNull(""))
        assertNull(FcmJson.parseObjectOrNull("not json"))
        assertNull(FcmJson.parseListOrNull("{\"not\":\"a list\"}"))
    }
}
