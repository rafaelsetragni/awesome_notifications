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
}
