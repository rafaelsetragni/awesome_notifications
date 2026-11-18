package me.carda.awesome_notifications_schedules

import java.text.ParseException
import java.util.Calendar
import java.util.TimeZone
import me.carda.awesome_notifications_schedules.externalLibs.CronExpression

/**
 * Faithful port of 0.12's `NotificationScheduleModel` hierarchy
 * (`NotificationCalendarModel`, `NotificationIntervalModel`,
 * `NotificationCrontabModel`) and `CronUtils`. Parsing defaults, validation
 * rules/messages, the cron-based next-date math and the serialized shape are
 * the 0.12 contract and are kept as-is, quirks included:
 *  - a calendar becomes a Quartz cron "<sec|*> <min|*> <hour|*> <day|*|?> <month|*> <weekday|?> <year|*>"
 *    (weekday ISO→standard, weekOfMonth/weekOfYear/era/millisecond ignored);
 *  - a free second still matches one second after the reference date;
 *  - the weekday is stored in "standard" (Sunday = 1) form and serialized back
 *    in ISO form (Monday = 1).
 */
abstract class NotificationScheduleModel {

    var timeZone: TimeZone? = null
    var createdDate: Calendar? = null
    var repeats: Boolean? = null
    var allowWhileIdle: Boolean? = null
    var preciseAlarm: Boolean? = null
    var delayTolerance: Int? = null

    open fun fromMap(arguments: Map<String, Any?>): NotificationScheduleModel {
        timeZone = getTimeZone(arguments, ScheduleKeys.TIME_ZONE, TimeZone.getDefault())
        createdDate = getCalendar(arguments, ScheduleKeys.CREATED_DATE, null)
        repeats = getBoolean(arguments, ScheduleKeys.REPEATS, false)
        allowWhileIdle = getBoolean(arguments, ScheduleKeys.ALLOW_WHILE_IDLE, false)
        preciseAlarm = getBoolean(arguments, ScheduleKeys.PRECISE_ALARM, false)
        delayTolerance = getInt(arguments, ScheduleKeys.DELAY_TOLERANCE, 0)
        return this
    }

    open fun toMap(): MutableMap<String, Any?> {
        val dataMap = HashMap<String, Any?>()
        put(dataMap, ScheduleKeys.TIME_ZONE, ScheduleCalendarUtils.timeZoneToString(timeZone))
        put(dataMap, ScheduleKeys.CREATED_DATE, ScheduleCalendarUtils.calendarToString(createdDate))
        put(dataMap, ScheduleKeys.REPEATS, repeats)
        put(dataMap, ScheduleKeys.ALLOW_WHILE_IDLE, allowWhileIdle)
        put(dataMap, ScheduleKeys.PRECISE_ALARM, preciseAlarm)
        put(dataMap, ScheduleKeys.DELAY_TOLERANCE, delayTolerance)
        return dataMap
    }

    @Throws(ScheduleException::class)
    abstract fun validate()

    @Throws(ScheduleException::class)
    abstract fun getNextValidDate(fixedNowDate: Calendar?): Calendar?

    /** 0.12: a non-repeating schedule without createdDate never has a next date. */
    @Throws(ScheduleException::class)
    fun hasNextValidDate(): Boolean {
        val repeats = this.repeats ?: false
        this.repeats = repeats
        if (createdDate == null && !repeats) return false
        return hasNextValidDate(ScheduleCalendarUtils.getCurrentCalendar())
    }

    @Throws(ScheduleException::class)
    fun hasNextValidDate(referenceDate: Calendar): Boolean {
        val nextSchedule = getNextValidDate(referenceDate)
        return nextSchedule != null &&
            (nextSchedule.after(referenceDate) || nextSchedule == referenceDate)
    }

    companion object {

        /**
         * 0.12 `getScheduleModelFromMap`: the KEYS present decide the type (a
         * Dart calendar always sends every component key, even null ones).
         */
        fun getScheduleModelFromMap(map: Map<String, Any?>?): NotificationScheduleModel? {
            if (map == null || map.isEmpty()) return null

            if (map.containsKey(ScheduleKeys.CRONTAB_EXPRESSION) ||
                map.containsKey(ScheduleKeys.PRECISE_SCHEDULES) ||
                map.containsKey(ScheduleKeys.EXPIRATION_DATE_TIME)
            ) return NotificationCrontabModel().fromMap(map)

            if (map.containsKey(ScheduleKeys.SECOND) ||
                map.containsKey(ScheduleKeys.MINUTE) ||
                map.containsKey(ScheduleKeys.HOUR) ||
                map.containsKey(ScheduleKeys.DAY) ||
                map.containsKey(ScheduleKeys.MONTH) ||
                map.containsKey(ScheduleKeys.YEAR) ||
                map.containsKey(ScheduleKeys.ERA) ||
                map.containsKey(ScheduleKeys.MILLISECOND) ||
                map.containsKey(ScheduleKeys.WEEKDAY) ||
                map.containsKey(ScheduleKeys.WEEK_OF_MONTH) ||
                map.containsKey(ScheduleKeys.WEEK_OF_YEAR)
            ) return NotificationCalendarModel().fromMap(map)

            if (map.containsKey(ScheduleKeys.INTERVAL))
                return NotificationIntervalModel().fromMap(map)

            return null
        }

        // 0.12 AbstractModel.getValueOrDefault / putDataOnSerializedMap semantics.

        internal fun getTimeZone(map: Map<String, Any?>, key: String, default: TimeZone?): TimeZone? {
            val value = map[key] ?: return default
            return ScheduleCalendarUtils.getValidTimeZone(value as? String)
        }

        internal fun getCalendar(map: Map<String, Any?>, key: String, default: Calendar?): Calendar? {
            val value = map[key] ?: return default
            if (value is String) return ScheduleCalendarUtils.calendarFromString(value)
            return default
        }

        internal fun getBoolean(map: Map<String, Any?>, key: String, default: Boolean?): Boolean? {
            val value = map[key] ?: return default
            return value as? Boolean ?: default
        }

        internal fun getInt(map: Map<String, Any?>, key: String, default: Int?): Int? {
            val value = map[key] ?: return default
            return (value as? Number)?.toInt() ?: default
        }

        internal fun getString(map: Map<String, Any?>, key: String, default: String?): String? {
            val value = map[key] ?: return default
            return value as? String ?: value.toString()
        }

        internal fun getCalendarList(map: Map<String, Any?>, key: String, default: List<Calendar?>?): List<Calendar?>? {
            val value = map[key] ?: return default
            if (value !is List<*>) return default
            return value.map { ScheduleCalendarUtils.calendarFromString(it as String?) }
        }

        internal fun put(map: MutableMap<String, Any?>, key: String, value: Any?) {
            if (value == null) return
            map[key] = value
        }

        internal fun invalidArguments(message: String, detail: String) =
            ScheduleException(
                ScheduleException.CODE_INVALID_ARGUMENTS,
                message,
                detail
            )

        internal fun isBetween(value: Int, min: Int, max: Int) = value in min..max
    }
}

class NotificationCalendarModel : NotificationScheduleModel() {

    var era: Int? = null
    var year: Int? = null
    var month: Int? = null
    var day: Int? = null
    var hour: Int? = null
    var minute: Int? = null
    var second: Int? = null
    var millisecond: Int? = null
    /** Standard form (Sunday = 1 … Saturday = 7), as 0.12 kept it internally. */
    var weekday: Int? = null
    var weekOfMonth: Int? = null
    var weekOfYear: Int? = null

    override fun fromMap(arguments: Map<String, Any?>): NotificationCalendarModel {
        super.fromMap(arguments)
        era = getInt(arguments, ScheduleKeys.ERA, null)
        year = getInt(arguments, ScheduleKeys.YEAR, null)
        month = getInt(arguments, ScheduleKeys.MONTH, null)
        day = getInt(arguments, ScheduleKeys.DAY, null)
        hour = getInt(arguments, ScheduleKeys.HOUR, null)
        minute = getInt(arguments, ScheduleKeys.MINUTE, null)
        second = getInt(arguments, ScheduleKeys.SECOND, null)
        millisecond = getInt(arguments, ScheduleKeys.MILLISECOND, null)
        weekday = getInt(arguments, ScheduleKeys.WEEKDAY, null)
        weekOfMonth = getInt(arguments, ScheduleKeys.WEEK_OF_MONTH, null)
        weekOfYear = getInt(arguments, ScheduleKeys.WEEK_OF_YEAR, null)
        weekday = weekDayISO8601ToStandard(weekday)
        return this
    }

    override fun toMap(): MutableMap<String, Any?> {
        val dataMap = super.toMap()
        put(dataMap, ScheduleKeys.ERA, era)
        put(dataMap, ScheduleKeys.YEAR, year)
        put(dataMap, ScheduleKeys.MONTH, month)
        put(dataMap, ScheduleKeys.DAY, day)
        put(dataMap, ScheduleKeys.HOUR, hour)
        put(dataMap, ScheduleKeys.MINUTE, minute)
        put(dataMap, ScheduleKeys.SECOND, second)
        put(dataMap, ScheduleKeys.MILLISECOND, millisecond)
        put(dataMap, ScheduleKeys.WEEK_OF_MONTH, weekOfMonth)
        put(dataMap, ScheduleKeys.WEEK_OF_YEAR, weekOfYear)
        put(dataMap, ScheduleKeys.WEEKDAY, weekDayStandardToISO8601(weekday))
        return dataMap
    }

    override fun validate() {
        if (era == null && year == null && month == null && day == null &&
            hour == null && minute == null && second == null && millisecond == null &&
            weekday == null && weekOfMonth == null && weekOfYear == null
        ) throw invalidArguments(
            "At least one time condition is required",
            ScheduleException.DETAILED_INVALID_ARGUMENTS + ".notificationCalendar"
        )

        if (era != null && !isBetween(era!!, 0, Int.MAX_VALUE) ||
            year != null && !isBetween(year!!, 0, Int.MAX_VALUE) ||
            month != null && !isBetween(month!!, 1, 12) ||
            day != null && !isBetween(day!!, 1, 31) ||
            hour != null && !isBetween(hour!!, 0, 23) ||
            minute != null && !isBetween(minute!!, 0, 59) ||
            second != null && !isBetween(second!!, 0, 59) ||
            millisecond != null && !isBetween(millisecond!!, 0, 999) ||
            weekday != null && !isBetween(weekday!!, 1, 7) ||
            weekOfMonth != null && !isBetween(weekOfMonth!!, 1, 6) ||
            weekOfYear != null && !isBetween(weekOfYear!!, 1, 53)
        ) throw invalidArguments(
            "The time conditions are invalid",
            ScheduleException.DETAILED_INVALID_ARGUMENTS + ".notificationCalendar"
        )
    }

    /** The Quartz cron expression 0.12 derived from the calendar components. */
    fun cronExpression(): String =
        (second?.toString() ?: "*") + " " +
            (minute?.toString() ?: "*") + " " +
            (hour?.toString() ?: "*") + " " +
            (if (weekday != null) "?" else (day?.toString() ?: "*")) + " " +
            (month?.toString() ?: "*") + " " +
            (weekday?.toString() ?: "?") + " " +
            (year?.toString() ?: "*")

    override fun getNextValidDate(fixedNowDate: Calendar?): Calendar? {
        val timeZone = this.timeZone ?: throw invalidArguments(
            "Invalid time zone",
            ScheduleException.DETAILED_INVALID_ARGUMENTS + ".notificationCalendar.timeZone"
        )
        // 0.12 dereferenced a null fixed date here (NPE → reported as an exception).
        fixedNowDate ?: throw ScheduleException(
            ScheduleException.CODE_UNKNOWN_EXCEPTION,
            "Invalid fixed date",
            ScheduleException.DETAILED_UNEXPECTED_ERROR
        )
        return ScheduleCronUtils.getNextCalendar(fixedNowDate, cronExpression(), timeZone)
    }

    companion object {
        fun weekDayISO8601ToStandard(weekdayISOValue: Int?): Int? {
            if (weekdayISOValue == null) return null
            if (weekdayISOValue <= 0) return weekdayISOValue
            if (weekdayISOValue > 7) return weekdayISOValue
            if (weekdayISOValue == 7) return 1
            return weekdayISOValue + 1
        }

        fun weekDayStandardToISO8601(weekdayValue: Int?): Int? {
            if (weekdayValue == null) return null
            if (weekdayValue <= 0) return weekdayValue
            if (weekdayValue > 7) return weekdayValue
            if (weekdayValue == 1) return 7
            return weekdayValue - 1
        }
    }
}

class NotificationIntervalModel : NotificationScheduleModel() {

    /** Seconds. */
    var interval: Int? = null

    override fun fromMap(arguments: Map<String, Any?>): NotificationIntervalModel {
        super.fromMap(arguments)
        interval = getInt(arguments, ScheduleKeys.INTERVAL, null)
        return this
    }

    override fun toMap(): MutableMap<String, Any?> {
        val dataMap = super.toMap()
        put(dataMap, ScheduleKeys.INTERVAL, interval)
        return dataMap
    }

    override fun validate() {
        val interval = this.interval
        if (interval == null || interval < 5) throw invalidArguments(
            "Interval is required and must be greater than 5",
            ScheduleException.DETAILED_INVALID_ARGUMENTS + ".notificationInterval.interval"
        )
        if (repeats == true && interval < 60) throw invalidArguments(
            "time interval must be at least 60 if repeating",
            ScheduleException.DETAILED_INVALID_ARGUMENTS + ".notificationInterval.interval"
        )
    }

    override fun getNextValidDate(fixedNowDate: Calendar?): Calendar? {
        val interval = this.interval ?: throw invalidArguments(
            "Interval is required and must be greater than 5",
            ScheduleException.DETAILED_INVALID_ARGUMENTS + ".notificationInterval.interval"
        )
        val now = fixedNowDate ?: ScheduleCalendarUtils.getCurrentCalendar(timeZone)
        val initialDate = createdDate ?: now

        val finalDate: Calendar
        if (repeats ?: false) {
            val initialEpoch = initialDate.timeInMillis
            val currentEpoch = now.timeInMillis
            val missingSeconds = Math.abs(currentEpoch - initialEpoch) / 1000 % interval

            finalDate =
                if (initialDate.after(now)) initialDate.clone() as Calendar
                else now.clone() as Calendar

            finalDate.add(Calendar.SECOND, interval - missingSeconds.toInt())
        } else {
            finalDate = initialDate.clone() as Calendar
            finalDate.add(Calendar.SECOND, interval)
        }

        return if (finalDate.after(now) || finalDate == now) finalDate else null
    }
}

class NotificationCrontabModel : NotificationScheduleModel() {

    var initialDateTime: Calendar? = null
    var expirationDateTime: Calendar? = null
    var crontabExpression: String? = null
    var preciseSchedules: List<Calendar?>? = null

    override fun fromMap(arguments: Map<String, Any?>): NotificationCrontabModel {
        super.fromMap(arguments)
        initialDateTime = getCalendar(arguments, ScheduleKeys.INITIAL_DATE_TIME, null)
        expirationDateTime = getCalendar(arguments, ScheduleKeys.EXPIRATION_DATE_TIME, null)
        crontabExpression = getString(arguments, ScheduleKeys.CRONTAB_EXPRESSION, null)
        preciseSchedules = getCalendarList(arguments, ScheduleKeys.PRECISE_SCHEDULES, null)
        return this
    }

    override fun toMap(): MutableMap<String, Any?> {
        val dataMap = super.toMap()
        put(dataMap, ScheduleKeys.INITIAL_DATE_TIME, ScheduleCalendarUtils.calendarToString(initialDateTime))
        put(dataMap, ScheduleKeys.EXPIRATION_DATE_TIME, ScheduleCalendarUtils.calendarToString(expirationDateTime))
        put(dataMap, ScheduleKeys.CRONTAB_EXPRESSION, crontabExpression)
        preciseSchedules?.takeIf { it.isNotEmpty() }?.let { list ->
            dataMap[ScheduleKeys.PRECISE_SCHEDULES] =
                list.filterNotNull().map { ScheduleCalendarUtils.calendarToString(it) }
        }
        return dataMap
    }

    override fun validate() {
        if (crontabExpression.isNullOrEmpty() && preciseSchedules.isNullOrEmpty())
            throw invalidArguments(
                "At least one schedule parameter is required",
                ScheduleException.DETAILED_REQUIRED_ARGUMENTS
            )
        try {
            val initial = initialDateTime
            val expiration = expirationDateTime
            if (initial != null && expiration != null) {
                if (initial == expiration || initial.after(expiration))
                    throw invalidArguments(
                        "Expiration date must be greater than initial date",
                        ScheduleException.DETAILED_INVALID_ARGUMENTS + ".periodOrder"
                    )
            }
            val cron = crontabExpression
            if (cron != null && !CronExpression.isValidExpression(cron))
                throw invalidArguments(
                    "Schedule cron expression is invalid",
                    ScheduleException.DETAILED_INVALID_ARGUMENTS + ".crontabExpression"
                )
        } catch (e: ScheduleException) {
            throw e
        } catch (e: Exception) {
            throw invalidArguments(
                "Schedule time is invalid",
                ScheduleException.DETAILED_INVALID_ARGUMENTS + ".scheduleTime"
            )
        }
    }

    override fun getNextValidDate(fixedNowDate: Calendar?): Calendar? {
        try {
            val now = fixedNowDate ?: ScheduleCalendarUtils.getCurrentCalendar(timeZone)

            // Same (precedence-sensitive) condition as 0.12.
            if (expirationDateTime != null && now.after(expirationDateTime) ||
                now == expirationDateTime
            ) return null

            var preciseCalendar: Calendar? = null
            var crontabCalendar: Calendar? = null

            if (!preciseSchedules.isNullOrEmpty())
                preciseCalendar = getNextMinimalPreciseSchedule(now)

            if (!crontabExpression.isNullOrEmpty())
                crontabCalendar = ScheduleCronUtils.getNextCalendar(
                    initialDateTime ?: now,
                    crontabExpression!!,
                    timeZone
                )

            if (preciseCalendar == null) return crontabCalendar
            if (crontabCalendar == null) return preciseCalendar
            if (preciseCalendar.before(crontabCalendar)) return preciseCalendar
            return crontabCalendar
        } catch (e: ScheduleException) {
            throw e
        } catch (e: Exception) {
            throw invalidArguments(
                "Schedule time is invalid",
                ScheduleException.DETAILED_INVALID_ARGUMENTS + ".notificationCrontab"
            )
        }
    }

    private fun getNextMinimalPreciseSchedule(fixedNowDate: Calendar): Calendar? {
        var preciseCalendar: Calendar? = null
        val fixedNowDatePlusSecond = fixedNowDate.clone() as Calendar
        fixedNowDatePlusSecond.add(Calendar.SECOND, 1)
        fixedNowDatePlusSecond.set(Calendar.MILLISECOND, 0)

        for (currentSchedule in preciseSchedules!!) {
            // A null entry (unparseable date) fails like 0.12's NPE did.
            currentSchedule!!
            if (initialDateTime != null && currentSchedule.before(initialDateTime)) continue
            if (currentSchedule.before(fixedNowDatePlusSecond)) continue
            if (preciseCalendar == null || currentSchedule.before(preciseCalendar))
                preciseCalendar = currentSchedule
        }
        return preciseCalendar
    }
}

/** Port of 0.12's `CronUtils`. */
object ScheduleCronUtils {

    /** `<second> <minute> <hour> <day-of-month> <month> <day-of-week> <year>` */
    fun getNextCalendar(fixedNowDate: Calendar?, crontabRule: String?, timeZone: TimeZone?): Calendar? {
        if (fixedNowDate == null || timeZone == null || crontabRule.isNullOrEmpty()) return null

        if (CronExpression.isValidExpression(crontabRule)) {
            try {
                val cronExpression = CronExpression(crontabRule)
                cronExpression.timeZone = timeZone
                val nextSchedule = cronExpression.getNextValidTimeAfter(fixedNowDate.time)

                val delayedNow = applyToleranceDate(fixedNowDate)
                return if (nextSchedule != null && nextSchedule >= delayedNow.time) {
                    val calendar = Calendar.getInstance()
                    calendar.timeZone = timeZone
                    calendar.time = nextSchedule
                    calendar
                } else {
                    // No more valid dates.
                    null
                }
            } catch (e: ParseException) {
                e.printStackTrace()
            }
        }
        return null
    }

    /** Processing time tolerance. */
    fun applyToleranceDate(initialScheduleDay: Calendar): Calendar {
        val shifted = initialScheduleDay.clone() as Calendar
        shifted.set(Calendar.MILLISECOND, 0)
        return shifted
    }
}
