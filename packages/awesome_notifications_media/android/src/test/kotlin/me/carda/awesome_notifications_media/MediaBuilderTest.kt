package me.carda.awesome_notifications_media

import android.app.Notification
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Looper
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.core.app.NotificationCompat
import androidx.test.core.app.ApplicationProvider
import java.util.concurrent.Executor
import me.carda.android_awn_core.AwesomeEventListener
import me.carda.android_awn_core.AwesomeEventsReceiver
import me.carda.android_awn_core.AwesomeNotifications
import me.carda.android_awn_core.BackgroundActions
import me.carda.android_awn_core.Definitions
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class MediaBuilderTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val core = AwesomeNotifications(context, Executor { it.run() })
    private val handler = MediaMethodHandler(context)

    private val events = mutableListOf<Pair<String, Map<String, Any?>>>()
    private val listener = object : AwesomeEventListener {
        override fun onNewAwesomeEvent(eventType: String, content: Map<String, Any?>) {
            events.add(eventType to content)
        }
    }
    private val streamed = mutableListOf<Map<String, Any?>>()

    private fun manager() =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    @Before fun setUp() {
        // The registry is process-wide (and clearing it is internal to the core).
        AwesomeNotificationsMediaPlugin.install()
        MediaSessions.clearForTest()
        manager().cancelAll()
        core.setChannel(
            mapOf(Definitions.NOTIFICATION_CHANNEL_KEY to "media", Definitions.NOTIFICATION_CHANNEL_NAME to "Media")
        )
        AwesomeEventsReceiver.subscribe(listener)
        MediaSessions.streamSink = { streamed.add(it) }
    }

    @After fun tearDown() {
        AwesomeEventsReceiver.unsubscribe(listener)
        MediaSessions.streamSink = null
        BackgroundActions.executor = null
    }

    private data class Outcome(val created: Boolean?, val code: String?, val detail: String?)

    private fun create(
        id: Int = 1,
        layout: String? = "MediaPlayer",
        media: Map<String, Any?>? = media(),
        content: Map<String, Any?> = emptyMap(),
        buttons: List<Map<String, Any?>>? = null
    ): Outcome {
        val c = mutableMapOf<String, Any?>(
            Definitions.NOTIFICATION_ID to id,
            Definitions.NOTIFICATION_CHANNEL_KEY to "media"
        )
        if (layout != null) c[Definitions.NOTIFICATION_LAYOUT] = layout
        c.putAll(content)
        val model = mutableMapOf<String, Any?>(Definitions.NOTIFICATION_CONTENT to c)
        if (media != null) model[MediaKeys.MEDIA] = media
        if (buttons != null) model[Definitions.NOTIFICATION_BUTTONS] = buttons
        var outcome = Outcome(null, null, null)
        core.createNotification(model, onError = { code, _, details -> outcome = Outcome(null, code, details) }) {
            outcome = Outcome(it, null, null)
        }
        shadowOf(Looper.getMainLooper()).idle()
        return outcome
    }

    private fun media(
        sessionId: String = "player",
        state: String = "playing",
        controls: List<String> = listOf("skipPrevious", "pause", "skipNext", "seekTo"),
        duration: Long? = 261_000,
        position: Long = 37_000,
        speed: Double = 1.0,
        target: String = "actionEvent",
        skipInterval: Long = 15_000
    ) = mutableMapOf<String, Any?>(
        "sessionId" to sessionId,
        "title" to "Champagne Supernova",
        "artist" to "Bright Sharp",
        "album" to "Morning Glory",
        "position" to position,
        "playbackSpeed" to speed,
        "state" to state,
        "controls" to controls,
        "skipInterval" to skipInterval,
        "commandTarget" to target
    ).apply { if (duration != null) this["duration"] = duration }

    private fun notification(id: Int = 1): Notification =
        manager().activeNotifications.first { it.id == id }.notification

    private fun session(id: String = "player") = MediaSessions.entry(id)!!.session

    // MARK: - Validation

    @Test fun theMediaPlayerLayoutRequiresMedia() {
        val outcome = create(media = null)
        assertEquals("INVALID_ARGUMENTS", outcome.code)
        assertEquals("arguments.invalid.notificationMedia", outcome.detail)
        assertTrue(manager().activeNotifications.isEmpty())
    }

    @Test fun mediaRequiresTheMediaPlayerLayout() {
        assertEquals("arguments.invalid.notificationMedia.layout", create(layout = null).detail)
        assertEquals("arguments.invalid.notificationMedia.layout", create(layout = "BigPicture").detail)
    }

    @Test fun anInvalidMediaBlockFails() {
        val outcome = create(media = media().apply { this["sessionId"] = " " })
        assertEquals("INVALID_ARGUMENTS", outcome.code)
        assertEquals("arguments.invalid.notificationMedia", outcome.detail)
        assertEquals("INVALID_ARGUMENTS", create(media = media().apply { remove("title") }).code)
    }

    @Test fun otherNotificationsAreUntouched() {
        assertEquals(true, create(layout = null, media = null).created)
        assertNull(MediaSessions.entry("player"))
    }

    // MARK: - Content

    @Test fun theTitleBodyAndPayloadAreFilled() {
        create(content = mapOf(Definitions.NOTIFICATION_PAYLOAD to mapOf("track" to "7")))
        val extras = notification().extras
        assertEquals("Champagne Supernova", extras.getCharSequence(NotificationCompat.EXTRA_TITLE).toString())
        assertEquals("Bright Sharp", extras.getCharSequence(NotificationCompat.EXTRA_TEXT).toString())
        @Suppress("UNCHECKED_CAST")
        val payload = MediaSessions.entry("player")!!.model[Definitions.NOTIFICATION_CONTENT]
            .let { (it as Map<String, Any?>)[Definitions.NOTIFICATION_PAYLOAD] as Map<String, Any?> }
        assertEquals(mapOf("track" to "7", "mediaSessionId" to "player"), payload)
    }

    @Test fun theContentsOwnTitleWins() {
        create(content = mapOf(Definitions.NOTIFICATION_TITLE to "Now playing"))
        assertEquals("Now playing", notification().extras.getCharSequence(NotificationCompat.EXTRA_TITLE).toString())
    }

    // MARK: - Session

    @Test fun theSessionHasTheMetadata() {
        create()
        val metadata = MediaSessions.entry("player")!!.metadata!!
        assertEquals("Champagne Supernova", metadata.getString(MediaMetadataCompat.METADATA_KEY_TITLE))
        assertEquals("Bright Sharp", metadata.getString(MediaMetadataCompat.METADATA_KEY_ARTIST))
        assertEquals("Morning Glory", metadata.getString(MediaMetadataCompat.METADATA_KEY_ALBUM))
        assertEquals(261_000L, metadata.getLong(MediaMetadataCompat.METADATA_KEY_DURATION))
        assertTrue(session().isActive)
    }

    @Test fun aLiveStreamHasNoDuration() {
        create(media = media(duration = null))
        assertFalse(MediaSessions.entry("player")!!.metadata!!.containsKey(MediaMetadataCompat.METADATA_KEY_DURATION))
    }

    @Test fun thePlaybackStateFollowsTheModel() {
        create(media = media(state = "paused", position = 12_000, speed = 0.0))
        val state = MediaSessions.entry("player")!!.playback!!
        assertEquals(PlaybackStateCompat.STATE_PAUSED, state.state)
        assertEquals(12_000L, state.position)
        assertEquals(0f, state.playbackSpeed)
        create(media = media(state = "playing", speed = 1.5))
        val playing = MediaSessions.entry("player")!!.playback!!
        assertEquals(PlaybackStateCompat.STATE_PLAYING, playing.state)
        assertEquals(1.5f, playing.playbackSpeed)
    }

    @Test fun theActionsComeFromTheControls() {
        create()
        val actions = MediaSessions.entry("player")!!.playback!!.actions
        val expected = PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS or PlaybackStateCompat.ACTION_PAUSE or
            PlaybackStateCompat.ACTION_PLAY_PAUSE or PlaybackStateCompat.ACTION_SKIP_TO_NEXT or
            PlaybackStateCompat.ACTION_SEEK_TO
        assertEquals(expected, actions)
        val all = MediaSessions.actions(MediaControl.values().toSet())
        listOf(
            PlaybackStateCompat.ACTION_PLAY, PlaybackStateCompat.ACTION_STOP,
            PlaybackStateCompat.ACTION_FAST_FORWARD, PlaybackStateCompat.ACTION_REWIND
        ).forEach { assertTrue(all and it != 0L) }
    }

    @Test fun skipsAndButtonsAreCustomActions() {
        val icon = "resource://drawable/awn_media_ic_stop" // a drawable the test app has
        create(
            media = media(controls = listOf("pause", "skipForward", "skipBackward"), skipInterval = 10_000),
            buttons = listOf(
                mapOf("key" to "like", "label" to "Like", "icon" to icon, "actionType" to "SilentAction"),
                mapOf("key" to "noIcon", "label" to "No icon")
            )
        )
        val custom = MediaSessions.entry("player")!!.playback!!.customActions
        assertEquals(listOf("awn.media.skipBackward", "awn.media.skipForward", "like"), custom.map { it.action })
        assertEquals("Forward 10 s", custom[1].name.toString())
        assertEquals(R.drawable.awn_media_ic_forward_10, custom[1].icon)
        assertEquals(R.drawable.awn_media_ic_replay_10, custom[0].icon)
    }

    @Test fun anOddIntervalHasTheGenericIcon() {
        val media = MediaModel.parse(media(skipInterval = 20_000)).first!!
        assertEquals(R.drawable.awn_media_ic_forward, MediaSessions.icon(MediaControl.skipForward, media))
    }

    @Test fun oneSessionPerId() {
        create(1, media = media(sessionId = "a"))
        create(2, media = media(sessionId = "b"))
        val a = session("a")
        create(1, media = media(sessionId = "a", state = "paused"))
        assertTrue(a === session("a"))
        assertTrue(session("a") !== session("b"))
    }

    // MARK: - Notification

    @Test fun theNotificationIsAMediaNotification() {
        create(buttons = listOf(mapOf("key" to "like", "label" to "Like", "actionType" to "SilentAction")))
        val notification = notification()
        assertEquals(Notification.CATEGORY_TRANSPORT, notification.category)
        assertNotNull(notification.extras.getParcelable<android.os.Parcelable>(Notification.EXTRA_MEDIA_SESSION))
        // The controls first (play / pause by the state), then the model's buttons.
        assertEquals(
            listOf("Previous", "Pause", "Next", "Like"),
            notification.actions.map { it.title.toString() }
        )
        assertEquals(listOf(0, 1, 2), notification.extras.getIntArray(Notification.EXTRA_COMPACT_ACTIONS)?.toList())
    }

    @Test fun playOrPauseByTheState() {
        val playing = MediaModel.parse(media(controls = listOf("play", "pause"))).first!!
        assertEquals(listOf(MediaControl.pause), MediaSessions.notificationControls(playing))
        val paused = MediaModel.parse(media(state = "paused", controls = listOf("play", "pause"))).first!!
        assertEquals(listOf(MediaControl.play), MediaSessions.notificationControls(paused))
    }

    @Test fun theCompactViewPrefersPlayPreviousNext() {
        val shown = listOf(
            MediaControl.skipPrevious, MediaControl.rewind, MediaControl.pause,
            MediaControl.fastForward, MediaControl.skipNext
        )
        assertEquals(listOf(0, 2, 4), MediaSessions.compactIndexes(shown).toList())
    }

    // MARK: - Commands

    private fun lastAction(): Map<String, Any?> {
        shadowOf(Looper.getMainLooper()).idle()
        return events.last { it.first == Definitions.EVENT_DEFAULT_ACTION }.second
    }

    @Test fun aSessionCommandIsAnActionEvent() {
        create()
        MediaSessions.entry("player")!!.callback.onPause()
        val action = lastAction()
        assertEquals("awn.media.pause", action[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED])
        assertNull(action[Definitions.NOTIFICATION_BUTTON_KEY_INPUT])
        assertEquals("SilentAction", action[Definitions.NOTIFICATION_ACTION_TYPE])
        @Suppress("UNCHECKED_CAST")
        assertEquals("player", (action[Definitions.NOTIFICATION_PAYLOAD] as Map<String, Any?>)["mediaSessionId"])
        // Not dismissed: the controls stay.
        assertEquals(1, manager().activeNotifications.size)
        assertTrue(streamed.isEmpty())
    }

    @Test fun seekToCarriesThePosition() {
        create()
        MediaSessions.entry("player")!!.callback.onSeekTo(90_500)
        val action = lastAction()
        assertEquals("awn.media.seekTo", action[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED])
        assertEquals("90500", action[Definitions.NOTIFICATION_BUTTON_KEY_INPUT])
    }

    @Test fun customActionsAreCommandsOrButtons() {
        create(
            media = media(controls = listOf("skipForward")),
            buttons = listOf(mapOf("key" to "like", "label" to "Like", "actionType" to "SilentAction"))
        )
        val callback = MediaSessions.entry("player")!!.callback
        callback.onCustomAction("awn.media.skipForward", null)
        assertEquals("awn.media.skipForward", lastAction()[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED])
        callback.onCustomAction("like", null)
        assertEquals("like", lastAction()[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED])
    }

    @Test fun theStreamTargetEmitsOnTheEventChannel() {
        create(media = media(target = "stream"))
        val callback = MediaSessions.entry("player")!!.callback
        callback.onSkipToNext()
        callback.onSeekTo(1_000)
        shadowOf(Looper.getMainLooper()).idle()
        assertEquals(
            listOf(
                mapOf("control" to "skipNext", "sessionId" to "player"),
                mapOf("control" to "seekTo", "sessionId" to "player", "position" to 1_000L)
            ),
            streamed
        )
        assertTrue(events.none { it.first == Definitions.EVENT_DEFAULT_ACTION })
    }

    @Test fun bothTargets() {
        create(media = media(target = "both"))
        MediaSessions.entry("player")!!.callback.onPlay()
        assertEquals("awn.media.play", lastAction()[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED])
        assertEquals(listOf(mapOf("control" to "play", "sessionId" to "player")), streamed)
    }

    @Test fun theReceiverDeliversANotificationActionsCommand() {
        create()
        val pending = notification().actions.first { it.title.toString() == "Next" }.actionIntent
        val intent = shadowOf(pending).savedIntent
        MediaCommandReceiver().onReceive(context, Intent(intent))
        val action = lastAction()
        assertEquals("awn.media.skipNext", action[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED])
        @Suppress("UNCHECKED_CAST")
        assertEquals("player", (action[Definitions.NOTIFICATION_PAYLOAD] as Map<String, Any?>)["mediaSessionId"])
    }

    @Test fun aKilledAppGetsTheCommandInTheBackground() {
        create()
        val intent = shadowOf(notification().actions.first { it.title.toString() == "Pause" }.actionIntent).savedIntent
        // The process died: no session, no app listening.
        MediaSessions.clearForTest()
        AwesomeEventsReceiver.unsubscribe(listener)
        var background: Map<String, Any?>? = null
        BackgroundActions.executor = BackgroundActions.Executor { _, action, done -> background = action; done() }
        MediaCommandReceiver().onReceive(context, Intent(intent))
        assertEquals("awn.media.pause", background!![Definitions.NOTIFICATION_BUTTON_KEY_PRESSED])
        assertEquals("Terminated", background!![Definitions.NOTIFICATION_ACTION_LIFECYCLE])
    }

    // MARK: - Channel methods

    @Test fun updatePositionKeepsStateAndSpeed() {
        create(media = media(speed = 1.25))
        var answered = false
        handler.handle(MediaKeys.METHOD_UPDATE_POSITION, mapOf("sessionId" to "player", "position" to 120_000), {
            answered = it == null
        })
        assertTrue(answered)
        val state = MediaSessions.entry("player")!!.playback!!
        assertEquals(120_000L, state.position)
        assertEquals(PlaybackStateCompat.STATE_PLAYING, state.state)
        assertEquals(1.25f, state.playbackSpeed)
        assertTrue(state.actions and PlaybackStateCompat.ACTION_SEEK_TO != 0L)
    }

    @Test fun stopReleasesTheSessionAndItsNotification() {
        create()
        val session = session()
        handler.handle(MediaKeys.METHOD_STOP, "player", {})
        assertNull(MediaSessions.entry("player"))
        assertFalse(session.isActive)
        assertTrue(manager().activeNotifications.isEmpty())
    }

    @Test fun anIdleSessionGoesWithItsNotification() {
        create(media = media(state = "stopped"))
        core.cancel(1)
        assertNull(MediaSessions.entry("player"))
        create(media = media(sessionId = "playing"))
        core.cancel(1)
        assertNotNull(MediaSessions.entry("playing"))
    }

    @Test fun capabilities() {
        var answer: Any? = null
        handler.handle(MediaKeys.METHOD_CAPABILITIES, null, { answer = it })
        assertEquals(
            mapOf("seekBar" to true, "artwork" to true, "customButtons" to true, "lockScreen" to true),
            answer
        )
        assertFalse(handler.handle("other", null, {}))
    }
}
