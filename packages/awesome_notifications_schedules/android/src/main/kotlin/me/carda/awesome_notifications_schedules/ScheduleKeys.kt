package me.carda.awesome_notifications_schedules

/**
 * Keys of the `schedule` block a notification carries and of the scheduling
 * channel methods. They match the strings the Dart schedule models
 * (`NotificationInterval`/`NotificationCalendar`) serialize and the 0.12
 * `Definitions` — the single source of truth for this decorator, so there are
 * no magic strings in the scheduling code.
 */
object ScheduleKeys {
    const val SCHEDULE = "schedule"
    const val INTERVAL = "interval"
    const val REPEATS = "repeats"
    const val ALLOW_WHILE_IDLE = "allowWhileIdle"
    const val PRECISE_ALARM = "preciseAlarm"
    const val DELAY_TOLERANCE = "delayTolerance"
    const val CREATED_DATE = "createdDate"
    const val TIME_ZONE = "timeZone"
    const val ERA = "era"
    const val YEAR = "year"
    const val MONTH = "month"
    const val DAY = "day"
    const val HOUR = "hour"
    const val MINUTE = "minute"
    const val SECOND = "second"
    const val MILLISECOND = "millisecond"
    const val WEEKDAY = "weekday"
    const val WEEK_OF_MONTH = "weekOfMonth"
    const val WEEK_OF_YEAR = "weekOfYear"

    // Android crontab schedule (0.12 NotificationAndroidCrontab).
    const val INITIAL_DATE_TIME = "initialDateTime"
    const val EXPIRATION_DATE_TIME = "expirationDateTime"
    const val CRONTAB_EXPRESSION = "crontabExpression"
    const val PRECISE_SCHEDULES = "preciseSchedules"

    /** getNextDate argument: the reference date ("yyyy-MM-dd HH:mm:ss"). */
    const val FIXED_DATE = "fixedDate"

    // Content keys the scheduler reads.
    const val CONTENT = "content"
    const val ID = "id"
    const val CHANNEL_KEY = "channelKey"
    const val GROUP_KEY = "groupKey"
    const val CATEGORY = "category"
    const val CATEGORY_ALARM = "Alarm"

    // AlarmManager PendingIntent extras (same names as 0.12).
    const val EXTRA_NOTIFICATION_ID = "id"
    const val EXTRA_NOTIFICATION_JSON = "notificationJson"

    // Channel methods answered by the decorator.
    const val METHOD_GET_NEXT_DATE = "getNextDate"
    const val METHOD_LIST_ALL_SCHEDULES = "listAllSchedules"
    const val METHOD_CANCEL_SCHEDULE = "cancelSchedule"
    const val METHOD_CANCEL_SCHEDULES_BY_CHANNEL_KEY = "cancelSchedulesByChannelKey"
    const val METHOD_CANCEL_SCHEDULES_BY_GROUP_KEY = "cancelSchedulesByGroupKey"
    const val METHOD_CANCEL_ALL_SCHEDULES = "cancelAllSchedules"
}
