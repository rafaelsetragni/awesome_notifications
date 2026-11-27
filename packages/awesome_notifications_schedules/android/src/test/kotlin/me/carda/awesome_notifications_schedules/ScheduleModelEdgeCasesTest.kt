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
 * The 0.12 schedule models' less common paths: the properties as a public API,
 * every out-of-range calendar component, the crontab's validation, expiry and
 * serialization, and the errors of the next-date math.
 */
class ScheduleModelEdgeCasesTest {

    /** Sunday 2026-07-05 08:30:00 UTC. */
    private fun fixedDate(): Calendar =
        ScheduleCalendarUtils.calendarFromString("2026-07-05 08:30:00")!!

    private fun date(text: String) = ScheduleCalendarUtils.calendarFromString(text)!!

    private fun string(calendar: Calendar?) = ScheduleCalendarUtils.calendarToString(calendar)

    private fun failure(block: () -> Unit): ScheduleException {
        try {
            block()
        } catch (e: ScheduleException) {
            return e
        }
        fail("expected a ScheduleException")
        throw AssertionError()
    }

    // MARK: - Calendar

    @Test fun calendarPropertiesAreReadAndWritten() {
        val model = NotificationCalendarModel().apply {
            timeZone = TimeZone.getTimeZone("UTC")
            era = 1
            year = 2027
            month = 3
            day = 4
            hour = 5
            minute = 6
            second = 7
            millisecond = 8
            weekOfMonth = 2
            weekOfYear = 10
            repeats = true
            allowWhileIdle = true
            preciseAlarm = true
            delayTolerance = 5000
            createdDate = fixedDate()
        }
        model.validate()
        assertEquals("7 6 5 4 3 ? 2027", model.cronExpression())
        val map = model.toMap()
        assertEquals(
            mapOf(
                ScheduleKeys.TIME_ZONE to "UTC",
                ScheduleKeys.CREATED_DATE to "2026-07-05 08:30:00 UTC",
                ScheduleKeys.REPEATS to true,
                ScheduleKeys.ALLOW_WHILE_IDLE to true,
                ScheduleKeys.PRECISE_ALARM to true,
                ScheduleKeys.DELAY_TOLERANCE to 5000,
                ScheduleKeys.ERA to 1,
                ScheduleKeys.YEAR to 2027,
                ScheduleKeys.MONTH to 3,
                ScheduleKeys.DAY to 4,
                ScheduleKeys.HOUR to 5,
                ScheduleKeys.MINUTE to 6,
                ScheduleKeys.SECOND to 7,
                ScheduleKeys.MILLISECOND to 8,
                ScheduleKeys.WEEK_OF_MONTH to 2,
                ScheduleKeys.WEEK_OF_YEAR to 10
            ),
            map
        )
        // And read back from the map, the same components.
        val parsed = NotificationCalendarModel().fromMap(map)
        assertEquals(listOf(1, 2027, 3, 4, 5, 6, 7, 8, 2, 10),
            listOf(parsed.era, parsed.year, parsed.month, parsed.day, parsed.hour, parsed.minute,
                parsed.second, parsed.millisecond, parsed.weekOfMonth, parsed.weekOfYear))
        assertEquals(true, parsed.repeats)
        assertEquals(true, parsed.allowWhileIdle)
        assertEquals(5000, parsed.delayTolerance)
        assertEquals("2026-07-05 08:30:00 UTC", string(parsed.createdDate))
    }

    @Test fun everyOutOfRangeComponentIsRejected() {
        val invalid: List<NotificationCalendarModel.() -> Unit> = listOf(
            { era = -1 }, { year = -1 }, { month = 13 }, { day = 0 }, { day = 32 },
            { hour = -1 }, { minute = 60 }, { second = 60 }, { millisecond = 1000 },
            { weekday = 0 }, { weekOfMonth = 0 }, { weekOfMonth = 7 }, { weekOfYear = 54 }
        )
        for (setUp in invalid) {
            val e = failure { NotificationCalendarModel().apply(setUp).validate() }
            assertEquals(ScheduleException.CODE_INVALID_ARGUMENTS, e.code)
            assertEquals("The time conditions are invalid", e.message)
            assertEquals("arguments.invalid.notificationCalendar", e.detailedCode)
        }
        val none = failure { NotificationCalendarModel().validate() }
        assertEquals("At least one time condition is required", none.message)
        // Only the ignored components are still conditions.
        NotificationCalendarModel().apply { era = 0 }.validate()
        NotificationCalendarModel().apply { weekOfYear = 53 }.validate()
    }

    @Test fun aCalendarWithoutAFixedDateFailsAsAnUnknownError() {
        val model = NotificationCalendarModel().apply { timeZone = TimeZone.getTimeZone("UTC"); hour = 9 }
        val e = failure { model.getNextValidDate(null) }
        assertEquals(ScheduleException.CODE_UNKNOWN_EXCEPTION, e.code)
        assertEquals("Invalid fixed date", e.message)
        assertEquals(ScheduleException.DETAILED_UNEXPECTED_ERROR, e.detailedCode)
    }

    @Test fun aCreatedDateThatIsNotAStringIsIgnored() {
        val model = NotificationScheduleModel.getScheduleModelFromMap(
            mapOf(ScheduleKeys.INTERVAL to 60, ScheduleKeys.CREATED_DATE to 1234)
        )!!
        assertNull(model.createdDate)
        val parsed = NotificationScheduleModel.getScheduleModelFromMap(
            mapOf(ScheduleKeys.INTERVAL to 60, ScheduleKeys.CREATED_DATE to "2026-07-05 08:30:00")
        )!!
        assertEquals("2026-07-05 08:30:00 UTC", string(parsed.createdDate))
    }

    @Test fun aNullRepeatsIsTreatedAsFalse() {
        val model = NotificationIntervalModel().apply { interval = 60; repeats = null }
        assertFalse(model.hasNextValidDate())
        assertEquals(false, model.repeats)
    }

    // MARK: - Interval

    @Test fun anIntervalWithoutItsValueHasNoNextDate() {
        val e = failure { NotificationIntervalModel().getNextValidDate(fixedDate()) }
        assertEquals("Interval is required and must be greater than 5", e.message)
        assertEquals("arguments.invalid.notificationInterval.interval", e.detailedCode)
    }

    @Test fun aRepeatingIntervalCreatedInTheFutureStartsFromItsCreation() {
        val model = NotificationIntervalModel().apply {
            interval = 60
            repeats = true
            timeZone = TimeZone.getTimeZone("UTC")
            createdDate = date("2026-07-05 09:00:00")
        }
        // 30 minutes after now = 1800 s, a multiple of 60: a full interval after the creation.
        assertEquals("2026-07-05 09:01:00 UTC", string(model.getNextValidDate(fixedDate())))
        assertEquals(mapOf(
            ScheduleKeys.TIME_ZONE to "UTC", ScheduleKeys.CREATED_DATE to "2026-07-05 09:00:00 UTC",
            ScheduleKeys.REPEATS to true, ScheduleKeys.INTERVAL to 60
        ), model.toMap())
    }

    @Test fun aNonRepeatingIntervalAlreadyPastHasNoNextDate() {
        val model = NotificationIntervalModel().apply {
            interval = 60
            repeats = false
            createdDate = date("2026-07-05 07:00:00")
        }
        assertNull(model.getNextValidDate(fixedDate()))
        assertFalse(model.hasNextValidDate(fixedDate()))
    }

    // MARK: - Crontab

    @Test fun crontabPropertiesAreSerialized() {
        val model = NotificationCrontabModel().apply {
            timeZone = TimeZone.getTimeZone("UTC")
            initialDateTime = date("2026-07-01 00:00:00")
            expirationDateTime = date("2026-08-01 00:00:00")
            crontabExpression = "0 0 12 * * ? *"
            preciseSchedules = listOf(date("2026-07-10 10:00:00"), null)
        }
        model.validate()
        val map = model.toMap()
        assertEquals("2026-07-01 00:00:00 UTC", map[ScheduleKeys.INITIAL_DATE_TIME])
        assertEquals("2026-08-01 00:00:00 UTC", map[ScheduleKeys.EXPIRATION_DATE_TIME])
        assertEquals("0 0 12 * * ? *", map[ScheduleKeys.CRONTAB_EXPRESSION])
        // The unparseable (null) dates are dropped.
        assertEquals(listOf("2026-07-10 10:00:00 UTC"), map[ScheduleKeys.PRECISE_SCHEDULES])
        val parsed = NotificationCrontabModel().fromMap(map)
        assertEquals("0 0 12 * * ? *", parsed.crontabExpression)
        assertEquals(1, parsed.preciseSchedules!!.size)
        // No precise dates: the key is left out.
        assertFalse(NotificationCrontabModel().apply { preciseSchedules = emptyList() }
            .toMap().containsKey(ScheduleKeys.PRECISE_SCHEDULES))
    }

    @Test fun crontabValidationFollows012() {
        val none = failure { NotificationCrontabModel().validate() }
        assertEquals("At least one schedule parameter is required", none.message)
        assertEquals(ScheduleException.DETAILED_REQUIRED_ARGUMENTS, none.detailedCode)

        for (expiration in listOf("2026-07-01 00:00:00", "2026-06-01 00:00:00")) {
            val e = failure {
                NotificationCrontabModel().apply {
                    crontabExpression = "0 0 12 * * ? *"
                    initialDateTime = date("2026-07-01 00:00:00")
                    expirationDateTime = date(expiration)
                }.validate()
            }
            assertEquals("Expiration date must be greater than initial date", e.message)
            assertEquals("arguments.invalid.periodOrder", e.detailedCode)
        }

        val cron = failure { NotificationCrontabModel().apply { crontabExpression = "every day" }.validate() }
        assertEquals("Schedule cron expression is invalid", cron.message)
        assertEquals("arguments.invalid.crontabExpression", cron.detailedCode)

        // Precise dates alone are enough.
        NotificationCrontabModel().apply { preciseSchedules = listOf(fixedDate()) }.validate()
    }

    @Test fun anExpiredCrontabHasNoNextDate() {
        val expired = NotificationCrontabModel().apply {
            timeZone = TimeZone.getTimeZone("UTC")
            crontabExpression = "0 0 12 * * ? *"
            expirationDateTime = date("2026-07-05 08:00:00")
        }
        assertNull(expired.getNextValidDate(fixedDate()))
        // Expiring right now is expired too.
        expired.expirationDateTime = fixedDate()
        assertNull(expired.getNextValidDate(fixedDate()))
        // Still valid until then.
        expired.expirationDateTime = date("2026-07-06 00:00:00")
        assertEquals("2026-07-05 12:00:00 UTC", string(expired.getNextValidDate(fixedDate())))
    }

    @Test fun theCronDateWinsWhenItIsEarlier() {
        val model = NotificationCrontabModel().apply {
            timeZone = TimeZone.getTimeZone("UTC")
            crontabExpression = "0 0 9 * * ? *"
            preciseSchedules = listOf(date("2026-07-05 10:00:00"))
        }
        assertEquals("2026-07-05 09:00:00 UTC", string(model.getNextValidDate(fixedDate())))
    }

    @Test fun preciseDatesAloneAndTheInitialDateLimit() {
        val model = NotificationCrontabModel().apply {
            timeZone = TimeZone.getTimeZone("UTC")
            initialDateTime = date("2026-07-05 09:30:00")
            preciseSchedules = listOf(
                date("2026-07-05 08:00:00"), // past
                date("2026-07-05 09:00:00"), // before the initial date
                date("2026-07-05 11:00:00"),
                date("2026-07-05 10:00:00")
            )
        }
        assertEquals("2026-07-05 10:00:00 UTC", string(model.getNextValidDate(fixedDate())))
        // All past: none.
        model.preciseSchedules = listOf(date("2026-07-05 08:00:00"))
        assertNull(model.getNextValidDate(fixedDate()))
    }

    @Test fun anUnparseablePreciseDateFailsTheNextDate() {
        val model = NotificationCrontabModel().fromMap(mapOf(
            ScheduleKeys.TIME_ZONE to "UTC",
            ScheduleKeys.PRECISE_SCHEDULES to listOf("tomorrow")
        ))
        val e = failure { model.getNextValidDate(fixedDate()) }
        assertEquals(ScheduleException.CODE_INVALID_ARGUMENTS, e.code)
        assertEquals("Schedule time is invalid", e.message)
        assertEquals("arguments.invalid.notificationCrontab", e.detailedCode)
    }

    @Test fun aCrontabWithoutAFixedDateUsesNow() {
        val model = NotificationCrontabModel().apply {
            timeZone = TimeZone.getTimeZone("UTC")
            crontabExpression = "0 0 * * * ? *"
        }
        val next = model.getNextValidDate(null)!!
        assertTrue(next.after(Calendar.getInstance()))
        assertEquals(0, next.get(Calendar.MINUTE))
    }

    // MARK: - Cron utils / time zones

    @Test fun theCronUtilsAnswerNullForMissingOrInvalidInput() {
        val utc = TimeZone.getTimeZone("UTC")
        assertNull(ScheduleCronUtils.getNextCalendar(null, "0 0 12 * * ? *", utc))
        assertNull(ScheduleCronUtils.getNextCalendar(fixedDate(), null, utc))
        assertNull(ScheduleCronUtils.getNextCalendar(fixedDate(), "", utc))
        assertNull(ScheduleCronUtils.getNextCalendar(fixedDate(), "0 0 12 * * ? *", null))
        assertNull(ScheduleCronUtils.getNextCalendar(fixedDate(), "not a cron", utc))
        // A year already past: no more dates.
        assertNull(ScheduleCronUtils.getNextCalendar(fixedDate(), "0 0 12 * * ? 2020", utc))
        val shifted = ScheduleCronUtils.applyToleranceDate(
            fixedDate().apply { set(Calendar.MILLISECOND, 999) })
        assertEquals(0, shifted.get(Calendar.MILLISECOND))
    }

    @Test fun timeZoneParsingFollows012() {
        assertNull(ScheduleCalendarUtils.getValidTimeZone(null))
        // Not a single token: not a zone.
        assertNull(ScheduleCalendarUtils.getValidTimeZone("America Sao_Paulo"))
        assertEquals("GMT+05:00", ScheduleCalendarUtils.getValidTimeZone("+05")?.id)
        assertEquals("America/Sao_Paulo", ScheduleCalendarUtils.getValidTimeZone("America/Sao_Paulo")?.id)
        assertNull(ScheduleCalendarUtils.timeZoneToString(null))
        val e = failure { ScheduleCalendarUtils.getCurrentCalendar(null) }
        assertEquals("Invalid time zone", e.message)
        assertEquals("arguments.invalid.calendar.timeZone", e.detailedCode)
    }
}
