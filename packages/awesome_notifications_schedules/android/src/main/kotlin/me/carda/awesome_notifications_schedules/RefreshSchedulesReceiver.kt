package me.carda.awesome_notifications_schedules

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * 0.12 `RefreshSchedulesReceiver`: after a reboot, an app update or an exact-alarm
 * permission change, AlarmManager has lost (or may have lost) the alarms, so every
 * stored schedule is re-armed. Like 0.12, receiving BOOT_COMPLETED still requires
 * the app to declare `android.permission.RECEIVE_BOOT_COMPLETED`.
 */
class RefreshSchedulesReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == null) return
        val pending = goAsync()
        Thread {
            try {
                NotificationScheduler.refreshScheduledNotifications(context)
            } catch (e: Exception) {
                Log.e("RefreshSchedulesReceiver", e.message ?: e.toString())
            } finally {
                pending.finish()
            }
        }.start()
    }
}
