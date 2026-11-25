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

    // --- NotificationActions.dispatch (controls that are not buttons) ---

    @Test fun aControlEmitsItsActionWithItsInput() {
        val control = mapOf<String, Any?>(
            Definitions.NOTIFICATION_BUTTON_KEY to "awn.media.seekTo",
            Definitions.NOTIFICATION_ACTION_TYPE to "SilentAction",
            Definitions.NOTIFICATION_AUTO_DISMISSIBLE to false
        )
        NotificationActions.dispatch(
            context, buttonModel("PLAY", "KeepOnTop"), "awn.media.seekTo", "37000", control)

        assertEquals(1, received.size)
        assertEquals(Definitions.EVENT_DEFAULT_ACTION, received[0].first)
        assertEquals("awn.media.seekTo", received[0].second[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED])
        assertEquals("37000", received[0].second[Definitions.NOTIFICATION_BUTTON_KEY_INPUT])
        assertEquals("SilentAction", received[0].second[Definitions.NOTIFICATION_ACTION_TYPE])
        assertEquals(5, received[0].second[Definitions.NOTIFICATION_ID])
    }

    @Test fun aControlKeepsTheNotificationWhenNotAutoDismissible() {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
        manager.createNotificationChannel(
            android.app.NotificationChannel("c", "c", android.app.NotificationManager.IMPORTANCE_DEFAULT))
        manager.notify(5, androidx.core.app.NotificationCompat.Builder(context, "c")
            .setSmallIcon(android.R.drawable.ic_media_play).build())
        val control = mapOf<String, Any?>(
            Definitions.NOTIFICATION_BUTTON_KEY to "awn.media.pause",
            Definitions.NOTIFICATION_ACTION_TYPE to "SilentAction",
            Definitions.NOTIFICATION_AUTO_DISMISSIBLE to false
        )
        NotificationActions.dispatch(context, buttonModel("PLAY", "KeepOnTop"), "awn.media.pause", null, control)
        assertEquals(listOf(5), manager.activeNotifications.map { it.id })
        assertEquals(null, received[0].second[Definitions.NOTIFICATION_BUTTON_KEY_INPUT])
    }

    @Test fun withoutAControlTheModelButtonIsUsed() {
        NotificationActions.dispatch(context, buttonModel("DEL", "DismissAction"), "DEL")
        assertEquals(Definitions.EVENT_NOTIFICATION_DISMISSED, received[0].first)
    }

    // --- 0.12 routing: the app's listener or the background isolate ---

    private val background = mutableListOf<Map<String, Any?>>()

    private fun withBackground(block: () -> Unit) {
        BackgroundActions.executor = BackgroundActions.Executor { _, action, done ->
            background.add(action)
            done()
        }
        try { block() } finally { BackgroundActions.executor = null }
    }

    @Test fun withNoAppListeningTheActionRunsInTheBackgroundAsTerminated() = withBackground {
        AwesomeEventsReceiver.unsubscribe(listener)
        var finished = false
        NotificationActions.dispatch(context, buttonModel("PLAY", "SilentAction"), "PLAY") { finished = true }
        assertTrue(received.isEmpty())
        assertEquals(1, background.size)
        assertEquals("PLAY", background[0][Definitions.NOTIFICATION_BUTTON_KEY_PRESSED])
        assertEquals("Terminated", background[0][Definitions.NOTIFICATION_ACTION_LIFECYCLE])
        assertTrue(finished)
    }

    @Test fun aSilentBackgroundActionAlwaysRunsInTheBackground() = withBackground {
        NotificationActions.dispatch(context, buttonModel("SYNC", "SilentBackgroundAction"), "SYNC")
        assertTrue(received.isEmpty())
        assertEquals("Background", background.single()[Definitions.NOTIFICATION_ACTION_LIFECYCLE])
    }

    @Test fun withTheAppListeningTheActionGoesToIt() = withBackground {
        NotificationActions.dispatch(context, buttonModel("PLAY", "SilentAction"), "PLAY")
        assertTrue(background.isEmpty())
        assertEquals(Definitions.EVENT_DEFAULT_ACTION, received.single().first)
    }

    @Test fun aDisabledActionDoesNothing() = withBackground {
        var finished = false
        NotificationActions.dispatch(context, buttonModel("OFF", "DisabledAction"), "OFF") { finished = true }
        assertTrue(received.isEmpty() && background.isEmpty())
        assertTrue(finished)
    }
}
