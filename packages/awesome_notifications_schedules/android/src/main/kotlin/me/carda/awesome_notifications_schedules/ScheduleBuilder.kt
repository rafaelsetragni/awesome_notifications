package me.carda.awesome_notifications_schedules

import android.content.Context
import me.carda.android_awn_core.AwesomeEventsReceiver
import me.carda.android_awn_core.BuildOutcome
import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.NotificationBuilder
import me.carda.android_awn_core.NotificationLifeCycle
import me.carda.android_awn_core.NotificationSource

/**
 * Builder decorator that intercepts the build of a notification carrying a
 * `schedule` and registers it for later delivery (AlarmManager) instead of
 * posting it now. It inherits the core [NotificationBuilder], overrides [build],
 * and — when there is no schedule (or it can't be scheduled) — delegates to the
 * wrapped builder via [next] for immediate delivery.
 *
 * Registered with a LOW priority so it ends up innermost: content decorators
 * (e.g. localization) transform the model first, and the already-transformed
 * model is what gets frozen into the scheduled payload.
 */
class ScheduleBuilder(inner: NotificationBuilder) : NotificationBuilder(inner) {

    private val scheduler = NotificationScheduler()

    override fun build(context: Context, model: Map<String, Any?>): BuildOutcome {
        @Suppress("UNCHECKED_CAST")
        val schedule = model[ScheduleKeys.SCHEDULE] as? Map<String, Any?>
            ?: return next(context, model) // no schedule → immediate delivery

        // Stamp the created lifecycle now (source = Schedule), so it is frozen into
        // the scheduled payload and round-trips to the displayed/action events at
        // fire time.
        val stamped = stampCreatedLifecycle(model, source = NotificationSource.Schedule)

        return if (scheduler.schedule(context, stamped)) {
            // Parity with iOS: the created event fires when the notification is
            // registered (scheduled), not when it later displays.
            AwesomeEventsReceiver.notifyAwesomeEvent(
                Definitions.EVENT_NOTIFICATION_CREATED,
                registerCreatedEvent(contentMap(stamped), NotificationLifeCycle.Foreground)
            )
            BuildOutcome.Handled // registered with AlarmManager; core must not post now
        } else {
            next(context, model) // unschedulable (past/invalid) → deliver now
        }
    }
}
