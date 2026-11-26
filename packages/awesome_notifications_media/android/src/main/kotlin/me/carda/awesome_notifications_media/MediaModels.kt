package me.carda.awesome_notifications_media

import android.support.v4.media.session.PlaybackStateCompat

/** A standard control (Dart `MediaControl`), in its declaration order. */
internal enum class MediaControl {
    play, pause, stop, skipNext, skipPrevious, skipForward, skipBackward, seekTo, fastForward, rewind;

    /** The `buttonKeyPressed` of this control's commands. */
    val key: String get() = MediaKeys.COMMAND_PREFIX + name

    companion object {
        fun from(name: String?): MediaControl? = values().firstOrNull { it.name == name }
        fun fromKey(key: String?): MediaControl? =
            if (key == null || !key.startsWith(MediaKeys.COMMAND_PREFIX)) null
            else from(key.substring(MediaKeys.COMMAND_PREFIX.length))
    }
}

internal enum class CommandTarget(val toActionEvent: Boolean, val toStream: Boolean) {
    actionEvent(true, false), stream(false, true), both(true, true);

    companion object {
        fun from(name: String?) = values().firstOrNull { it.name == name } ?: actionEvent
    }
}

/** The `media` block of a model. */
internal data class MediaModel(
    val sessionId: String,
    val title: String,
    val artist: String?,
    val album: String?,
    val artwork: String?,
    /** Null for a live stream. */
    val durationMs: Long?,
    val positionMs: Long,
    val speed: Float,
    val state: String,
    val controls: Set<MediaControl>,
    val skipIntervalMs: Long,
    val target: CommandTarget
) {
    /** The PlaybackStateCompat state of [state]. */
    val playbackState: Int get() = when (state) {
        "stopped" -> PlaybackStateCompat.STATE_STOPPED
        "paused" -> PlaybackStateCompat.STATE_PAUSED
        "playing" -> PlaybackStateCompat.STATE_PLAYING
        "forwarding" -> PlaybackStateCompat.STATE_FAST_FORWARDING
        "rewinding" -> PlaybackStateCompat.STATE_REWINDING
        "buffering" -> PlaybackStateCompat.STATE_BUFFERING
        "error" -> PlaybackStateCompat.STATE_ERROR
        "connecting" -> PlaybackStateCompat.STATE_CONNECTING
        "previous" -> PlaybackStateCompat.STATE_SKIPPING_TO_PREVIOUS
        "next" -> PlaybackStateCompat.STATE_SKIPPING_TO_NEXT
        "skippingToQueueItem" -> PlaybackStateCompat.STATE_SKIPPING_TO_QUEUE_ITEM
        else -> PlaybackStateCompat.STATE_NONE // none, unknown
    }

    /** Whether the player is (about to be) playing: pause is the toggle's action. */
    val isPlaying: Boolean get() =
        state in setOf("playing", "forwarding", "rewinding", "buffering", "connecting")

    /** Stopped or nothing loaded: the session can go once its notification is gone. */
    val isIdle: Boolean get() = state == "stopped" || state == "none"

    companion object {
        /** Parses the block, or returns the reason it is invalid. */
        fun parse(block: Any?): Pair<MediaModel?, String?> {
            val map = block as? Map<*, *> ?: return null to "The media block must be a map"
            val sessionId = (map[MediaKeys.SESSION_ID] as? String)?.trim()
            if (sessionId.isNullOrEmpty()) return null to "The media session needs a non-empty sessionId"
            val title = map[MediaKeys.TITLE] as? String
            if (title.isNullOrBlank()) return null to "The media needs a non-empty title"
            val duration = (map[MediaKeys.DURATION] as? Number)?.toLong()
            if (duration != null && duration <= 0) return null to "The media duration must be positive"
            val position = (map[MediaKeys.POSITION] as? Number)?.toLong() ?: 0L
            if (position < 0) return null to "The media position can't be negative"
            val speed = (map[MediaKeys.PLAYBACK_SPEED] as? Number)?.toFloat()
            if (speed != null && speed < 0) return null to "The playback speed can't be negative"
            val state = map[MediaKeys.STATE] as? String ?: "unknown"
            val controls = (map[MediaKeys.CONTROLS] as? List<*>).orEmpty()
                .mapNotNull { MediaControl.from(it as? String) }.toSet()
            val skip = (map[MediaKeys.SKIP_INTERVAL] as? Number)?.toLong() ?: 15_000L
            if (skip <= 0) return null to "The skip interval must be positive"
            return MediaModel(
                sessionId = sessionId,
                title = title,
                artist = map[MediaKeys.ARTIST] as? String,
                album = map[MediaKeys.ALBUM] as? String,
                artwork = map[MediaKeys.ARTWORK] as? String,
                durationMs = duration,
                positionMs = position,
                speed = speed ?: if (state == "playing") 1f else 0f,
                state = state,
                controls = controls,
                skipIntervalMs = skip,
                target = CommandTarget.from(map[MediaKeys.COMMAND_TARGET] as? String)
            ) to null
        }
    }
}
