package me.carda.awesome_notifications_fcm

import android.content.Context
import android.os.Looper
import androidx.test.core.app.ApplicationProvider
import com.google.android.gms.tasks.Tasks
import com.google.firebase.FirebaseApp
import com.google.firebase.messaging.FirebaseMessaging
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import java.nio.ByteBuffer
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.BeforeClass
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.ArgumentCaptor
import org.mockito.ArgumentMatchers.any
import org.mockito.ArgumentMatchers.eq
import org.mockito.ArgumentMatchers.isNull
import org.mockito.MockedStatic
import org.mockito.Mockito.atLeast
import org.mockito.Mockito.mock
import org.mockito.Mockito.mockStatic
import org.mockito.Mockito.verify
import org.mockito.Mockito.`when`
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/** The `awesome_notifications_fcm` channel: Firebase token / topic calls and the events pushed to Dart. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class AwesomeNotificationsFcmPluginTest {

    companion object {
        /** Mockito 5.0's Byte Buddy predates Java 21 class files: let it read them. */
        @JvmStatic @BeforeClass fun allowNewerClassFiles() {
            System.setProperty("net.bytebuddy.experimental", "true")
        }
    }

    private val context: Context get() = ApplicationProvider.getApplicationContext()

    private lateinit var messenger: BinaryMessenger
    private lateinit var binding: FlutterPlugin.FlutterPluginBinding
    private lateinit var firebaseApps: MockedStatic<FirebaseApp>
    private lateinit var firebaseMessagingStatic: MockedStatic<FirebaseMessaging>
    private lateinit var messaging: FirebaseMessaging
    private val plugin = AwesomeNotificationsFcmPlugin()

    @Before fun setUp() {
        messenger = mock(BinaryMessenger::class.java)
        binding = mock(FlutterPlugin.FlutterPluginBinding::class.java)
        `when`(binding.applicationContext).thenReturn(context)
        `when`(binding.binaryMessenger).thenReturn(messenger)

        messaging = mock(FirebaseMessaging::class.java)
        firebaseApps = mockStatic(FirebaseApp::class.java)
        firebaseMessagingStatic = mockStatic(FirebaseMessaging::class.java)
        firebaseMessagingStatic.`when`<FirebaseMessaging> { FirebaseMessaging.getInstance() }.thenReturn(messaging)
        setFirebaseAvailable(true)

        plugin.onAttachedToEngine(binding)
    }

    @After fun tearDown() {
        plugin.onDetachedFromEngine(binding)
        firebaseMessagingStatic.close()
        firebaseApps.close()
    }

    private fun setFirebaseAvailable(available: Boolean) {
        val apps = if (available) listOf(mock(FirebaseApp::class.java)) else emptyList()
        firebaseApps.`when`<List<FirebaseApp>> { FirebaseApp.getApps(any(Context::class.java)) }.thenReturn(apps)
    }

    private fun idle() = shadowOf(Looper.getMainLooper()).idle()

    /** Records what a method call answered. */
    private class Answer : MethodChannel.Result {
        val values = mutableListOf<Any?>()
        var notImplemented = false
        override fun success(result: Any?) { values.add(result) }
        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) { values.add("error:$errorCode") }
        override fun notImplemented() { notImplemented = true }
    }

    private fun call(method: String, arguments: Any? = null): Answer {
        val answer = Answer()
        plugin.onMethodCall(MethodCall(method, arguments), answer)
        idle()
        return answer
    }

    /** The method calls the plugin sent to Dart on its channel. */
    private fun sentToDart(): List<MethodCall> {
        val captor = ArgumentCaptor.forClass(ByteBuffer::class.java)
        return try {
            verify(messenger, atLeast(1)).send(eq(FcmDefinitions.CHANNEL_FLUTTER_PLUGIN), captor.capture(), isNull())
            captor.allValues.map { StandardMethodCodec.INSTANCE.decodeMethodCall(it.apply { rewind() }) }
        } catch (e: Throwable) {
            if (e is AssertionError) emptyList() else throw e
        }
    }

    // MARK: - Attach / detach

    @Test fun attachingListensOnThePluginChannelAndDetachingStops() {
        verify(messenger).setMessageHandler(eq(FcmDefinitions.CHANNEL_FLUTTER_PLUGIN), any())
        plugin.onDetachedFromEngine(binding)
        verify(messenger).setMessageHandler(eq(FcmDefinitions.CHANNEL_FLUTTER_PLUGIN), isNull())
        assertFalse(FcmEventsReceiver.hasSilentListener())
        // Detached: tokens no longer reach this engine.
        FcmEventsReceiver.notifyFcmToken("late")
        idle()
        assertTrue(sentToDart().isEmpty())
    }

    // MARK: - initialize

    @Test fun initializeStoresTheHandlesAndDeliversTheCurrentToken() {
        `when`(messaging.token).thenReturn(Tasks.forResult("tok-1"))
        val answer = call(
            FcmDefinitions.CHANNEL_METHOD_INITIALIZE,
            mapOf(
                FcmDefinitions.DEBUG_MODE to true,
                FcmDefinitions.DART_BG_HANDLE to 101,
                FcmDefinitions.SILENT_HANDLE to 202L
            )
        )
        assertEquals(listOf<Any?>(true), answer.values)
        assertEquals(101L, FcmDefaultsManager.getDartBackgroundHandle(context))
        assertEquals(202L, FcmDefaultsManager.getSilentCallbackHandle(context))
        assertTrue(FcmDefaultsManager.isDebug(context))
        assertEquals("tok-1", FcmDefaultsManager.getLastToken(context))
        val sent = sentToDart().single()
        assertEquals(FcmDefinitions.CHANNEL_METHOD_NEW_FCM_TOKEN, sent.method)
        assertEquals("tok-1", sent.arguments)
    }

    @Test fun initializeWithoutArgumentsOrFirebaseStillSucceeds() {
        setFirebaseAvailable(false)
        val answer = call(FcmDefinitions.CHANNEL_METHOD_INITIALIZE, null)
        assertEquals(listOf<Any?>(true), answer.values)
        assertEquals(0L, FcmDefaultsManager.getDartBackgroundHandle(context))
        assertFalse(FcmDefaultsManager.isDebug(context))
        assertTrue(sentToDart().isEmpty())
    }

    @Test fun initializeDeliversNoTokenWhenFirebaseFailsOrHasNone() {
        `when`(messaging.token).thenReturn(Tasks.forException(RuntimeException("offline")))
        call(FcmDefinitions.CHANNEL_METHOD_INITIALIZE, emptyMap<String, Any?>())
        @Suppress("UNCHECKED_CAST")
        `when`(messaging.token).thenReturn(Tasks.forResult(null as String?))
        call(FcmDefinitions.CHANNEL_METHOD_INITIALIZE, emptyMap<String, Any?>())
        assertNull(FcmDefaultsManager.getLastToken(context))
        assertTrue(sentToDart().isEmpty())
    }

    // MARK: - Firebase calls

    @Test fun isFirebaseAvailableReflectsTheInitializedApps() {
        assertEquals(listOf<Any?>(true), call(FcmDefinitions.CHANNEL_METHOD_IS_FCM_AVAILABLE).values)
        setFirebaseAvailable(false)
        assertEquals(listOf<Any?>(false), call(FcmDefinitions.CHANNEL_METHOD_IS_FCM_AVAILABLE).values)
    }

    @Test fun getFirebaseTokenAnswersTheTokenOrEmpty() {
        `when`(messaging.token).thenReturn(Tasks.forResult("tok-2"))
        assertEquals(listOf<Any?>("tok-2"), call(FcmDefinitions.CHANNEL_METHOD_GET_FCM_TOKEN).values)

        `when`(messaging.token).thenReturn(Tasks.forResult(null as String?))
        assertEquals(listOf<Any?>(""), call(FcmDefinitions.CHANNEL_METHOD_GET_FCM_TOKEN).values)

        `when`(messaging.token).thenReturn(Tasks.forException(RuntimeException("offline")))
        assertEquals(listOf<Any?>(""), call(FcmDefinitions.CHANNEL_METHOD_GET_FCM_TOKEN).values)

        setFirebaseAvailable(false)
        assertEquals(listOf<Any?>(""), call(FcmDefinitions.CHANNEL_METHOD_GET_FCM_TOKEN).values)
    }

    @Test fun subscribeTopicAnswersWhetherFirebaseSubscribed() {
        val topic = mapOf(FcmDefinitions.NOTIFICATION_TOPIC to "news")
        `when`(messaging.subscribeToTopic("news")).thenReturn(Tasks.forResult(null))
        assertEquals(listOf<Any?>(true), call(FcmDefinitions.CHANNEL_METHOD_SUBSCRIBE_TOPIC, topic).values)
        verify(messaging).subscribeToTopic("news")

        `when`(messaging.subscribeToTopic("news")).thenReturn(Tasks.forException(RuntimeException("no")))
        assertEquals(listOf<Any?>(false), call(FcmDefinitions.CHANNEL_METHOD_SUBSCRIBE_TOPIC, topic).values)

        // No topic, or no Firebase: false without asking Firebase.
        assertEquals(listOf<Any?>(false), call(FcmDefinitions.CHANNEL_METHOD_SUBSCRIBE_TOPIC, emptyMap<String, Any?>()).values)
        assertEquals(listOf<Any?>(false), call(FcmDefinitions.CHANNEL_METHOD_SUBSCRIBE_TOPIC, "news").values)
        setFirebaseAvailable(false)
        assertEquals(listOf<Any?>(false), call(FcmDefinitions.CHANNEL_METHOD_SUBSCRIBE_TOPIC, topic).values)
    }

    @Test fun unsubscribeTopicAnswersWhetherFirebaseUnsubscribed() {
        val topic = mapOf(FcmDefinitions.NOTIFICATION_TOPIC to "news")
        `when`(messaging.unsubscribeFromTopic("news")).thenReturn(Tasks.forResult(null))
        assertEquals(listOf<Any?>(true), call(FcmDefinitions.CHANNEL_METHOD_UNSUBSCRIBE_TOPIC, topic).values)
        verify(messaging).unsubscribeFromTopic("news")

        `when`(messaging.unsubscribeFromTopic("news")).thenReturn(Tasks.forException(RuntimeException("no")))
        assertEquals(listOf<Any?>(false), call(FcmDefinitions.CHANNEL_METHOD_UNSUBSCRIBE_TOPIC, topic).values)

        assertEquals(listOf<Any?>(false), call(FcmDefinitions.CHANNEL_METHOD_UNSUBSCRIBE_TOPIC, null).values)
        setFirebaseAvailable(false)
        assertEquals(listOf<Any?>(false), call(FcmDefinitions.CHANNEL_METHOD_UNSUBSCRIBE_TOPIC, topic).values)
    }

    @Test fun deleteTokenAnswersWhetherFirebaseDeletedIt() {
        `when`(messaging.deleteToken()).thenReturn(Tasks.forResult(null))
        assertEquals(listOf<Any?>(true), call(FcmDefinitions.CHANNEL_METHOD_DELETE_TOKEN).values)
        `when`(messaging.deleteToken()).thenReturn(Tasks.forException(RuntimeException("no")))
        assertEquals(listOf<Any?>(false), call(FcmDefinitions.CHANNEL_METHOD_DELETE_TOKEN).values)
        setFirebaseAvailable(false)
        assertEquals(listOf<Any?>(false), call(FcmDefinitions.CHANNEL_METHOD_DELETE_TOKEN).values)
    }

    @Test fun unknownMethodsAreNotImplemented() {
        val answer = call("nope")
        assertTrue(answer.notImplemented)
        assertTrue(answer.values.isEmpty())
    }

    // MARK: - Events to Dart

    @Test fun tokenRefreshesAreForwardedToDart() {
        FcmEventsReceiver.notifyFcmToken("fresh")
        FcmEventsReceiver.notifyNativeToken("native")
        idle()
        val sent = sentToDart()
        assertEquals(
            listOf(FcmDefinitions.CHANNEL_METHOD_NEW_FCM_TOKEN to "fresh", FcmDefinitions.CHANNEL_METHOD_NEW_NATIVE_TOKEN to "native"),
            sent.map { it.method to it.arguments }
        )
    }

    @Test fun foregroundSilentDataIsConsumedAndSentWithTheSilentHandle() {
        call(FcmDefinitions.CHANNEL_METHOD_INITIALIZE, mapOf(FcmDefinitions.SILENT_HANDLE to 77))
        val data = SilentDataModel().fromData(mapOf("orderId" to "9"))
        assertTrue(FcmEventsReceiver.notifySilentData(data))
        idle()
        val sent = sentToDart().last()
        assertEquals(FcmDefinitions.CHANNEL_METHOD_SILENT_CALLBACK, sent.method)
        @Suppress("UNCHECKED_CAST")
        val payload = sent.arguments as Map<String, Any?>
        assertEquals("9", payload["orderId"])
        assertEquals(77, (payload[FcmDefinitions.SILENT_HANDLE] as Number).toInt())
    }

    @Test fun pushesFromDartAreHandledByThePlugin() {
        // The channel's handler is the plugin itself.
        val captor = ArgumentCaptor.forClass(BinaryMessenger.BinaryMessageHandler::class.java)
        verify(messenger).setMessageHandler(eq(FcmDefinitions.CHANNEL_FLUTTER_PLUGIN), captor.capture())
        var reply: ByteBuffer? = null
        captor.value.onMessage(
            StandardMethodCodec.INSTANCE.encodeMethodCall(MethodCall(FcmDefinitions.CHANNEL_METHOD_IS_FCM_AVAILABLE, null))
                .apply { rewind() }
        ) { reply = it }
        assertEquals(true, StandardMethodCodec.INSTANCE.decodeEnvelope(reply!!.apply { rewind() }))
    }
}
