package me.carda.android_awn_core

import android.app.Notification

/**
 * The result of running the builder decorator chain for a notification.
 *
 * Unlike iOS, Android has no OS-level delivery trigger: a decorator that defers
 * delivery (e.g. scheduling via AlarmManager) takes over posting itself and
 * reports [Handled], so the core does not post the notification now.
 */
sealed class BuildOutcome {
    /** Post this freshly built notification now. */
    data class Post(
        val id: Int,
        val notification: Notification,
        /** The (possibly decorator-transformed) model, for stamping events. */
        val model: Map<String, Any?>
    ) : BuildOutcome()

    /** A decorator took over delivery (e.g. scheduled it); do not post now. */
    object Handled : BuildOutcome()

    /** The model was invalid; nothing to post. */
    object Invalid : BuildOutcome()
}
