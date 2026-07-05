package me.carda.awesome_notifications_schedules

import android.app.AlarmManager
import android.content.Context
import androidx.test.core.app.ApplicationProvider
import me.carda.android_awn_core.AwesomeEventListener
import me.carda.android_awn_core.AwesomeEventsReceiver
import me.carda.android_awn_core.BuildOutcome
import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.NotificationBuilder
import org.junit.After
import org.junit.Assert.assertEquals
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
 * The scheduling builder decorator (Handled vs delegate) and the cancel
 * interceptor that drops the AlarmManager registration.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class ScheduleBuilderTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val alarmManager get() =
        context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    private val events = mutableListOf<Pair<String, Map<String, Any?>>>()
    private val listener = object : AwesomeEventListener {
        override fun onNewAwesomeEvent(eventType: String, content: Map<String, Any?>) {
            events.add(eventType to content)
        }
    }

    @Before fun subscribe() = AwesomeEventsReceiver.subscribe(listener)
    @After fun unsubscribe() = AwesomeEventsReceiver.unsubscribe(listener)

    private fun scheduledModel(id: Int): Map<String, Any?> = mapOf(
        Definitions.NOTIFICATION_CONTENT to mapOf(
            Definitions.NOTIFICATION_ID to id,
            Definitions.NOTIFICATION_CHANNEL_KEY to "ch",
            Definitions.NOTIFICATION_TITLE to "T"
        ),
        ScheduleKeys.SCHEDULE to mapOf(ScheduleKeys.INTERVAL to 60)
    )

    @Test fun schedulableModelIsHandledAndRegistersAlarm() {
        val builder = ScheduleBuilder(NotificationBuilder.getNewBuilder())
        val outcome = builder.build(context, scheduledModel(1))

        assertEquals(BuildOutcome.Handled, outcome)
        assertNotNull(shadowOf(alarmManager).peekNextScheduledAlarm())
    }

    @Test fun schedulingEmitsCreatedEventWithScheduleSource() {
        val builder = ScheduleBuilder(NotificationBuilder.getNewBuilder())
        builder.build(context, scheduledModel(2))

        val created = events.firstOrNull { it.first == Definitions.EVENT_NOTIFICATION_CREATED }
        assertNotNull(created)
        assertEquals("Schedule", created!!.second[Definitions.NOTIFICATION_CREATED_SOURCE])
    }

    @Test fun modelWithoutScheduleDelegatesForImmediateDelivery() {
        val builder = ScheduleBuilder(NotificationBuilder.getNewBuilder())
        val outcome = builder.build(
            context,
            mapOf(
                Definitions.NOTIFICATION_CONTENT to mapOf(
                    Definitions.NOTIFICATION_ID to 3,
                    Definitions.NOTIFICATION_CHANNEL_KEY to "ch"
                )
            )
        )
        assertTrue(outcome is BuildOutcome.Post)
    }

    @Test fun cancelInterceptorDropsTheScheduledAlarm() {
        val scheduler = NotificationScheduler()
        assertTrue(scheduler.schedule(context, scheduledModel(5)))
        assertNotNull(shadowOf(alarmManager).peekNextScheduledAlarm())

        ScheduleCancelInterceptor().onCancel(context, 5)
        assertNull(shadowOf(alarmManager).peekNextScheduledAlarm())
    }
}
