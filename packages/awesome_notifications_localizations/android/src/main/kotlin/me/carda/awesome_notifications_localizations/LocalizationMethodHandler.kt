package me.carda.awesome_notifications_localizations

import me.carda.android_awn_core.AwesomeMethodHandler

/** Answers the core's setLocalization/getLocalization channel methods. */
class LocalizationMethodHandler(
    private val manager: LocalizationManager
) : AwesomeMethodHandler {

    override fun handle(method: String, arguments: Any?, result: (Any?) -> Unit): Boolean {
        return when (method) {
            "setLocalization" -> {
                result(manager.setLocalization(arguments as? String))
                true
            }
            "getLocalization" -> {
                result(manager.getLocalization())
                true
            }
            else -> false
        }
    }
}
