package me.carda.awesome_notifications_schedules

import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Pure next-fire-time math for interval and calendar schedules, including the
 * "advance to the next occurrence when the computed time is already past" rule.
 */
class NotificationSchedulerTest {

    private val hour = 3600_000L

    @Test fun intervalFiresAfterTheDelay() {
        val before = System.currentTimeMillis()
        val fire = NotificationScheduler.nextFireTime(mapOf(ScheduleKeys.INTERVAL to 10))
        assertNotNull(fire)
        // ~10s from "now"; allow a wide tolerance for slow CI.
        assertTrue(fire!! in (before + 8_000)..(before + 12_000))
    }

    @Test fun noCalendarComponentsAndNoIntervalReturnsNull() {
        assertNull(NotificationScheduler.nextFireTime(mapOf(ScheduleKeys.REPEATS to true)))
    }

    @Test fun calendarTimeIsWithinNextDay() {
        val now = System.currentTimeMillis()
        val fire = NotificationScheduler.nextFireTime(
            mapOf(ScheduleKeys.HOUR to 8, ScheduleKeys.MINUTE to 0, ScheduleKeys.SECOND to 0)
        )
        assertNotNull(fire)
        // Either later today or tomorrow at 08:00 — always inside the next 25h.
        assertTrue(fire!! in now..(now + 25 * hour))
    }

    @Test fun weekdayScheduleIsInTheFuture() {
        val now = System.currentTimeMillis()
        val fire = NotificationScheduler.nextFireTime(
            mapOf(ScheduleKeys.WEEKDAY to 1, ScheduleKeys.HOUR to 9)
        )
        assertNotNull(fire)
        assertTrue(fire!! > now - 1_000)
        assertTrue(fire in now..(now + 8 * 24 * hour)) // within a week
    }

    @Test fun fullySpecifiedPastDateReturnsNull() {
        assertNull(
            NotificationScheduler.nextFireTime(
                mapOf(
                    ScheduleKeys.YEAR to 2000,
                    ScheduleKeys.MONTH to 1,
                    ScheduleKeys.DAY to 1,
                    ScheduleKeys.HOUR to 0,
                    ScheduleKeys.MINUTE to 0,
                    ScheduleKeys.SECOND to 0
                )
            )
        )
    }
}
