package me.carda.android_awn_core

import android.app.PendingIntent
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.core.app.NotificationCompat
import androidx.media.app.NotificationCompat.MediaStyle

/**
 * The `MediaPlayer` layout of 0.12 (NotificationBuilder `setMediaPlayerLayout`),
 * ported as it was, quirks included:
 *  - ONE media session for the whole app (tag `PUSH_MEDIA`), shared by every
 *    media notification;
 *  - a notification of a group still on screen is shown under the id of the
 *    group's first one;
 *  - Android 10+: the session's metadata (title, artist = body, duration in
 *    seconds, album art = big picture or large icon) and playback state
 *    (missing fields default to progress 0, playing, speed 0, duration 0; the
 *    position is `progress × duration × 10` ms);
 *  - Android 11+: each button is also a session custom action; using it fires
 *    the button's own action. A button without an icon can't be one: 0.12
 *    stops there (after the session's metadata, before the style), so the
 *    notification falls back to the default layout;
 *  - `summary` is the sub text, the progress bar shows a 0–100 `progress`, and
 *    the time is hidden.
 *
 * A media add-on (awesome_notifications_media) replaces this through the
 * decorator chain.
 */
internal object MediaPlayerLayout {

    private const val SESSION_TAG = "PUSH_MEDIA"
    private const val KEY_SUMMARY = "summary"
    private const val KEY_PROGRESS = "progress"
    private const val KEY_DURATION = "duration"
    private const val KEY_PLAY_STATE = "playState"
    private const val KEY_PLAYBACK_SPEED = "playbackSpeed"
    private const val KEY_SHOW_IN_COMPACT_VIEW = "showInCompactView"

    /** 0.12 `NotificationPlayState.playing`. */
    private const val STATE_PLAYING = 3

    @Volatile
    private var session: MediaSessionCompat? = null

    fun isMedia(content: Map<String, Any?>) =
        NotificationLayout.from(content[Definitions.NOTIFICATION_LAYOUT] as? String) ==
            NotificationLayout.MediaPlayer

    /** 0.12 made the session at init; this makes it on first use, once. */
    fun session(context: Context): MediaSessionCompat =
        session ?: synchronized(this) {
            session ?: MediaSessionCompat(context.applicationContext, SESSION_TAG).also { session = it }
        }

    /**
     * The model step of 0.12 `setMediaPlayerLayout`: the id the notification
     * is shown under. Returns the model unchanged when the layout does not
     * apply. (The media fields' defaults stay inside the style step: 0.12
     * events never carry the media fields.)
     */
    fun prepare(context: Context, model: Map<String, Any?>): Map<String, Any?> {
        @Suppress("UNCHECKED_CAST")
        val content = (model[Definitions.NOTIFICATION_CONTENT] as? Map<String, Any?>) ?: return model
        if (!isMedia(content)) return model

        val updated = content.toMutableMap()
        val groupKey = content[Definitions.NOTIFICATION_GROUP_KEY] as? String
        MessagingLayout.activeIdsOfGroup(context, groupKey).firstOrNull()
            ?.let { updated[Definitions.NOTIFICATION_ID] = it }
        return model.toMutableMap().apply { this[Definitions.NOTIFICATION_CONTENT] = updated }
    }

    /**
     * The style step of 0.12 `setMediaPlayerLayout`, on a prepared content.
     * [buttonIntents] holds each button's action intent by key (null when the
     * button is disabled), as the notification's actions were built.
     */
    fun applyStyle(
        context: Context,
        content: Map<String, Any?>,
        buttons: List<Map<String, Any?>>,
        buttonIntents: Map<String, PendingIntent?>,
        builder: NotificationCompat.Builder,
        bitmapUtils: BitmapUtils
    ): Boolean {
        if (!isMedia(content)) return false
        val mapUtils = MapUtils.getInstance()
        val session = session(context)

        val compact = buttons.indices
            .filter { mapUtils.getBool(buttons[it][KEY_SHOW_IN_COMPACT_VIEW]) == true }
            .toIntArray()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val title = mapUtils.getString(content[Definitions.NOTIFICATION_TITLE])
            val body = mapUtils.getString(content[Definitions.NOTIFICATION_BODY])
            val duration = mapUtils.getInt(content[KEY_DURATION]) ?: 0
            val progress = (content[KEY_PROGRESS] as? Number)?.toFloat() ?: 0f
            val speed = (content[KEY_PLAYBACK_SPEED] as? Number)?.toFloat() ?: 0f
            val state = mapUtils.getInt(content[KEY_PLAY_STATE]) ?: STATE_PLAYING

            val metadata = MediaMetadataCompat.Builder()
            if (title != null) metadata.putString(MediaMetadataCompat.METADATA_KEY_TITLE, title)
            if (body != null) metadata.putString(MediaMetadataCompat.METADATA_KEY_ARTIST, body)
            if (content[KEY_DURATION] != null) {
                metadata.putLong(MediaMetadataCompat.METADATA_KEY_DURATION, duration * 1000L)
            }
            val art = mapUtils.getString(content[Definitions.NOTIFICATION_BIG_PICTURE])
                ?.let { bitmapUtils.getBitmapFromSource(context, it) }
                ?: mapUtils.getString(content[Definitions.NOTIFICATION_LARGE_ICON])
                    ?.let { bitmapUtils.getBitmapFromSource(context, it) }
            if (art != null) metadata.putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, art)
            session.setMetadata(metadata.build())

            val playback = PlaybackStateCompat.Builder().setState(
                state,
                (progress * duration * 10).toLong(),
                speed,
                SystemClock.elapsedRealtime())

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val iconless = buttons.any {
                    mapUtils.getString(it[Definitions.NOTIFICATION_BUTTON_KEY]) != null &&
                        buttonIcon(context, it) == 0
                }
                if (iconless) return false
                for (button in buttons) {
                    val key = mapUtils.getString(button[Definitions.NOTIFICATION_BUTTON_KEY]) ?: continue
                    val label = mapUtils.getString(button[Definitions.NOTIFICATION_BUTTON_LABEL]) ?: key
                    val icon = buttonIcon(context, button)
                    playback.addCustomAction(
                        PlaybackStateCompat.CustomAction.Builder(key, label, icon)
                            .setExtras(Bundle())
                            .build())
                }
                // The core builds off the main thread; the session's callback
                // needs a looper (0.12 built on the main thread).
                session.setCallback(object : MediaSessionCompat.Callback() {
                    override fun onCustomAction(action: String?, extras: Bundle?) {
                        super.onCustomAction(action, extras)
                        try {
                            buttonIntents[action ?: return]?.send()
                        } catch (_: PendingIntent.CanceledException) {
                        }
                    }
                }, Handler(Looper.getMainLooper()))
            }
            session.setPlaybackState(playback.build())
        }

        builder.setStyle(
            MediaStyle()
                .setMediaSession(session.sessionToken)
                .setShowActionsInCompactView(*compact)
                .setShowCancelButton(true))

        val summary = mapUtils.getString(content[KEY_SUMMARY])
        if (!summary.isNullOrEmpty()) builder.setSubText(summary)

        val progress = (content[KEY_PROGRESS] as? Number)?.toInt()
        if (progress != null && progress in 0..100) {
            builder.setProgress(100, progress, false)
        }
        builder.setShowWhen(false)
        return true
    }

    /** A button's `resource://type/name` icon (0 = none). */
    private fun buttonIcon(context: Context, button: Map<String, Any?>): Int {
        val icon = MapUtils.getInstance().getString(button[Definitions.NOTIFICATION_BUTTON_ICON])
            ?: return 0
        if (!icon.startsWith(MediaSourcePrefix.RESOURCE)) return 0
        val parts = icon.substring(MediaSourcePrefix.RESOURCE.length).split("/")
        if (parts.size < 2) return 0
        return context.resources.getIdentifier(parts[1], parts[0], context.packageName)
    }
}
