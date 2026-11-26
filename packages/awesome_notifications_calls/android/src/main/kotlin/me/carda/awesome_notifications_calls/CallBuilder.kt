package me.carda.awesome_notifications_calls

import android.app.Notification
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import me.carda.android_awn_core.BuildOutcome
import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.NotificationBuilder

/**
 * Takes over a notification carrying a `call` block: the system's call
 * notification (CallStyle, the full-screen intent of an incoming call, a
 * `phoneCall` foreground service, the Telecom call) instead of the core's
 * rendering. A notification without a `call` block is left to the core,
 * `NotificationCategory.Call` included (0.12 behavior).
 *
 * The core's content options stay as the core applies them; the call adds
 * what its state needs on top (decided once, here, so nothing is applied twice):
 * - incoming: full-screen intent (the content's tap intent, as the core's
 *   `fullScreenIntent`), the ringtone looping until answered (FLAG_INSISTENT,
 *   as the core's `Call` category) with the channel's sound, alerting once;
 * - outgoing / ongoing / held: silent, no full-screen intent, never
 *   insistent (even with the `Call` category), the call's timer;
 * - every live state: ongoing, not auto-cancelled and not clearable.
 */
internal class CallBuilder(inner: NotificationBuilder) : NotificationBuilder(inner) {

    override fun build(context: Context, model: Map<String, Any?>): BuildOutcome {
        val block = model[CallKeys.CALL] ?: return next(context, model)

        // Push or local, a call is shown now: it can't wait for a schedule.
        if (model[CallKeys.SCHEDULE] != null) return invalid(
            "A call notification cannot be scheduled", ".schedule"
        )
        val (call, error) = CallModel.parse(block)
        if (call == null) return invalid(error!!, "")

        val content = contentMap(model)
        val id = notificationId(model)
        val channelKey = content[Definitions.NOTIFICATION_CHANNEL_KEY] as? String
        if (!call.state.isLive) {
            Calls.finish(context, call, id, channelKey)
            return BuildOutcome.Answered(true)
        }
        if (id == null) return next(context, model)

        var prepared = Calls.prepare(model, call)
        // Android 12+ shows an ongoing CallStyle only for a foreground service
        // (an incoming one has its full-screen intent): the service must be in
        // the foreground with this notification before the core posts it.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            call.state != CallState.incoming &&
            !Calls.foreground.isShowing(id)
        ) {
            val styled = next(context, prepared)
            if (styled !is BuildOutcome.Post) return styled
            adjustFlags(call, styled.notification)
            if (Calls.foreground.show(context, id, channelKey, styled.notification, wait = true)) {
                Calls.posted(context, call, styled)
                return styled
            }
            // No service: the same notification without CallStyle.
            prepared = prepared.toMutableMap().apply { this[CallKeys.MODEL_PLAIN] = true }
        }

        val outcome = next(context, prepared)
        if (outcome is BuildOutcome.Post) {
            adjustFlags(call, outcome.notification)
            Calls.posted(context, call, outcome)
        }
        return outcome
    }

    override fun decorate(
        context: Context,
        model: Map<String, Any?>,
        builder: NotificationCompat.Builder
    ) {
        val call = if (hasCustomLayout(model)) model[CallKeys.CALL]?.let { CallModel.parse(it).first } else null
        if (call != null && call.state.isLive) CallNotifications.render(context, call, model, builder)
        super.decorate(context, model, builder)
    }

    private fun invalid(message: String, detail: String) = BuildOutcome.Failed(
        CallKeys.CODE_INVALID_ARGUMENTS, message, CallKeys.DETAILED_INVALID_CALL + detail
    )

    companion object {
        /**
         * After the core's flags (its 0.12 `Call` category flags run after the
         * build): only a ringing call loops its sound; every live call stays.
         */
        fun adjustFlags(call: CallModel, notification: Notification) {
            var flags = notification.flags or Notification.FLAG_NO_CLEAR or Notification.FLAG_ONGOING_EVENT
            flags = if (call.state == CallState.incoming) flags or Notification.FLAG_INSISTENT
            else flags and Notification.FLAG_INSISTENT.inv()
            notification.flags = flags
        }
    }
}
