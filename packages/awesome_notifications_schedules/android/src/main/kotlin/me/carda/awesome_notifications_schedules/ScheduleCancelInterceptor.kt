package me.carda.awesome_notifications_schedules

import android.content.Context
import me.carda.android_awn_core.CancelInterceptor

/**
 * Hooks the core's `cancel*` so canceling notifications also cancels their
 * schedules (alarm + store), like 0.12's CancellationManager did:
 * cancelNotification(id) / cancelNotificationsByChannelKey / …ByGroupKey /
 * cancelAllNotifications = dismiss + cancel the matching schedules.
 */
class ScheduleCancelInterceptor : CancelInterceptor {

    override fun onCancel(context: Context, id: Int) {
        // 0.12 rejected negative ids before touching anything.
        if (id < 0) return
        NotificationScheduler.cancelSchedule(context, id)
    }

    override fun onCancelAll(context: Context) {
        NotificationScheduler.cancelAllSchedules(context)
    }

    override fun onCancelByChannelKey(context: Context, channelKey: String) {
        if (channelKey.isEmpty()) return
        NotificationScheduler.cancelSchedulesByChannelKey(context, channelKey)
    }

    override fun onCancelByGroupKey(context: Context, groupKey: String) {
        if (groupKey.isEmpty()) return
        NotificationScheduler.cancelSchedulesByGroupKey(context, groupKey)
    }
}
