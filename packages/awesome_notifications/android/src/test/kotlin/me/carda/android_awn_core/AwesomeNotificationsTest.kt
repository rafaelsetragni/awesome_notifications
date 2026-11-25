package me.carda.android_awn_core

import android.app.NotificationManager
import android.content.Context
import android.os.Looper
import androidx.test.core.app.ApplicationProvider
import java.util.concurrent.Executor
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/**
 * The Flutter-free engine: channel creation (with importance mapping) and the
 * cancel path fanning out to the registered [CancelInterceptor]s. The async
 * create/post path runs on its own executor thread and is exercised through
 * NotificationBuilder's build tests instead.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class AwesomeNotificationsTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val core = AwesomeNotifications(context)

    // A second engine whose executor runs inline, so createNotification (which
    // builds off-thread) completes synchronously and can be asserted on.
    private val syncCore = AwesomeNotifications(context, Executor { it.run() })

    private fun notificationManager() =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private fun content(vararg entries: Pair<String, Any?>): Map<String, Any?> =
        mapOf(Definitions.NOTIFICATION_CONTENT to mapOf(*entries))

    /** Runs createNotification synchronously and returns the reported result. */
    private fun create(model: Map<String, Any?>): Boolean {
        NotificationBuilderRegistry.clearForTest()
        core.setChannel(
            mapOf(
                Definitions.NOTIFICATION_CHANNEL_KEY to "ch",
                Definitions.NOTIFICATION_CHANNEL_NAME to "Ch"
            )
        )
        var result: Boolean? = null
        syncCore.createNotification(model) { result = it }
        shadowOf(Looper.getMainLooper()).idle() // run the posted callback
        return result!!
    }

    @After fun cleanRegistry() = NotificationBuilderRegistry.clearForTest()

    @Test fun setChannelCreatesChannelWithMappedImportance() {
        core.setChannel(
            mapOf(
                Definitions.NOTIFICATION_CHANNEL_KEY to "alerts",
                Definitions.NOTIFICATION_CHANNEL_NAME to "Alerts",
                Definitions.NOTIFICATION_CHANNEL_DESCRIPTION to "desc",
                Definitions.NOTIFICATION_IMPORTANCE to "High"
            )
        )
        val channel = notificationManager().getNotificationChannel("alerts")
        assertNotNull(channel)
        assertEquals(NotificationManager.IMPORTANCE_HIGH, channel.importance)
        assertEquals("desc", channel.description)
    }

    @Test fun setChannelDefaultsImportanceWhenMissing() {
        core.setChannel(
            mapOf(
                Definitions.NOTIFICATION_CHANNEL_KEY to "plain",
                Definitions.NOTIFICATION_CHANNEL_NAME to "Plain"
            )
        )
        assertEquals(
            NotificationManager.IMPORTANCE_DEFAULT,
            notificationManager().getNotificationChannel("plain").importance
        )
    }

    @Test fun cancelInvokesInterceptorThenDismisses() {
        val cancelled = mutableListOf<Int>()
        val interceptor = object : CancelInterceptor {
            override fun onCancel(context: Context, id: Int) { cancelled.add(id) }
        }
        CancelInterceptorRegistry.register(interceptor)
        try {
            core.cancel(42)
            assertEquals(listOf(42), cancelled)
        } finally {
            CancelInterceptorRegistry.unregister(interceptor)
        }
    }

    @Test fun cancelAllInvokesInterceptor() {
        var calledAll = false
        val interceptor = object : CancelInterceptor {
            override fun onCancelAll(context: Context) { calledAll = true }
        }
        CancelInterceptorRegistry.register(interceptor)
        try {
            core.cancelAll()
            assertTrue(calledAll)
        } finally {
            CancelInterceptorRegistry.unregister(interceptor)
        }
    }

    @Test fun dismissAndCancelInvokeTheDismissHooks() {
        val calls = mutableListOf<String>()
        val interceptor = object : CancelInterceptor {
            override fun onDismiss(context: Context, id: Int) { calls.add("dismiss:$id") }
            override fun onDismissAll(context: Context) { calls.add("all") }
            override fun onDismissByChannelKey(context: Context, channelKey: String) {
                calls.add("channel:$channelKey")
            }
            override fun onDismissByGroupKey(context: Context, groupKey: String) {
                calls.add("group:$groupKey")
            }
        }
        CancelInterceptorRegistry.register(interceptor)
        try {
            core.dismiss(1)
            core.cancel(2)
            core.dismissAll()
            core.cancelAll()
            core.dismissByChannelKey("c")
            core.cancelByChannelKey("c")
            core.dismissByGroupKey("g")
            core.cancelByGroupKey("g")
            assertEquals(
                listOf("dismiss:1", "dismiss:2", "all", "all", "channel:c", "channel:c", "group:g", "group:g"),
                calls
            )
        } finally {
            CancelInterceptorRegistry.unregister(interceptor)
        }
    }

    @Test fun aSwipeInvokesTheDismissHook() {
        val dismissed = mutableListOf<Int>()
        val interceptor = object : CancelInterceptor {
            override fun onDismiss(context: Context, id: Int) { dismissed.add(id) }
        }
        CancelInterceptorRegistry.register(interceptor)
        try {
            val intent = android.content.Intent(context, DismissedNotificationReceiver::class.java).apply {
                action = Definitions.DISMISSED_NOTIFICATION
                putExtra(
                    Definitions.NOTIFICATION_JSON,
                    JsonUtils.getInstance().toJson(
                        mapOf(Definitions.NOTIFICATION_CONTENT to mapOf(Definitions.NOTIFICATION_ID to 9))
                    )
                )
            }
            DismissedNotificationReceiver().onReceive(context, intent)
            assertEquals(listOf(9), dismissed)
        } finally {
            CancelInterceptorRegistry.unregister(interceptor)
        }
    }

    @Test fun isNotificationAllowedReturnsBoolean() {
        // Robolectric enables notifications by default.
        assertTrue(core.isNotificationAllowed())
    }

    // --- create / post path (via the injected synchronous executor) ---

    @Test fun createPostsToStatusBarAndReportsSuccess() {
        val created = create(
            content(
                Definitions.NOTIFICATION_ID to 7,
                Definitions.NOTIFICATION_CHANNEL_KEY to "ch",
                Definitions.NOTIFICATION_TITLE to "Hi"
            )
        )
        assertTrue(created)
        val active = notificationManager().activeNotifications
        assertEquals(1, active.size)
        assertEquals(7, active[0].id)
    }

    @Test fun createEmitsCreatedAndDisplayedEvents() {
        val events = mutableListOf<String>()
        val listener = object : AwesomeEventListener {
            override fun onNewAwesomeEvent(eventType: String, content: Map<String, Any?>) {
                events.add(eventType)
            }
        }
        AwesomeEventsReceiver.subscribe(listener)
        try {
            create(
                content(
                    Definitions.NOTIFICATION_ID to 8,
                    Definitions.NOTIFICATION_CHANNEL_KEY to "ch",
                    Definitions.NOTIFICATION_TITLE to "Hi"
                )
            )
            assertTrue(events.contains(Definitions.EVENT_NOTIFICATION_CREATED))
            assertTrue(events.contains(Definitions.EVENT_NOTIFICATION_DISPLAYED))
        } finally {
            AwesomeEventsReceiver.unsubscribe(listener)
        }
    }

    @Test fun createInvalidModelReportsFailureAndPostsNothing() {
        val created = create(content(Definitions.NOTIFICATION_CHANNEL_KEY to "ch")) // no id
        assertFalse(created)
        assertEquals(0, notificationManager().activeNotifications.size)
    }

    @Test fun createHandledByDecoratorSucceedsWithoutPosting() {
        core.setChannel(
            mapOf(
                Definitions.NOTIFICATION_CHANNEL_KEY to "ch",
                Definitions.NOTIFICATION_CHANNEL_NAME to "Ch"
            )
        )
        NotificationBuilderRegistry.clearForTest()
        // A decorator that takes over delivery (like scheduling): returns Handled.
        NotificationBuilderRegistry.register(10) { inner ->
            object : NotificationBuilder(inner) {
                override fun build(context: Context, model: Map<String, Any?>) =
                    BuildOutcome.Handled
            }
        }
        var created: Boolean? = null
        syncCore.createNotification(
            content(
                Definitions.NOTIFICATION_ID to 9,
                Definitions.NOTIFICATION_CHANNEL_KEY to "ch"
            )
        ) { created = it }
        shadowOf(Looper.getMainLooper()).idle()
        assertEquals(true, created)
        assertEquals(0, notificationManager().activeNotifications.size)
    }

    private fun createWith(outcome: BuildOutcome, withOnError: Boolean): Pair<Boolean?, String?> {
        core.setChannel(
            mapOf(
                Definitions.NOTIFICATION_CHANNEL_KEY to "ch",
                Definitions.NOTIFICATION_CHANNEL_NAME to "Ch"
            )
        )
        NotificationBuilderRegistry.clearForTest()
        NotificationBuilderRegistry.register(10) { inner ->
            object : NotificationBuilder(inner) {
                override fun build(context: Context, model: Map<String, Any?>) = outcome
            }
        }
        var created: Boolean? = null
        var error: String? = null
        val model = content(
            Definitions.NOTIFICATION_ID to 9,
            Definitions.NOTIFICATION_CHANNEL_KEY to "ch"
        )
        if (withOnError) {
            syncCore.createNotification(model, onError = { code, _, _ -> error = code }) { created = it }
        } else {
            syncCore.createNotification(model) { created = it }
        }
        shadowOf(Looper.getMainLooper()).idle()
        return created to error
    }

    @Test fun createAnsweredByDecoratorReportsItsValue() {
        assertEquals(false to null, createWith(BuildOutcome.Answered(false), withOnError = true))
        assertEquals(true to null, createWith(BuildOutcome.Answered(true), withOnError = true))
        assertEquals(0, notificationManager().activeNotifications.size)
    }

    @Test fun createFailedByDecoratorReportsTheError() {
        val failed = BuildOutcome.Failed("INVALID_ARGUMENTS", "bad", "arguments.invalid")
        assertEquals(null to "INVALID_ARGUMENTS", createWith(failed, withOnError = true))
        // Without an error callback the create just answers false.
        assertEquals(false to null, createWith(failed, withOnError = false))
    }
}
