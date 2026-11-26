package me.carda.awesome_notifications_schedules

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.app.NotificationManagerCompat
import me.carda.android_awn_core.AwesomeEventsReceiver
import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.JsonUtils
import me.carda.android_awn_core.NotificationBuilder
import me.carda.android_awn_core.NotificationLifeCycle

/**
 * Fired by AlarmManager at the scheduled time (0.12 `ScheduledNotificationReceiver`):
 * rebuilds the notification from the serialized model and posts it, then
 * re-arms the schedule when it repeats, or drops it from the store when it
 * doesn't. Works while the app is backgrounded or killed.
 */
class ScheduledNotificationReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val json = intent.getStringExtra(ScheduleKeys.EXTRA_NOTIFICATION_JSON)
        if (json.isNullOrEmpty()) return
        val pending = goAsync() // keep the process alive while we build (I/O) + post
        Thread {
            try {
                fire(context, json)
            } catch (e: Exception) {
                Log.e(TAG, e.message ?: e.toString())
            } finally {
                pending.finish()
            }
        }.start()
    }

    internal fun fire(context: Context, json: String) {
        val model = JsonUtils.getInstance().fromJson(json)
        val builder = NotificationBuilder.getNewBuilder()
        val content = builder.contentMap(model)

        // 0.12 NotificationSender: only a notification with a title or a body is
        // displayed.
        var sent = model
        val title = content[Definitions.NOTIFICATION_TITLE] as? String
        val body = content[Definitions.NOTIFICATION_BODY] as? String
        if (!title.isNullOrEmpty() || !body.isNullOrEmpty()) {
            // Stamp the actual display time into the (already created-stamped,
            // possibly localized) model, so it is frozen into the posted
            // notification's tap PendingIntent and round-trips to the action.
            sent = builder.prepareLayout(
                context,
                builder.stampDisplayedLifecycle(
                    model,
                    displayedDate = builder.nowUtc(),
                    lifeCycle = NotificationLifeCycle.Background
                )
            )
            val notification = builder.createNotificationContent(context, sent)
            val id = builder.notificationId(sent)
            if (notification != null && id != null) {
                try {
                    NotificationManagerCompat.from(context).notify(id, notification)
                    AwesomeEventsReceiver.notifyAwesomeEvent(
                        Definitions.EVENT_NOTIFICATION_DISPLAYED,
                        builder.registerDisplayedEvent(
                            builder.contentMap(sent), NotificationLifeCycle.Background
                        )
                    )
                } catch (_: SecurityException) {
                    // POST_NOTIFICATIONS not granted (Android 13+).
                }
            }
        }

        @Suppress("UNCHECKED_CAST")
        val schedule = NotificationScheduleModel.getScheduleModelFromMap(
            model[ScheduleKeys.SCHEDULE] as? Map<String, Any?>
        ) ?: return

        if (schedule.repeats == true) {
            NotificationScheduler.schedule(context, sent, isReschedule = true)
        } else {
            builder.notificationId(model)?.let { NotificationScheduler.cancelSchedule(context, it) }
        }
    }

    companion object {
        private const val TAG = "ScheduledNotificationReceiver"
    }
}
