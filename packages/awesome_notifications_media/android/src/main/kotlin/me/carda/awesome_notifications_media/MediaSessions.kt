package me.carda.awesome_notifications_media

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.media.app.NotificationCompat.MediaStyle
import me.carda.android_awn_core.ActionType
import me.carda.android_awn_core.BitmapUtils
import me.carda.android_awn_core.CancelInterceptor
import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.JsonUtils
import me.carda.android_awn_core.NotificationActions

/**
 * One [MediaSessionCompat] per `sessionId`: made on first use, updated on every
 * notification of the session, released by `mediaStop`, when its notification
 * is dismissed / cancelled / swiped away, or once it is idle and its
 * notification is gone. Turns the user's commands into the core's
 * action event and / or the commands stream.
 */
internal object MediaSessions {

    /** A live session and what its last notification carried. */
    class Entry(val session: MediaSessionCompat, @Volatile var media: MediaModel) {
        @Volatile var model: Map<String, Any?> = emptyMap()
        @Volatile var notificationId: Int? = null
        @Volatile var channelKey: String? = null
        @Volatile var groupKey: String? = null
        @Volatile var playback: PlaybackStateCompat? = null
        @Volatile var metadata: MediaMetadataCompat? = null
        lateinit var callback: MediaSessionCompat.Callback
    }

    private val entries = mutableMapOf<String, Entry>()
    private val main by lazy { Handler(Looper.getMainLooper()) }

    /** Where `stream` commands go: set by the plugin while Dart listens. */
    @Volatile var streamSink: ((Map<String, Any?>) -> Unit)? = null

    fun entry(sessionId: String): Entry? = synchronized(entries) { entries[sessionId] }

    // MARK: - Rendering

    /** Updates the session of [media] and styles [builder] as its media notification. */
    fun render(
        context: Context,
        media: MediaModel,
        model: Map<String, Any?>,
        builder: NotificationCompat.Builder
    ) {
        pruneIdle(context)
        val app = context.applicationContext
        val entry = obtain(app, media)
        @Suppress("UNCHECKED_CAST")
        val content = (model[Definitions.NOTIFICATION_CONTENT] as? Map<String, Any?>).orEmpty()
        entry.model = model
        entry.media = media
        entry.notificationId = (content[Definitions.NOTIFICATION_ID] as? Number)?.toInt()
        entry.channelKey = content[Definitions.NOTIFICATION_CHANNEL_KEY] as? String
        entry.groupKey = content[Definitions.NOTIFICATION_GROUP_KEY] as? String

        val art = media.artwork?.let { BitmapUtils.getInstance().getBitmapFromSource(app, it) }
        val metadata = metadata(media, art)
        entry.metadata = metadata
        entry.session.setMetadata(metadata)
        val playback = playbackState(app, media, buttons(model))
        entry.playback = playback
        entry.session.setPlaybackState(playback)
        entry.session.isActive = true

        // The controls as notification actions (what Android < 13 draws, and
        // the fallback once the session died with the app's process), before
        // the model's own buttons.
        val buttonActions = ArrayList(builder.mActions)
        builder.clearActions()
        val shown = notificationControls(media)
        shown.forEach { builder.addAction(controlAction(app, media, model, it)) }
        buttonActions.forEach { builder.addAction(it) }

        builder.setStyle(
            MediaStyle()
                .setMediaSession(entry.session.sessionToken)
                .setShowActionsInCompactView(*compactIndexes(shown))
        )
        art?.let { builder.setLargeIcon(it) }
        builder.setShowWhen(false)
        builder.setCategory(NotificationCompat.CATEGORY_TRANSPORT)
        builder.setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
    }

    private fun obtain(context: Context, media: MediaModel): Entry = synchronized(entries) {
        val sessionId = media.sessionId
        entries[sessionId] ?: Entry(MediaSessionCompat(context, "awn.media.$sessionId"), media).also { entry ->
            entry.callback = callback(context, sessionId)
            // The core builds off the main thread: the callback needs a looper.
            entry.session.setCallback(entry.callback, main)
            entries[sessionId] = entry
        }
    }

    fun metadata(media: MediaModel, art: Bitmap?): MediaMetadataCompat {
        val metadata = MediaMetadataCompat.Builder()
            .putString(MediaMetadataCompat.METADATA_KEY_TITLE, media.title)
        media.artist?.let { metadata.putString(MediaMetadataCompat.METADATA_KEY_ARTIST, it) }
        media.album?.let { metadata.putString(MediaMetadataCompat.METADATA_KEY_ALBUM, it) }
        // No duration: a live stream, without a progress bar.
        media.durationMs?.let { metadata.putLong(MediaMetadataCompat.METADATA_KEY_DURATION, it) }
        art?.let { metadata.putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, it) }
        return metadata.build()
    }

    fun playbackState(
        context: Context,
        media: MediaModel,
        buttons: List<Map<String, Any?>>
    ): PlaybackStateCompat {
        val state = PlaybackStateCompat.Builder()
            .setState(media.playbackState, media.positionMs, media.speed, SystemClock.elapsedRealtime())
            .setActions(actions(media.controls))
        // What the system has no standard button for (Android 13+ draws only
        // play / pause, previous and next from the actions).
        for (control in CUSTOM_CONTROLS) {
            if (control !in media.controls) continue
            state.addCustomAction(
                PlaybackStateCompat.CustomAction.Builder(
                    control.key, label(control, media), icon(control, media)
                ).build()
            )
        }
        for (button in buttons) {
            val key = button[Definitions.NOTIFICATION_BUTTON_KEY] as? String ?: continue
            if (button[Definitions.NOTIFICATION_BUTTON_ENABLED] == false) continue
            val icon = resourceIcon(context, button[Definitions.NOTIFICATION_BUTTON_ICON] as? String)
            if (icon == 0) continue
            val label = button[Definitions.NOTIFICATION_BUTTON_LABEL] as? String ?: key
            state.addCustomAction(PlaybackStateCompat.CustomAction.Builder(key, label, icon).build())
        }
        return state.build()
    }

    /** The session's actions bitmask of [controls]. */
    fun actions(controls: Set<MediaControl>): Long {
        var actions = 0L
        for (control in controls) actions = actions or when (control) {
            MediaControl.play -> PlaybackStateCompat.ACTION_PLAY
            MediaControl.pause -> PlaybackStateCompat.ACTION_PAUSE
            MediaControl.stop -> PlaybackStateCompat.ACTION_STOP
            MediaControl.skipNext -> PlaybackStateCompat.ACTION_SKIP_TO_NEXT
            MediaControl.skipPrevious -> PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS
            MediaControl.seekTo -> PlaybackStateCompat.ACTION_SEEK_TO
            MediaControl.fastForward -> PlaybackStateCompat.ACTION_FAST_FORWARD
            MediaControl.rewind -> PlaybackStateCompat.ACTION_REWIND
            MediaControl.skipForward, MediaControl.skipBackward -> 0L
        }
        if (MediaControl.play in controls || MediaControl.pause in controls)
            actions = actions or PlaybackStateCompat.ACTION_PLAY_PAUSE
        return actions
    }

    /**
     * The controls drawn as notification actions, in display order. Play and
     * pause share one slot: the one the state calls for.
     */
    fun notificationControls(media: MediaModel): List<MediaControl> {
        val controls = media.controls
        val toggle = when {
            MediaControl.play in controls && MediaControl.pause in controls ->
                if (media.isPlaying) MediaControl.pause else MediaControl.play
            MediaControl.pause in controls -> MediaControl.pause
            MediaControl.play in controls -> MediaControl.play
            else -> null
        }
        return listOfNotNull(
            MediaControl.skipPrevious.takeIf { it in controls },
            MediaControl.rewind.takeIf { it in controls },
            MediaControl.skipBackward.takeIf { it in controls },
            toggle,
            MediaControl.skipForward.takeIf { it in controls },
            MediaControl.fastForward.takeIf { it in controls },
            MediaControl.skipNext.takeIf { it in controls },
            MediaControl.stop.takeIf { it in controls }
        )
    }

    /** Up to 3 actions in the compact view: play / pause, previous, next first. */
    fun compactIndexes(shown: List<MediaControl>): IntArray {
        val preferred = listOf(
            MediaControl.play, MediaControl.pause, MediaControl.skipPrevious, MediaControl.skipNext,
            MediaControl.skipBackward, MediaControl.skipForward, MediaControl.rewind,
            MediaControl.fastForward, MediaControl.stop
        )
        return preferred.map { shown.indexOf(it) }.filter { it >= 0 }.take(3).sorted().toIntArray()
    }

    private fun controlAction(
        context: Context,
        media: MediaModel,
        model: Map<String, Any?>,
        control: MediaControl
    ): NotificationCompat.Action {
        val intent = Intent(context, MediaCommandReceiver::class.java).apply {
            action = control.key
            // Unique per session and control (extras don't tell PendingIntents apart).
            data = Uri.parse("awn-media://" + Uri.encode(media.sessionId) + "/" + control.name)
            putExtra(MediaKeys.EXTRA_CONTROL, control.name)
            putExtra(Definitions.NOTIFICATION_JSON, JsonUtils.getInstance().toJson(model))
        }
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) flags = flags or PendingIntent.FLAG_IMMUTABLE
        val pending = PendingIntent.getBroadcast(context, control.ordinal, intent, flags)
        return NotificationCompat.Action.Builder(icon(control, media), label(control, media), pending).build()
    }

    // MARK: - Commands

    private fun callback(context: Context, sessionId: String) = object : MediaSessionCompat.Callback() {
        override fun onPlay() = command(context, sessionId, MediaControl.play)
        override fun onPause() = command(context, sessionId, MediaControl.pause)
        override fun onStop() = command(context, sessionId, MediaControl.stop)
        override fun onSkipToNext() = command(context, sessionId, MediaControl.skipNext)
        override fun onSkipToPrevious() = command(context, sessionId, MediaControl.skipPrevious)
        override fun onFastForward() = command(context, sessionId, MediaControl.fastForward)
        override fun onRewind() = command(context, sessionId, MediaControl.rewind)
        override fun onSeekTo(pos: Long) = command(context, sessionId, MediaControl.seekTo, pos)
        override fun onCustomAction(action: String?, extras: android.os.Bundle?) {
            val key = action ?: return
            val control = MediaControl.fromKey(key)
            if (control != null) return command(context, sessionId, control)
            // A model's action button: as if it was pressed.
            val entry = entry(sessionId) ?: return
            NotificationActions.dispatch(context, entry.model, key)
        }
    }

    /** A command of the live session [sessionId]. */
    fun command(context: Context, sessionId: String, control: MediaControl, positionMs: Long? = null) {
        val entry = entry(sessionId) ?: return
        deliver(context, entry.model, entry.media, control, positionMs)
    }

    /** Delivers a command to the targets of [media]. */
    fun deliver(
        context: Context,
        model: Map<String, Any?>,
        media: MediaModel,
        control: MediaControl,
        positionMs: Long? = null,
        onFinished: () -> Unit = {}
    ) {
        if (media.target.toStream) {
            streamSink?.let { sink ->
                val event = mutableMapOf<String, Any?>(
                    MediaKeys.CONTROL to control.name,
                    MediaKeys.SESSION_ID to media.sessionId
                )
                if (positionMs != null) event[MediaKeys.POSITION] = positionMs
                if (Looper.myLooper() == Looper.getMainLooper()) sink(event) else main.post { sink(event) }
            }
        }
        if (media.target.toActionEvent) {
            NotificationActions.dispatch(
                context, model, control.key, positionMs?.toString(), syntheticButton(control), onFinished
            )
        } else {
            onFinished()
        }
    }

    /** Keeps the notification on screen and reaches the app (or a background isolate). */
    fun syntheticButton(control: MediaControl): Map<String, Any?> = mapOf(
        Definitions.NOTIFICATION_BUTTON_KEY to control.key,
        Definitions.NOTIFICATION_ACTION_TYPE to ActionType.SilentAction.name,
        Definitions.NOTIFICATION_AUTO_DISMISSIBLE to false
    )

    // MARK: - Channel methods

    /** Updates only the position (keeps state, speed and actions). */
    fun updatePosition(sessionId: String, positionMs: Long): Boolean {
        val entry = entry(sessionId) ?: return false
        val last = entry.playback ?: return false
        val updated = PlaybackStateCompat.Builder(last)
            .setState(last.state, positionMs, last.playbackSpeed, SystemClock.elapsedRealtime())
            .build()
        entry.playback = updated
        entry.session.setPlaybackState(updated)
        return true
    }

    /** Releases the session and removes its notification. */
    fun stop(context: Context, sessionId: String) {
        val entry = synchronized(entries) { entries.remove(sessionId) } ?: return
        release(entry)
        entry.notificationId?.let { NotificationManagerCompat.from(context).cancel(it) }
    }

    private fun release(entry: Entry) {
        entry.session.isActive = false
        entry.session.release()
    }

    /** Releases idle sessions whose notification is no longer on screen. */
    fun pruneIdle(context: Context) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val active = try {
            manager.activeNotifications.map { it.id }.toSet()
        } catch (_: Exception) {
            return
        }
        releaseWhere { it.media.isIdle && it.notificationId !in active }
    }

    private fun releaseWhere(predicate: (Entry) -> Boolean) {
        val gone = synchronized(entries) {
            val matched = entries.filterValues(predicate)
            matched.keys.forEach { entries.remove(it) }
            matched.values
        }
        gone.forEach { release(it) }
    }

    /**
     * A media notification left the status bar (dismiss* / cancel*, a swipe, an
     * action dismissing it): its session ends as `mediaStop` does, whatever its state.
     */
    val cancelInterceptor = object : CancelInterceptor {
        override fun onDismiss(context: Context, id: Int) =
            stopWhere(context) { it.notificationId == id }
        override fun onDismissAll(context: Context) = stopWhere(context) { true }
        override fun onDismissByChannelKey(context: Context, channelKey: String) =
            stopWhere(context) { it.channelKey == channelKey }
        override fun onDismissByGroupKey(context: Context, groupKey: String) =
            stopWhere(context) { it.groupKey == groupKey }
    }

    private fun stopWhere(context: Context, predicate: (Entry) -> Boolean) {
        val ids = synchronized(entries) { entries.filterValues(predicate).keys.toList() }
        ids.forEach { stop(context, it) }
    }

    /** Test-only: releases every session. */
    internal fun clearForTest() = releaseWhere { true }

    // MARK: - Resources

    private val CUSTOM_CONTROLS = listOf(
        MediaControl.skipBackward, MediaControl.rewind, MediaControl.fastForward,
        MediaControl.skipForward, MediaControl.stop
    )
    private val NUMBERED_SKIPS = setOf(5, 10, 15, 30)

    fun icon(control: MediaControl, media: MediaModel): Int {
        val seconds = (media.skipIntervalMs / 1000).toInt()
        val numbered = media.skipIntervalMs % 1000 == 0L && seconds in NUMBERED_SKIPS
        return when (control) {
            MediaControl.play -> R.drawable.awn_media_ic_play
            MediaControl.pause -> R.drawable.awn_media_ic_pause
            MediaControl.stop -> R.drawable.awn_media_ic_stop
            MediaControl.skipNext -> R.drawable.awn_media_ic_skip_next
            MediaControl.skipPrevious -> R.drawable.awn_media_ic_skip_previous
            MediaControl.fastForward -> R.drawable.awn_media_ic_fast_forward
            MediaControl.rewind -> R.drawable.awn_media_ic_rewind
            MediaControl.seekTo -> R.drawable.awn_media_ic_play
            MediaControl.skipForward -> if (!numbered) R.drawable.awn_media_ic_forward else when (seconds) {
                5 -> R.drawable.awn_media_ic_forward_5
                10 -> R.drawable.awn_media_ic_forward_10
                15 -> R.drawable.awn_media_ic_forward_15
                else -> R.drawable.awn_media_ic_forward_30
            }
            MediaControl.skipBackward -> if (!numbered) R.drawable.awn_media_ic_replay else when (seconds) {
                5 -> R.drawable.awn_media_ic_replay_5
                10 -> R.drawable.awn_media_ic_replay_10
                15 -> R.drawable.awn_media_ic_replay_15
                else -> R.drawable.awn_media_ic_replay_30
            }
        }
    }

    fun label(control: MediaControl, media: MediaModel): String {
        val seconds = media.skipIntervalMs / 1000.0
        val interval = if (seconds % 1.0 == 0.0) "${seconds.toLong()} s" else "$seconds s"
        return when (control) {
            MediaControl.play -> "Play"
            MediaControl.pause -> "Pause"
            MediaControl.stop -> "Stop"
            MediaControl.skipNext -> "Next"
            MediaControl.skipPrevious -> "Previous"
            MediaControl.skipForward -> "Forward $interval"
            MediaControl.skipBackward -> "Back $interval"
            MediaControl.seekTo -> "Seek"
            MediaControl.fastForward -> "Fast forward"
            MediaControl.rewind -> "Rewind"
        }
    }

    /** A `resource://type/name` icon of the app (0 = none). */
    private fun resourceIcon(context: Context, path: String?): Int {
        val prefix = "resource://"
        if (path == null || !path.startsWith(prefix)) return 0
        val parts = path.substring(prefix.length).split("/")
        if (parts.size < 2) return 0
        return context.resources.getIdentifier(parts[1], parts[0], context.packageName)
    }

    @Suppress("UNCHECKED_CAST")
    private fun buttons(model: Map<String, Any?>): List<Map<String, Any?>> =
        (model[Definitions.NOTIFICATION_BUTTONS] as? List<Map<String, Any?>>).orEmpty()
}
