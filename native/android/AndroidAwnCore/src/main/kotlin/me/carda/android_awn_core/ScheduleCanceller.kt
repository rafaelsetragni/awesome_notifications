package me.carda.android_awn_core

import android.content.Context

/**
 * Decorator seam for canceling scheduled creations (AlarmManager) without the
 * core depending on the scheduling feature.
 *
 * On Android a schedule is an AlarmManager PendingIntent, which
 * `NotificationManagerCompat.cancel` does NOT touch. So **dismiss** only removes
 * the visible notification from the status bar, while **cancel** must also cancel
 * the pending scheduled creation. The scheduling decorator registers an
 * implementation via [AwesomeNotifications.scheduleCanceller]; in the bare core
 * it is null and cancel coincides with dismiss.
 */
interface ScheduleCanceller {
    fun cancelSchedule(context: Context, id: Int)
    fun cancelSchedulesByChannelKey(context: Context, channelKey: String)
    fun cancelSchedulesByGroupKey(context: Context, groupKey: String)
    fun cancelAllSchedules(context: Context)
}
