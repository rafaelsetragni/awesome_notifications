package me.carda.android_awn_core

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Receives the notification's deleteIntent (fired when the user swipes the
 * notification away) and emits a "notificationDismissed" event.
 */
class DismissedNotificationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Definitions.ACTION_DISMISSED_NOTIFICATION) return
        val json = intent.getStringExtra(Definitions.NOTIFICATION_JSON) ?: return
        val content = MapJson.fromJson(json)
        AwesomeEventSink.emit(
            Definitions.EVENT_NOTIFICATION_DISMISSED,
            content + mapOf(Definitions.ACTION_LIFECYCLE to "Foreground")
        )
    }
}
