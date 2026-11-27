package me.carda.awesome_notifications_live_activities

import android.app.NotificationManager
import android.content.Context
import android.os.Build
import me.carda.android_awn_core.AwesomeMethodHandler

/** Answers the AwesomeNotificationsLiveActivities channel methods. */
internal class LiveMethodHandler(
    private val context: Context,
    /** Opens the system page of live notifications and answers when the user is back. */
    private val requestPermission: ((Boolean) -> Unit) -> Unit
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
            LiveKeys.METHOD_END -> {
                val args = arguments as? Map<*, *>
                val activityId = args?.get(LiveKeys.ACTIVITY_ID) as? String
                val dismissal = LiveDismissal.from(args?.get(LiveKeys.DISMISSAL))
                if (activityId.isNullOrBlank() || dismissal == null) {
                    error(
                        LiveKeys.CODE_INVALID_ARGUMENTS, "liveActivityEnd needs an activityId and a dismissal",
                        "arguments.invalid.liveActivityEnd"
                    )
                } else {
                    LiveActivities.end(context, activityId, dismissal) { result(null) }
                }
            }
            LiveKeys.METHOD_LIST -> result(LiveActivities.list(context))
            LiveKeys.METHOD_ARE_ENABLED -> result(areEnabled(context))
            LiveKeys.METHOD_REQUEST_PERMISSION -> {
                if (areEnabled(context)) result(true) else requestPermission { result(it) }
            }
            // ActivityKit only (iOS).
            LiveKeys.METHOD_PUSH_TO_START_TOKEN, LiveKeys.METHOD_PUSH_TOKEN -> result(null)
            LiveKeys.METHOD_CAPABILITIES -> {
                val liveUpdates = Build.VERSION.SDK_INT >= LiveNotifications.PROMOTED_SDK
                result(
                    mapOf(
                        LiveKeys.CAP_SYSTEM_SURFACE to liveUpdates,
                        // Android 16: ProgressStyle; before: the package's own layout.
                        LiveKeys.CAP_PROGRESS_SEGMENTS to true,
                        // Before Android 16 the package's layout draws them in
                        // columns; on 16 they go in the body (MetricStyle is 17).
                        LiveKeys.CAP_METRICS to !liveUpdates,
                        LiveKeys.CAP_BUTTONS to true,
                        // FCM data pushes reach the core's createNotification.
                        LiveKeys.CAP_PUSH to true
                    )
                )
            }
            else -> return false
        }
        return true
    }

    companion object {
        /** Android 16+: the user's "Live notifications" switch. Allowed before (nothing to promote). */
        fun areEnabled(context: Context): Boolean {
            if (Build.VERSION.SDK_INT < LiveNotifications.PROMOTED_SDK) return true
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            return try {
                manager.canPostPromotedNotifications()
            } catch (e: Exception) {
                false
            }
        }
    }
}
