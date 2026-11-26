package me.carda.awesome_notifications_calls

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build

/**
 * The package's own channel for the calls that don't ring (outgoing, ongoing,
 * held): no sound, no vibration. Moving a ringing call's notification here is
 * what stops the ringtone and vibration the call's channel was looping
 * (FLAG_INSISTENT): Android stops them only for an update without a sound.
 */
internal object SilentCallChannel {

    const val ID = "awn_calls_silent"

    /** Creates the channel once (Android 8+), named with [name]. */
    fun id(context: Context, name: String): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = context.getSystemService(NotificationManager::class.java)
            if (manager.getNotificationChannel(ID) == null) {
                manager.createNotificationChannel(
                    NotificationChannel(ID, name, NotificationManager.IMPORTANCE_DEFAULT).apply {
                        setSound(null, null)
                        enableVibration(false)
                        enableLights(false)
                        setShowBadge(false)
                    }
                )
            }
        }
        return ID
    }
}
