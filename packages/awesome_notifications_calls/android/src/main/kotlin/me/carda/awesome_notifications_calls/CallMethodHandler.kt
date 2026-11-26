package me.carda.awesome_notifications_calls

import android.app.NotificationManager
import android.content.Context
import android.os.Build
import me.carda.android_awn_core.AwesomeMethodHandler

/** Answers the AwesomeNotificationsCalls channel methods. */
internal class CallMethodHandler(
    private val context: Context,
    /** Opens the system page of full-screen calls and answers when the user is back. */
    private val requestFullScreenIntent: ((Boolean) -> Unit) -> Unit
) : AwesomeMethodHandler {

    override fun handle(method: String, arguments: Any?, result: (Any?) -> Unit): Boolean =
        handle(method, arguments, result) { _, _, _ -> result(null) }

    override fun handle(
        method: String,
        arguments: Any?,
        result: (Any?) -> Unit,
        error: (code: String, message: String?, details: Any?) -> Unit
    ): Boolean {
        when (method) {
            CallKeys.METHOD_END -> {
                val args = arguments as? Map<*, *>
                val callId = args?.get(CallKeys.CALL_ID) as? String
                if (callId.isNullOrBlank()) {
                    error(
                        CallKeys.CODE_INVALID_ARGUMENTS, "callEnd needs a callId",
                        "arguments.invalid.callEnd"
                    )
                } else {
                    Calls.endCall(context, callId, EndReason.from(args[CallKeys.REASON]))
                    result(true)
                }
            }
            CallKeys.METHOD_ACTIVE_CALLS -> result(Calls.activeCalls())
            CallKeys.METHOD_VOIP_TOKEN -> result(null)
            CallKeys.METHOD_CAN_USE_FULL_SCREEN_INTENT -> result(canUseFullScreenIntent(context))
            CallKeys.METHOD_REQUEST_FULL_SCREEN_INTENT -> {
                if (canUseFullScreenIntent(context)) result(true) else requestFullScreenIntent { result(it) }
            }
            CallKeys.METHOD_CAPABILITIES -> result(
                mapOf(
                    // The system's call notification (CallStyle) from Android 12.
                    "systemCallUI" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S),
                    "lockScreen" to canUseFullScreenIntent(context),
                    "muteAndHold" to true,
                    "push" to true
                )
            )
            else -> return false
        }
        return true
    }

    companion object {
        /** Android 14+: the user can revoke full-screen intents. Allowed before. */
        fun canUseFullScreenIntent(context: Context): Boolean {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return true
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            return manager.canUseFullScreenIntent()
        }
    }
}
