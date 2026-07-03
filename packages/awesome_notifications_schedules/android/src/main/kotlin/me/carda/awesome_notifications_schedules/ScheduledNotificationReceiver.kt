package me.carda.awesome_notifications_schedules

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationManagerCompat
import me.carda.android_awn_core.JsonUtils
import me.carda.android_awn_core.NotificationBuilder

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
                val notification = builder.build(context, model)
                val id = builder.notificationId(model)
                if (notification != null && id != null) {
                    try {
                        NotificationManagerCompat.from(context).notify(id, notification)
                    } catch (_: SecurityException) {
                        // POST_NOTIFICATIONS not granted (Android 13+).
                    }
                }

                // Re-schedule the next occurrence for a repeating schedule.
                @Suppress("UNCHECKED_CAST")
                val schedule = model["schedule"] as? Map<String, Any?>
                if (schedule?.get("repeats") == true) {
                    NotificationScheduler().schedule(context, model)
                }
            } finally {
                pending.finish()
            }
        }.start()
    }
}
