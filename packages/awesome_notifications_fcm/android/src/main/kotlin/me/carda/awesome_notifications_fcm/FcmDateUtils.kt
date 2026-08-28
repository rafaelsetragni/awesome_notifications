package me.carda.awesome_notifications_fcm

import me.carda.android_awn_core.Definitions
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone

/** UTC timestamp formatted exactly like the core lifecycle dates. */
object FcmDateUtils {
    fun nowUtc(): String {
        val formatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US)
        formatter.timeZone = TimeZone.getTimeZone(Definitions.UTC_TIMEZONE)
        return formatter.format(java.util.Date())
    }
}
