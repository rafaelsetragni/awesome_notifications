package me.carda.awesome_notifications_live_activities

import android.app.Activity
import android.app.Notification
import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.net.Uri
import android.os.Bundle
import android.os.Looper
import android.view.View
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.RemoteViews
import android.widget.TextView
import androidx.test.core.app.ApplicationProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.nio.ByteBuffer
import java.util.concurrent.Executor
import me.carda.android_awn_core.AwesomeMethodHandlerRegistry
import me.carda.android_awn_core.AwesomeNotifications
import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.NotificationBuilderRegistry
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
import org.robolectric.annotation.GraphicsMode

// MARK: - Flutter fakes

/** Records the channel handlers the plugin sets. */
internal class FakeMessenger : BinaryMessenger {
    val handlers = mutableMapOf<String, BinaryMessenger.BinaryMessageHandler?>()
    override fun send(channel: String, message: ByteBuffer?) {}
    override fun send(channel: String, message: ByteBuffer?, callback: BinaryMessenger.BinaryReply?) {}
    override fun setMessageHandler(channel: String, handler: BinaryMessenger.BinaryMessageHandler?) {
        handlers[channel] = handler
    }
}

/** Collects what the plugin sends to Dart. */
internal class FakeSink : EventChannel.EventSink {
    val events = mutableListOf<Any?>()
    override fun success(event: Any?) { events.add(event) }
    override fun error(errorCode: String?, errorMessage: String?, errorDetails: Any?) {}
    override fun endOfStream() {}
}

/** An activity binding that keeps the result listeners it is given. */
internal class FakeActivityBinding(private val activity: Activity) : ActivityPluginBinding {
    val resultListeners = mutableListOf<PluginRegistry.ActivityResultListener>()
    override fun getActivity(): Activity = activity
    override fun getLifecycle(): Any = Unit
    override fun addRequestPermissionsResultListener(listener: PluginRegistry.RequestPermissionsResultListener) {}
    override fun removeRequestPermissionsResultListener(listener: PluginRegistry.RequestPermissionsResultListener) {}
    override fun addActivityResultListener(listener: PluginRegistry.ActivityResultListener) { resultListeners.add(listener) }
    override fun removeActivityResultListener(listener: PluginRegistry.ActivityResultListener) { resultListeners.remove(listener) }
    override fun addOnNewIntentListener(listener: PluginRegistry.NewIntentListener) {}
    override fun removeOnNewIntentListener(listener: PluginRegistry.NewIntentListener) {}
    override fun addOnUserLeaveHintListener(listener: PluginRegistry.UserLeaveHintListener) {}
    override fun removeOnUserLeaveHintListener(listener: PluginRegistry.UserLeaveHintListener) {}
    override fun addOnWindowFocusChangedListener(listener: PluginRegistry.WindowFocusChangedListener) {}
    override fun removeOnWindowFocusChangedListener(listener: PluginRegistry.WindowFocusChangedListener) {}
    override fun addOnSaveStateListener(listener: ActivityPluginBinding.OnSaveInstanceStateListener) {}
    override fun removeOnSaveStateListener(listener: ActivityPluginBinding.OnSaveInstanceStateListener) {}
}

/** An activity whose settings screen can't be opened. */
class NoSettingsActivity : Activity() {
    @Deprecated("Deprecated in Java")
    override fun startActivityForResult(intent: Intent, requestCode: Int, options: Bundle?) {
        throw ActivityNotFoundException("no settings")
    }
}

/** A binding with the application context and [messenger] (built reflectively:
 *  the rest are engine objects the plugin never touches). */
internal fun pluginBinding(context: Context, messenger: BinaryMessenger): FlutterPlugin.FlutterPluginBinding {
    val constructor = FlutterPlugin.FlutterPluginBinding::class.java.declaredConstructors
        .first { it.parameterTypes.firstOrNull() == Context::class.java }
    constructor.isAccessible = true
    val args = constructor.parameterTypes.map {
        when (it) {
            Context::class.java -> context
            BinaryMessenger::class.java -> messenger
            else -> null
        }
    }
    return constructor.newInstance(*args.toTypedArray()) as FlutterPlugin.FlutterPluginBinding
}

/** A small PNG on disk, for the `file://` image sources. */
internal fun pngSource(context: Context, name: String, width: Int = 8, height: Int = 8, color: Int = Color.RED): String {
    val file = File(context.cacheDir, "$name.png")
    file.outputStream().use {
        Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            .apply { eraseColor(color) }
            .compress(Bitmap.CompressFormat.PNG, 100, it)
    }
    return "file://" + file.absolutePath
}

// MARK: - The plugin

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class LivePluginTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val REQUEST_PROMOTION = 0x0A11
    private val SETTINGS = "android.settings.APP_NOTIFICATION_PROMOTION_SETTINGS"

    @Before fun setUp() = LiveActivities.resetForTest(context)
    @After fun tearDown() = LiveActivities.resetForTest(context)

    private fun answer(method: String, arguments: Any? = null): Pair<Boolean, Any?> {
        var value: Any? = "unanswered"
        val handled = AwesomeMethodHandlerRegistry.handle(method, arguments, { value = it })
        shadowOf(Looper.getMainLooper()).idle()
        return handled to value
    }

    private fun attached(): Triple<AwesomeNotificationsLiveActivitiesPlugin, FakeMessenger, FlutterPlugin.FlutterPluginBinding> {
        val messenger = FakeMessenger()
        val plugin = AwesomeNotificationsLiveActivitiesPlugin()
        val binding = pluginBinding(context, messenger)
        plugin.onAttachedToEngine(binding)
        return Triple(plugin, messenger, binding)
    }

    @Test fun attachingAnswersTheMethodsAndOpensTheEventsChannel() {
        val (plugin, messenger, binding) = attached()
        assertTrue(NotificationBuilderRegistry.makeBuilder() is LiveBuilder)
        assertNotNull(messenger.handlers[LiveKeys.EVENTS_CHANNEL])
        assertEquals(true to emptyList<Any?>(), answer(LiveKeys.METHOD_LIST))

        plugin.onDetachedFromEngine(binding)
        assertTrue(messenger.handlers.containsKey(LiveKeys.EVENTS_CHANNEL))
        assertNull(messenger.handlers[LiveKeys.EVENTS_CHANNEL])
        assertFalse(answer(LiveKeys.METHOD_LIST).first)
    }

    @Test fun whileDartListensTheStateChangesGoToItsSink() {
        val plugin = AwesomeNotificationsLiveActivitiesPlugin()
        val sink = FakeSink()
        plugin.onListen(null, sink)
        LiveActivities.streamSink!!(mapOf("activityId" to "a"))
        assertEquals(listOf(mapOf("activityId" to "a")), sink.events)
        plugin.onCancel(null)
        assertNull(LiveActivities.streamSink)
    }

    @Test fun anotherEnginesListenerIsKeptWhenThisOneStops() {
        val mine = AwesomeNotificationsLiveActivitiesPlugin()
        val other = AwesomeNotificationsLiveActivitiesPlugin()
        mine.onListen(null, FakeSink())
        other.onListen(null, FakeSink())
        val othersSink = LiveActivities.streamSink
        mine.onCancel(null)
        assertSame(othersSink, LiveActivities.streamSink)
    }

    @Test fun beforeAndroid16ThePermissionIsAnsweredAtOnce() {
        val (plugin, _, binding) = attached()
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        plugin.onAttachedToActivity(FakeActivityBinding(activity))
        assertEquals(true to true, answer(LiveKeys.METHOD_REQUEST_PERMISSION))
        assertNull(shadowOf(activity).nextStartedActivityForResult)
        plugin.onDetachedFromActivity()
        plugin.onDetachedFromEngine(binding)
    }

    @Test fun anotherRequestCodeIsNotThePlugins() {
        val plugin = AwesomeNotificationsLiveActivitiesPlugin()
        assertFalse(plugin.onActivityResult(1, Activity.RESULT_OK, null))
        // Its own code, without an activity: consumed, nothing to answer.
        assertTrue(plugin.onActivityResult(REQUEST_PROMOTION, Activity.RESULT_OK, null))
    }

    @Config(sdk = [36])
    @Test fun onAndroid16ThePermissionOpensTheLiveNotificationsSettings() {
        val (plugin, _, binding) = attached()
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        val activityBinding = FakeActivityBinding(activity)
        plugin.onAttachedToActivity(activityBinding)
        assertEquals(listOf(plugin), activityBinding.resultListeners)
        val enabled = LiveMethodHandler.areEnabled(context)
        assertFalse(enabled) // Robolectric's user hasn't allowed them.

        var answered: Any? = "unanswered"
        assertTrue(AwesomeMethodHandlerRegistry.handle(LiveKeys.METHOD_REQUEST_PERMISSION, null, { answered = it }))
        assertEquals("unanswered", answered) // waits for the user

        val started = shadowOf(activity).nextStartedActivityForResult
        assertEquals(REQUEST_PROMOTION, started.requestCode)
        assertEquals(SETTINGS, started.intent.action)
        assertEquals(context.packageName, started.intent.getStringExtra("android.provider.extra.APP_PACKAGE"))
        assertEquals(Uri.fromParts("package", context.packageName, null), started.intent.data)

        // The user is back.
        assertTrue(plugin.onActivityResult(REQUEST_PROMOTION, Activity.RESULT_CANCELED, null))
        assertEquals(enabled, answered)

        // A second result has nobody waiting.
        answered = "unanswered"
        assertTrue(plugin.onActivityResult(REQUEST_PROMOTION, Activity.RESULT_CANCELED, null))
        assertEquals("unanswered", answered)

        plugin.onDetachedFromActivity()
        assertTrue(activityBinding.resultListeners.isEmpty())
        plugin.onDetachedFromEngine(binding)
    }

    @Config(sdk = [36])
    @Test fun onAndroid16ANewRequestAnswersThePreviousOneAndLeavingTheActivityAnswersTheLast() {
        val (plugin, _, binding) = attached()
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        plugin.onAttachedToActivity(FakeActivityBinding(activity))
        val answers = mutableListOf<Any?>()
        AwesomeMethodHandlerRegistry.handle(LiveKeys.METHOD_REQUEST_PERMISSION, null, { answers.add("first:$it") })
        AwesomeMethodHandlerRegistry.handle(LiveKeys.METHOD_REQUEST_PERMISSION, null, { answers.add("second:$it") })
        assertEquals(listOf<Any?>("first:false"), answers)

        // A configuration change: the activity goes, the request is answered.
        plugin.onDetachedFromActivityForConfigChanges()
        assertEquals(listOf<Any?>("first:false", "second:false"), answers)
        plugin.onReattachedToActivityForConfigChanges(FakeActivityBinding(activity))
        plugin.onDetachedFromActivity()
        assertEquals(2, answers.size)
        plugin.onDetachedFromEngine(binding)
    }

    @Config(sdk = [36])
    @Test fun onAndroid16WithoutAnActivityTheCurrentStateIsTheAnswer() {
        val (plugin, _, binding) = attached()
        assertEquals(true to false, answer(LiveKeys.METHOD_REQUEST_PERMISSION))
        plugin.onDetachedFromEngine(binding)
    }

    @Config(sdk = [36])
    @Test fun onAndroid16SettingsThatCantOpenAnswerTheCurrentState() {
        val (plugin, _, binding) = attached()
        val activity = Robolectric.buildActivity(NoSettingsActivity::class.java).setup().get()
        plugin.onAttachedToActivity(FakeActivityBinding(activity))
        assertEquals(true to false, answer(LiveKeys.METHOD_REQUEST_PERMISSION))
        // Nothing left waiting: leaving the activity answers nobody again.
        var answers = 0
        AwesomeMethodHandlerRegistry.handle(LiveKeys.METHOD_ARE_ENABLED, null, { answers++ })
        plugin.onDetachedFromActivity()
        assertEquals(1, answers)
        plugin.onDetachedFromEngine(binding)
    }

    @Config(sdk = [36])
    @Test fun onAndroid16TheMethodsAnswerTheUsersSwitch() {
        val handler = LiveMethodHandler(context) { it(false) }
        var value: Any? = null
        assertTrue(handler.handle(LiveKeys.METHOD_ARE_ENABLED, null) { value = it })
        assertEquals(false, value)
    }

    @Test fun theInitializerInstallsTheDecoratorAndIsAnInertProvider() {
        val provider = LiveInitializer()
        assertTrue(provider.onCreate())
        assertTrue(NotificationBuilderRegistry.makeBuilder() is LiveBuilder)
        val uri = Uri.parse("content://live")
        assertNull(provider.query(uri, null, null, null, null))
        assertNull(provider.getType(uri))
        assertNull(provider.insert(uri, ContentValues()))
        assertEquals(0, provider.delete(uri, null, null))
        assertEquals(0, provider.update(uri, ContentValues(), null, null))
    }
}

// MARK: - Layouts, images and the rest of the model

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class LiveLayoutsTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val direct = Executor { it.run() }
    private val core = AwesomeNotifications(context, direct)
    private val now = 1_800_000_000_000L
    private val streamed = mutableListOf<Map<String, Any?>>()

    private fun manager() = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    @Before fun setUp() {
        AwesomeNotificationsLiveActivitiesPlugin.install()
        LiveActivities.resetForTest(context)
        LiveActivities.executor = direct
        LiveActivities.clock = { now }
        LiveActivities.streamSink = { streamed.add(it) }
        manager().cancelAll()
        core.setChannel(
            mapOf(Definitions.NOTIFICATION_CHANNEL_KEY to "live", Definitions.NOTIFICATION_CHANNEL_NAME to "Live")
        )
    }

    @After fun tearDown() = LiveActivities.resetForTest(context)

    private fun create(live: Map<String, Any?>, id: Int = 400, content: Map<String, Any?> = emptyMap()): Any? {
        val c = mutableMapOf<String, Any?>(
            Definitions.NOTIFICATION_ID to id,
            Definitions.NOTIFICATION_CHANNEL_KEY to "live",
            Definitions.NOTIFICATION_TITLE to "Your order",
            Definitions.NOTIFICATION_BODY to "On the way"
        )
        c.putAll(content)
        var result: Any? = null
        core.createNotification(
            mapOf(Definitions.NOTIFICATION_CONTENT to c, LiveKeys.LIVE_ACTIVITY to live),
            onError = { _, message, _ -> result = message }
        ) { result = it }
        shadowOf(Looper.getMainLooper()).idle()
        return result
    }

    private fun shown(id: Int = 400): Notification = shadowOf(manager()).getNotification(null, id)!!

    private fun inflate(views: RemoteViews): View = views.apply(context, FrameLayout(context))

    private fun visible(root: View, id: Int) = root.findViewById<View>(id)?.visibility == View.VISIBLE

    private fun textOf(root: View, id: Int): String? =
        root.findViewById<TextView>(id)?.takeIf { it.visibility == View.VISIBLE }?.text?.toString()

    private fun metric(label: String, value: String, image: String? = null) =
        mutableMapOf<String, Any?>(LiveKeys.LABEL to label, LiveKeys.VALUE to value).apply { image?.let { this[LiveKeys.IMAGE] = it } }

    private fun model(block: Map<String, Any?>) = LiveActivityModel.parse(block, 1).first!!

    @GraphicsMode(GraphicsMode.Mode.NATIVE) // a missing file decodes to nothing
    @Test fun theExpandedLayoutShowsTheLargeIcon() {
        assertEquals(true, create(
            mapOf(LiveKeys.STATE to "active"),
            content = mapOf(Definitions.NOTIFICATION_LARGE_ICON to pngSource(context, "large"))
        ))
        val expanded = inflate(shown().bigContentView)
        assertTrue(visible(expanded, R.id.awn_live_image))
        assertNotNull((expanded.findViewById<ImageView>(R.id.awn_live_image)).drawable)
        // An image that can't load leaves it hidden.
        create(mapOf(LiveKeys.STATE to "active"), id = 401,
            content = mapOf(Definitions.NOTIFICATION_LARGE_ICON to "file:///no/such/image.png"))
        assertFalse(visible(inflate(shown(401).bigContentView), R.id.awn_live_image))
    }

    @Test fun aCustomLayoutGetsTheAccentTheBarTheImagesAndTheClock() {
        val (collapsed, expanded) = LiveCustomLayout.views(
            context,
            model(mapOf(
                LiveKeys.CUSTOM_LAYOUT to "awn_live_expanded",
                LiveKeys.ACCENT_COLOR to 0xFF2196F3.toInt(),
                LiveKeys.SHORT_TEXT to "12 min",
                LiveKeys.TIMER to mapOf(LiveKeys.END to System.currentTimeMillis() + 600_000),
                LiveKeys.METRICS to listOf(metric("Speed", "42", pngSource(context, "speed")))
            )),
            mapOf(Definitions.NOTIFICATION_TITLE to "Title", Definitions.NOTIFICATION_LARGE_ICON to pngSource(context, "large")),
            50.0,
            hasBar = true
        )
        for (views in listOf(inflate(collapsed), inflate(expanded))) {
            assertEquals("Title", textOf(views, R.id.awn_live_title))
            assertNull(textOf(views, R.id.awn_live_body)) // no body: hidden
            assertEquals("12 min", textOf(views, R.id.awn_live_short))
            assertEquals(0xFF2196F3.toInt(), views.findViewById<TextView>(R.id.awn_live_short).currentTextColor)
            assertTrue(visible(views, R.id.awn_live_bar))
            assertTrue(visible(views, R.id.awn_live_image))
            assertEquals("42", textOf(views, R.id.awn_live_metric_value_0))
        }
    }

    @Test fun aCustomLayoutWithAnExpandedVariantUsesItExpanded() {
        // Without a `<name>_expanded` layout, the same layout is used expanded.
        assertEquals(0, LiveCustomLayout.layoutId(context, "awn_live"))
        assertTrue(LiveCustomLayout.layoutId(context, "awn_live_expanded") != 0)
        val (collapsed, expanded) = LiveCustomLayout.views(
            context, model(mapOf(LiveKeys.CUSTOM_LAYOUT to "awn_live_collapsed")),
            mapOf(Definitions.NOTIFICATION_TITLE to "Title"), null, hasBar = false
        )
        assertEquals(R.layout.awn_live_collapsed, collapsed.layoutId)
        assertEquals(R.layout.awn_live_collapsed, expanded.layoutId)
    }

    @Test fun aVersusScoreboardShowsTheLogosAndTheLatestPlaysPicture() {
        val (collapsed, expanded) = LiveCustomLayout.views(
            context,
            model(mapOf(
                LiveKeys.LAYOUT to LiveKeys.LAYOUT_VERSUS,
                LiveKeys.METRICS to listOf(metric("LIO", "1", pngSource(context, "lio")), metric("EAG", "0"))
            )),
            mapOf(Definitions.NOTIFICATION_BODY to "Goal!", Definitions.NOTIFICATION_LARGE_ICON to pngSource(context, "player", 10, 6)),
            null, hasBar = false
        )
        for (views in listOf(inflate(collapsed), inflate(expanded))) {
            assertTrue(visible(views, R.id.awn_vs_logo_0))
            assertFalse(visible(views, R.id.awn_vs_logo_1))
            assertNull(textOf(views, R.id.awn_vs_short))
        }
        val big = inflate(expanded)
        assertTrue(visible(big, R.id.awn_vs_play_image))
        assertEquals("Goal!", textOf(big, R.id.awn_vs_body))
    }

    @GraphicsMode(GraphicsMode.Mode.NATIVE)
    @Test fun thePointsAreSolidOnceReachedAndLighterBefore() {
        val live = model(mapOf(LiveKeys.PROGRESS to mapOf(LiveKeys.POINTS to listOf(
            mapOf(LiveKeys.POSITION to 25, LiveKeys.COLOR to 0xFFFF0000.toInt()),
            mapOf(LiveKeys.POSITION to 75, LiveKeys.COLOR to 0xFF0000FF.toInt())
        ))))
        val bar = LiveCustomLayout.bar(live, 50.0, 1f, 16f)
        // 320 px wide, points 12 px: x = 6 + 308 * position / 100.
        assertEquals(0xFFFF0000.toInt(), bar.getPixel(83, 8))
        assertEquals(Color.rgb(127, 127, 255), bar.getPixel(237, 8))
    }

    @GraphicsMode(GraphicsMode.Mode.NATIVE)
    @Test fun theCircleIsTheCenteredSquareCroppedRound() {
        val source = Bitmap.createBitmap(40, 24, Bitmap.Config.ARGB_8888).apply { eraseColor(Color.GREEN) }
        val circle = LiveCustomLayout.circle(source)
        assertEquals(24, circle.width)
        assertEquals(24, circle.height)
        assertEquals(Color.GREEN, circle.getPixel(12, 12))
        assertEquals(0, Color.alpha(circle.getPixel(0, 0)))
    }

    @Test fun dismissingTheGroupEndsItsActivities() {
        create(mapOf(LiveKeys.ACTIVITY_ID to "a"), id = 1, content = mapOf(Definitions.NOTIFICATION_GROUP_KEY to "g"))
        create(mapOf(LiveKeys.ACTIVITY_ID to "b"), id = 2)
        core.dismissByGroupKey("g")
        shadowOf(Looper.getMainLooper()).idle()
        assertEquals(listOf(mapOf(LiveKeys.ACTIVITY_ID to "a", LiveKeys.STATE to LiveKeys.STATUS_DISMISSED)),
            streamed.map { mapOf(LiveKeys.ACTIVITY_ID to it[LiveKeys.ACTIVITY_ID], LiveKeys.STATE to it[LiveKeys.STATE]) })
        assertEquals(listOf("b"), LiveActivities.list(context).map { it[LiveKeys.ACTIVITY_ID] })
    }

    @Test fun anUnreadableSavedActivityIsSkipped() {
        create(mapOf(LiveKeys.ACTIVITY_ID to "a"))
        context.getSharedPreferences("awesome_notifications_live_activities", Context.MODE_PRIVATE).edit()
            .putString("broken", "{not json")
            .putString("partial", "{\"ended\":false}")
            .putInt("number", 1)
            .commit()
        LiveActivities.forgetMemoryForTest()
        assertEquals(listOf("a"), LiveActivities.list(context).map { it[LiveKeys.ACTIVITY_ID] })
    }

    @Test fun theListMethodAnswersTheActivities() {
        create(mapOf(LiveKeys.ACTIVITY_ID to "a"))
        var value: Any? = null
        assertTrue(LiveMethodHandler(context) { it(false) }.handle(LiveKeys.METHOD_LIST, null) { value = it })
        assertEquals(listOf(mapOf(LiveKeys.ACTIVITY_ID to "a", LiveKeys.STATE to "active")), value)
    }

    @Test fun theLessCommonModelShapes() {
        fun error(block: Map<String, Any?>) = LiveActivityModel.parse(block, 1).second
        assertEquals("The live activity metrics must be a list", error(mapOf(LiveKeys.METRICS to 5)))
        assertEquals("The live activity metrics must be a list", error(mapOf(LiveKeys.METRICS to "[not json")))
        assertEquals("The live activity segments and points must be lists",
            error(mapOf(LiveKeys.PROGRESS to mapOf(LiveKeys.SEGMENTS to 5))))
        assertEquals("The live activity progress must be a map", error(mapOf(LiveKeys.PROGRESS to "{not json")))
        assertEquals("Unknown live activity dismissal: true", error(mapOf(LiveKeys.DISMISSAL to true)))

        // A push's metrics, as a JSON text.
        val pushed = model(mapOf(LiveKeys.METRICS to "[{\"label\":\"Speed\",\"value\":\"42\"}]"))
        assertEquals(listOf("Speed 42"), pushed.metrics.map { it.text })

        assertTrue(LiveTimer(null, 10L).countDown)
        assertFalse(LiveTimer(0L, null).countDown)
    }
}

// MARK: - Android 16: the system's Live Update

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36])
class LiveUpdatesTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val direct = Executor { it.run() }
    private val core = AwesomeNotifications(context, direct)

    private fun manager() = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    @Before fun setUp() {
        AwesomeNotificationsLiveActivitiesPlugin.install()
        LiveActivities.resetForTest(context)
        LiveActivities.executor = direct
        manager().cancelAll()
        core.setChannel(
            mapOf(Definitions.NOTIFICATION_CHANNEL_KEY to "live", Definitions.NOTIFICATION_CHANNEL_NAME to "Live")
        )
    }

    @After fun tearDown() = LiveActivities.resetForTest(context)

    private fun create(live: Map<String, Any?>, content: Map<String, Any?> = emptyMap()): Notification {
        val c = mutableMapOf<String, Any?>(
            Definitions.NOTIFICATION_ID to 400,
            Definitions.NOTIFICATION_CHANNEL_KEY to "live",
            Definitions.NOTIFICATION_TITLE to "Match",
            Definitions.NOTIFICATION_BODY to "Goal!"
        )
        c.putAll(content)
        var created: Any? = null
        core.createNotification(
            mapOf(Definitions.NOTIFICATION_CONTENT to c, LiveKeys.LIVE_ACTIVITY to live),
            onError = { _, message, _ -> created = message }
        ) { created = it }
        shadowOf(Looper.getMainLooper()).idle()
        assertEquals(true, created)
        return shadowOf(manager()).getNotification(null, 400)!!
    }

    @Test fun aVersusScoreGoesBeforeTheBody() {
        val n = create(mapOf(
            LiveKeys.LAYOUT to LiveKeys.LAYOUT_VERSUS,
            LiveKeys.METRICS to listOf(
                mapOf(LiveKeys.LABEL to "LIO", LiveKeys.VALUE to "1"),
                mapOf(LiveKeys.LABEL to "EAG", LiveKeys.VALUE to "0")
            )
        ))
        val text = n.extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
            ?: n.extras.getCharSequence(Notification.EXTRA_TEXT).toString()
        assertTrue(text, text.startsWith("LIO 1 – 0 EAG"))
        assertTrue(text, text.endsWith("\nGoal!"))
    }

    @Suppress("DEPRECATION")
    private fun icon(n: Notification, key: String): android.graphics.drawable.Icon? = n.extras.getParcelable(key)

    @Test fun withoutAValueTheBarIsIndeterminateAndTheIconsAreSet() {
        val n = create(mapOf(LiveKeys.PROGRESS to mapOf(
            LiveKeys.TRACKER_ICON to pngSource(context, "tracker"),
            LiveKeys.START_ICON to "resource://drawable/awn_live_card",
            LiveKeys.END_ICON to "resource://drawable/no_such_drawable"
        )))
        assertTrue(n.extras.getBoolean(Notification.EXTRA_PROGRESS_INDETERMINATE))
        assertNotNull(icon(n, "android.progressTrackerIcon"))
        val start = icon(n, "android.progressStartIcon")!!
        assertEquals(R.drawable.awn_live_card, start.resId)
        // A resource the app doesn't have (and no image either): no icon.
        assertNull(icon(n, "android.progressEndIcon"))
    }
}
