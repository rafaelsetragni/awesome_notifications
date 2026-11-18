package me.carda.awesome_notifications_schedules

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import androidx.test.core.app.ApplicationProvider
import me.carda.android_awn_core.AwesomeEventListener
import me.carda.android_awn_core.AwesomeEventsReceiver
import me.carda.android_awn_core.BuildOutcome
import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.JsonUtils
import me.carda.android_awn_core.NotificationBuilder
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/**
 * The scheduling decorator end to end on Robolectric: the builder's answers
 * (0.12: false when scheduled, an error when invalid), the persisted store, the
 * AlarmManager registration, the cancel interceptor, the channel methods, the
 * fire/repeat receiver and the refresh of lost alarms.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class ScheduleBuilderTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val alarmManager get() =
        context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    private val handler = ScheduleMethodHandler(context)

    private val events = mutableListOf<Pair<String, Map<String, Any?>>>()
    private val listener = object : AwesomeEventListener {
        override fun onNewAwesomeEvent(eventType: String, content: Map<String, Any?>) {
            events.add(eventType to content)
        }
    }

    @Before fun setUp() {
        SchedulesDatabase.resetForTest()
        AwesomeEventsReceiver.subscribe(listener)
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(
            NotificationChannel("ch", "Ch", NotificationManager.IMPORTANCE_DEFAULT)
        )
    }

    @After fun tearDown() {
        AwesomeEventsReceiver.unsubscribe(listener)
        SchedulesDatabase.resetForTest()
    }

    private fun model(
        id: Int,
        schedule: Map<String, Any?>?,
        channelKey: String = "ch",
        groupKey: String? = null
    ): Map<String, Any?> = buildMap {
        put(
            Definitions.NOTIFICATION_CONTENT,
            mapOf(
                Definitions.NOTIFICATION_ID to id,
                Definitions.NOTIFICATION_CHANNEL_KEY to channelKey,
                ScheduleKeys.GROUP_KEY to groupKey,
                Definitions.NOTIFICATION_TITLE to "T"
            )
        )
        if (schedule != null) put(ScheduleKeys.SCHEDULE, schedule)
    }

    private fun interval(seconds: Int, repeats: Boolean = false) = mapOf(
        ScheduleKeys.INTERVAL to seconds,
        ScheduleKeys.TIME_ZONE to "UTC",
        ScheduleKeys.REPEATS to repeats,
        ScheduleKeys.PRECISE_ALARM to true
    )

    private fun calendar(vararg entries: Pair<String, Any?>) = mapOf(
        ScheduleKeys.YEAR to null, ScheduleKeys.MONTH to null, ScheduleKeys.DAY to null,
        ScheduleKeys.HOUR to null, ScheduleKeys.MINUTE to null, ScheduleKeys.SECOND to null,
        ScheduleKeys.WEEKDAY to null, ScheduleKeys.TIME_ZONE to "UTC"
    ) + mapOf(*entries)

    private fun build(model: Map<String, Any?>): BuildOutcome =
        ScheduleBuilder(NotificationBuilder.getNewBuilder()).build(context, model)

    private fun listedIds(): List<Int?> = handler.listAllSchedules().map {
        @Suppress("UNCHECKED_CAST")
        ((it[Definitions.NOTIFICATION_CONTENT] as Map<String, Any?>)[Definitions.NOTIFICATION_ID] as? Number)?.toInt()
    }

    private fun alarmFor(id: Int): Boolean =
        NotificationScheduler.isScheduleActiveOnAlarmManager(context, id) &&
            shadowOf(alarmManager).scheduledAlarms.isNotEmpty()

    // MARK: - create

    @Test fun scheduledAnswersFalseStoresAndArmsTheAlarm() {
        assertEquals(BuildOutcome.Answered(false), build(model(1, interval(3600))))
        assertNotNull(shadowOf(alarmManager).peekNextScheduledAlarm())
        assertEquals(listOf(1), listedIds())
    }

    @Test fun schedulingEmitsCreatedEventWithScheduleSource() {
        build(model(2, interval(3600)))
        val created = events.firstOrNull { it.first == Definitions.EVENT_NOTIFICATION_CREATED }
        assertNotNull(created)
        assertEquals("Schedule", created!!.second[Definitions.NOTIFICATION_CREATED_SOURCE])
    }

    @Test fun invalidSchedulesFailAndAreNotStored() {
        for (schedule in listOf(
            interval(30, repeats = true),
            interval(0),
            calendar(ScheduleKeys.HOUR to 24),
            calendar()
        )) {
            val outcome = build(model(3, schedule))
            assertTrue("$schedule → $outcome", outcome is BuildOutcome.Failed)
            assertEquals(ScheduleException.CODE_INVALID_ARGUMENTS, (outcome as BuildOutcome.Failed).code)
        }
        assertTrue(listedIds().isEmpty())
        assertNull(shadowOf(alarmManager).peekNextScheduledAlarm())
    }

    @Test fun calendarWithoutNextDateAnswersFalseAndIsNotStored() {
        val outcome = build(model(4, calendar(
            ScheduleKeys.YEAR to 2020, ScheduleKeys.MONTH to 1, ScheduleKeys.DAY to 1, ScheduleKeys.HOUR to 0
        )))
        assertEquals(BuildOutcome.Answered(false), outcome)
        assertTrue(listedIds().isEmpty())
        assertTrue(events.none { it.first == Definitions.EVENT_NOTIFICATION_CREATED })
    }

    @Test fun unknownChannelFails() {
        val outcome = build(model(5, interval(3600), channelKey = "missing"))
        assertTrue(outcome is BuildOutcome.Failed)
        assertTrue(listedIds().isEmpty())
    }

    @Test fun modelWithoutScheduleDelegatesForImmediateDelivery() {
        assertTrue(build(model(6, null)) is BuildOutcome.Post)
    }

    @Test fun immediateNotificationReplacesStoredScheduleWithSameId() {
        build(model(7, interval(3600)))
        assertEquals(listOf(7), listedIds())
        build(model(7, null))
        assertTrue(listedIds().isEmpty())
    }

    @Test fun negativeIdGetsARandomPositiveOne() {
        build(model(-1, interval(3600)))
        val ids = listedIds()
        assertEquals(1, ids.size)
        assertTrue(ids.single()!! >= 0)
    }

    // MARK: - list / cancel

    @Test fun listedWeekdayIsIso() {
        build(model(8, calendar(ScheduleKeys.WEEKDAY to 1, ScheduleKeys.HOUR to 10)))
        @Suppress("UNCHECKED_CAST")
        val schedule = handler.listAllSchedules().single()[ScheduleKeys.SCHEDULE] as Map<String, Any?>
        assertEquals(1, schedule[ScheduleKeys.WEEKDAY])
        assertEquals(10, schedule[ScheduleKeys.HOUR])
        assertEquals("UTC", schedule[ScheduleKeys.TIME_ZONE])
    }

    @Test fun cancelByIdChannelGroupAndAll() {
        build(model(10, interval(3600, repeats = true), groupKey = "g1"))
        build(model(11, interval(3600, repeats = true), groupKey = "g2"))
        build(model(12, interval(3600, repeats = true)))

        handler.cancelSchedule(10)
        assertEquals(setOf(11, 12), listedIds().toSet())
        handler.cancelSchedulesByGroupKey("g2")
        assertEquals(listOf(12), listedIds())
        build(model(13, interval(3600, repeats = true)))
        handler.cancelSchedulesByChannelKey("ch")
        assertTrue(listedIds().isEmpty())

        build(model(14, interval(3600, repeats = true)))
        handler.cancelAllSchedules()
        assertTrue(listedIds().isEmpty())
        assertNull(shadowOf(alarmManager).peekNextScheduledAlarm())
    }

    @Test fun cancelInterceptorDropsAlarmAndStore() {
        build(model(15, interval(3600)))
        assertNotNull(shadowOf(alarmManager).peekNextScheduledAlarm())
        ScheduleCancelInterceptor().onCancel(context, 15)
        assertNull(shadowOf(alarmManager).peekNextScheduledAlarm())
        assertTrue(listedIds().isEmpty())

        build(model(16, interval(3600)))
        ScheduleCancelInterceptor().onCancelAll(context)
        assertTrue(listedIds().isEmpty())
    }

    @Test fun channelMethodsValidateTheirArgumentsLike012() {
        var error: String? = null
        var answered = false
        val handled = handler.handle(
            ScheduleKeys.METHOD_CANCEL_SCHEDULE, -1, { answered = true }
        ) { code, _, _ -> error = code }
        assertTrue(handled)
        assertFalse(answered)
        assertEquals(ScheduleException.CODE_INVALID_ARGUMENTS, error)

        error = null
        handler.handle(ScheduleKeys.METHOD_CANCEL_SCHEDULES_BY_CHANNEL_KEY, "", {}) { c, _, _ -> error = c }
        assertEquals(ScheduleException.CODE_INVALID_ARGUMENTS, error)

        assertFalse(handler.handle("someOtherMethod", null, {}) { _, _, _ -> })
    }

    @Test fun getNextDateRepliesLike012() {
        fun next(schedule: Map<String, Any?>): Any? {
            var reply: Any? = "unset"
            handler.handle(
                ScheduleKeys.METHOD_GET_NEXT_DATE,
                mapOf(ScheduleKeys.FIXED_DATE to "2026-07-05 08:30:00", ScheduleKeys.SCHEDULE to schedule),
                { reply = it }
            ) { _, _, _ -> reply = "error" }
            return reply
        }
        assertEquals("2026-07-05 08:31:30 UTC", next(interval(90)))
        assertEquals(
            "2026-07-05 09:00:00 America/Sao_Paulo",
            next(calendar(
                ScheduleKeys.HOUR to 9, ScheduleKeys.MINUTE to 0, ScheduleKeys.SECOND to 0,
                ScheduleKeys.TIME_ZONE to "America/Sao_Paulo"
            ))
        )
        assertEquals("2026-07-05 08:30:01 UTC", next(calendar(ScheduleKeys.MINUTE to 30)))
        assertNull(next(calendar(ScheduleKeys.YEAR to 2020, ScheduleKeys.MONTH to 1)))
        assertEquals("error", next(emptyMap()))
    }

    // MARK: - fire / repeat / refresh

    private fun fire(id: Int) {
        val stored = ScheduleManager.getScheduleById(context, id)!!
        ScheduledNotificationReceiver().fire(context, JsonUtils.getInstance().toJson(stored))
    }

    @Test fun firingANonRepeatingScheduleRemovesIt() {
        build(model(20, interval(3600)))
        fire(20)
        assertTrue(listedIds().isEmpty())
        assertTrue(events.any { it.first == Definitions.EVENT_NOTIFICATION_DISPLAYED })
    }

    @Test fun firingARepeatingScheduleReArmsIt() {
        build(model(21, interval(3600, repeats = true)))
        events.clear()
        fire(21)
        assertEquals(listOf(21), listedIds())
        assertTrue(alarmFor(21))
        // A re-arm is not a new creation.
        assertTrue(events.none { it.first == Definitions.EVENT_NOTIFICATION_CREATED })
    }

    @Test fun refreshReArmsLostAlarmsAndDropsExpiredOnes() {
        val stored = NotificationBuilder.getNewBuilder().stampCreatedLifecycle(
            model(22, NotificationIntervalModel().fromMap(interval(3600, repeats = true)).toMap())
        )
        ScheduleManager.saveSchedule(context, stored)
        // Non-repeating interval without createdDate: 0.12 drops it.
        ScheduleManager.saveSchedule(context, model(23, interval(3600)))
        assertFalse(NotificationScheduler.isScheduleActiveOnAlarmManager(context, 22))

        NotificationScheduler.refreshScheduledNotifications(context)

        assertTrue(NotificationScheduler.isScheduleActiveOnAlarmManager(context, 22))
        assertEquals(listOf(22), ScheduleManager.listScheduledIds(context))
    }

    @Test fun refreshReceiverIgnoresIntentsWithoutAction() {
        ScheduleManager.saveSchedule(context, model(24, interval(3600, repeats = true)))
        RefreshSchedulesReceiver().onReceive(context, Intent())
        assertFalse(NotificationScheduler.isScheduleActiveOnAlarmManager(context, 24))
    }
}
