package me.carda.awesome_notifications_fcm

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.test.core.app.ApplicationProvider
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterJNI
import io.flutter.embedding.engine.dart.PlatformMessageHandler
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import io.flutter.view.FlutterCallbackInformation
import java.nio.ByteBuffer
import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.atomic.AtomicBoolean
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.ArgumentCaptor
import org.mockito.ArgumentMatchers.any
import org.mockito.ArgumentMatchers.anyInt
import org.mockito.ArgumentMatchers.anyLong
import org.mockito.ArgumentMatchers.eq
import org.mockito.ArgumentMatchers.isNull
import org.mockito.MockedStatic
import org.mockito.Mockito.atLeastOnce
import org.mockito.Mockito.doAnswer
import org.mockito.Mockito.mock
import org.mockito.Mockito.mockStatic
import org.mockito.Mockito.never
import org.mockito.Mockito.times
import org.mockito.Mockito.verify
import org.mockito.Mockito.`when`
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/**
 * The headless isolate that runs the Dart silent handler while the app is
 * terminated: started once per burst, fed one message per `pushNext`, torn down
 * when the queue drains. The Flutter engine runs on a mocked JNI, so the test
 * plays the Dart side through the engine's platform message handler.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class FcmBackgroundExecutorTest {

    private val context: Context get() = ApplicationProvider.getApplicationContext()

    private lateinit var loader: FlutterLoader
    private lateinit var jni: FlutterJNI
    private lateinit var callbacks: MockedStatic<FlutterCallbackInformation>
    private var callbackInfo: FlutterCallbackInformation? = null
    private val initialized = mutableListOf<Runnable>()

    @Suppress("UNCHECKED_CAST")
    private fun <T> field(name: String): T =
        FcmBackgroundExecutor::class.java.getDeclaredField(name).apply { isAccessible = true }.get(FcmBackgroundExecutor) as T

    private fun setField(name: String, value: Any?) =
        FcmBackgroundExecutor::class.java.getDeclaredField(name).apply { isAccessible = true }.set(FcmBackgroundExecutor, value)

    private fun queue(): ConcurrentLinkedQueue<Map<String, Any?>> = field("queue")
    private fun isRunning(): Boolean = field<AtomicBoolean>("isRunning").get()

    private fun idle() = shadowOf(Looper.getMainLooper()).idle()

    private fun silent(vararg data: Pair<String, String>) = SilentDataModel().fromData(mapOf(*data))

    private fun newCallbackInfo(): FlutterCallbackInformation =
        FlutterCallbackInformation::class.java
            .getDeclaredConstructor(String::class.java, String::class.java, String::class.java)
            .apply { isAccessible = true }
            .newInstance("silentPushBackgroundMain", "", "package:awesome_notifications_fcm/main.dart")

    @Before fun setUp() {
        queue().clear()
        field<AtomicBoolean>("isRunning").set(false)
        setField("engine", null)
        setField("channel", null)

        loader = mock(FlutterLoader::class.java)
        doAnswer { initialized.add(it.getArgument(3)); null }
            .`when`(loader).ensureInitializationCompleteAsync(any(), isNull(), any(Handler::class.java), any(Runnable::class.java))
        `when`(loader.findAppBundlePath()).thenReturn("flutter_assets")
        jni = mock(FlutterJNI::class.java)
        // Attached once the engine attaches it, as the real JNI.
        var attached = false
        doAnswer { attached = true; null }.`when`(jni).attachToNative()
        `when`(jni.isAttached).thenAnswer { attached }
        val factory = object : FlutterJNI.Factory() {
            override fun provideFlutterJNI(): FlutterJNI = jni
        }
        FlutterInjector.setInstance(FlutterInjector.Builder().setFlutterLoader(loader).setFlutterJNIFactory(factory).build())

        callbacks = mockStatic(FlutterCallbackInformation::class.java)
        callbacks.`when`<FlutterCallbackInformation?> { FlutterCallbackInformation.lookupCallbackInformation(anyLong()) }
            .thenAnswer { callbackInfo }
    }

    @After fun tearDown() {
        callbacks.close()
        FlutterInjector.reset()
        queue().clear()
        field<AtomicBoolean>("isRunning").set(false)
        setField("engine", null)
        setField("channel", null)
    }

    private fun registerHandles(background: Long = 10L, silentHandle: Long = 20L) =
        FcmDefaultsManager.saveHandles(context, background, silentHandle, false)

    /** Runs the loader's "initialization complete" callback, as the Flutter loader would. */
    private fun completeInitialization() {
        assertTrue(initialized.isNotEmpty())
        initialized.removeAt(0).run()
    }

    /** The engine's platform message handler: the Dart side of the reverse channel. */
    private fun dart(): PlatformMessageHandler {
        val captor = ArgumentCaptor.forClass(PlatformMessageHandler::class.java)
        verify(jni, atLeastOnce()).setPlatformMessageHandler(captor.capture())
        return captor.allValues.last { it != null }
    }

    /** The messages the isolate sent to Dart on the reverse channel, with their reply ids. */
    private fun sentToDart(): List<Pair<MethodCall, Int>> {
        val buffers = ArgumentCaptor.forClass(ByteBuffer::class.java)
        val replies = ArgumentCaptor.forClass(Int::class.java)
        return try {
            verify(jni, atLeastOnce()).dispatchPlatformMessage(
                eq(FcmDefinitions.DART_FCM_REVERSE_CHANNEL), buffers.capture(), anyInt(), replies.capture()
            )
            buffers.allValues.mapIndexed { i, b ->
                StandardMethodCodec.INSTANCE.decodeMethodCall(b.duplicate().apply { rewind() }) to replies.allValues[i]
            }
        } catch (e: AssertionError) {
            emptyList()
        }
    }

    /** Dart asks for the next message, as the isolate's main does when ready. */
    private fun pushNext(): Any? {
        var answered: Any? = "unset"
        FcmBackgroundExecutor.onMethodCall(MethodCall(FcmDefinitions.CHANNEL_METHOD_PUSH_NEXT_DATA, null), object : MethodChannel.Result {
            override fun success(result: Any?) { answered = result }
            override fun error(c: String, m: String?, d: Any?) { answered = "error" }
            override fun notImplemented() { answered = "notImplemented" }
        })
        idle()
        return answered
    }

    // MARK: - enqueue

    @Test fun nothingRunsBeforeTheHandlesAreRegistered() {
        FcmBackgroundExecutor.enqueue(context, silent("k" to "v"))
        idle()
        assertTrue(queue().isEmpty())
        assertFalse(isRunning())
        verify(loader, never()).startInitialization(any())

        // Only one of the two handles is not enough either.
        FcmDefaultsManager.saveHandles(context, 10L, null, false)
        FcmBackgroundExecutor.enqueue(context, silent("k" to "v"))
        assertTrue(queue().isEmpty())
    }

    @Test fun anUnknownCallbackHandleStopsTheIsolate() {
        registerHandles()
        callbackInfo = null
        FcmBackgroundExecutor.enqueue(context, silent("k" to "v"))
        assertTrue(isRunning())
        idle()
        verify(loader).startInitialization(any())
        completeInitialization()
        assertFalse(isRunning())
        assertNull(field<Any?>("engine"))
        // The message stays queued for the next start.
        assertEquals(1, queue().size)
    }

    @Test fun theIsolateRunsTheDartEntryPointAndDrainsTheQueueOneByOne() {
        registerHandles(silentHandle = 20L)
        callbackInfo = newCallbackInfo()
        FcmBackgroundExecutor.enqueue(context, silent("order" to "1"))
        FcmBackgroundExecutor.enqueue(context, silent("order" to "2"))
        idle()
        // One start for the burst.
        verify(loader, times(1)).ensureInitializationCompleteAsync(any(), isNull(), any(Handler::class.java), any(Runnable::class.java))
        completeInitialization()
        assertNotNull(field<Any?>("engine"))
        assertNotNull(field<Any?>("channel"))
        verify(jni).runBundleAndSnapshotFromLibrary(
            eq("flutter_assets"), eq("silentPushBackgroundMain"),
            eq("package:awesome_notifications_fcm/main.dart"), any(), isNull(), anyLong()
        )

        // The isolate is ready: the first message goes, with the silent handle.
        assertEquals(true, pushNext())
        val first = sentToDart().single()
        assertEquals(FcmDefinitions.CHANNEL_METHOD_SILENT_CALLBACK, first.first.method)
        @Suppress("UNCHECKED_CAST")
        val payload = first.first.arguments as Map<String, Any?>
        assertEquals("1", payload["order"])
        assertEquals(20L, (payload[FcmDefinitions.SILENT_HANDLE] as Number).toLong())

        // Dart handled it: the next one follows.
        dart().handlePlatformMessageResponse(first.second, StandardMethodCodec.INSTANCE.encodeSuccessEnvelope(null).apply { rewind() })
        idle()
        val second = sentToDart().last()
        @Suppress("UNCHECKED_CAST")
        assertEquals("2", (second.first.arguments as Map<String, Any?>)["order"])

        // Dart failed this one: the queue still moves on, and then drains.
        dart().handlePlatformMessageResponse(
            second.second, StandardMethodCodec.INSTANCE.encodeErrorEnvelope("E", "boom", null).apply { rewind() }
        )
        idle()
        assertEquals(2, sentToDart().size)
        assertNull(field<Any?>("engine"))
        assertNull(field<Any?>("channel"))
        assertFalse(isRunning())
        verify(jni).detachFromNativeAndReleaseResources()
    }

    @Test fun aHandlerDartDoesntImplementStillMovesTheQueue() {
        registerHandles()
        callbackInfo = newCallbackInfo()
        FcmBackgroundExecutor.enqueue(context, silent("order" to "1"))
        idle()
        completeInitialization()
        pushNext()
        val sent = sentToDart().single()
        // No reply bytes: the method is not implemented on the Dart side.
        dart().handlePlatformMessageResponse(sent.second, null)
        idle()
        assertFalse(isRunning())
        assertTrue(queue().isEmpty())
    }

    @Test fun aMessageArrivingWhileTheIsolateClosesStartsItAgain() {
        registerHandles()
        callbackInfo = newCallbackInfo()
        FcmBackgroundExecutor.enqueue(context, silent("order" to "1"))
        idle()
        completeInitialization()
        pushNext()
        val sent = sentToDart().single()
        // Dart's reply finds the queue empty and posts the teardown...
        dart().handlePlatformMessageResponse(sent.second, StandardMethodCodec.INSTANCE.encodeSuccessEnvelope(null).apply { rewind() })
        // ...but a message arrives before it runs: it only queues (the isolate is still running).
        FcmBackgroundExecutor.enqueue(context, silent("order" to "late"))
        assertTrue(isRunning())
        verify(loader, times(1)).ensureInitializationCompleteAsync(any(), isNull(), any(Handler::class.java), any(Runnable::class.java))
        idle()
        // The teardown closed the engine and restarted the isolate for it.
        assertTrue(isRunning())
        verify(jni).detachFromNativeAndReleaseResources()
        verify(loader, times(2)).ensureInitializationCompleteAsync(any(), isNull(), any(Handler::class.java), any(Runnable::class.java))
        assertEquals(1, queue().size)
    }

    @Test fun aPushNextWithAnEmptyQueueClosesTheIsolate() {
        registerHandles()
        callbackInfo = newCallbackInfo()
        FcmBackgroundExecutor.enqueue(context, silent("order" to "1"))
        idle()
        completeInitialization()
        queue().clear()
        assertEquals(true, pushNext())
        assertTrue(sentToDart().isEmpty())
        assertFalse(isRunning())
        assertNull(field<Any?>("engine"))
    }

    @Test fun otherMethodsFromDartAreNotImplemented() {
        var notImplemented = false
        FcmBackgroundExecutor.onMethodCall(MethodCall("other", null), object : MethodChannel.Result {
            override fun success(result: Any?) {}
            override fun error(c: String, m: String?, d: Any?) {}
            override fun notImplemented() { notImplemented = true }
        })
        assertTrue(notImplemented)
    }
}
