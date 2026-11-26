package me.carda.awesome_notifications_calls

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import me.carda.android_awn_core.ActionType
import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.JsonUtils
import me.carda.android_awn_core.NotificationBuilder

/**
 * The Answer button: applies the answer to the system call at once (ongoing,
 * ringing stopped), then opens the app with the `accept` action, as a
 * foreground notification button does (Android 12+ forbids opening an
 * activity from a receiver; this one is an activity itself, shown over the
 * lock screen, without a window of its own).
 */
class CallAnswerActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
        }
        answer(intent)
        finish()
    }

    private fun answer(intent: Intent) {
        val callId = intent.getStringExtra(CallKeys.EXTRA_CALL_ID) ?: return
        val sent = NotificationBuilder.getNewBuilder().notificationModel(intent) ?: return
        val model = Calls.entry(callId)?.model ?: sent
        val call = Calls.entry(callId)?.call ?: CallModel.parse(model[CallKeys.CALL]).first ?: return
        if (call.state != CallState.incoming) return openApp(callId, null)

        // The system call first; the stream at once, the action event with the app.
        Calls.command(this, CallAction.accept, callId, sent, toActionEvent = false)
        openApp(callId, if (call.target.toActionEvent) model else null)
    }

    /** The app's launch activity, with the core's foreground button action when [model] is given. */
    private fun openApp(callId: String, model: Map<String, Any?>?) {
        val launch = packageManager.getLaunchIntentForPackage(packageName) ?: return
        launch.putExtra(CallKeys.EXTRA_CALL_ID, callId)
        if (model != null) {
            val key = CallAction.accept.key
            @Suppress("UNCHECKED_CAST")
            val buttons = (model[Definitions.NOTIFICATION_BUTTONS] as? List<Map<String, Any?>>).orEmpty() +
                // The package keeps the call's notification: the core must not dismiss it.
                listOf(Calls.syntheticButton(CallAction.accept, ActionType.Default))
            val withButton = model.toMutableMap().apply { this[Definitions.NOTIFICATION_BUTTONS] = buttons }
            launch.action = Definitions.NOTIFICATION_BUTTON_ACTION_PREFIX + "_" + key
            launch.putExtra(Definitions.NOTIFICATION_JSON, JsonUtils.getInstance().toJson(withButton))
            launch.putExtra(Definitions.NOTIFICATION_BUTTON_KEY_PRESSED, key)
        }
        launch.addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        )
        startActivity(launch)
    }
}
