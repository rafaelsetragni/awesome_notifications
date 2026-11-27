package me.carda.awesome_notifications_media

import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Looper
import android.support.v4.media.session.PlaybackStateCompat
import androidx.test.core.app.ApplicationProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import java.nio.ByteBuffer
import java.util.concurrent.Executor
import me.carda.android_awn_core.AwesomeEventListener
import me.carda.android_awn_core.AwesomeEventsReceiver
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
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

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

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class MediaPluginTest {

    private val context: Context = ApplicationProvider.getApplicationContext()

    @After fun tearDown() {
        MediaSessions.streamSink = null
    }

    private fun answer(method: String, arguments: Any? = null): Pair<Boolean, Any?> {
        var value: Any? = null
        val handled = AwesomeMethodHandlerRegistry.handle(method, arguments, { value = it })
        return handled to value
    }

    @Test fun attachingAnswersTheMethodsAndOpensTheCommandsChannel() {
        val messenger = FakeMessenger()
        val plugin = AwesomeNotificationsMediaPlugin()
        val binding = pluginBinding(context, messenger)
        plugin.onAttachedToEngine(binding)

        assertTrue(NotificationBuilderRegistry.makeBuilder() is MediaBuilder)
        assertNotNull(messenger.handlers[MediaKeys.COMMANDS_CHANNEL])
        assertTrue(answer(MediaKeys.METHOD_CAPABILITIES).first)

        plugin.onDetachedFromEngine(binding)
        assertTrue(messenger.handlers.containsKey(MediaKeys.COMMANDS_CHANNEL))
        assertNull(messenger.handlers[MediaKeys.COMMANDS_CHANNEL])
        assertFalse(answer(MediaKeys.METHOD_CAPABILITIES).first)
    }

    @Test fun whileDartListensTheCommandsGoToItsSink() {
        val plugin = AwesomeNotificationsMediaPlugin()
        val sink = FakeSink()
        plugin.onListen(null, sink)
        val stream = MediaSessions.streamSink!!
        stream(mapOf("control" to "play"))
        assertEquals(listOf(mapOf("control" to "play")), sink.events)

        plugin.onCancel(null)
        assertNull(MediaSessions.streamSink)
    }

    @Test fun anotherEnginesListenerIsKeptWhenThisOneStops() {
        val mine = AwesomeNotificationsMediaPlugin()
        val other = AwesomeNotificationsMediaPlugin()
        mine.onListen(null, FakeSink())
        other.onListen(null, FakeSink())
        val othersSink = MediaSessions.streamSink
        mine.onCancel(null)
        assertSame(othersSink, MediaSessions.streamSink)
        other.onDetachedFromEngine(pluginBinding(context, FakeMessenger()))
        assertNull(MediaSessions.streamSink)
    }

    @Test fun theInitializerInstallsTheDecoratorAndIsAnInertProvider() {
        val provider = MediaInitializer()
        assertTrue(provider.onCreate())
        assertTrue(NotificationBuilderRegistry.makeBuilder() is MediaBuilder)
        val uri = Uri.parse("content://media")
        assertNull(provider.query(uri, null, null, null, null))
        assertNull(provider.getType(uri))
        assertNull(provider.insert(uri, ContentValues()))
        assertEquals(0, provider.delete(uri, null, null))
        assertEquals(0, provider.update(uri, ContentValues(), null, null))
    }
}

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class MediaSessionsTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val core = AwesomeNotifications(context, Executor { it.run() })
    private val handler = MediaMethodHandler(context)

    private val pressed = mutableListOf<Any?>()
    private val listener = object : AwesomeEventListener {
        override fun onNewAwesomeEvent(eventType: String, content: Map<String, Any?>) {
            if (eventType == Definitions.EVENT_DEFAULT_ACTION) pressed.add(content[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED])
        }
    }

    @Before fun setUp() {
        AwesomeNotificationsMediaPlugin.install()
        MediaSessions.clearForTest()
        core.setChannel(
            mapOf(Definitions.NOTIFICATION_CHANNEL_KEY to "media", Definitions.NOTIFICATION_CHANNEL_NAME to "Media")
        )
        AwesomeEventsReceiver.subscribe(listener)
    }

    @After fun tearDown() {
        AwesomeEventsReceiver.unsubscribe(listener)
    }

    private fun media(state: String = "playing", skipInterval: Long = 15_000, controls: List<String> = emptyList()) =
        mapOf(
            "sessionId" to "player", "title" to "Song", "state" to state,
            "controls" to controls, "skipInterval" to skipInterval
        )

    private fun model(map: Map<String, Any?>) = MediaModel.parse(map).first!!

    @Test fun everyStateHasItsPlaybackState() {
        val expected = mapOf(
            "stopped" to PlaybackStateCompat.STATE_STOPPED,
            "paused" to PlaybackStateCompat.STATE_PAUSED,
            "playing" to PlaybackStateCompat.STATE_PLAYING,
            "forwarding" to PlaybackStateCompat.STATE_FAST_FORWARDING,
            "rewinding" to PlaybackStateCompat.STATE_REWINDING,
            "buffering" to PlaybackStateCompat.STATE_BUFFERING,
            "error" to PlaybackStateCompat.STATE_ERROR,
            "connecting" to PlaybackStateCompat.STATE_CONNECTING,
            "previous" to PlaybackStateCompat.STATE_SKIPPING_TO_PREVIOUS,
            "next" to PlaybackStateCompat.STATE_SKIPPING_TO_NEXT,
            "skippingToQueueItem" to PlaybackStateCompat.STATE_SKIPPING_TO_QUEUE_ITEM,
            "none" to PlaybackStateCompat.STATE_NONE,
            "unknown" to PlaybackStateCompat.STATE_NONE
        )
        for ((state, playback) in expected) assertEquals(state, playback, model(media(state)).playbackState)
        // Missing state: unknown, and a stopped speed.
        val noState = model(mapOf("sessionId" to "p", "title" to "t"))
        assertEquals(PlaybackStateCompat.STATE_NONE, noState.playbackState)
        assertEquals(0f, noState.speed)
    }

    @Test fun everyControlHasItsIconAndLabel() {
        val media = model(media(skipInterval = 15_000))
        val expected = mapOf(
            MediaControl.play to (R.drawable.awn_media_ic_play to "Play"),
            MediaControl.pause to (R.drawable.awn_media_ic_pause to "Pause"),
            MediaControl.stop to (R.drawable.awn_media_ic_stop to "Stop"),
            MediaControl.skipNext to (R.drawable.awn_media_ic_skip_next to "Next"),
            MediaControl.skipPrevious to (R.drawable.awn_media_ic_skip_previous to "Previous"),
            MediaControl.fastForward to (R.drawable.awn_media_ic_fast_forward to "Fast forward"),
            MediaControl.rewind to (R.drawable.awn_media_ic_rewind to "Rewind"),
            MediaControl.seekTo to (R.drawable.awn_media_ic_play to "Seek"),
            MediaControl.skipForward to (R.drawable.awn_media_ic_forward_15 to "Forward 15 s"),
            MediaControl.skipBackward to (R.drawable.awn_media_ic_replay_15 to "Back 15 s")
        )
        for ((control, pair) in expected) {
            assertEquals(control.name, pair.first, MediaSessions.icon(control, media))
            assertEquals(control.name, pair.second, MediaSessions.label(control, media))
        }
    }

    @Test fun theSkipIconsFollowTheInterval() {
        val icons = mapOf(
            5_000L to (R.drawable.awn_media_ic_forward_5 to R.drawable.awn_media_ic_replay_5),
            10_000L to (R.drawable.awn_media_ic_forward_10 to R.drawable.awn_media_ic_replay_10),
            30_000L to (R.drawable.awn_media_ic_forward_30 to R.drawable.awn_media_ic_replay_30),
            // Not a numbered icon: the generic ones.
            20_000L to (R.drawable.awn_media_ic_forward to R.drawable.awn_media_ic_replay),
            5_500L to (R.drawable.awn_media_ic_forward to R.drawable.awn_media_ic_replay)
        )
        for ((interval, pair) in icons) {
            val media = model(media(skipInterval = interval))
            assertEquals(pair.first, MediaSessions.icon(MediaControl.skipForward, media))
            assertEquals(pair.second, MediaSessions.icon(MediaControl.skipBackward, media))
        }
        assertEquals("Back 5.5 s", MediaSessions.label(MediaControl.skipBackward, model(media(skipInterval = 5_500))))
    }

    @Test fun theOtherSessionCommandsAreActionEvents() {
        val content = mapOf<String, Any?>(
            Definitions.NOTIFICATION_ID to 1,
            Definitions.NOTIFICATION_CHANNEL_KEY to "media",
            Definitions.NOTIFICATION_LAYOUT to "MediaPlayer"
        )
        var created: Boolean? = null
        core.createNotification(
            mapOf(Definitions.NOTIFICATION_CONTENT to content,
                MediaKeys.MEDIA to media(controls = listOf("stop", "skipPrevious", "fastForward", "rewind"))),
            onError = { _, _, _ -> created = false }
        ) { created = it }
        shadowOf(Looper.getMainLooper()).idle()
        assertEquals(true, created)

        val callback = MediaSessions.entry("player")!!.callback
        callback.onStop()
        callback.onSkipToPrevious()
        callback.onFastForward()
        callback.onRewind()
        callback.onCustomAction(null, null) // nothing
        shadowOf(Looper.getMainLooper()).idle()
        assertEquals(
            listOf("awn.media.stop", "awn.media.skipPrevious", "awn.media.fastForward", "awn.media.rewind"),
            pressed
        )
    }

    @Test fun aCommandOfAnUnknownSessionIsIgnored() {
        MediaSessions.command(context, "nobody", MediaControl.play)
        shadowOf(Looper.getMainLooper()).idle()
        assertTrue(pressed.isEmpty())
        assertFalse(MediaSessions.updatePosition("nobody", 1_000))
    }

    @Test fun updatePositionValidatesItsArguments() {
        for (args in listOf(
            null,
            mapOf("position" to 1_000),
            mapOf("sessionId" to " ", "position" to 1_000),
            mapOf("sessionId" to "player"),
            mapOf("sessionId" to "player", "position" to -1)
        )) {
            var error: Triple<String, String?, Any?>? = null
            var answered = false
            assertTrue(handler.handle(MediaKeys.METHOD_UPDATE_POSITION, args, { answered = true }) { c, m, d ->
                error = Triple(c, m, d)
            })
            assertFalse(answered)
            assertEquals(
                Triple("INVALID_ARGUMENTS", "mediaUpdatePosition needs a sessionId and a position",
                    "arguments.invalid.mediaUpdatePosition"),
                error
            )
        }
        // Without an error callback the failure answers null.
        var value: Any? = "unset"
        assertTrue(handler.handle(MediaKeys.METHOD_UPDATE_POSITION, null) { value = it })
        assertNull(value)
    }

    @Test fun otherMethodsAreNotAnswered() {
        assertFalse(handler.handle("createNotification", null) { throw AssertionError("not answered") })
    }
}
