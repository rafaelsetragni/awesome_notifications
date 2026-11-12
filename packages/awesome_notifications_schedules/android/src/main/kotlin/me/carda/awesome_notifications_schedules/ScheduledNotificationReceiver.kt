package me.carda.awesome_notifications_schedules

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationManagerCompat
import me.carda.android_awn_core.AwesomeEventsReceiver
import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.JsonUtils
import me.carda.android_awn_core.NotificationBuilder
import me.carda.android_awn_core.NotificationLifeCycle

/**
 * Fired by AlarmManager at the scheduled time: rebuilds the notification from the
 * serialized model and posts it, then re-schedules it when the schedule repeats.
 * Works while the app is backgrounded or killed.
 */
class ScheduledNotificationReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val json = intent.getStringExtra(NotificationScheduler.EXTRA_MODEL) ?: return
        val pending = goAsync() // keep the process alive while we build (I/O) + post
        Thread {
            try {
                val model = JsonUtils.getInstance().fromJson(json)
                val builder = NotificationBuilder.getNewBuilder()
                // Stamp the actual display time into the (already created-stamped,
                // possibly localized) model, so it is frozen into the posted
                // notification's tap PendingIntent and round-trips to the action.
                val stamped = builder.stampDisplayedLifecycle(
                    model,
                    displayedDate = builder.nowUtc(),
                    lifeCycle = NotificationLifeCycle.Background)
                val notification = builder.createNotificationContent(context, stamped)
                val id = builder.notificationId(stamped)
                if (notification != null && id != null) {
                    try {
                        NotificationManagerCompat.from(context).notify(id, notification)
                        AwesomeEventsReceiver.notifyAwesomeEvent(
                            Definitions.EVENT_NOTIFICATION_DISPLAYED,
                            builder.registerDisplayedEvent(
                                builder.contentMap(stamped), NotificationLifeCycle.Background)
                        )
                    } catch (_: SecurityException) {
                        // POST_NOTIFICATIONS not granted (Android 13+).
                    }
                }

                // Re-schedule the next occurrence for a repeating schedule.
                @Suppress("UNCHECKED_CAST")
                val schedule = model[ScheduleKeys.SCHEDULE] as? Map<String, Any?>
                if (schedule?.get(ScheduleKeys.REPEATS) == true) {
                    NotificationScheduler().schedule(context, model)
                }
            } finally {
                pending.finish()
            }
        }.start()
    }
}
