package me.carda.awesome_notifications_schedules

import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.regex.Pattern

/**
 * Faithful port of the 0.12 `CalendarUtils` + `TimeZoneUtils` (AndroidAwnCore),
 * restricted to what scheduling uses. The string formats, the time-zone
 * parsing rules and their quirks are part of the 0.12 contract and are kept
 * as-is (e.g. [calendarFromString] always answers a UTC calendar, because 0.12
 * discarded the shifted copy).
 */
object ScheduleCalendarUtils {

    private val utcTimeZone: TimeZone = TimeZone.getTimeZone("GMT")

    /** Now, in UTC, truncated to the second. */
    fun getNowCalendar(): Calendar {
        val calendar = Calendar.getInstance(TimeZone.getTimeZone("UTC"))
        calendar.time = Date()
        calendar.set(Calendar.MILLISECOND, 0)
        return calendar
    }

    fun getCurrentCalendar(): Calendar = getNowCalendar()

    /** Now, expressed in [timeZone] (same instant). Throws on a null zone, like 0.12. */
    fun getCurrentCalendar(timeZone: TimeZone?): Calendar {
        if (timeZone == null) throw invalidTimeZone()
        return shiftTimeZone(getNowCalendar(), timeZone)
    }

    /** "yyyy-MM-dd HH:mm:ss <zone id>", in the calendar's own time zone. */
    fun calendarToString(calendar: Calendar?): String? {
        if (calendar == null) return null
        return String.format(
            Locale.US,
            "%04d-%02d-%02d %02d:%02d:%02d %s",
            calendar.get(Calendar.YEAR),
            calendar.get(Calendar.MONTH) + 1,
            calendar.get(Calendar.DAY_OF_MONTH),
            calendar.get(Calendar.HOUR_OF_DAY),
            calendar.get(Calendar.MINUTE),
            calendar.get(Calendar.SECOND),
            calendar.timeZone.id
        )
    }

    /** 0.12 `shiftTimeZone(Calendar, TimeZone)`: same instant plus the source zone offset. */
    fun shiftTimeZone(calendar: Calendar, timeZone: TimeZone): Calendar {
        val date = calendar.time
        val offsetFromUTC = calendar.timeZone.getOffset(date.time)
        val shifted = Calendar.getInstance(timeZone)
        shifted.time = date
        shifted.add(Calendar.MILLISECOND, offsetFromUTC)
        return shifted
    }

    fun calendarFromString(date: String?): Calendar? {
        if (date.isNullOrEmpty()) return null
        val matcher = Pattern
            .compile("^((\\d+)-(\\d+)-(\\d+) (\\d+):(\\d+):(\\d+))( (\\S+))?$", Pattern.CASE_INSENSITIVE)
            .matcher(date)
        return if (matcher.matches()) calendarFromString(matcher.group(1)!!, matcher.group(9))
        else null
    }

    fun calendarFromString(date: String?, timeZoneId: String?): Calendar? {
        if (date.isNullOrEmpty()) return null
        val timeZone =
            if (timeZoneId.isNullOrEmpty()) utcTimeZone
            else getValidTimeZone(timeZoneId)
        return calendarFromString(date, timeZone)
    }

    fun calendarFromString(date: String?, @Suppress("UNUSED_PARAMETER") timeZone: TimeZone?): Calendar? {
        if (date.isNullOrEmpty()) return null
        val matcher = Pattern
            .compile("^(\\d+)-(\\d+)-(\\d+) (\\d+):(\\d+):(\\d+)$", Pattern.CASE_INSENSITIVE)
            .matcher(date)
        if (!matcher.matches()) return null

        // 0.12 quirk: the shifted copy is discarded, so the calendar stays in UTC.
        val calendar = getNowCalendar()
        calendar.set(Calendar.YEAR, matcher.group(1)!!.toInt())
        calendar.set(Calendar.MONTH, matcher.group(2)!!.toInt() - 1)
        calendar.set(Calendar.DAY_OF_MONTH, matcher.group(3)!!.toInt())
        calendar.set(Calendar.HOUR_OF_DAY, matcher.group(4)!!.toInt())
        calendar.set(Calendar.MINUTE, matcher.group(5)!!.toInt())
        calendar.set(Calendar.SECOND, matcher.group(6)!!.toInt())
        return calendar
    }

    /** 0.12 `TimeZoneUtils.getValidTimeZone`: null when the id is not recognized. */
    fun getValidTimeZone(timeZoneId: String?): TimeZone? {
        if (timeZoneId == null) return null
        val matcher = Pattern
            .compile("^((\\-|\\+)?(\\d{2}(:\\d{2})?))|(\\S+)$", Pattern.MULTILINE)
            .matcher(timeZoneId)

        val finalTimeZone: TimeZone =
            if (matcher.matches()) {
                if (matcher.group(1) != null) {
                    TimeZone.getTimeZone(
                        "GMT" +
                            (matcher.group(2) ?: "+") +
                            matcher.group(3) +
                            (matcher.group(4) ?: ":00")
                    )
                } else {
                    TimeZone.getTimeZone(matcher.group(5))
                }
            } else {
                TimeZone.getDefault()
            }

        return if (finalTimeZone.id.contains(timeZoneId)) finalTimeZone else null
    }

    fun timeZoneToString(timeZone: TimeZone?): String? = timeZone?.id

    private fun invalidTimeZone() = ScheduleException(
        ScheduleException.CODE_INVALID_ARGUMENTS,
        "Invalid time zone",
        ScheduleException.DETAILED_INVALID_ARGUMENTS + ".calendar.timeZone"
    )
}
