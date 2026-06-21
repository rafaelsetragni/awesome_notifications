package me.carda.android_awn_core

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.RemoteInput

/**
 * Receives the PendingIntent of a non-foreground action button (KeepOnTop,
 * SilentAction, DismissAction, …). It recovers the notification model and the
 * pressed button key (plus any typed text for reply buttons), auto-dismisses the
 * notification when requested, and emits the matching action/dismiss event.
 *
 * Foreground (`Default`) buttons instead open the app and are handled by the
 * plugin's onNewIntent.
 */
class NotificationButtonReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (!action.startsWith(Definitions.NOTIFICATION_BUTTON_ACTION_PREFIX)) return

        val builder = NotificationBuilder.getNewBuilder()
        val model = builder.notificationModel(intent) ?: return
        var content = builder.contentMap(model)

        val buttonKey = intent.getStringExtra(Definitions.NOTIFICATION_BUTTON_KEY_PRESSED) ?: ""
        val button = builder.findButton(model, buttonKey)

        // Carry the pressed key + any typed reply back to Dart.
        content = content + (Definitions.NOTIFICATION_BUTTON_KEY_PRESSED to buttonKey)
        RemoteInput.getResultsFromIntent(intent)
            ?.getCharSequence(Definitions.NOTIFICATION_BUTTON_KEY_INPUT)
            ?.let { content = content + (Definitions.NOTIFICATION_BUTTON_KEY_INPUT to it.toString()) }

        // Auto-dismiss the visible notification when the button requests it.
        if (builder.shouldButtonAutoDismiss(button)) {
            builder.readId(content)?.let { NotificationManagerCompat.from(context).cancel(it) }
        }

        if (builder.buttonActionType(button).endsWith("DismissAction")) {
            AwesomeEventsReceiver.notifyAwesomeEvent(
                Definitions.EVENT_NOTIFICATION_DISMISSED,
                builder.registerDismissedEvent(content, "Background")
            )
        } else {
            AwesomeEventsReceiver.notifyAwesomeEvent(
                Definitions.EVENT_DEFAULT_ACTION,
                builder.registerActionEvent(content, "Background", builder.buttonActionType(button))
            )
        }
    }
}
