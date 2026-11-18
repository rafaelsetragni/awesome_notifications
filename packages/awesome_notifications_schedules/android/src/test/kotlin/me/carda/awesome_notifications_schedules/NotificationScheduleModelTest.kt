package me.carda.awesome_notifications_schedules

import java.util.Calendar
import java.util.TimeZone
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test

/**
 * The ported 0.12 schedule models: next-date math (Quartz cron for calendars,
 * fixed + interval for intervals), validation, type resolution and
 * serialization. Expected values are the ones 0.12 itself answered (they are
 * the same as the compat suite's Android reference table).
 */
class NotificationScheduleModelTest {

    /** The suite's fixed "now": Sunday 2026-07-05 08:30:00 UTC. */
    private fun fixedDate(): Calendar =
        ScheduleCalendarUtils.calendarFromString("2026-07-05 08:30:00")!!

    private fun calendar(vararg entries: Pair<String, Any?>): Map<String, Any?> =
        // Like the Dart side: every component key is present, null when unset.
        listOf(
            ScheduleKeys.ERA, ScheduleKeys.YEAR, ScheduleKeys.MONTH, ScheduleKeys.DAY,
            ScheduleKeys.HOUR, ScheduleKeys.MINUTE, ScheduleKeys.SECOND,
            ScheduleKeys.WEEKDAY, ScheduleKeys.WEEK_OF_MONTH, ScheduleKeys.WEEK_OF_YEAR
        ).associateWith { null as Any? } + mapOf(
            ScheduleKeys.TIME_ZONE to "UTC",
            ScheduleKeys.REPEATS to false,
            ScheduleKeys.ALLOW_WHILE_IDLE to false,
            ScheduleKeys.PRECISE_ALARM to true,
            ScheduleKeys.DELAY_TOLERANCE to 600000
        ) + mapOf(*entries)

    private fun interval(seconds: Int, vararg entries: Pair<String, Any?>): Map<String, Any?> =
        mapOf(
            ScheduleKeys.INTERVAL to seconds,
            ScheduleKeys.TIME_ZONE to "UTC",
            ScheduleKeys.REPEATS to false
        ) + mapOf(*entries)

    private fun next(schedule: Map<String, Any?>): String? =
        ScheduleCalendarUtils.calendarToString(
            NotificationScheduleModel.getScheduleModelFromMap(schedule)!!
                .getNextValidDate(fixedDate())
        )

    // MARK: - next date (0.12 reference values)

    @Test fun intervalIsFixedDatePlusInterval() {
        assertEquals("2026-07-05 08:31:30 UTC", next(interval(90)))
        assertEquals("2026-07-05 08:31:30 UTC", next(interval(90, ScheduleKeys.REPEATS to true)))
        // The interval keeps the fixed date's (UTC) zone, whatever the schedule zone.
        assertEquals(
            "2026-07-05 08:31:30 UTC",
            next(interval(90, ScheduleKeys.TIME_ZONE to "America/Sao_Paulo"))
        )
    }

    @Test fun calendarAnswersTheWallClockOfTheScheduleZone() {
        assertEquals(
            "2026-07-05 09:00:00 UTC",
            next(calendar(ScheduleKeys.HOUR to 9, ScheduleKeys.MINUTE to 0, ScheduleKeys.SECOND to 0))
        )
        assertEquals(
            "2026-07-05 09:00:00 America/Sao_Paulo",
            next(calendar(
                ScheduleKeys.HOUR to 9, ScheduleKeys.MINUTE to 0, ScheduleKeys.SECOND to 0,
                ScheduleKeys.TIME_ZONE to "America/Sao_Paulo"
            ))
        )
        assertEquals(
            "2026-07-05 09:00:00 America/New_York",
            next(calendar(
                ScheduleKeys.HOUR to 9, ScheduleKeys.MINUTE to 0, ScheduleKeys.SECOND to 0,
                ScheduleKeys.TIME_ZONE to "America/New_York"
            ))
        )
    }

    @Test fun freeComponentsFollowQuartzCron() {
        assertEquals("2026-07-05 09:00:00 UTC", next(calendar(ScheduleKeys.HOUR to 9)))
        // The second is free: 08:30:00 + 1 s still matches minute 30.
        assertEquals("2026-07-05 08:30:01 UTC", next(calendar(ScheduleKeys.MINUTE to 30)))
        assertEquals("2026-07-05 08:30:15 UTC", next(calendar(ScheduleKeys.SECOND to 15)))
        assertEquals("2026-07-10 00:00:00 UTC", next(calendar(ScheduleKeys.DAY to 10)))
        assertEquals("2026-09-01 00:00:00 UTC", next(calendar(ScheduleKeys.MONTH to 9)))
        assertEquals(
            "2026-07-05 09:15:00 UTC",
            next(calendar(ScheduleKeys.HOUR to 9, ScheduleKeys.MINUTE to 15))
        )
        assertEquals(
            "2026-07-06 08:30:00 UTC",
            next(calendar(ScheduleKeys.HOUR to 8, ScheduleKeys.MINUTE to 30, ScheduleKeys.SECOND to 0))
        )
    }

    @Test fun weekdayIsIsoAndWeekOfYearIsIgnored() {
        assertEquals(
            "2026-07-06 10:00:00 UTC",
            next(calendar(ScheduleKeys.WEEKDAY to 1, ScheduleKeys.HOUR to 10))
        )
        assertEquals(
            "2026-07-05 10:00:00 UTC",
            next(calendar(ScheduleKeys.WEEKDAY to 7, ScheduleKeys.HOUR to 10))
        )
        assertEquals(
            "2026-07-08 00:00:00 UTC",
            next(calendar(ScheduleKeys.WEEK_OF_YEAR to 28, ScheduleKeys.WEEKDAY to 3))
        )
    }

    @Test fun datesWithAndWithoutFutureOccurrence() {
        assertEquals(
            "2028-02-29 12:00:00 UTC",
            next(calendar(ScheduleKeys.MONTH to 2, ScheduleKeys.DAY to 29, ScheduleKeys.HOUR to 12))
        )
        assertNull(next(calendar(
            ScheduleKeys.YEAR to 2020, ScheduleKeys.MONTH to 1, ScheduleKeys.DAY to 1, ScheduleKeys.HOUR to 0
        )))
        assertEquals(
            "2027-02-01 08:00:00 UTC",
            next(calendar(
                ScheduleKeys.YEAR to 2027, ScheduleKeys.MONTH to 2, ScheduleKeys.DAY to 1, ScheduleKeys.HOUR to 8
            ))
        )
    }

    @Test fun cronExpressionMatches012() {
        val model = NotificationCalendarModel().fromMap(
            calendar(ScheduleKeys.WEEKDAY to 1, ScheduleKeys.HOUR to 10)
        )
        assertEquals("* * 10 ? * 2 *", model.cronExpression())
        assertEquals(
            "0 15 9 1 * ? 2027",
            NotificationCalendarModel().fromMap(calendar(
                ScheduleKeys.SECOND to 0, ScheduleKeys.MINUTE to 15, ScheduleKeys.HOUR to 9,
                ScheduleKeys.DAY to 1, ScheduleKeys.YEAR to 2027
            )).cronExpression()
        )
    }

    // MARK: - validation

    private fun assertInvalid(schedule: Map<String, Any?>) {
        try {
            NotificationScheduleModel.getScheduleModelFromMap(schedule)!!.validate()
            fail("expected a ScheduleException")
        } catch (e: ScheduleException) {
            assertEquals(ScheduleException.CODE_INVALID_ARGUMENTS, e.code)
        }
    }

    @Test fun validationRejectsWhat012Rejected() {
        assertInvalid(interval(30, ScheduleKeys.REPEATS to true)) // repeating < 60 s
        assertInvalid(interval(0))
        assertInvalid(interval(4)) // < 5 s
        assertInvalid(calendar(ScheduleKeys.HOUR to 24))
        assertInvalid(calendar()) // no component
        assertInvalid(calendar(ScheduleKeys.WEEKDAY to 8))
        assertInvalid(calendar(ScheduleKeys.MONTH to 0))
        // Accepted ones.
        NotificationScheduleModel.getScheduleModelFromMap(interval(60, ScheduleKeys.REPEATS to true))!!.validate()
        NotificationScheduleModel.getScheduleModelFromMap(interval(5))!!.validate()
        NotificationScheduleModel.getScheduleModelFromMap(calendar(ScheduleKeys.SECOND to 0))!!.validate()
    }

    // MARK: - type resolution / serialization

    @Test fun theKeysDecideTheScheduleType() {
        assertTrue(NotificationScheduleModel.getScheduleModelFromMap(calendar()) is NotificationCalendarModel)
        assertTrue(NotificationScheduleModel.getScheduleModelFromMap(interval(60)) is NotificationIntervalModel)
        assertTrue(
            NotificationScheduleModel.getScheduleModelFromMap(
                mapOf(ScheduleKeys.CRONTAB_EXPRESSION to "0 0 * * * ? *")
            ) is NotificationCrontabModel
        )
        assertNull(NotificationScheduleModel.getScheduleModelFromMap(emptyMap()))
        assertNull(NotificationScheduleModel.getScheduleModelFromMap(mapOf(ScheduleKeys.REPEATS to true)))
    }

    @Test fun weekdayIsStoredStandardAndSerializedIso() {
        val model = NotificationCalendarModel().fromMap(calendar(ScheduleKeys.WEEKDAY to 7))
        assertEquals(1, model.weekday) // Sunday, standard
        val map = model.toMap()
        assertEquals(7, map[ScheduleKeys.WEEKDAY])
        assertEquals("UTC", map[ScheduleKeys.TIME_ZONE])
        assertFalse(map.containsKey(ScheduleKeys.HOUR)) // nulls are omitted
        assertEquals(600000, map[ScheduleKeys.DELAY_TOLERANCE])
    }

    @Test fun unknownTimeZoneIsNullAndCalendarFails() {
        val model = NotificationCalendarModel().fromMap(
            calendar(ScheduleKeys.HOUR to 9, ScheduleKeys.TIME_ZONE to "Mars/Olympus")
        )
        assertNull(model.timeZone)
        try {
            model.getNextValidDate(fixedDate())
            fail("expected a ScheduleException")
        } catch (e: ScheduleException) {
            assertEquals("Invalid time zone", e.message)
        }
        // No time zone at all: the device default.
        val default = NotificationCalendarModel().fromMap(mapOf(ScheduleKeys.HOUR to 9))
        assertEquals(TimeZone.getDefault().id, default.timeZone?.id)
    }

    @Test fun hasNextValidDateFollows012() {
        // Non-repeating without createdDate: never (0.12 drops it on refresh).
        assertFalse(NotificationScheduleModel.getScheduleModelFromMap(interval(3600))!!.hasNextValidDate())
        assertTrue(
            NotificationScheduleModel.getScheduleModelFromMap(
                interval(3600, ScheduleKeys.REPEATS to true)
            )!!.hasNextValidDate()
        )
    }

    @Test fun crontabPicksTheEarliestOfCronAndPreciseDates() {
        val model = NotificationCrontabModel().fromMap(mapOf(
            ScheduleKeys.TIME_ZONE to "UTC",
            ScheduleKeys.CRONTAB_EXPRESSION to "0 0 12 * * ? *",
            ScheduleKeys.PRECISE_SCHEDULES to listOf("2026-07-05 10:00:00", "2026-07-05 08:00:00")
        ))
        model.validate()
        assertEquals(
            "2026-07-05 10:00:00 UTC",
            ScheduleCalendarUtils.calendarToString(model.getNextValidDate(fixedDate()))
        )
    }

    // MARK: - calendar utils

    @Test fun calendarStringsRoundTrip() {
        val parsed = ScheduleCalendarUtils.calendarFromString("2026-07-05 08:30:00 America/Sao_Paulo")!!
        // 0.12 quirk: always parsed as UTC.
        assertEquals("2026-07-05 08:30:00 UTC", ScheduleCalendarUtils.calendarToString(parsed))
        assertNull(ScheduleCalendarUtils.calendarFromString("05/07/2026"))
        assertEquals("GMT-03:00", ScheduleCalendarUtils.getValidTimeZone("-03")?.id)
        assertNull(ScheduleCalendarUtils.getValidTimeZone("Nowhere/Land"))
    }
}
