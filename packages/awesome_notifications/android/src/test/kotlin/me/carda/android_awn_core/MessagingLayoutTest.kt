package me.carda.android_awn_core

import android.app.Notification
import android.app.NotificationManager
import android.content.Context
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.test.core.app.ApplicationProvider
import java.util.concurrent.Executor
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/** The 0.12 `Messaging` / `MessagingGroup` layouts, as an app sees them on screen. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class MessagingLayoutTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val core = AwesomeNotifications(context, Executor { it.run() })

    private fun manager() =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    @Before fun setUp() {
        NotificationBuilderRegistry.clearForTest()
        manager().cancelAll()
        core.setChannel(
            mapOf(
                Definitions.NOTIFICATION_CHANNEL_KEY to "chat",
                Definitions.NOTIFICATION_CHANNEL_NAME to "Chat"
            )
        )
        core.setChannel(
            mapOf(
                Definitions.NOTIFICATION_CHANNEL_KEY to "grouped",
                Definitions.NOTIFICATION_CHANNEL_NAME to "Grouped",
                Definitions.NOTIFICATION_GROUP_KEY to "from-channel"
            )
        )
    }

    @After fun tearDown() = NotificationBuilderRegistry.clearForTest()

    private fun send(
        id: Int,
        body: String,
        layout: String = "Messaging",
        groupKey: String? = "family",
        title: String = "Ana",
        summary: String? = null,
        channel: String = "chat"
    ) {
        val content = mutableMapOf<String, Any?>(
            Definitions.NOTIFICATION_ID to id,
            Definitions.NOTIFICATION_CHANNEL_KEY to channel,
            Definitions.NOTIFICATION_TITLE to title,
            Definitions.NOTIFICATION_BODY to body,
            Definitions.NOTIFICATION_LAYOUT to layout,
            "summary" to summary
        )
        if (groupKey != null) content[Definitions.NOTIFICATION_GROUP_KEY] = groupKey
        core.createNotification(mapOf(Definitions.NOTIFICATION_CONTENT to content)) {}
        shadowOf(Looper.getMainLooper()).idle()
    }

    private fun shown(id: Int): Notification? =
        manager().activeNotifications.firstOrNull { it.id == id }?.notification

    private fun texts(id: Int): List<String> =
        NotificationCompat.MessagingStyle
            .extractMessagingStyleFromNotification(shown(id)!!)!!
            .messages.map { it.text.toString() }

    @Test fun aGroupStacksInTheFirstNotification() {
        send(1, "oi")
        send(2, "tudo bem?")
        assertEquals(listOf(1), manager().activeNotifications.map { it.id })
        assertEquals(listOf("oi", "tudo bem?"), texts(1))
    }

    @Test fun everyMessageIsDrawnUnderTheCurrentSender() {
        send(1, "oi", title = "Ana")
        send(2, "olá", title = "Bia")
        val style = NotificationCompat.MessagingStyle.extractMessagingStyleFromNotification(shown(1)!!)!!
        assertEquals(listOf("Bia", "Bia"), style.messages.map { it.person?.name.toString() })
    }

    @Test fun messagingGroupHasTheSummaryAsTitle() {
        send(1, "oi", layout = "MessagingGroup", summary = "Família")
        val style = NotificationCompat.MessagingStyle.extractMessagingStyleFromNotification(shown(1)!!)!!
        assertEquals("Família", style.conversationTitle.toString())
        assertEquals(true, style.isGroupConversation)
    }

    @Test fun withoutAGroupKeyEachMessageStandsAlone() {
        send(1, "oi", groupKey = null)
        send(2, "olá", groupKey = null)
        assertEquals(setOf(1, 2), manager().activeNotifications.map { it.id }.toSet())
        assertEquals(listOf("olá"), texts(2))
    }

    @Test fun theChannelGroupKeyIsUsedWhenTheContentHasNone() {
        send(1, "oi", groupKey = null, channel = "grouped")
        send(2, "olá", groupKey = null, channel = "grouped")
        assertEquals(listOf(1), manager().activeNotifications.map { it.id })
    }

    @Test fun withoutATitleTheDefaultLayoutIsUsed() {
        send(1, "oi")
        send(2, "olá", title = "")
        assertNull(NotificationCompat.MessagingStyle.extractMessagingStyleFromNotification(shown(2)!!))
    }

    @Test fun theHistoryRestartsOnceTheGroupLeftTheScreen() {
        send(1, "oi")
        manager().cancel(1)
        send(2, "de novo")
        assertEquals(listOf("de novo"), texts(2))
    }
}
