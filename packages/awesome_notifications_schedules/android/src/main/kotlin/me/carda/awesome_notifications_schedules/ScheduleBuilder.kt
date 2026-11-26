package me.carda.awesome_notifications_schedules

import android.content.Context
import androidx.core.app.NotificationManagerCompat
import me.carda.android_awn_core.BuildOutcome
import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.NotificationBuilder

/**
 * Builder decorator that intercepts the build of a notification carrying a
 * `schedule` and registers it for later delivery ([NotificationScheduler])
 * instead of posting it now; without a schedule it delegates to the wrapped
 * builder via [next] for immediate delivery.
 *
 * It answers the create call exactly like 0.12 did on Android:
 *  - scheduled (or no next date, which is not stored): `false` — 0.12's
 *    scheduler completed with `handle(exception != null, …)`;
 *  - invalid schedule / disabled channel / notifications not allowed: an error
 *    (PlatformException on the Dart side).
 *
 * Registered with a LOW priority so it ends up innermost: content decorators
 * (e.g. localization) transform the model first, and the already-transformed
 * model is what gets frozen into the scheduled payload.
 */
class ScheduleBuilder(inner: NotificationBuilder) : NotificationBuilder(inner) {

    override fun build(context: Context, model: Map<String, Any?>): BuildOutcome {
        @Suppress("UNCHECKED_CAST")
        val scheduleData = model[ScheduleKeys.SCHEDULE] as? Map<String, Any?>

        // 0.12: an empty/unrecognized schedule block parsed to a null schedule,
        // so the notification was delivered immediately.
        if (NotificationScheduleModel.getScheduleModelFromMap(scheduleData) == null)
            return deliverNow(context, model)

        return try {
            // 0.12 AwesomeNotifications.createNotification: global permission first.
            if (!NotificationManagerCompat.from(context).areNotificationsEnabled())
                throw ScheduleException(
                    ScheduleException.CODE_INSUFFICIENT_PERMISSIONS,
                    "Notifications are disabled",
                    ScheduleException.DETAILED_INSUFFICIENT_PERMISSIONS + ".global"
                )
            NotificationScheduler.schedule(context, model, isReschedule = false)
            BuildOutcome.Answered(false)
        } catch (e: ScheduleException) {
            BuildOutcome.Failed(e.code, e.message, e.detailedCode)
        } catch (e: Exception) {
            BuildOutcome.Failed(
                ScheduleException.CODE_UNKNOWN_EXCEPTION,
                e.message ?: e.javaClass.simpleName,
                ScheduleException.DETAILED_UNEXPECTED_ERROR
            )
        }
    }

    /**
     * Immediate delivery. Like 0.12's NotificationSender, a freshly created
     * notification (not yet stamped as created) replaces any stored schedule with
     * the same id in the schedule store.
     */
    private fun deliverNow(context: Context, model: Map<String, Any?>): BuildOutcome {
        val content = contentMap(model)
        val freshlyCreated = content[Definitions.NOTIFICATION_CREATED_DATE] == null
        val outcome = next(context, model)
        if (freshlyCreated && outcome is BuildOutcome.Post) {
            try {
                ScheduleManager.cancelScheduleById(context, outcome.id)
            } catch (_: Exception) {
                // The schedule store is best-effort here; never block the delivery.
            }
        }
        return outcome
    }
}
