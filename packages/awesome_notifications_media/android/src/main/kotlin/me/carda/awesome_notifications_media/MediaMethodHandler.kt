package me.carda.awesome_notifications_media

import android.content.Context
import android.os.Build
import me.carda.android_awn_core.AwesomeMethodHandler

/** Answers the AwesomeNotificationsMedia channel methods. */
internal class MediaMethodHandler(private val context: Context) : AwesomeMethodHandler {

    override fun handle(method: String, arguments: Any?, result: (Any?) -> Unit): Boolean =
        handle(method, arguments, result) { _, _, _ -> result(null) }

    override fun handle(
        method: String,
        arguments: Any?,
        result: (Any?) -> Unit,
        error: (code: String, message: String?, details: Any?) -> Unit
    ): Boolean {
        when (method) {
            MediaKeys.METHOD_STOP -> {
                (arguments as? String)?.let { MediaSessions.stop(context, it) }
                result(null)
            }
            MediaKeys.METHOD_UPDATE_POSITION -> {
                val args = arguments as? Map<*, *>
                val id = args?.get(MediaKeys.SESSION_ID) as? String
                val position = (args?.get(MediaKeys.POSITION) as? Number)?.toLong()
                if (id.isNullOrBlank() || position == null || position < 0) {
                    error(
                        MediaKeys.CODE_INVALID_ARGUMENTS, "mediaUpdatePosition needs a sessionId and a position",
                        MediaKeys.DETAILED_INVALID_ARGUMENTS + ".mediaUpdatePosition"
                    )
                } else {
                    MediaSessions.updatePosition(id, position)
                    result(null)
                }
            }
            MediaKeys.METHOD_CAPABILITIES -> result(
                mapOf(
                    // The media notification's progress bar (draggable with seekTo).
                    "seekBar" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q),
                    "artwork" to true,
                    "customButtons" to true,
                    "lockScreen" to true
                )
            )
            else -> return false
        }
        return true
    }
}
