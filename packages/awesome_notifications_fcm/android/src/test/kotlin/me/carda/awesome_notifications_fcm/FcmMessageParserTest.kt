package me.carda.awesome_notifications_fcm

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.NotificationLifeCycle
import me.carda.android_awn_core.NotificationSource
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class FcmMessageParserTest {

    private val context: Context get() = ApplicationProvider.getApplicationContext()
    private val parser = FcmMessageParser()

    private fun notification() = FcmMessageParser.StandardNotification(
        title = "Hi", body = "There", channelId = "push", imageUrl = null, sticky = false
    )

    @Test
    fun `isDisplayable is true for a standard notification block`() {
        assertTrue(parser.isDisplayable(emptyMap(), notification()))
    }

    @Test
    fun `isDisplayable is true when a content key is present`() {
        assertTrue(parser.isDisplayable(mapOf("content" to "{}"), null))
        assertTrue(parser.isDisplayable(mapOf("content.title" to "Hi"), null))
    }

    @Test
    fun `isDisplayable is false for pure data or an explicit silent flag`() {
        assertFalse(parser.isDisplayable(mapOf("orderId" to "9"), null))
        assertFalse(parser.isDisplayable(mapOf("content" to "{}", "isSilentData" to "true"), null))
    }

    @Test
    fun `a conversation reaches the core, structured or flattened`() {
        val structured = parser.buildAwesomeMap(
            context = context, notificationId = 1,
            data = mapOf(
                "content" to "{\"id\":7,\"channelKey\":\"chat\",\"notificationLayout\":\"Messaging\"}",
                "conversation" to "{\"id\":\"ana\",\"me\":{\"key\":\"me\",\"name\":\"Me\"}," +
                    "\"message\":{\"sender\":{\"key\":\"ana\",\"name\":\"Ana\"},\"text\":\"Hi\"}}"
            ),
            notification = null, lifeCycle = NotificationLifeCycle.Foreground
        )
        @Suppress("UNCHECKED_CAST")
        assertEquals("ana", (structured["conversation"] as Map<String, Any?>)["id"])

        val flattened = parser.buildAwesomeMap(
            context = context, notificationId = 1,
            data = mapOf(
                "content.id" to "7", "content.channelKey" to "chat",
                "conversation.id" to "ana",
                "conversation.me.key" to "me", "conversation.me.name" to "Me",
                "conversation.message.sender.key" to "ana",
                "conversation.message.sender.name" to "Ana",
                "conversation.message.text" to "Hi"
            ),
            notification = null, lifeCycle = NotificationLifeCycle.Foreground
        )
        @Suppress("UNCHECKED_CAST")
        val conversation = flattened["conversation"] as Map<String, Any?>
        assertEquals("ana", conversation["id"])
        @Suppress("UNCHECKED_CAST")
        val content = flattened[Definitions.NOTIFICATION_CONTENT] as Map<String, Any?>
        assertEquals(null, content[Definitions.NOTIFICATION_PAYLOAD])
    }

    @Test
    fun `a call reaches the core, structured or flattened, and stays out of the payload`() {
        val structured = parser.buildAwesomeMap(
            context = context, notificationId = 1,
            data = mapOf(
                "content" to "{\"id\":300,\"channelKey\":\"calls\"}",
                "call" to "{\"callId\":\"c-1\",\"caller\":{\"key\":\"ana\",\"name\":\"Ana\"}," +
                    "\"state\":\"incoming\",\"video\":true,\"ringTimeout\":30000}"
            ),
            notification = null, lifeCycle = NotificationLifeCycle.Terminated
        )
        @Suppress("UNCHECKED_CAST")
        val call = structured["call"] as Map<String, Any?>
        assertEquals("c-1", call["callId"])
        assertEquals(true, call["video"])
        assertEquals(30000, (call["ringTimeout"] as Number).toInt())

        val flattened = parser.buildAwesomeMap(
            context = context, notificationId = 1,
            data = mapOf(
                "content.id" to "300", "content.channelKey" to "calls",
                "call.callId" to "c-1", "call.state" to "incoming",
                "call.caller.key" to "ana", "call.caller.name" to "Ana"
            ),
            notification = null, lifeCycle = NotificationLifeCycle.Terminated
        )
        @Suppress("UNCHECKED_CAST")
        assertEquals("c-1", (flattened["call"] as Map<String, Any?>)["callId"])
        @Suppress("UNCHECKED_CAST")
        val content = flattened[Definitions.NOTIFICATION_CONTENT] as Map<String, Any?>
        assertEquals(null, content[Definitions.NOTIFICATION_PAYLOAD])
    }

    @Test
    fun `structured content is parsed and stamped with the firebase source`() {
        val model = parser.buildAwesomeMap(
            context = context,
            notificationId = 100,
            data = mapOf("content" to "{\"id\":10,\"title\":\"Server\",\"channelKey\":\"push\"}"),
            notification = null,
            lifeCycle = NotificationLifeCycle.Terminated
        )
        @Suppress("UNCHECKED_CAST")
        val content = model[Definitions.NOTIFICATION_CONTENT] as Map<String, Any?>
        assertEquals(10, content[Definitions.NOTIFICATION_ID])
        assertEquals("Server", content[Definitions.NOTIFICATION_TITLE])
        assertEquals("push", content[Definitions.NOTIFICATION_CHANNEL_KEY])
        assertEquals(NotificationSource.Firebase.name, content[Definitions.NOTIFICATION_CREATED_SOURCE])
        assertEquals(NotificationLifeCycle.Terminated.name, content[Definitions.NOTIFICATION_CREATED_LIFECYCLE])
    }

    @Test
    fun `the standard notification block seeds title and body`() {
        val model = parser.buildAwesomeMap(
            context = context,
            notificationId = 7,
            data = mapOf("content" to "{\"channelKey\":\"push\"}"),
            notification = notification(),
            lifeCycle = NotificationLifeCycle.Foreground
        )
        @Suppress("UNCHECKED_CAST")
        val content = model[Definitions.NOTIFICATION_CONTENT] as Map<String, Any?>
        assertEquals("Hi", content[Definitions.NOTIFICATION_TITLE])
        assertEquals("There", content[Definitions.NOTIFICATION_BODY])
        assertEquals("push", content[Definitions.NOTIFICATION_CHANNEL_KEY])
    }

    @Test
    fun `structured buttons and schedule ride through as siblings`() {
        val model = parser.buildAwesomeMap(
            context = context,
            notificationId = 1,
            data = mapOf(
                "content" to "{\"id\":1,\"channelKey\":\"push\"}",
                "actionButtons" to "[{\"key\":\"OK\"}]",
                "schedule" to "{\"interval\":60}"
            ),
            notification = null,
            lifeCycle = NotificationLifeCycle.Foreground
        )
        assertTrue(model.containsKey(FcmDefinitions.MODEL_BUTTONS))
        assertTrue(model.containsKey(FcmDefinitions.MODEL_SCHEDULE))
    }

    @Test
    fun `flattened content is reconstructed`() {
        val model = parser.buildAwesomeMap(
            context = context,
            notificationId = 3,
            data = mapOf(
                "content.id" to "3",
                "content.title" to "Flat",
                "content.channelKey" to "push"
            ),
            notification = null,
            lifeCycle = NotificationLifeCycle.Foreground
        )
        @Suppress("UNCHECKED_CAST")
        val content = model[Definitions.NOTIFICATION_CONTENT] as Map<String, Any?>
        assertEquals("Flat", content[Definitions.NOTIFICATION_TITLE])
    }

    @Test
    @Suppress("UNCHECKED_CAST")
    fun `flattened payload keeps images, booleans and a clean payload`() {
        val model = parser.buildAwesomeMap(
            context, 5,
            mapOf(
                "orderId" to "9",
                "content.channelKey" to "push",
                "content.title" to "Hi",
                "content.bigPicture" to "https://example.com/big.jpg",
                "content.largeIcon" to "https://example.com/icon.png",
                "content.displayOnForeground" to "true",
                "content.privacy" to "null",
                "content.payload.secret" to "s3cr3t",
                "actionButtons.0.key" to "OK"
            ),
            null, NotificationLifeCycle.Foreground
        )
        val content = model["content"] as Map<String, Any?>
        assertEquals("https://example.com/big.jpg", content[Definitions.NOTIFICATION_BIG_PICTURE])
        assertEquals("https://example.com/icon.png", content[Definitions.NOTIFICATION_LARGE_ICON])
        assertEquals(true, content["displayOnForeground"])
        assertFalse(content.containsKey("privacy"))
        val payload = content[Definitions.NOTIFICATION_PAYLOAD] as Map<String, Any?>
        assertEquals(mapOf("orderId" to "9", "secret" to "s3cr3t"), payload)
        assertEquals(1, (model["actionButtons"] as List<*>).size)
    }
}
