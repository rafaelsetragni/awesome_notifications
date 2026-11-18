package me.carda.awesome_notifications_schedules

import android.annotation.SuppressLint
import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import java.util.Calendar
import java.util.Random
import me.carda.android_awn_core.AwesomeEventsReceiver
import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.JsonUtils
import me.carda.android_awn_core.NotificationBuilder
import me.carda.android_awn_core.NotificationLifeCycle
import me.carda.android_awn_core.NotificationSource

/**
 * Port of 0.12's `NotificationScheduler` thread + its static cancel/refresh
 * helpers. Registers a scheduled notification on AlarmManager (one alarm per
 * notification id, payload = the whole model as JSON), persists it in
 * [ScheduleManager], re-arms repeating schedules and restores lost alarms.
 *
 * Runs synchronously on the caller's thread: [schedule] is called from the
 * core's build executor or from a broadcast receiver's worker thread.
 */
object NotificationScheduler {

    private val random = Random()

    /**
     * Schedules [model] (which must carry a `schedule` block). Mirrors 0.12:
     * validates, stamps the created lifecycle (source = Schedule), computes the
     * next date from "now" in the schedule's time zone, arms the alarm and
     * stores the model. Returns the next date, or null when the schedule has no
     * future date (it is then removed). Throws [ScheduleException] like 0.12
     * threw `AwesomeNotificationsException`.
     *
     * [isReschedule]: re-arming an existing schedule (repeat / refresh) — no
     * created event, like 0.12.
     */
    @Throws(ScheduleException::class)
    fun schedule(
        context: Context,
        model: Map<String, Any?>,
        isReschedule: Boolean,
        lifeCycle: NotificationLifeCycle = NotificationLifeCycle.Foreground
    ): Calendar? {
        @Suppress("UNCHECKED_CAST")
        val scheduleData = model[ScheduleKeys.SCHEDULE] as? Map<String, Any?>
        val scheduleModel = NotificationScheduleModel.getScheduleModelFromMap(scheduleData)
            ?: throw ScheduleException(
                ScheduleException.CODE_INVALID_ARGUMENTS,
                "Invalid notification content",
                ScheduleException.DETAILED_INVALID_ARGUMENTS + ".notificationModel"
            )

        // notificationModel.validate(context)
        scheduleModel.validate()

        val initialDate = ScheduleCalendarUtils.getCurrentCalendar(scheduleModel.timeZone)

        // Only generate randomly for first time to avoid collisions.
        var content = ScheduleManager.contentOf(model).toMutableMap()
        val currentId = (content[ScheduleKeys.ID] as? Number)?.toInt()
        if (currentId == null || currentId < 0) content[ScheduleKeys.ID] = generateNextRandomId()

        val channelKey = content[ScheduleKeys.CHANNEL_KEY] as? String
        if (!isChannelEnabled(context, channelKey)) throw ScheduleException(
            ScheduleException.CODE_INVALID_ARGUMENTS,
            "Channel '$channelKey' do not exist or is disabled",
            ScheduleException.DETAILED_INSUFFICIENT_PERMISSIONS + ".channel." + channelKey
        )

        // registerCreatedEvent (only once: keeps an already stamped creation).
        val builder = NotificationBuilder.getNewBuilder()
        var notificationModel: Map<String, Any?> = model.toMutableMap().apply {
            this[ScheduleKeys.CONTENT] = content
            this[ScheduleKeys.SCHEDULE] = scheduleModel.toMap()
        }
        notificationModel = builder.stampCreatedLifecycle(
            notificationModel, lifeCycle = lifeCycle, source = NotificationSource.Schedule
        )
        content = ScheduleManager.contentOf(notificationModel).toMutableMap()
        val id = (content[ScheduleKeys.ID] as Number).toInt()

        val nextValidDate = scheduleModel.getNextValidDate(initialDate)

        if (nextValidDate == null) {
            cancelSchedule(context, id)
            return null
        }

        scheduleNotificationWithAlarmManager(context, notificationModel, scheduleModel, id, nextValidDate)
        ScheduleManager.saveSchedule(context, notificationModel)

        if (!isReschedule) {
            AwesomeEventsReceiver.notifyAwesomeEvent(
                Definitions.EVENT_NOTIFICATION_CREATED,
                builder.registerCreatedEvent(content, lifeCycle)
            )
        }
        return nextValidDate
    }

    // MARK: - AlarmManager

    @SuppressLint("MissingPermission")
    private fun scheduleNotificationWithAlarmManager(
        context: Context,
        model: Map<String, Any?>,
        schedule: NotificationScheduleModel,
        id: Int,
        nextValidDate: Calendar
    ) {
        val intent = Intent(context, ScheduledNotificationReceiver::class.java).apply {
            flags = Intent.FLAG_INCLUDE_STOPPED_PACKAGES
            putExtra(ScheduleKeys.EXTRA_NOTIFICATION_ID, id)
            putExtra(ScheduleKeys.EXTRA_NOTIFICATION_JSON, JsonUtils.getInstance().toJson(model))
        }
        val pendingIntent = PendingIntent.getBroadcast(context, id, intent, pendingFlags())

        val alarmManager = getAlarmManager(context)
        val timeMillis = nextValidDate.timeInMillis

        if (schedule.preciseAlarm == true && isPreciseAlarmGloballyAllowed(alarmManager)) {
            val category = ScheduleManager.contentOf(model)[ScheduleKeys.CATEGORY]
            if (category == ScheduleKeys.CATEGORY_ALARM) {
                val info = AlarmManager.AlarmClockInfo(timeMillis, pendingIntent)
                alarmManager.setAlarmClock(info, pendingIntent)
            } else {
                if (schedule.allowWhileIdle == true) {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
                    return
                }
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
            }
            return
        }

        if (schedule.delayTolerance == null) schedule.delayTolerance = 0

        if (schedule.allowWhileIdle == true) {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
            return
        }

        alarmManager.setWindow(
            AlarmManager.RTC, timeMillis, schedule.delayTolerance!!.toLong(), pendingIntent
        )
    }

    // MARK: - Refresh (boot / app start / listing)

    /**
     * 0.12 `refreshScheduledNotifications`: re-arms every stored schedule whose
     * alarm is gone (e.g. after a reboot), dropping the ones without a next date.
     */
    fun refreshScheduledNotifications(context: Context) {
        val ids = ScheduleManager.listScheduledIds(context)
        if (ids.isEmpty()) return

        for (id in ids) {
            if (isScheduleActiveOnAlarmManager(context, id)) continue

            val model = ScheduleManager.getScheduleById(context, id)
            @Suppress("UNCHECKED_CAST")
            val schedule = NotificationScheduleModel.getScheduleModelFromMap(
                model?.get(ScheduleKeys.SCHEDULE) as? Map<String, Any?>
            )
            if (model == null || schedule == null) {
                ScheduleManager.cancelScheduleById(context, id)
            } else if (schedule.hasNextValidDate()) {
                schedule(context, model, isReschedule = true)
            } else {
                ScheduleManager.removeSchedule(context, model)
            }
        }
    }

    // MARK: - Cancel

    fun cancelSchedule(context: Context, id: Int) {
        removeFromAlarm(context, id)
        ScheduleManager.cancelScheduleById(context, id)
    }

    fun cancelSchedulesByChannelKey(context: Context, channelKey: String) {
        removeAllFromAlarm(context, ScheduleManager.listScheduledIdsFromChannel(context, channelKey))
        ScheduleManager.cancelSchedulesByChannelKey(context, channelKey)
    }

    fun cancelSchedulesByGroupKey(context: Context, groupKey: String) {
        removeAllFromAlarm(context, ScheduleManager.listScheduledIdsFromGroup(context, groupKey))
        ScheduleManager.cancelSchedulesByGroupKey(context, groupKey)
    }

    fun cancelAllSchedules(context: Context) {
        removeAllFromAlarm(context, ScheduleManager.listScheduledIds(context))
        ScheduleManager.cancelAllSchedules(context)
    }

    private fun removeFromAlarm(context: Context, id: Int) {
        val intent = Intent(context, ScheduledNotificationReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(context, id, intent, pendingFlags())
        getAlarmManager(context).cancel(pendingIntent)
    }

    private fun removeAllFromAlarm(context: Context, ids: List<Int>) {
        val alarmManager = getAlarmManager(context)
        val intent = Intent(context, ScheduledNotificationReceiver::class.java)
        for (id in ids) {
            alarmManager.cancel(PendingIntent.getBroadcast(context, id, intent, pendingFlags()))
        }
    }

    @Throws(ScheduleException::class)
    fun isScheduleActiveOnAlarmManager(context: Context, notificationId: Int): Boolean {
        if (notificationId < 0) throw ScheduleException(
            ScheduleException.CODE_INVALID_ARGUMENTS,
            "Scheduled notification Id is invalid",
            ScheduleException.DETAILED_INVALID_ARGUMENTS + ".notificationId"
        )
        val intent = Intent(context, ScheduledNotificationReceiver::class.java)
        val flags =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
                PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_NO_CREATE
            else PendingIntent.FLAG_NO_CREATE
        return PendingIntent.getBroadcast(context, notificationId, intent, flags) != null
    }

    // MARK: - Helpers

    fun getAlarmManager(context: Context): AlarmManager =
        context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    fun isPreciseAlarmGloballyAllowed(alarmManager: AlarmManager): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) alarmManager.canScheduleExactAlarms()
        else true

    /** 0.12 `ChannelManager.isChannelEnabled` (Android 8+: the OS channel must exist and not be blocked). */
    private fun isChannelEnabled(context: Context, channelKey: String?): Boolean {
        if (channelKey.isNullOrEmpty()) return false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channel = manager.getNotificationChannel(channelKey) ?: return false
            return channel.importance != NotificationManager.IMPORTANCE_NONE
        }
        return true
    }

    @SuppressLint("WrongConstant")
    private fun pendingFlags(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
            PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        else PendingIntent.FLAG_UPDATE_CURRENT

    private fun generateNextRandomId(): Int {
        val randomValue = random.nextInt()
        return if (randomValue < 0) randomValue * -1 else randomValue
    }
}
