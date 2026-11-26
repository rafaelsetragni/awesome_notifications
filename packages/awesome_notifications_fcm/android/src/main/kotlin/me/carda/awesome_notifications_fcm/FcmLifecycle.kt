package me.carda.awesome_notifications_fcm

import android.app.ActivityManager
import android.content.Context
import me.carda.android_awn_core.NotificationLifeCycle

/**
 * Best-effort app lifecycle for stamping a received push, without pulling in
 * androidx.lifecycle. Reads the process importance from ActivityManager:
 *  - a foreground process -> Foreground,
 *  - a live-but-background process -> Background,
 *  - no live process record -> Terminated.
 */
object FcmLifecycle {
    fun current(context: Context): NotificationLifeCycle {
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
            ?: return NotificationLifeCycle.Terminated
        val myPid = android.os.Process.myPid()
        val process = am.runningAppProcesses?.firstOrNull { it.pid == myPid }
            ?: return NotificationLifeCycle.Terminated
        return when (process.importance) {
            ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND,
            ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND_SERVICE,
            ActivityManager.RunningAppProcessInfo.IMPORTANCE_VISIBLE ->
                NotificationLifeCycle.Foreground
            else -> NotificationLifeCycle.Background
        }
    }
}
