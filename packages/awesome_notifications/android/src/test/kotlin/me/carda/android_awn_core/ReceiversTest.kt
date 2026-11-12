package me.carda.android_awn_core

import android.content.Context
import android.content.Intent
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * The BroadcastReceivers that turn a swipe-away (delete intent) and a
 * non-foreground action-button press into the corresponding lifecycle events.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class ReceiversTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val json = JsonUtils.getInstance()

    private val received = mutableListOf<Pair<String, Map<String, Any?>>>()
    private val listener = object : AwesomeEventListener {
        override fun onNewAwesomeEvent(eventType: String, content: Map<String, Any?>) {
            received.add(eventType to content)
        }
    }

    @Before fun subscribe() = AwesomeEventsReceiver.subscribe(listener)
    @After fun unsubscribe() = AwesomeEventsReceiver.unsubscribe(listener)

    private fun payloadIntent(action: String, model: Map<String, Any?>): Intent =
        Intent(action).putExtra(Definitions.NOTIFICATION_JSON, json.toJson(model))

    // --- DismissedNotificationReceiver ---

    @Test fun dismissedReceiverEmitsDismissEvent() {
        val model = mapOf(
            Definitions.NOTIFICATION_CONTENT to mapOf(Definitions.NOTIFICATION_ID to 3)
        )
        DismissedNotificationReceiver().onReceive(
            context, payloadIntent(Definitions.DISMISSED_NOTIFICATION, model)
        )
        assertEquals(1, received.size)
        assertEquals(Definitions.EVENT_NOTIFICATION_DISMISSED, received[0].first)
        assertEquals(3, received[0].second[Definitions.NOTIFICATION_ID])
        assertNotNull(received[0].second[Definitions.NOTIFICATION_DISMISSED_DATE])
    }

    @Test fun dismissedReceiverIgnoresWrongAction() {
        val model = mapOf(
            Definitions.NOTIFICATION_CONTENT to mapOf(Definitions.NOTIFICATION_ID to 3)
        )
        DismissedNotificationReceiver().onReceive(context, payloadIntent("OTHER", model))
        assertTrue(received.isEmpty())
    }

    // --- NotificationButtonReceiver ---

    private fun buttonModel(key: String, actionType: String): Map<String, Any?> = mapOf(
        Definitions.NOTIFICATION_CONTENT to mapOf(Definitions.NOTIFICATION_ID to 5),
        Definitions.NOTIFICATION_BUTTONS to listOf(
            mapOf(
                Definitions.NOTIFICATION_BUTTON_KEY to key,
                Definitions.NOTIFICATION_ACTION_TYPE to actionType
            )
        )
    )

    @Test fun buttonReceiverEmitsActionForNonDismissButton() {
        val model = buttonModel("REPLY", "KeepOnTop")
        val intent = payloadIntent(
            Definitions.NOTIFICATION_BUTTON_ACTION_PREFIX + "_REPLY", model
        ).putExtra(Definitions.NOTIFICATION_BUTTON_KEY_PRESSED, "REPLY")

        NotificationButtonReceiver().onReceive(context, intent)

        assertEquals(1, received.size)
        assertEquals(Definitions.EVENT_DEFAULT_ACTION, received[0].first)
        assertEquals("REPLY", received[0].second[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED])
        assertEquals("KeepOnTop", received[0].second[Definitions.NOTIFICATION_ACTION_TYPE])
    }

    @Test fun buttonReceiverEmitsDismissForDismissActionButton() {
        val model = buttonModel("DEL", "DismissAction")
        val intent = payloadIntent(
            Definitions.NOTIFICATION_BUTTON_ACTION_PREFIX + "_DEL", model
        ).putExtra(Definitions.NOTIFICATION_BUTTON_KEY_PRESSED, "DEL")

        NotificationButtonReceiver().onReceive(context, intent)

        assertEquals(1, received.size)
        assertEquals(Definitions.EVENT_NOTIFICATION_DISMISSED, received[0].first)
    }

    @Test fun buttonReceiverIgnoresForeignAction() {
        val intent = payloadIntent("SOMETHING_ELSE", buttonModel("K", "KeepOnTop"))
        NotificationButtonReceiver().onReceive(context, intent)
        assertTrue(received.isEmpty())
    }
}
