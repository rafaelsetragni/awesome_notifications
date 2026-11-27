package me.carda.awesome_notifications

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.test.core.app.ApplicationProvider
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import io.flutter.view.FlutterCallbackInformation
import java.nio.ByteBuffer
import me.carda.android_awn_core.BackgroundActions
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.ArgumentMatchers.any
import org.mockito.ArgumentMatchers.anyLong
import org.mockito.ArgumentMatchers.anyString
import org.mockito.MockedConstruction
import org.mockito.MockedStatic
import org.mockito.Mockito
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/**
 * The headless isolate that runs `onActionReceivedMethod` for a killed app
 * (0.12's background executor): it starts a Flutter engine on the saved entry
 * point, waits for Dart's `pushNext`, hands it each queued action over the
 * reverse channel, then tears the engine down. The Flutter engine itself
 * (native) is replaced by mocks.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class ActionBackgroundExecutorTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val loader: FlutterLoader = Mockito.mock(FlutterLoader::class.java)
    private val callbackInfo: FlutterCallbackInformation = Mockito.mock(FlutterCallbackInformation::class.java)
    private lateinit var lookup: MockedStatic<FlutterCallbackInformation>
    private lateinit var engines: MockedConstruction<FlutterEngine>
    private val dartExecutors = mutableListOf<DartExecutor>()

    /** What the engine sent to Dart over the reverse channel. */
    private val sentToDart = mutableListOf<MethodCall>()

    /** How Dart answers each `silentCallbackReference` (null = never answers). */
    private var dartAnswer: ((BinaryMessenger.BinaryReply) -> Unit)? = { it.reply(null) }

    @Before fun setUp() {
        FlutterInjector.reset()
        FlutterInjector.setInstance(FlutterInjector.Builder().setFlutterLoader(loader).build())
        Mockito.`when`(loader.findAppBundlePath()).thenReturn("flutter_assets")
        // Initialization completes right away, on the given handler.
        Mockito.doAnswer { invocation ->
            (invocation.getArgument(2) as Handler).post(invocation.getArgument(3) as Runnable)
            null
        }.`when`(loader).ensureInitializationCompleteAsync(any(), Mockito.any(), any(), any())

        lookup = Mockito.mockStatic(FlutterCallbackInformation::class.java)
        lookup.`when`<FlutterCallbackInformation> {
            FlutterCallbackInformation.lookupCallbackInformation(anyLong())
        }.thenReturn(callbackInfo)

        engines = Mockito.mockConstruction(FlutterEngine::class.java) { engine, _ ->
            val dart = Mockito.mock(DartExecutor::class.java)
            Mockito.doAnswer { invocation ->
                val message = invocation.getArgument<ByteBuffer>(1)
                message.rewind()
                sentToDart.add(StandardMethodCodec.INSTANCE.decodeMethodCall(message))
                val reply = invocation.getArgument<BinaryMessenger.BinaryReply?>(2)
                if (reply != null) dartAnswer?.invoke(reply)
                null
            }.`when`(dart).send(anyString(), any(), Mockito.any())
            dartExecutors.add(dart)
            Mockito.`when`(engine.dartExecutor).thenReturn(dart)
        }

        ActionHandles.save(context, ActionHandles.BACKGROUND_HANDLE, 11L)
        ActionHandles.save(context, ActionHandles.ACTION_HANDLE, 22L)
    }

    @After fun tearDown() {
        lookup.close()
        engines.close()
        FlutterInjector.reset()
        ActionHandles.save(context, ActionHandles.BACKGROUND_HANDLE, null)
        ActionHandles.save(context, ActionHandles.ACTION_HANDLE, null)
    }

    private fun idle() = shadowOf(Looper.getMainLooper()).idle()

    /** Dart's background isolate says it is ready. */
    private fun pushNext(): MethodChannel.Result {
        val result = Mockito.mock(MethodChannel.Result::class.java)
        ActionBackgroundExecutor.onMethodCall(MethodCall("pushNext", null), result)
        idle()
        return result
    }

    @Test fun withoutTheAppsHandlesTheActionIsDropped() {
        ActionHandles.save(context, ActionHandles.ACTION_HANDLE, 0L)
        var done = 0
        ActionBackgroundExecutor.execute(context, mapOf("id" to 1)) { done++ }
        idle()
        assertEquals(1, done)
        assertTrue(engines.constructed().isEmpty())

        ActionHandles.save(context, ActionHandles.ACTION_HANDLE, 22L)
        ActionHandles.save(context, ActionHandles.BACKGROUND_HANDLE, null)
        ActionBackgroundExecutor.execute(context, mapOf("id" to 1)) { done++ }
        idle()
        assertEquals(2, done)
        assertTrue(engines.constructed().isEmpty())
    }

    @Test fun anActionRunsInABackgroundEngineThatIsThenDestroyed() {
        var done = 0
        ActionBackgroundExecutor.execute(context, mapOf("id" to 7, "buttonKeyPressed" to "ok")) { done++ }
        idle()

        Mockito.verify(loader).startInitialization(context)
        assertEquals(1, engines.constructed().size)
        val dart = dartExecutors.single()
        val captor = org.mockito.ArgumentCaptor.forClass(DartExecutor.DartCallback::class.java)
        Mockito.verify(dart).executeDartCallback(captor.capture())
        assertEquals("flutter_assets", captor.value.pathToBundle)
        assertSame(callbackInfo, captor.value.callbackHandle)
        lookup.verify { FlutterCallbackInformation.lookupCallbackInformation(11L) }
        Mockito.verify(dart).setMessageHandler(Mockito.eq("awesome_notifications_reverse"), Mockito.notNull())
        assertEquals(0, done) // waits for Dart

        Mockito.verify(pushNext()).success(true)

        val call = sentToDart.single()
        assertEquals("silentCallbackReference", call.method)
        assertEquals(mapOf("id" to 7, "buttonKeyPressed" to "ok", "actionHandle" to 22L), call.arguments)
        assertEquals(1, done)
        // Drained: the engine is torn down.
        Mockito.verify(engines.constructed().single()).destroy()
        Mockito.verify(dart).setMessageHandler("awesome_notifications_reverse", null)
    }

    @Test fun queuedActionsRunOneAfterTheOtherInTheSameEngine() {
        val done = mutableListOf<Int>()
        dartAnswer = { it.reply(StandardMethodCodec.INSTANCE.encodeSuccessEnvelope(true).also { b -> b.rewind() }) }
        ActionBackgroundExecutor.execute(context, mapOf("id" to 1)) { done.add(1) }
        ActionBackgroundExecutor.execute(context, mapOf("id" to 2)) { done.add(2) }
        idle()
        pushNext()
        assertEquals(listOf(1, 2), done)
        assertEquals(1, engines.constructed().size)
        assertEquals(listOf(1, 2), sentToDart.map { (it.arguments as Map<*, *>)["id"] })
    }

    @Test fun aFailedOrUnknownAnswerStillMovesOn() {
        val done = mutableListOf<Int>()
        var replies = 0
        dartAnswer = {
            replies++
            if (replies == 1) it.reply(StandardMethodCodec.INSTANCE.encodeErrorEnvelope("E", "boom", null).also { b -> b.rewind() })
            else it.reply(null) // notImplemented
        }
        ActionBackgroundExecutor.execute(context, mapOf("id" to 1)) { done.add(1) }
        ActionBackgroundExecutor.execute(context, mapOf("id" to 2)) { done.add(2) }
        idle()
        pushNext()
        assertEquals(listOf(1, 2), done)
    }

    /** Dart answers the last action later: [answer] runs it outside the looper. */
    private var pendingReply: BinaryMessenger.BinaryReply? = null

    private fun answer() {
        val reply = pendingReply!!
        pendingReply = null
        reply.reply(null)
    }

    @Test fun anActionArrivingWhileTearingDownStartsANewEngine() {
        dartAnswer = { pendingReply = it }
        val done = mutableListOf<Int>()
        ActionBackgroundExecutor.execute(context, mapOf("id" to 1)) { done.add(1) }
        idle()
        pushNext()
        answer() // the queue is found empty: the teardown is posted
        // Arrives after the queue was found empty, before the teardown ran.
        ActionBackgroundExecutor.execute(context, mapOf("id" to 2)) { done.add(2) }
        idle()
        assertEquals(listOf(1), done)
        assertEquals(2, engines.constructed().size)
        Mockito.verify(engines.constructed()[0]).destroy()

        pushNext()
        answer()
        idle()
        assertEquals(listOf(1, 2), done)
        Mockito.verify(engines.constructed()[1]).destroy()
    }

    @Test fun anActionArrivingWhileTearingDownIsDroppedWithoutAnEntryPoint() {
        dartAnswer = { pendingReply = it }
        val done = mutableListOf<Int>()
        ActionBackgroundExecutor.execute(context, mapOf("id" to 1)) { done.add(1) }
        idle()
        pushNext()
        answer()
        ActionBackgroundExecutor.execute(context, mapOf("id" to 2)) { done.add(2) }
        // The app's entry point is gone before the restart.
        ActionHandles.save(context, ActionHandles.BACKGROUND_HANDLE, null)
        idle()
        assertEquals(listOf(1, 2), done)
        assertEquals(1, engines.constructed().size)

        // Not stuck: with the entry point back, the next action runs.
        ActionHandles.save(context, ActionHandles.BACKGROUND_HANDLE, 11L)
        dartAnswer = { it.reply(null) }
        ActionBackgroundExecutor.execute(context, mapOf("id" to 3)) { done.add(3) }
        idle()
        pushNext()
        assertEquals(listOf(1, 2, 3), done)
    }

    @Test fun anUnknownEntryPointDropsEveryQueuedAction() {
        lookup.`when`<FlutterCallbackInformation> {
            FlutterCallbackInformation.lookupCallbackInformation(anyLong())
        }.thenReturn(null)
        val done = mutableListOf<Int>()
        ActionBackgroundExecutor.execute(context, mapOf("id" to 1)) { done.add(1) }
        ActionBackgroundExecutor.execute(context, mapOf("id" to 2)) { done.add(2) }
        idle()
        assertEquals(listOf(1, 2), done)
        assertTrue(engines.constructed().isEmpty())

        // Not stuck: the next action tries again.
        lookup.`when`<FlutterCallbackInformation> {
            FlutterCallbackInformation.lookupCallbackInformation(anyLong())
        }.thenReturn(callbackInfo)
        ActionBackgroundExecutor.execute(context, mapOf("id" to 3)) { done.add(3) }
        idle()
        pushNext()
        assertEquals(listOf(1, 2, 3), done)
    }

    @Test fun otherReverseChannelMethodsAreNotImplemented() {
        val result = Mockito.mock(MethodChannel.Result::class.java)
        ActionBackgroundExecutor.onMethodCall(MethodCall("somethingElse", null), result)
        Mockito.verify(result).notImplemented()
    }

    @Test fun aPushNextWithNothingQueuedOnlyAnswers() {
        Mockito.verify(pushNext()).success(true)
        assertTrue(sentToDart.isEmpty())
    }
}

/** The Dart handles kept on disk, and the process-start installer. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class ActionHandlesAndInitializerTest {

    private val context: Context = ApplicationProvider.getApplicationContext()

    @Test fun handlesAreKeptAndForgotten() {
        ActionHandles.save(context, ActionHandles.ACTION_HANDLE, 1234567890123L)
        assertEquals(1234567890123L, ActionHandles.get(context, ActionHandles.ACTION_HANDLE))
        ActionHandles.save(context, ActionHandles.ACTION_HANDLE, 0L)
        assertEquals(0L, ActionHandles.get(context, ActionHandles.ACTION_HANDLE))
        ActionHandles.save(context, ActionHandles.ACTION_HANDLE, 5L)
        ActionHandles.save(context, ActionHandles.ACTION_HANDLE, null)
        assertEquals(0L, ActionHandles.get(context, ActionHandles.ACTION_HANDLE))
        // Survives a new read of the preferences.
        ActionHandles.save(context, ActionHandles.BACKGROUND_HANDLE, 9L)
        assertEquals(
            9L,
            context.getSharedPreferences("me.carda.awesome_notifications.handles", Context.MODE_PRIVATE)
                .getLong(ActionHandles.BACKGROUND_HANDLE, 0L)
        )
    }

    @Test fun theInitializerInstallsTheBackgroundExecutorAndAnswersNoData() {
        BackgroundActions.executor = null
        val provider = AwesomeNotificationsInitializer()
        assertTrue(provider.onCreate())
        assertSame(ActionBackgroundExecutor, BackgroundActions.executor)

        val uri = Uri.parse("content://x/y")
        assertNull(provider.query(uri, null, null, null, null))
        assertNull(provider.getType(uri))
        assertNull(provider.insert(uri, null))
        assertEquals(0, provider.delete(uri, null, null))
        assertEquals(0, provider.update(uri, null, null, null))
        assertFalse(BackgroundActions.executor == null)
        BackgroundActions.executor = null
    }
}
