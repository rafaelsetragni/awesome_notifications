package me.carda.awesome_notifications_calls

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import me.carda.android_awn_core.NotificationBuilder

/**
 * Receives a call's notification buttons (decline, hang up, mute, hold) and its
 * ring timeout alarm. The intent carries the notification's model, so a killed
 * app still applies and gets the command (a background isolate runs it).
 */
class CallCommandReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val callId = intent.getStringExtra(CallKeys.EXTRA_CALL_ID) ?: return
        val model = NotificationBuilder.getNewBuilder().notificationModel(intent)
        when (intent.action) {
            CallKeys.INTENT_COMMAND -> {
                val action = CallAction.from(intent.getStringExtra(CallKeys.EXTRA_ACTION)) ?: return
                val pending: PendingResult? = goAsync()
                Calls.command(context, action, callId, model) { pending?.finish() }
            }
            CallKeys.INTENT_TIMEOUT -> {
                val pending: PendingResult? = goAsync()
                Calls.timeout(context, callId, model) { pending?.finish() }
            }
        }
    }
}
