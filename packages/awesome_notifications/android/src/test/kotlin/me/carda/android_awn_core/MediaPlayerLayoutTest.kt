package me.carda.android_awn_core

import android.app.Notification
import android.app.NotificationManager
import android.content.Context
import android.os.Looper
import android.support.v4.media.session.PlaybackStateCompat
import androidx.test.core.app.ApplicationProvider
import java.util.concurrent.Executor
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/** The 0.12 `MediaPlayer` layout, as an app sees it on screen. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class MediaPlayerLayoutTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val core = AwesomeNotifications(context, Executor { it.run() })

    private fun manager() =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    @Before fun setUp() {
        NotificationBuilderRegistry.clearForTest()
        manager().cancelAll()
        core.setChannel(
            mapOf(
                Definitions.NOTIFICATION_CHANNEL_KEY to "media",
                Definitions.NOTIFICATION_CHANNEL_NAME to "Media"
            )
        )
    }

    @After fun tearDown() = NotificationBuilderRegistry.clearForTest()

    private fun button(key: String, compact: Boolean = false, enabled: Boolean = true) = mapOf<String, Any?>(
        Definitions.NOTIFICATION_BUTTON_KEY to key,
        Definitions.NOTIFICATION_BUTTON_LABEL to key,
        Definitions.NOTIFICATION_BUTTON_ENABLED to enabled,
        "showInCompactView" to compact,
        Definitions.NOTIFICATION_ACTION_TYPE to "KeepOnTop"
    )

    private fun send(
        id: Int,
        groupKey: String? = "player",
        buttons: List<Map<String, Any?>> = emptyList(),
        extra: Map<String, Any?> = emptyMap()
    ) {
        val content = mutableMapOf<String, Any?>(
            Definitions.NOTIFICATION_ID to id,
            Definitions.NOTIFICATION_CHANNEL_KEY to "media",
            Definitions.NOTIFICATION_TITLE to "Bright Sharp",
            Definitions.NOTIFICATION_BODY to "Champagne Supernova",
            Definitions.NOTIFICATION_LAYOUT to "MediaPlayer"
        ) + extra
        val withGroup = if (groupKey != null) content + (Definitions.NOTIFICATION_GROUP_KEY to groupKey) else content
        core.createNotification(
            mapOf(
                Definitions.NOTIFICATION_CONTENT to withGroup,
                Definitions.NOTIFICATION_BUTTONS to buttons
            )
        ) {}
        shadowOf(Looper.getMainLooper()).idle()
    }

    private fun shown(id: Int): Notification? =
        manager().activeNotifications.firstOrNull { it.id == id }?.notification

    @Test fun itIsAMediaStyleNotificationWithTheSession() {
        send(1)
        val extras = shown(1)!!.extras
        assertEquals("android.app.Notification\$MediaStyle", extras.getString(Notification.EXTRA_TEMPLATE))
        assertNotNull(extras.getParcelable<android.os.Parcelable>(Notification.EXTRA_MEDIA_SESSION))
    }

    @Test fun aGroupPlaysInTheFirstNotification() {
        send(1)
        send(2)
        assertEquals(listOf(1), manager().activeNotifications.map { it.id })
    }

    @Test fun withoutAGroupKeyEachStandsAlone() {
        send(1, groupKey = null)
        send(2, groupKey = null)
        assertEquals(setOf(1, 2), manager().activeNotifications.map { it.id }.toSet())
    }

    /** Android 10: no session custom actions, so buttons need no icon. */
    @Config(sdk = [29])
    @Test fun compactViewButtonsKeepTheirIndexesWithADisabledOne() {
        send(1, buttons = listOf(
            button("PREV", enabled = false),
            button("PLAY", compact = true),
            button("NEXT", compact = true)))
        val notification = shown(1)!!
        // 0.12: a disabled button is still shown (no intent), so the compact
        // view indexes point at PLAY and NEXT.
        assertEquals(listOf("PREV", "PLAY", "NEXT"), notification.actions.map { it.title.toString() })
        assertNull(notification.actions[0].actionIntent)
        assertEquals(listOf(1, 2),
            notification.extras.getIntArray(Notification.EXTRA_COMPACT_ACTIONS)?.toList())
    }

    /** 0.12 on Android 11+: a button without an icon can't be a custom action. */
    @Test fun aButtonWithoutAnIconFallsBackToTheDefaultLayout() {
        send(1, buttons = listOf(button("PLAY", compact = true)))
        assertNull(shown(1)!!.extras.getString(Notification.EXTRA_TEMPLATE)
            ?.takeIf { it.contains("MediaStyle") })
    }

    @Test fun thePlaybackStateFollowsThe012Formula() {
        send(1, extra = mapOf("duration" to 200, "progress" to 25.0, "playbackSpeed" to 1.0, "playState" to 2))
        val state = MediaPlayerLayout.session(context).controller.playbackState!!
        assertEquals(PlaybackStateCompat.STATE_PAUSED, state.state)
        assertEquals(25L * 200 * 10, state.position)
        assertEquals(1f, state.playbackSpeed)
    }

    @Test fun missingMediaFieldsDefaultToPlayingAtZero() {
        send(1)
        val state = MediaPlayerLayout.session(context).controller.playbackState!!
        assertEquals(PlaybackStateCompat.STATE_PLAYING, state.state)
        assertEquals(0L, state.position)
        assertEquals(0f, state.playbackSpeed)
    }

    @Test fun theSummaryIsTheSubText() {
        send(1, extra = mapOf("summary" to "Now playing"))
        assertEquals("Now playing", shown(1)!!.extras.getCharSequence(Notification.EXTRA_SUB_TEXT).toString())
    }

    @Test fun otherLayoutsAreUntouched() {
        core.createNotification(
            mapOf(
                Definitions.NOTIFICATION_CONTENT to mapOf(
                    Definitions.NOTIFICATION_ID to 7,
                    Definitions.NOTIFICATION_CHANNEL_KEY to "media",
                    Definitions.NOTIFICATION_TITLE to "Hi",
                    Definitions.NOTIFICATION_BODY to "there"
                )
            )
        ) {}
        shadowOf(Looper.getMainLooper()).idle()
        assertNull(shown(7)!!.extras.getParcelable<android.os.Parcelable>(Notification.EXTRA_MEDIA_SESSION))
    }
}
