package me.carda.awesome_notifications_calls

import android.app.Activity
import android.app.Application
import android.content.ActivityNotFoundException
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import androidx.test.core.app.ApplicationProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.StandardMethodCodec
import io.flutter.plugin.platform.PlatformViewRegistry
import io.flutter.view.TextureRegistry
import me.carda.android_awn_core.AwesomeMethodHandlerRegistry
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class AwesomeNotificationsCallsPluginTest {

    private val context: Application = ApplicationProvider.getApplicationContext()
    private val harness = CallsHarness(context)
    private val messenger = RecordingMessenger()
    private val plugin = AwesomeNotificationsCallsPlugin()

    /** An activity binding that records its listeners. */
    private class FakeActivityBinding(private val activity: Activity) : ActivityPluginBinding {
        val newIntentListeners = mutableListOf<PluginRegistry.NewIntentListener>()
        val resultListeners = mutableListOf<PluginRegistry.ActivityResultListener>()
        override fun getActivity() = activity
        override fun getLifecycle(): Any = Any()
        override fun addRequestPermissionsResultListener(l: PluginRegistry.RequestPermissionsResultListener) {}
        override fun removeRequestPermissionsResultListener(l: PluginRegistry.RequestPermissionsResultListener) {}
        override fun addActivityResultListener(l: PluginRegistry.ActivityResultListener) { resultListeners.add(l) }
        override fun removeActivityResultListener(l: PluginRegistry.ActivityResultListener) { resultListeners.remove(l) }
        override fun addOnNewIntentListener(l: PluginRegistry.NewIntentListener) { newIntentListeners.add(l) }
        override fun removeOnNewIntentListener(l: PluginRegistry.NewIntentListener) { newIntentListeners.remove(l) }
        override fun addOnUserLeaveHintListener(l: PluginRegistry.UserLeaveHintListener) {}
        override fun removeOnUserLeaveHintListener(l: PluginRegistry.UserLeaveHintListener) {}
        override fun addOnWindowFocusChangedListener(l: PluginRegistry.WindowFocusChangedListener) {}
        override fun removeOnWindowFocusChangedListener(l: PluginRegistry.WindowFocusChangedListener) {}
        override fun addOnSaveStateListener(l: ActivityPluginBinding.OnSaveInstanceStateListener) {}
        override fun removeOnSaveStateListener(l: ActivityPluginBinding.OnSaveInstanceStateListener) {}
    }

    /** An activity whose system pages can't be opened. */
    class NoSettingsActivity : Activity() {
        @Deprecated("Deprecated in Java")
        override fun startActivityForResult(intent: Intent, requestCode: Int) {
            throw ActivityNotFoundException("no settings")
        }
        @Deprecated("Deprecated in Java")
        override fun startActivityForResult(intent: Intent, requestCode: Int, options: Bundle?) {
            throw ActivityNotFoundException("no settings")
        }
    }

    private fun pluginBinding(): FlutterPlugin.FlutterPluginBinding =
        FlutterPlugin.FlutterPluginBinding::class.java.getConstructor(
            android.content.Context::class.java, FlutterEngine::class.java, BinaryMessenger::class.java,
            TextureRegistry::class.java, PlatformViewRegistry::class.java,
            FlutterPlugin.FlutterAssets::class.java, FlutterEngineGroup::class.java
        ).newInstance(context, null, messenger, null, null, null, null)

    private fun activity(intent: Intent? = null): Activity =
        Robolectric.buildActivity(Activity::class.java, intent ?: Intent(context, Activity::class.java)).setup().get()

    private fun callIntent(callId: String) = Intent(context, Activity::class.java).putExtra(CallKeys.EXTRA_CALL_ID, callId)

    private fun showsWhenLocked(activity: Activity) = shadowOf(activity).showWhenLocked
    private fun turnsScreenOn(activity: Activity) = shadowOf(activity).turnScreenOn

    /** Robolectric's NotificationManager answers no to full-screen intents on Android 14. */
    private fun allowed() = CallMethodHandler.canUseFullScreenIntent(context)

    /** Calls a method through the core's handler registry, as the core's channel does. */
    private fun invoke(method: String): Pair<Boolean, MutableList<Any?>> {
        val values = mutableListOf<Any?>()
        val handled = AwesomeMethodHandlerRegistry.handle(method, null, { values.add(it) })
        harness.idle()
        return handled to values
    }

    @Before fun setUp() {
        harness.setUp()
        Calls.streamSink = null
    }

    @After fun tearDown() {
        plugin.onDetachedFromActivity()
        plugin.onDetachedFromEngine(pluginBinding())
        harness.tearDown()
    }

    // MARK: - Engine

    @Test fun attachingRegistersTheCallMethodsAndDetachingRemovesThem() {
        assertFalse(invoke(CallKeys.METHOD_VOIP_TOKEN).first)
        plugin.onAttachedToEngine(pluginBinding())
        assertEquals(true to mutableListOf<Any?>(null), invoke(CallKeys.METHOD_VOIP_TOKEN))
        assertNotNull(messenger.handlers[CallKeys.EVENTS_CHANNEL])

        plugin.onDetachedFromEngine(pluginBinding())
        assertFalse(invoke(CallKeys.METHOD_VOIP_TOKEN).first)
        assertNull(messenger.handlers[CallKeys.EVENTS_CHANNEL])
    }

    @Test fun theEventsStreamCarriesTheCommandsWhileDartListens() {
        plugin.onAttachedToEngine(pluginBinding())
        val handler = messenger.handlers[CallKeys.EVENTS_CHANNEL]!!
        handler.onMessage(StandardMethodCodec.INSTANCE.encodeMethodCall(MethodCall("listen", null)).apply { rewind() }) {}
        val sink = Calls.streamSink
        assertNotNull(sink)

        sink!!(mapOf("kind" to "command", "action" to "accept", "callId" to "c-1"))
        val event = messenger.sent.last { it.first == CallKeys.EVENTS_CHANNEL }.second!!
        event.rewind()
        assertEquals(
            mapOf("kind" to "command", "action" to "accept", "callId" to "c-1"),
            StandardMethodCodec.INSTANCE.decodeEnvelope(event)
        )

        handler.onMessage(StandardMethodCodec.INSTANCE.encodeMethodCall(MethodCall("cancel", null)).apply { rewind() }) {}
        assertNull(Calls.streamSink)
    }

    @Test fun anotherEnginesListenerIsKeptWhenThisOneStops() {
        plugin.onAttachedToEngine(pluginBinding())
        val other: (Map<String, Any?>) -> Unit = {}
        Calls.streamSink = other
        plugin.onCancel(null)
        assertSame(other, Calls.streamSink)
    }

    @Test fun installingTwiceKeepsOneDecorator() {
        AwesomeNotificationsCallsPlugin.install()
        AwesomeNotificationsCallsPlugin.install()
        // One CallBuilder in the chain: a call still posts exactly one notification.
        assertEquals(true, harness.create())
        assertEquals(1, harness.manager().activeNotifications.count { it.id == 300 })
    }

    // MARK: - Lock screen

    @Test fun anActivityOpenedForACallShowsOverTheLockScreenUntilTheCallsEnd() {
        val intent = callIntent("c-1")
        val activity = activity(intent)
        val binding = FakeActivityBinding(activity)
        plugin.onAttachedToActivity(binding)
        assertTrue(showsWhenLocked(activity))
        assertTrue(turnsScreenOn(activity))
        // The call's mark is consumed.
        assertFalse(activity.intent.hasExtra(CallKeys.EXTRA_CALL_ID))
        assertEquals(listOf<Any>(plugin), binding.newIntentListeners)
        assertEquals(listOf<Any>(plugin), binding.resultListeners)

        // A call starts and ends: no live call is left, the activity leaves the lock screen.
        assertEquals(true, harness.create())
        assertTrue(showsWhenLocked(activity))
        Calls.endCall(context, "c-1", EndReason.remoteEnded)
        harness.idle()
        assertFalse(showsWhenLocked(activity))
        assertFalse(turnsScreenOn(activity))

        plugin.onDetachedFromActivity()
        assertTrue(binding.newIntentListeners.isEmpty())
        assertTrue(binding.resultListeners.isEmpty())
        assertNull(Calls.onCallsChanged)
    }

    @Test fun anActivityOpenedNormallyStaysOffTheLockScreen() {
        val activity = activity()
        plugin.onAttachedToActivity(FakeActivityBinding(activity))
        assertFalse(showsWhenLocked(activity))
        // Calls changing with nothing on the lock screen changes nothing.
        Calls.onCallsChanged!!()
        assertFalse(showsWhenLocked(activity))
    }

    @Test fun aNewIntentOfALiveCallShowsOverTheLockScreen() {
        val activity = activity()
        plugin.onAttachedToActivity(FakeActivityBinding(activity))
        assertEquals(true, harness.create())
        // An unknown call while another lasts: ignored (a stale intent).
        assertFalse(plugin.onNewIntent(callIntent("gone")))
        assertFalse(showsWhenLocked(activity))
        assertFalse(plugin.onNewIntent(callIntent("c-1")))
        assertTrue(showsWhenLocked(activity))
        // Already over the lock screen: a second intent changes nothing.
        assertFalse(plugin.onNewIntent(callIntent("c-1")))
        assertTrue(showsWhenLocked(activity))
    }

    @Test fun reattachingAfterAConfigChangeShowsTheCallAgain() {
        val first = activity()
        plugin.onAttachedToActivity(FakeActivityBinding(first))
        plugin.onDetachedFromActivityForConfigChanges()
        val second = activity(callIntent("c-9"))
        plugin.onReattachedToActivityForConfigChanges(FakeActivityBinding(second))
        assertTrue(showsWhenLocked(second))
    }

    @Test fun anIntentWithoutAnActivityChangesNothing() {
        // Not attached to an activity: nothing to show.
        assertFalse(plugin.onNewIntent(callIntent("c-1")))
    }

    @Config(sdk = [26])
    @Test fun beforeAndroid81TheWindowFlagsShowOverTheLockScreen() {
        val activity = activity(callIntent("c-1"))
        plugin.onAttachedToActivity(FakeActivityBinding(activity))
        val flags = WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        assertEquals(flags, activity.window.attributes.flags and flags)
        Calls.onCallsChanged!!()
        assertEquals(0, activity.window.attributes.flags and flags)
    }

    // MARK: - Full-screen intents

    @Test fun requestingWithoutAnActivityAnswersTheCurrentPermission() {
        assertFalse(allowed())
        plugin.onAttachedToEngine(pluginBinding())
        assertEquals(true to mutableListOf<Any?>(false), invoke(CallKeys.METHOD_REQUEST_FULL_SCREEN_INTENT))
    }

    @Test fun requestingOpensTheSystemPageAndAnswersWhenTheUserIsBack() {
        assertFalse(allowed())
        plugin.onAttachedToEngine(pluginBinding())
        val activity = activity()
        plugin.onAttachedToActivity(FakeActivityBinding(activity))

        val (handled, values) = invoke(CallKeys.METHOD_REQUEST_FULL_SCREEN_INTENT)
        assertTrue(handled)
        assertTrue(values.isEmpty()) // waits for the user
        val opened = shadowOf(activity).nextStartedActivityForResult
        assertEquals(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT, opened.intent.action)
        assertEquals("package:" + context.packageName, opened.intent.dataString)

        // Another activity's result is not ours.
        assertFalse(plugin.onActivityResult(1, Activity.RESULT_OK, null))
        assertTrue(values.isEmpty())

        assertTrue(plugin.onActivityResult(opened.requestCode, Activity.RESULT_OK, null))
        assertEquals(listOf<Any?>(false), values)
        // Answered once.
        assertTrue(plugin.onActivityResult(opened.requestCode, Activity.RESULT_OK, null))
        assertEquals(listOf<Any?>(false), values)
    }

    @Test fun aSecondRequestAnswersTheFirstOne() {
        assertFalse(allowed())
        plugin.onAttachedToEngine(pluginBinding())
        plugin.onAttachedToActivity(FakeActivityBinding(activity()))
        val first = invoke(CallKeys.METHOD_REQUEST_FULL_SCREEN_INTENT).second
        val second = invoke(CallKeys.METHOD_REQUEST_FULL_SCREEN_INTENT).second
        assertEquals(listOf<Any?>(false), first)
        assertTrue(second.isEmpty())
    }

    @Test fun leavingTheActivityKeepsAPendingRequestForTheNextOne() {
        assertFalse(allowed())
        plugin.onAttachedToEngine(pluginBinding())
        plugin.onAttachedToActivity(FakeActivityBinding(activity()))
        val first = invoke(CallKeys.METHOD_REQUEST_FULL_SCREEN_INTENT).second
        // The activity is already gone when detach looks for it: nothing is answered yet.
        plugin.onDetachedFromActivity()
        assertTrue(first.isEmpty())
        // Without an activity a result is consumed but answers nothing.
        assertTrue(plugin.onActivityResult(0x0CA11, Activity.RESULT_OK, null))
        assertTrue(first.isEmpty())
        // The next request (with an activity again) answers the pending one.
        plugin.onAttachedToActivity(FakeActivityBinding(activity()))
        invoke(CallKeys.METHOD_REQUEST_FULL_SCREEN_INTENT)
        assertEquals(listOf<Any?>(false), first)
    }

    @Test fun aSystemPageThatCantOpenAnswersTheCurrentPermission() {
        assertFalse(allowed())
        plugin.onAttachedToEngine(pluginBinding())
        val activity = Robolectric.buildActivity(NoSettingsActivity::class.java).setup().get()
        plugin.onAttachedToActivity(FakeActivityBinding(activity))
        assertEquals(true to mutableListOf<Any?>(false), invoke(CallKeys.METHOD_REQUEST_FULL_SCREEN_INTENT))
        // Nothing is left pending.
        plugin.onActivityResult(0x0CA11, Activity.RESULT_OK, null)
    }

    // MARK: - Initializer

    @Test fun theInitializerInstallsTheDecoratorAndServesNothing() {
        val provider = CallInitializer()
        assertTrue(provider.onCreate())
        val uri = android.net.Uri.parse("content://x/y")
        assertNull(provider.query(uri, null, null, null, null))
        assertNull(provider.getType(uri))
        assertNull(provider.insert(uri, null))
        assertEquals(0, provider.delete(uri, null, null))
        assertEquals(0, provider.update(uri, null, null, null))
        // The decorator is in the chain: a call's notification is built by it.
        assertEquals(true, harness.create())
        assertNotNull(Calls.entry("c-1"))
    }
}
