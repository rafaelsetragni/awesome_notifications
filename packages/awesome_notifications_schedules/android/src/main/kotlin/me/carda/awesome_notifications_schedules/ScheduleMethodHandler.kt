package me.carda.awesome_notifications_schedules

import android.content.Context
import me.carda.android_awn_core.AwesomeMethodHandler

/**
 * Answers the schedule-management channel methods exactly like 0.12's
 * `AwesomeNotificationsPlugin` did (same arguments, validation, errors and
 * replies): getNextDate, listAllSchedules, cancelSchedule,
 * cancelSchedulesByChannelKey, cancelSchedulesByGroupKey, cancelAllSchedules.
 */
class ScheduleMethodHandler(private val context: Context) : AwesomeMethodHandler {

    override fun handle(method: String, arguments: Any?, result: (Any?) -> Unit): Boolean =
        handle(method, arguments, result) { _, _, _ -> result(null) }

    override fun handle(
        method: String,
        arguments: Any?,
        result: (Any?) -> Unit,
        error: (code: String, message: String?, details: Any?) -> Unit
    ): Boolean {
        val action: () -> Any? = when (method) {
            ScheduleKeys.METHOD_GET_NEXT_DATE -> { { getNextDate(arguments) } }
            ScheduleKeys.METHOD_LIST_ALL_SCHEDULES -> { { listAllSchedules() } }
            ScheduleKeys.METHOD_CANCEL_SCHEDULE -> { { cancelSchedule(arguments) } }
            ScheduleKeys.METHOD_CANCEL_SCHEDULES_BY_CHANNEL_KEY -> { { cancelSchedulesByChannelKey(arguments) } }
            ScheduleKeys.METHOD_CANCEL_SCHEDULES_BY_GROUP_KEY -> { { cancelSchedulesByGroupKey(arguments) } }
            ScheduleKeys.METHOD_CANCEL_ALL_SCHEDULES -> { { cancelAllSchedules() } }
            else -> return false
        }
        try {
            result(action())
        } catch (e: ScheduleException) {
            error(e.code, e.message, e.detailedCode)
        } catch (e: Exception) {
            error(
                ScheduleException.CODE_UNKNOWN_EXCEPTION,
                e.message ?: e.javaClass.simpleName,
                ScheduleException.DETAILED_UNEXPECTED_ERROR
            )
        }
        return true
    }

    // MARK: - getNextDate

    /**
     * 0.12 `channelMethodGetNextDate`: the next date after `fixedDate` (UTC
     * "yyyy-MM-dd HH:mm:ss", defaults to now), formatted in the time zone of the
     * resulting calendar ("yyyy-MM-dd HH:mm:ss <zone id>"), or null. The schedule
     * is not validated first, like in 0.12.
     */
    internal fun getNextDate(arguments: Any?): String? {
        @Suppress("UNCHECKED_CAST")
        val data = arguments as? Map<String, Any?> ?: throw invalidScheduleData()

        @Suppress("UNCHECKED_CAST")
        val scheduleData = data[ScheduleKeys.SCHEDULE] as? Map<String, Any?>
        if (scheduleData.isNullOrEmpty()) throw invalidScheduleData()

        val scheduleModel = NotificationScheduleModel.getScheduleModelFromMap(scheduleData)
            ?: throw invalidScheduleData()

        val fixedDate =
            (data[ScheduleKeys.FIXED_DATE] as? String)
                ?.let { ScheduleCalendarUtils.calendarFromString(it) }
                ?: ScheduleCalendarUtils.getCurrentCalendar()

        val nextValidDate = scheduleModel.getNextValidDate(fixedDate)
        return ScheduleCalendarUtils.calendarToString(nextValidDate)
    }

    // MARK: - listAllSchedules

    /** 0.12 `listAllPendingSchedules`: refreshes lost alarms, then lists the stored models. */
    internal fun listAllSchedules(): List<Map<String, Any?>> {
        NotificationScheduler.refreshScheduledNotifications(context)
        return ScheduleManager.listSchedules(context).map { model ->
            @Suppress("UNCHECKED_CAST")
            val schedule = NotificationScheduleModel.getScheduleModelFromMap(
                model[ScheduleKeys.SCHEDULE] as? Map<String, Any?>
            )
            model.toMutableMap().apply {
                if (schedule == null) remove(ScheduleKeys.SCHEDULE)
                else this[ScheduleKeys.SCHEDULE] = schedule.toMap()
            }
        }
    }

    // MARK: - cancel*

    internal fun cancelSchedule(arguments: Any?): Boolean {
        val id = (arguments as? Number)?.toInt()
        if (id == null || id < 0) throw ScheduleException(
            ScheduleException.CODE_INVALID_ARGUMENTS,
            "Invalid id value",
            ScheduleException.DETAILED_INVALID_ARGUMENTS + ".dismiss.id"
        )
        NotificationScheduler.cancelSchedule(context, id)
        return true
    }

    internal fun cancelSchedulesByChannelKey(arguments: Any?): Boolean {
        val channelKey = arguments as? String
        if (channelKey.isNullOrEmpty()) throw ScheduleException(
            ScheduleException.CODE_INVALID_ARGUMENTS,
            "Invalid channel Key value",
            ScheduleException.DETAILED_INVALID_ARGUMENTS + ".dismiss.channelKey"
        )
        NotificationScheduler.cancelSchedulesByChannelKey(context, channelKey)
        return true
    }

    internal fun cancelSchedulesByGroupKey(arguments: Any?): Boolean {
        val groupKey = arguments as? String
        if (groupKey.isNullOrEmpty()) throw ScheduleException(
            ScheduleException.CODE_INVALID_ARGUMENTS,
            "Invalid groupKey value",
            ScheduleException.DETAILED_INVALID_ARGUMENTS + ".dismiss.groupKey"
        )
        NotificationScheduler.cancelSchedulesByGroupKey(context, groupKey)
        return true
    }

    internal fun cancelAllSchedules(): Boolean {
        NotificationScheduler.cancelAllSchedules(context)
        return true
    }

    private fun invalidScheduleData() = ScheduleException(
        ScheduleException.CODE_INVALID_ARGUMENTS,
        "Schedule data is invalid",
        ScheduleException.DETAILED_INVALID_ARGUMENTS + ".schedule.data"
    )
}
