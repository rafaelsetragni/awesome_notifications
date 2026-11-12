package me.carda.awesome_notifications_schedules

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import java.util.Calendar
import java.util.TimeZone
import me.carda.android_awn_core.JsonUtils
import me.carda.android_awn_core.NotificationBuilder

/**
 * Schedules notifications for later delivery via AlarmManager and cancels them.
 *
 * A notification carrying a `schedule` map is registered as a one-shot alarm
 * whose PendingIntent (to [ScheduledNotificationReceiver]) carries the serialized
 * model; the receiver rebuilds and posts it, re-scheduling if the schedule
 * repeats. Driven by [ScheduleBuilder] (delivery) and [ScheduleCancelInterceptor]
 * (cancellation) — the decorator's hooks into the core.
 *
 * Note: without a persistent store, `cancel*ByChannelKey/ByGroupKey/all` and
 * reboot re-scheduling are not yet supported (follow-up); cancel-by-id works.
 */
class NotificationScheduler {

    /** Registers [model] for later delivery; returns false if it can't be scheduled. */
    fun schedule(context: Context, model: Map<String, Any?>): Boolean {
        @Suppress("UNCHECKED_CAST")
        val schedule = model[ScheduleKeys.SCHEDULE] as? Map<String, Any?> ?: return false
        val id = NotificationBuilder.getNewBuilder().notificationId(model) ?: return false
        val fireAt = nextFireTime(schedule) ?: return false

        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pending = firePendingIntent(context, id, model)
        val allowWhileIdle = schedule[ScheduleKeys.ALLOW_WHILE_IDLE] as? Boolean ?: false

        if (allowWhileIdle && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, fireAt, pending)
        } else {
            am.setExact(AlarmManager.RTC_WAKEUP, fireAt, pending)
        }
        return true
    }

    fun cancelSchedule(context: Context, id: Int) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.cancel(cancelPendingIntent(context, id))
    }

    companion object {
        const val ACTION = "me.carda.awesome_notifications_schedules.FIRE"
        const val EXTRA_MODEL = "notificationModel"

        private fun firePendingIntent(
            context: Context, id: Int, model: Map<String, Any?>
        ): PendingIntent {
            val intent = Intent(context, ScheduledNotificationReceiver::class.java).apply {
                action = ACTION
                putExtra(EXTRA_MODEL, JsonUtils.getInstance().toJson(model))
            }
            return PendingIntent.getBroadcast(context, id, intent, flags())
        }

        private fun cancelPendingIntent(context: Context, id: Int): PendingIntent {
            val intent = Intent(context, ScheduledNotificationReceiver::class.java)
                .apply { action = ACTION }
            return PendingIntent.getBroadcast(context, id, intent, flags())
        }

        private fun flags(): Int {
            var f = PendingIntent.FLAG_UPDATE_CURRENT
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) f = f or PendingIntent.FLAG_IMMUTABLE
            return f
        }

        /** Next fire time (epoch ms) for an interval or calendar schedule, or null. */
        fun nextFireTime(schedule: Map<String, Any?>): Long? {
            val now = System.currentTimeMillis()
            (schedule[ScheduleKeys.INTERVAL] as? Number)?.let { return now + it.toLong() * 1000L }
            return nextCalendarTime(schedule, now)
        }

        private fun nextCalendarTime(schedule: Map<String, Any?>, now: Long): Long? {
            if (ScheduleKeys.CALENDAR_COMPONENTS.none { schedule[it] != null }) return null

            val tz = (schedule[ScheduleKeys.TIME_ZONE] as? String)?.let { TimeZone.getTimeZone(it) }
                ?: TimeZone.getDefault()
            val cal = Calendar.getInstance(tz).apply {
                timeInMillis = now
                set(Calendar.MILLISECOND, 0)
            }
            (schedule[ScheduleKeys.YEAR] as? Number)?.let { cal.set(Calendar.YEAR, it.toInt()) }
            (schedule[ScheduleKeys.MONTH] as? Number)?.let { cal.set(Calendar.MONTH, it.toInt() - 1) }
            (schedule[ScheduleKeys.DAY] as? Number)?.let { cal.set(Calendar.DAY_OF_MONTH, it.toInt()) }
            (schedule[ScheduleKeys.HOUR] as? Number)?.let { cal.set(Calendar.HOUR_OF_DAY, it.toInt()) }
            (schedule[ScheduleKeys.MINUTE] as? Number)?.let { cal.set(Calendar.MINUTE, it.toInt()) }
            (schedule[ScheduleKeys.SECOND] as? Number)?.let { cal.set(Calendar.SECOND, it.toInt()) }
            // Dart weekday: 1=Monday..7=Sunday; Calendar: 1=Sunday..7=Saturday.
            (schedule[ScheduleKeys.WEEKDAY] as? Number)?.let { cal.set(Calendar.DAY_OF_WEEK, (it.toInt() % 7) + 1) }

            // If the computed time is already past, advance to the next occurrence
            // based on the coarsest unspecified period.
            if (cal.timeInMillis <= now) {
                when {
                    schedule[ScheduleKeys.WEEKDAY] != null -> cal.add(Calendar.WEEK_OF_YEAR, 1)
                    schedule[ScheduleKeys.DAY] == null && schedule[ScheduleKeys.HOUR] != null -> cal.add(Calendar.DAY_OF_MONTH, 1)
                    schedule[ScheduleKeys.DAY] != null && schedule[ScheduleKeys.MONTH] == null -> cal.add(Calendar.MONTH, 1)
                    schedule[ScheduleKeys.MONTH] != null && schedule[ScheduleKeys.YEAR] == null -> cal.add(Calendar.YEAR, 1)
                    else -> return null // fully-specified past date: no next occurrence
                }
            }
            return cal.timeInMillis
        }
    }
}
