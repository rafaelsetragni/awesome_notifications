package me.carda.awesome_notifications_live_activities

import android.content.Context
import androidx.core.app.NotificationCompat
import me.carda.android_awn_core.BuildOutcome
import me.carda.android_awn_core.NotificationBuilder

/**
 * Takes over a notification carrying a `liveActivity` block: Android 16+
 * posts it as a Live Update (a promoted ongoing notification: status bar chip,
 * lock screen, Always-On Display) with ProgressStyle; older Android, as an
 * ongoing progress notification (the 0.12 ProgressBar look). A notification
 * without the block is left to the core.
 *
 * The core's content options stay as the core applies them (title, body,
 * large icon, buttons, channel); [LiveNotifications] adds the activity's on
 * top, decided once, here, so nothing is applied twice.
 */
internal class LiveBuilder(inner: NotificationBuilder) : NotificationBuilder(inner) {

    override fun build(context: Context, model: Map<String, Any?>): BuildOutcome {
        val block = model[LiveKeys.LIVE_ACTIVITY]
        if (block == null) {
            // A plain notification on an activity's id replaces the activity.
            val outcome = next(context, model)
            if (outcome is BuildOutcome.Post) LiveActivities.replacedByPlain(context, outcome.id)
            return outcome
        }

        // Shown now and updated in place: it can't wait for a schedule.
        if (model[LiveKeys.SCHEDULE] != null) return invalid("Live activities can't be scheduled", ".schedule")
        val id = notificationId(model) ?: return invalid("A live activity needs the notification id", "")
        val (live, error) = LiveActivityModel.parse(block, id)
        if (live == null) return invalid(error!!, "")
        live.customLayout?.let { name ->
            if (LiveCustomLayout.layoutId(context, name) == 0)
                return invalid("The live activity's customLayout $name is not a layout of the app (res/layout/$name.xml)", "")
        }

        val removalAt = LiveActivities.removalAt(live)
        if ((live.ended && live.dismissal == LiveDismissal.Immediate) ||
            (removalAt != null && removalAt <= LiveActivities.clock())
        ) {
            LiveActivities.goneAtOnce(context, live, id)
            return BuildOutcome.Answered(true)
        }

        val outcome = next(context, LiveActivities.prepare(model, live))
        if (outcome is BuildOutcome.Post) LiveActivities.posted(context, live, outcome)
        return outcome
    }

    override fun decorate(context: Context, model: Map<String, Any?>, builder: NotificationCompat.Builder) {
        val live = if (hasCustomLayout(model)) {
            model[LiveKeys.LIVE_ACTIVITY]?.let { block ->
                notificationId(model)?.let { LiveActivityModel.parse(block, it).first }
            }
        } else null
        if (live != null) LiveNotifications.render(context, live, model, builder)
        super.decorate(context, model, builder)
    }

    private fun invalid(message: String, detail: String) = BuildOutcome.Failed(
        LiveKeys.CODE_INVALID_ARGUMENTS, message, LiveKeys.DETAILED_INVALID_LIVE_ACTIVITY + detail
    )
}
