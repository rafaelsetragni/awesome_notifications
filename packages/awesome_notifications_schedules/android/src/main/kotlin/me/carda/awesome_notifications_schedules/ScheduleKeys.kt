package me.carda.awesome_notifications_schedules

/**
 * Keys of the `schedule` block a notification carries. They match the strings the
 * Dart schedule models (`NotificationInterval`/`NotificationCalendar`) serialize —
 * the single source of truth for this decorator, so there are no magic strings in
 * the scheduling code.
 */
object ScheduleKeys {
    const val SCHEDULE = "schedule"
    const val INTERVAL = "interval"
    const val REPEATS = "repeats"
    const val ALLOW_WHILE_IDLE = "allowWhileIdle"
    const val TIME_ZONE = "timeZone"
    const val ERA = "era"
    const val YEAR = "year"
    const val MONTH = "month"
    const val DAY = "day"
    const val HOUR = "hour"
    const val MINUTE = "minute"
    const val SECOND = "second"
    const val WEEKDAY = "weekday"
    const val WEEK_OF_MONTH = "weekOfMonth"
    const val WEEK_OF_YEAR = "weekOfYear"

    /** Calendar-component keys; any present → a calendar (date) schedule. */
    val CALENDAR_COMPONENTS = listOf(
        ERA, YEAR, MONTH, DAY, HOUR, MINUTE, SECOND, WEEKDAY, WEEK_OF_MONTH, WEEK_OF_YEAR
    )
}
