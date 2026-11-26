package me.carda.awesome_notifications_schedules

/**
 * The scheduling counterpart of 0.12's `AwesomeNotificationsException`: the
 * [code] / [message] / [detailedCode] triple reaches Dart as a
 * `PlatformException(code, message, details)`, exactly as 0.12 reported it.
 */
class ScheduleException(
    val code: String,
    override val message: String,
    val detailedCode: String
) : Exception(message) {

    companion object {
        // Same strings as 0.12's ExceptionCode.
        const val CODE_INVALID_ARGUMENTS = "INVALID_ARGUMENTS"
        const val CODE_INSUFFICIENT_PERMISSIONS = "INSUFFICIENT_PERMISSIONS"
        const val CODE_UNKNOWN_EXCEPTION = "UNKNOWN_EXCEPTION"
        const val DETAILED_INVALID_ARGUMENTS = "arguments.invalid"
        const val DETAILED_REQUIRED_ARGUMENTS = "arguments.required"
        const val DETAILED_INSUFFICIENT_PERMISSIONS = "insufficientPermissions"
        const val DETAILED_UNEXPECTED_ERROR = "unexpectedError"
    }
}
