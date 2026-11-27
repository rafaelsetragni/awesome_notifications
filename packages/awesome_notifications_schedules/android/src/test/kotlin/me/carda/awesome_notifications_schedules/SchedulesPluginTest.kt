package me.carda.awesome_notifications_schedules

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Looper
import androidx.test.core.app.ApplicationProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import me.carda.android_awn_core.AwesomeEventListener
import me.carda.android_awn_core.AwesomeEventsReceiver
import me.carda.android_awn_core.AwesomeMethodHandlerRegistry
import me.carda.android_awn_core.BuildOutcome
import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.JsonUtils
import me.carda.android_awn_core.NotificationBuilder
import me.carda.android_awn_core.NotificationBuilderRegistry
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowAlarmManager

/** A binding with only the application context (the plugin uses nothing else). */
private fun pluginBinding(context: Context): FlutterPlugin.FlutterPluginBinding {
    val constructor = FlutterPlugin.FlutterPluginBinding::class.java.declaredConstructors
        .first { it.parameterTypes.firstOrNull() == Context::class.java }
    constructor.isAccessible = true
    val args = constructor.parameterTypes.mapIndexed { i, _ -> if (i == 0) context else null }
    return constructor.newInstance(*args.toTypedArray()) as FlutterPlugin.FlutterPluginBinding
}

/** Waits for work done on another thread (the receivers' and the plugin's workers). */
private fun eventually(timeoutMs: Long = 5_000, condition: () -> Boolean) {
    val end = System.currentTimeMillis() + timeoutMs
    while (System.currentTimeMillis() < end) {
        shadowOf(Looper.getMainLooper()).idle()
        if (condition()) return
        Thread.sleep(20)
    }
    fail("condition not met in $timeoutMs ms")
}

private fun scheduleModel(
    id: Int,
    schedule: Map<String, Any?>?,
    channelKey: String = "ch",
    groupKey: String? = null,
    extraContent: Map<String, Any?> = mapOf(Definitions.NOTIFICATION_TITLE to "T")
): Map<String, Any?> = buildMap {
    put(
        Definitions.NOTIFICATION_CONTENT,
        mapOf(
            Definitions.NOTIFICATION_ID to id,
            Definitions.NOTIFICATION_CHANNEL_KEY to channelKey,
            ScheduleKeys.GROUP_KEY to groupKey
        ) + extraContent
    )
    if (schedule != null) put(ScheduleKeys.SCHEDULE, schedule)
}

private fun interval(seconds: Int, repeats: Boolean = false, precise: Boolean = true, whileIdle: Boolean = false) = mapOf(
    ScheduleKeys.INTERVAL to seconds,
    ScheduleKeys.TIME_ZONE to "UTC",
    ScheduleKeys.REPEATS to repeats,
    ScheduleKeys.PRECISE_ALARM to precise,
    ScheduleKeys.ALLOW_WHILE_IDLE to whileIdle
)

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class SchedulesPluginTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val alarmManager get() = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    private val handler = ScheduleMethodHandler(context)

    private val events = mutableListOf<Pair<String, Map<String, Any?>>>()
    private val listener = object : AwesomeEventListener {
        override fun onNewAwesomeEvent(eventType: String, content: Map<String, Any?>) {
            synchronized(events) { events.add(eventType to content) }
        }
    }

    private fun manager() = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    @Before fun setUp() {
        SchedulesDatabase.resetForTest()
        AwesomeEventsReceiver.subscribe(listener)
        manager().createNotificationChannel(NotificationChannel("ch", "Ch", NotificationManager.IMPORTANCE_DEFAULT))
    }

    @After fun tearDown() {
        AwesomeEventsReceiver.unsubscribe(listener)
        ShadowAlarmManager.setCanScheduleExactAlarms(false)
        SchedulesDatabase.resetForTest()
    }

    private fun build(model: Map<String, Any?>): BuildOutcome =
        ScheduleBuilder(NotificationBuilder.getNewBuilder()).build(context, model)

    private fun stored(id: Int) = ScheduleManager.getScheduleById(context, id)

    private fun displayed() = synchronized(events) { events.count { it.first == Definitions.EVENT_NOTIFICATION_DISPLAYED } }

    private data class Call(val handled: Boolean, val value: Any?, val error: Triple<String, String?, Any?>?)

    private fun call(method: String, arguments: Any? = null): Call {
        var value: Any? = "unanswered"
        var error: Triple<String, String?, Any?>? = null
        val handled = handler.handle(method, arguments, { value = it }) { c, m, d -> error = Triple(c, m, d) }
        return Call(handled, value, error)
    }

    // MARK: - Plugin

    @Test fun attachingInstallsTheDecoratorAndReArmsTheStoredSchedules() {
        val lost = NotificationBuilder.getNewBuilder().stampCreatedLifecycle(
            scheduleModel(30, NotificationIntervalModel().fromMap(interval(3600, repeats = true)).toMap())
        )
        ScheduleManager.saveSchedule(context, lost)
        assertFalse(NotificationScheduler.isScheduleActiveOnAlarmManager(context, 30))

        val plugin = AwesomeNotificationsSchedulesPlugin()
        val binding = pluginBinding(context)
        plugin.onAttachedToEngine(binding)
        try {
            assertTrue(NotificationBuilderRegistry.makeBuilder() is ScheduleBuilder)
            eventually { NotificationScheduler.isScheduleActiveOnAlarmManager(context, 30) }
            var listed: Any? = null
            assertTrue(AwesomeMethodHandlerRegistry.handle(ScheduleKeys.METHOD_LIST_ALL_SCHEDULES, null, { listed = it }))
            assertEquals(1, (listed as List<*>).size)
        } finally {
            plugin.onDetachedFromEngine(binding)
        }
        assertFalse(AwesomeMethodHandlerRegistry.handle(ScheduleKeys.METHOD_LIST_ALL_SCHEDULES, null, {}))
    }

    // MARK: - Receivers

    @Test fun theAlarmBroadcastPostsTheNotificationAndDropsTheSchedule() {
        build(scheduleModel(31, interval(3600)))
        val json = JsonUtils.getInstance().toJson(stored(31)!!)
        context.sendBroadcast(
            Intent(context, ScheduledNotificationReceiver::class.java)
                .putExtra(ScheduleKeys.EXTRA_NOTIFICATION_JSON, json)
        )
        eventually { stored(31) == null }
        eventually { manager().activeNotifications.any { it.id == 31 } }
        assertEquals(1, displayed())
    }

    @Test fun anAlarmBroadcastWithoutTheModelDoesNothing() {
        build(scheduleModel(32, interval(3600)))
        context.sendBroadcast(Intent(context, ScheduledNotificationReceiver::class.java))
        shadowOf(Looper.getMainLooper()).idle()
        Thread.sleep(100)
        assertNotNull(stored(32))
        assertTrue(manager().activeNotifications.isEmpty())
    }

    @Test fun anUnreadableModelIsLoggedAndTheReceiverFinishes() {
        context.sendBroadcast(
            Intent(context, ScheduledNotificationReceiver::class.java)
                .putExtra(ScheduleKeys.EXTRA_NOTIFICATION_JSON, "{not json")
        )
        shadowOf(Looper.getMainLooper()).idle()
        Thread.sleep(200)
        assertTrue(manager().activeNotifications.isEmpty())
        assertEquals(0, displayed())
    }

    @Test fun firingWithoutTitleOrBodyShowsNothingButStillEndsTheSchedule() {
        build(scheduleModel(33, interval(3600), extraContent = emptyMap()))
        ScheduledNotificationReceiver().fire(context, JsonUtils.getInstance().toJson(stored(33)!!))
        assertNull(stored(33))
        assertTrue(manager().activeNotifications.isEmpty())
        assertEquals(0, displayed())
    }

    @Test fun firingAModelWithoutAScheduleOnlyShowsIt() {
        build(scheduleModel(34, interval(3600, repeats = true)))
        val other = scheduleModel(35, null)
        ScheduledNotificationReceiver().fire(context, JsonUtils.getInstance().toJson(other))
        shadowOf(Looper.getMainLooper()).idle()
        assertTrue(manager().activeNotifications.any { it.id == 35 })
        assertNotNull(stored(34))
    }

    @Test fun theRefreshBroadcastReArmsTheLostAlarms() {
        val lost = NotificationBuilder.getNewBuilder().stampCreatedLifecycle(
            scheduleModel(36, NotificationIntervalModel().fromMap(interval(3600, repeats = true)).toMap())
        )
        ScheduleManager.saveSchedule(context, lost)
        context.sendBroadcast(Intent(Intent.ACTION_BOOT_COMPLETED).setClass(context, RefreshSchedulesReceiver::class.java))
        eventually { NotificationScheduler.isScheduleActiveOnAlarmManager(context, 36) }
    }

    @Test fun refreshDropsAStoredModelWithoutAReadableSchedule() {
        ScheduleManager.saveSchedule(context, scheduleModel(37, mapOf("unknown" to 1)))
        assertEquals(listOf(37), ScheduleManager.listScheduledIds(context))
        NotificationScheduler.refreshScheduledNotifications(context)
        assertTrue(ScheduleManager.listScheduledIds(context).isEmpty())
    }

    // MARK: - Alarms

    @Test fun aPreciseAlarmCategoryIsAnAlarmClock() {
        ShadowAlarmManager.setCanScheduleExactAlarms(true)
        build(scheduleModel(40, interval(3600),
            extraContent = mapOf(Definitions.NOTIFICATION_TITLE to "Wake up", ScheduleKeys.CATEGORY to "Alarm")))
        val clock = alarmManager.nextAlarmClock
        assertNotNull(clock)
        val expected = System.currentTimeMillis() + 3_600_000
        assertTrue(Math.abs(clock!!.triggerTime - expected) < 5_000)
    }

    @Test fun aPreciseAlarmIsExact() {
        ShadowAlarmManager.setCanScheduleExactAlarms(true)
        build(scheduleModel(41, interval(3600)))
        val alarm = shadowOf(alarmManager).scheduledAlarms.single()
        assertEquals(AlarmManager.RTC_WAKEUP, alarm.type)
        assertFalse(alarm.allowWhileIdle)
        assertNull(alarmManager.nextAlarmClock)
    }

    @Test fun aPreciseAlarmAllowedWhileIdle() {
        ShadowAlarmManager.setCanScheduleExactAlarms(true)
        build(scheduleModel(42, interval(3600, whileIdle = true)))
        val alarm = shadowOf(alarmManager).scheduledAlarms.single()
        assertEquals(AlarmManager.RTC_WAKEUP, alarm.type)
        assertTrue(alarm.allowWhileIdle)
    }

    @Test fun anInexactAlarmAllowedWhileIdle() {
        build(scheduleModel(43, interval(3600, precise = false, whileIdle = true)))
        val alarm = shadowOf(alarmManager).scheduledAlarms.single()
        assertEquals(AlarmManager.RTC_WAKEUP, alarm.type)
        assertTrue(alarm.allowWhileIdle)
    }

    @Test fun anInexactAlarmIsAWindowThatDoesNotWakeTheDevice() {
        build(scheduleModel(44, interval(3600, precise = false)))
        val alarm = shadowOf(alarmManager).scheduledAlarms.single()
        assertEquals(AlarmManager.RTC, alarm.type)
        assertFalse(alarm.allowWhileIdle)
    }

    // MARK: - Builder failures

    @Test fun disabledNotificationsFailTheSchedule() {
        shadowOf(manager()).setNotificationsEnabled(false)
        val outcome = build(scheduleModel(45, interval(3600))) as BuildOutcome.Failed
        assertEquals(ScheduleException.CODE_INSUFFICIENT_PERMISSIONS, outcome.code)
        assertEquals("insufficientPermissions.global", outcome.details)
        assertNull(stored(45))
    }

    @Test fun anUnknownTimeZoneFailsTheSchedule() {
        val schedule = mapOf(ScheduleKeys.HOUR to 9, ScheduleKeys.TIME_ZONE to "Mars/Olympus")
        val outcome = build(scheduleModel(46, schedule)) as BuildOutcome.Failed
        assertEquals(ScheduleException.CODE_INVALID_ARGUMENTS, outcome.code)
        assertEquals("arguments.invalid.calendar.timeZone", outcome.details)
    }

    @Test fun schedulingAModelWithoutAScheduleFails() {
        try {
            NotificationScheduler.schedule(context, scheduleModel(47, null), isReschedule = false)
            fail("expected a ScheduleException")
        } catch (e: ScheduleException) {
            assertEquals("Invalid notification content", e.message)
            assertEquals("arguments.invalid.notificationModel", e.detailedCode)
        }
    }

    @Test fun aNegativeIdIsNeverActive() {
        try {
            NotificationScheduler.isScheduleActiveOnAlarmManager(context, -1)
            fail("expected a ScheduleException")
        } catch (e: ScheduleException) {
            assertEquals("Scheduled notification Id is invalid", e.message)
            assertEquals("arguments.invalid.notificationId", e.detailedCode)
        }
    }

    // MARK: - Cancel interceptor

    @Test fun theInterceptorCancelsByChannelAndGroupButIgnoresEmptyKeys() {
        build(scheduleModel(50, interval(3600), groupKey = "g"))
        build(scheduleModel(51, interval(3600)))
        val interceptor = ScheduleCancelInterceptor()
        interceptor.onCancel(context, -1)
        interceptor.onCancelByGroupKey(context, "")
        interceptor.onCancelByChannelKey(context, "")
        assertEquals(setOf(50, 51), ScheduleManager.listScheduledIds(context).toSet())

        interceptor.onCancelByGroupKey(context, "g")
        assertEquals(listOf(51), ScheduleManager.listScheduledIds(context))
        assertEquals(1, shadowOf(alarmManager).scheduledAlarms.size)
        interceptor.onCancelByChannelKey(context, "ch")
        assertTrue(ScheduleManager.listScheduledIds(context).isEmpty())
        assertTrue(shadowOf(alarmManager).scheduledAlarms.isEmpty())
    }

    // MARK: - Channel methods

    @Test fun everyManagementMethodAnswersThroughHandle() {
        build(scheduleModel(60, interval(3600), groupKey = "g"))
        build(scheduleModel(61, interval(3600), groupKey = "h"))
        build(scheduleModel(62, interval(3600)))
        build(scheduleModel(63, interval(3600)))

        assertEquals(4, (call(ScheduleKeys.METHOD_LIST_ALL_SCHEDULES).value as List<*>).size)
        assertEquals(Call(true, true, null), call(ScheduleKeys.METHOD_CANCEL_SCHEDULE, 60))
        assertEquals(Call(true, true, null), call(ScheduleKeys.METHOD_CANCEL_SCHEDULES_BY_GROUP_KEY, "h"))
        assertEquals(listOf(62, 63), ScheduleManager.listScheduledIds(context).sorted())
        assertEquals(Call(true, true, null), call(ScheduleKeys.METHOD_CANCEL_SCHEDULES_BY_CHANNEL_KEY, "ch"))
        assertTrue(ScheduleManager.listScheduledIds(context).isEmpty())
        build(scheduleModel(64, interval(3600)))
        assertEquals(Call(true, true, null), call(ScheduleKeys.METHOD_CANCEL_ALL_SCHEDULES))
        assertTrue(ScheduleManager.listScheduledIds(context).isEmpty())
    }

    @Test fun theListDropsAScheduleBlockItCannotRead() {
        // Its alarm is armed (so the refresh before listing leaves it alone)...
        build(scheduleModel(65, interval(3600)))
        // ...but the stored model has no readable schedule.
        ScheduleManager.saveSchedule(context, scheduleModel(65, mapOf("unknown" to 1)))
        @Suppress("UNCHECKED_CAST")
        val listed = call(ScheduleKeys.METHOD_LIST_ALL_SCHEDULES).value as List<Map<String, Any?>>
        assertFalse(listed.single().containsKey(ScheduleKeys.SCHEDULE))
    }

    @Test fun invalidKeysAndIdsAreRejectedLike012() {
        assertEquals(
            Triple("INVALID_ARGUMENTS", "Invalid groupKey value", "arguments.invalid.dismiss.groupKey"),
            call(ScheduleKeys.METHOD_CANCEL_SCHEDULES_BY_GROUP_KEY, null).error
        )
        assertEquals(
            Triple("INVALID_ARGUMENTS", "Invalid channel Key value", "arguments.invalid.dismiss.channelKey"),
            call(ScheduleKeys.METHOD_CANCEL_SCHEDULES_BY_CHANNEL_KEY, 1).error
        )
        assertEquals(
            Triple("INVALID_ARGUMENTS", "Invalid id value", "arguments.invalid.dismiss.id"),
            call(ScheduleKeys.METHOD_CANCEL_SCHEDULE, "1").error
        )
    }

    @Test fun getNextDateRejectsUnreadableScheduleData() {
        val invalid = Triple("INVALID_ARGUMENTS", "Schedule data is invalid", "arguments.invalid.schedule.data")
        assertEquals(invalid, call(ScheduleKeys.METHOD_GET_NEXT_DATE, "schedule").error)
        assertEquals(invalid, call(ScheduleKeys.METHOD_GET_NEXT_DATE, mapOf(ScheduleKeys.SCHEDULE to emptyMap<String, Any?>())).error)
        assertEquals(invalid, call(ScheduleKeys.METHOD_GET_NEXT_DATE, mapOf(ScheduleKeys.SCHEDULE to mapOf("unknown" to 1))).error)
    }

    @Test fun anUnexpectedFailureIsAnUnknownException() {
        // A precise date that is not a string breaks the parsing itself.
        val call = call(ScheduleKeys.METHOD_GET_NEXT_DATE, mapOf(
            ScheduleKeys.SCHEDULE to mapOf(ScheduleKeys.PRECISE_SCHEDULES to listOf(123))
        ))
        assertTrue(call.handled)
        assertEquals("UNKNOWN_EXCEPTION", call.error!!.first)
        assertNotNull(call.error!!.second)
        assertEquals("unexpectedError", call.error!!.third)
    }

    @Test fun getNextDateWithoutAFixedDateIsFromNow() {
        val next = call(ScheduleKeys.METHOD_GET_NEXT_DATE, mapOf(ScheduleKeys.SCHEDULE to interval(3600))).value as String
        val expected = ScheduleCalendarUtils.getCurrentCalendar().apply { add(java.util.Calendar.SECOND, 3600) }
        val parsed = ScheduleCalendarUtils.calendarFromString(next)!!
        assertTrue(Math.abs(parsed.timeInMillis - expected.timeInMillis) < 5_000)
    }

    @Test fun withoutAnErrorCallbackAFailureAnswersNull() {
        var value: Any? = "unset"
        assertTrue(handler.handle(ScheduleKeys.METHOD_CANCEL_SCHEDULE, -5) { value = it })
        assertNull(value)
    }
}

/** Android 7.1: no channels, no exact-alarm permission, immutable-by-default intents. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [25])
class SchedulesBeforeAndroid8Test {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val alarmManager get() = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    @Before fun setUp() = SchedulesDatabase.resetForTest()
    @After fun tearDown() = SchedulesDatabase.resetForTest()

    @Test fun anyChannelKeyIsEnabledAndAPreciseAlarmIsExact() {
        val outcome = ScheduleBuilder(NotificationBuilder.getNewBuilder())
            .build(context, scheduleModel(70, interval(3600), channelKey = "any"))
        assertEquals(BuildOutcome.Answered(false), outcome)
        assertTrue(NotificationScheduler.isScheduleActiveOnAlarmManager(context, 70))
        assertTrue(NotificationScheduler.isPreciseAlarmGloballyAllowed(alarmManager))
        val alarm = shadowOf(alarmManager).scheduledAlarms.single()
        assertEquals(AlarmManager.RTC_WAKEUP, alarm.type)
    }

    @Test fun aScheduleStillNeedsAChannelKey() {
        val outcome = ScheduleBuilder(NotificationBuilder.getNewBuilder())
            .build(context, scheduleModel(71, interval(3600), channelKey = "")) as BuildOutcome.Failed
        assertEquals(ScheduleException.CODE_INVALID_ARGUMENTS, outcome.code)
        assertEquals("insufficientPermissions.channel.", outcome.details)
    }
}
