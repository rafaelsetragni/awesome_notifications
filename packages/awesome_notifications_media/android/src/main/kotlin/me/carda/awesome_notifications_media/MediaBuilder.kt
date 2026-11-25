package me.carda.awesome_notifications_media

import android.content.Context
import androidx.core.app.NotificationCompat
import me.carda.android_awn_core.BuildOutcome
import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.NotificationBuilder

/**
 * Takes over the `MediaPlayer` layout: the notification is the system's media
 * notification of a [MediaSessionCompat] (MediaStyle, session metadata and
 * playback state) instead of the core's 0.12 rendering.
 *
 * `build` validates and marks the model (the core then skips its built-in
 * layout); `decorate` updates the session and styles the Android builder, both
 * for an immediate notification and at a schedule's fire time.
 */
internal class MediaBuilder(inner: NotificationBuilder) : NotificationBuilder(inner) {

    override fun build(context: Context, model: Map<String, Any?>): BuildOutcome {
        val content = contentMap(model)
        val isMediaLayout = content[Definitions.NOTIFICATION_LAYOUT] == MediaKeys.LAYOUT_MEDIA_PLAYER
        val block = model[MediaKeys.MEDIA]

        if (block == null) {
            return if (isMediaLayout) invalid(
                "The MediaPlayer layout requires a NotificationMedia", ".notificationMedia"
            ) else next(context, model)
        }
        if (!isMediaLayout) return invalid(
            "A NotificationMedia requires the MediaPlayer layout", ".notificationMedia.layout"
        )
        val (media, error) = MediaModel.parse(block)
        if (media == null) return invalid(error!!, ".notificationMedia")

        // What the collapsed view and platforms without media controls show.
        val updated = content.toMutableMap()
        if ((updated[Definitions.NOTIFICATION_TITLE] as? String).isNullOrEmpty())
            updated[Definitions.NOTIFICATION_TITLE] = media.title
        if ((updated[Definitions.NOTIFICATION_BODY] as? String).isNullOrEmpty() && media.artist != null)
            updated[Definitions.NOTIFICATION_BODY] = media.artist
        @Suppress("UNCHECKED_CAST")
        val payload = (updated[Definitions.NOTIFICATION_PAYLOAD] as? Map<String, Any?>)
            ?.toMutableMap() ?: mutableMapOf()
        payload[MediaKeys.PAYLOAD_SESSION_ID] = media.sessionId
        updated[Definitions.NOTIFICATION_PAYLOAD] = payload

        return next(context, model.toMutableMap().apply {
            this[Definitions.NOTIFICATION_CONTENT] = updated
            this[CUSTOM_LAYOUT] = true
        })
    }

    override fun decorate(
        context: Context,
        model: Map<String, Any?>,
        builder: NotificationCompat.Builder
    ) {
        val isMediaLayout =
            contentMap(model)[Definitions.NOTIFICATION_LAYOUT] == MediaKeys.LAYOUT_MEDIA_PLAYER
        val media = model[MediaKeys.MEDIA]?.let { MediaModel.parse(it).first }
        if (media != null && isMediaLayout && hasCustomLayout(model)) {
            MediaSessions.render(context, media, model, builder)
        }
        super.decorate(context, model, builder)
    }

    private fun invalid(message: String, detail: String) = BuildOutcome.Failed(
        MediaKeys.CODE_INVALID_ARGUMENTS, message, MediaKeys.DETAILED_INVALID_ARGUMENTS + detail
    )
}
