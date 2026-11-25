package me.carda.android_awn_core

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
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

        val model = NotificationBuilder.getNewBuilder().notificationModel(intent) ?: return
        val buttonKey = intent.getStringExtra(Definitions.NOTIFICATION_BUTTON_KEY_PRESSED) ?: ""
        // Any typed reply travels as the button's input.
        val input = RemoteInput.getResultsFromIntent(intent)
            ?.getCharSequence(Definitions.NOTIFICATION_BUTTON_KEY_INPUT)
            ?.toString()
        // The app may be killed: keep the receiver alive while the action runs
        // in a background isolate.
        val pending: PendingResult? = goAsync()
        NotificationActions.dispatch(context, model, buttonKey, input) { pending?.finish() }
    }
}
