package me.carda.android_awn_core

/**
 * 0.12 `AwesomeNotificationsException`: a failure the bridge answers as a
 * `PlatformException(code, message, details = detailedCode)`.
 */
class AwesomeNotificationsException(
    val code: String,
    message: String,
    val detailedCode: String
) : Exception(message)
