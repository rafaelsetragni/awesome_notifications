package me.carda.awesome_notifications_fcm

import android.app.Notification
import android.app.NotificationManager
import android.content.Context
import android.os.Bundle
import android.os.Looper
import androidx.test.core.app.ApplicationProvider
import com.google.firebase.messaging.RemoteMessage
import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.atomic.AtomicBoolean
import me.carda.android_awn_core.AwesomeNotifications
import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.NotificationLifeCycle
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/**
 * Every push goes through the service: a displayable one is posted by the
 * Flutter-free core engine (any app state), a data-only one goes to the
 * attached plugin or, with the app terminated, to the headless isolate.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class AwnFcmServiceTest {

    private val context: Context get() = ApplicationProvider.getApplicationContext()
    private lateinit var service: AwnFcmService

    private class Tokens : FcmEventsReceiver.TokenListener {
        val received = mutableListOf<String?>()
        override fun onNewFcmToken(token: String?) { received.add(token) }
        override fun onNewNativeToken(token: String?) {}
    }

    private class Silent(val consume: Boolean) : FcmEventsReceiver.SilentListener {
        val received = mutableListOf<SilentDataModel>()
        override fun onSilentData(silentData: SilentDataModel): Boolean {
            received.add(silentData)
            return consume
        }
    }

    private val tokens = Tokens()
    private val silent = Silent(consume = true)

    @Suppress("UNCHECKED_CAST")
    private fun backgroundQueue(): ConcurrentLinkedQueue<Map<String, Any?>> =
        FcmBackgroundExecutor::class.java.getDeclaredField("queue").apply { isAccessible = true }
            .get(FcmBackgroundExecutor) as ConcurrentLinkedQueue<Map<String, Any?>>

    @Before fun setUp() {
        backgroundQueue().clear()
        service = Robolectric.buildService(AwnFcmService::class.java).create().get()
        AwesomeNotifications(context).setChannel(
            mapOf(Definitions.NOTIFICATION_CHANNEL_KEY to "push", Definitions.NOTIFICATION_CHANNEL_NAME to "Push")
        )
    }

    @After fun tearDown() {
        FcmEventsReceiver.unsubscribeToken(tokens)
        FcmEventsReceiver.unsubscribeSilent(silent)
        backgroundQueue().clear()
        FcmBackgroundExecutor::class.java.getDeclaredField("isRunning").apply { isAccessible = true }
            .let { (it.get(FcmBackgroundExecutor) as AtomicBoolean).set(false) }
    }

    private fun manager() = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    /** The core posts off the main thread: waits for [id] to be shown. */
    private fun awaitPosted(id: Int? = null, timeoutMs: Long = 5_000): Notification? {
        val end = System.currentTimeMillis() + timeoutMs
        while (System.currentTimeMillis() < end) {
            shadowOf(Looper.getMainLooper()).idle()
            val found = manager().activeNotifications.firstOrNull { id == null || it.id == id }
            if (found != null) return found.notification
            Thread.sleep(20)
        }
        return null
    }

    /** A push with a `notification` block, as FCM delivers it. */
    private fun notificationMessage(messageId: String?, image: String? = null, sticky: Boolean = false): RemoteMessage {
        val bundle = Bundle().apply {
            if (messageId != null) putString("google.message_id", messageId)
            putString("gcm.n.e", "1")
            putString("gcm.n.title", "Hello")
            putString("gcm.n.body", "World")
            putString("gcm.n.android_channel_id", "push")
            if (image != null) putString("gcm.n.image", image)
            if (sticky) putString("gcm.n.sticky", "true")
            putString("orderId", "9")
        }
        return RemoteMessage(bundle)
    }

    @Test fun aNewTokenIsPersistedAndForwarded() {
        FcmEventsReceiver.subscribeToken(tokens)
        service.onNewToken("tok-9")
        assertEquals("tok-9", FcmDefaultsManager.getLastToken(context))
        assertEquals(listOf<String?>("tok-9"), tokens.received)
    }

    @Test fun aNotificationPushIsPostedWithTheIdOfItsMessageId() {
        service.onMessageReceived(notificationMessage("0:12345%abc"))
        val posted = awaitPosted(12345)
        assertNotNull(posted)
        posted!!
        assertEquals("push", posted.channelId)
        assertEquals("Hello", posted.extras.getCharSequence(Notification.EXTRA_TITLE).toString())
        assertEquals("World", posted.extras.getCharSequence(Notification.EXTRA_TEXT).toString())
        assertTrue(posted.flags and Notification.FLAG_AUTO_CANCEL != 0)
        assertTrue(silent.received.isEmpty())
    }

    @Test fun aMessageIdWithoutANumberIsHashed() {
        val messageId = "projects/p/messages/abc"
        service.onMessageReceived(notificationMessage(messageId, sticky = true))
        val posted = awaitPosted(kotlin.math.abs(messageId.hashCode()))
        assertNotNull(posted)
        // Sticky: not dismissed on tap.
        assertEquals(0, posted!!.flags and Notification.FLAG_AUTO_CANCEL)
    }

    @Test fun aPushWithoutAMessageIdStillPosts() {
        service.onMessageReceived(notificationMessage(null, image = "https://example.com/x.png"))
        assertNotNull(awaitPosted())
    }

    @Test fun anAwesomeContentPushIsPostedWithItsOwnId() {
        val message = RemoteMessage.Builder("sender@fcm.googleapis.com")
            .setMessageId("0:1%x")
            .setData(
                mapOf("content" to """{"id":77,"channelKey":"push","title":"Awesome","body":"Body"}""")
            )
            .build()
        service.onMessageReceived(message)
        val posted = awaitPosted(77)
        assertNotNull(posted)
        assertEquals("Awesome", posted!!.extras.getCharSequence(Notification.EXTRA_TITLE).toString())
    }

    @Test fun aDataPushGoesToTheAttachedPluginStampedWithTheLifecycle() {
        FcmEventsReceiver.subscribeSilent(silent)
        val message = RemoteMessage.Builder("sender@fcm.googleapis.com")
            .setMessageId("0:2%x")
            .setData(mapOf("orderId" to "9", "isSilentData" to "true"))
            .build()
        service.onMessageReceived(message)
        shadowOf(Looper.getMainLooper()).idle()
        val received = silent.received.single()
        assertEquals("9", received.data["orderId"])
        assertFalse(received.data.containsKey("isSilentData"))
        assertEquals(FcmLifecycle.current(context), received.createdLifeCycle)
        assertTrue(manager().activeNotifications.isEmpty())
        assertTrue(backgroundQueue().isEmpty())
    }

    @Test fun aDataPushWithTheAppTerminatedGoesToTheBackgroundIsolate() {
        // Handles registered by a past initialize(), no plugin attached.
        FcmDefaultsManager.saveHandles(context, 10L, 20L, false)
        val message = RemoteMessage.Builder("sender@fcm.googleapis.com")
            .setData(mapOf("orderId" to "9", Definitions.NOTIFICATION_CREATED_LIFECYCLE to "Terminated"))
            .build()
        service.onMessageReceived(message)
        val queued = backgroundQueue().single()
        assertEquals("9", queued["orderId"])
        assertEquals(NotificationLifeCycle.Terminated.name, queued[Definitions.NOTIFICATION_CREATED_LIFECYCLE])
        assertTrue(manager().activeNotifications.isEmpty())
    }
}
