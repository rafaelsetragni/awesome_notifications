package me.carda.android_awn_core

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

/** The `decorate` seam: decorators adjust the Android builder before it is built. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class DecorateSeamTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val core = AwesomeNotifications(context, Executor { it.run() })
    private val calls = mutableListOf<String>()

    /** Records its name, then lets the inner decorators run. */
    private inner class Recorder(inner: NotificationBuilder, private val name: String) :
        NotificationBuilder(inner) {
        override fun decorate(
            context: Context,
            model: Map<String, Any?>,
            builder: NotificationCompat.Builder
        ) {
            calls.add(name)
            builder.setSubText(name)
            super.decorate(context, model, builder)
        }
    }

    /** Renders the messaging layout itself: marks the model and sets its own style. */
    private class OwnMessaging(inner: NotificationBuilder) : NotificationBuilder(inner) {
        override fun build(context: Context, model: Map<String, Any?>): BuildOutcome =
            next(context, model + (CUSTOM_LAYOUT to true))

        override fun decorate(
            context: Context,
            model: Map<String, Any?>,
            builder: NotificationCompat.Builder
        ) {
            builder.setStyle(NotificationCompat.BigTextStyle().bigText("own"))
            super.decorate(context, model, builder)
        }
    }

    private fun manager() =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    @Before fun setUp() {
        NotificationBuilderRegistry.clearForTest()
        manager().cancelAll()
        core.setChannel(
            mapOf(Definitions.NOTIFICATION_CHANNEL_KEY to "ch", Definitions.NOTIFICATION_CHANNEL_NAME to "Ch")
        )
    }

    @After fun tearDown() = NotificationBuilderRegistry.clearForTest()

    private fun create(id: Int, vararg content: Pair<String, Any?>) {
        core.createNotification(
            mapOf(
                Definitions.NOTIFICATION_CONTENT to mapOf(
                    Definitions.NOTIFICATION_ID to id,
                    Definitions.NOTIFICATION_CHANNEL_KEY to "ch",
                    Definitions.NOTIFICATION_TITLE to "T",
                    *content
                )
            )
        ) {}
        shadowOf(Looper.getMainLooper()).idle()
    }

    private fun extras(id: Int) =
        manager().activeNotifications.first { it.id == id }.notification.extras

    @Test fun decoratorsRunOutermostFirstOnTheBuilder() {
        NotificationBuilderRegistry.register(10) { Recorder(it, "inner") }
        NotificationBuilderRegistry.register(20) { Recorder(it, "outer") }
        create(1)
        assertEquals(listOf("outer", "inner"), calls)
        // The innermost one ran last, so its value stands.
        assertEquals("inner", extras(1).getCharSequence(NotificationCompat.EXTRA_SUB_TEXT).toString())
    }

    @Test fun aCustomLayoutReplacesTheBuiltInMessaging() {
        NotificationBuilderRegistry.register(10) { OwnMessaging(it) }
        create(1, Definitions.NOTIFICATION_LAYOUT to "Messaging", Definitions.NOTIFICATION_GROUP_KEY to "g")
        create(2, Definitions.NOTIFICATION_LAYOUT to "Messaging", Definitions.NOTIFICATION_GROUP_KEY to "g")
        // No 0.12 stacking: each message keeps its own id, with the decorator's style.
        assertEquals(setOf(1, 2), manager().activeNotifications.map { it.id }.toSet())
        val notification = manager().activeNotifications.first { it.id == 2 }.notification
        assertNull(NotificationCompat.MessagingStyle.extractMessagingStyleFromNotification(notification))
        assertEquals("own", notification.extras.getCharSequence(NotificationCompat.EXTRA_BIG_TEXT).toString())
    }
}
