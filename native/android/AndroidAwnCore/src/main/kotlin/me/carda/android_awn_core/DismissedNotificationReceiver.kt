package me.carda.android_awn_core

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Receives the notification's deleteIntent (fired when the user swipes the
 * notification away), recovers the model from the injected payload and emits a
 * "notificationDismissed" event.
 */
class DismissedNotificationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Definitions.DISMISSED_NOTIFICATION) return

        val builder = NotificationBuilder.getNewBuilder()
        val model = builder.notificationModel(intent) ?: return
        val content = builder.contentMap(model)

        AwesomeEventsReceiver.notifyAwesomeEvent(
            Definitions.EVENT_NOTIFICATION_DISMISSED,
            builder.registerDismissedEvent(content, "Foreground")
        )
    }
}
