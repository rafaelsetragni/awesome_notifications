package me.carda.awesome_notifications_schedules

import android.content.Context
import me.carda.android_awn_core.CancelInterceptor

/**
 * Hooks the core's `cancel*` so canceling a notification also drops its pending
 * AlarmManager schedule (which `NotificationManager.cancel` would not touch).
 *
 * Only cancel-by-id is honored for now; the by-channel/by-group/all variants need
 * a persistent schedule store (follow-up), so they stay no-ops via the interface
 * defaults.
 */
class ScheduleCancelInterceptor : CancelInterceptor {

    private val scheduler = NotificationScheduler()

    override fun onCancel(context: Context, id: Int) {
        scheduler.cancelSchedule(context, id)
    }
}
