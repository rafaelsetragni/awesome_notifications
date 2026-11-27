package me.carda.awesome_notifications_live_activities

import android.app.Notification
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Looper
import androidx.test.core.app.ApplicationProvider
import java.time.Duration
import java.util.concurrent.Executor
import me.carda.android_awn_core.AwesomeEventListener
import me.carda.android_awn_core.AwesomeEventsReceiver
import me.carda.android_awn_core.AwesomeNotifications
import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.DismissedNotificationReceiver
import me.carda.android_awn_core.JsonUtils
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

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class LiveActivitiesTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val direct = Executor { it.run() }
    private val core = AwesomeNotifications(context, direct)

    private val events = mutableListOf<Pair<String, Map<String, Any?>>>()
    private val listener = object : AwesomeEventListener {
        override fun onNewAwesomeEvent(eventType: String, content: Map<String, Any?>) {
            events.add(eventType to content)
        }
    }
    private val streamed = mutableListOf<Map<String, Any?>>()

    /** The tests' "now" (UTC milliseconds). */
    private val now = 1_800_000_000_000L

    private fun manager() = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    @Before fun setUp() {
        AwesomeNotificationsLiveActivitiesPlugin.install()
        LiveActivities.resetForTest(context)
        LiveActivities.executor = direct
        LiveActivities.clock = { now }
        LiveActivities.streamSink = { streamed.add(it) }
        manager().cancelAll()
        core.setChannel(
            mapOf(Definitions.NOTIFICATION_CHANNEL_KEY to "live", Definitions.NOTIFICATION_CHANNEL_NAME to "Live")
        )
        AwesomeEventsReceiver.subscribe(listener)
    }

    @After fun tearDown() {
        AwesomeEventsReceiver.unsubscribe(listener)
        LiveActivities.resetForTest(context)
    }

    // MARK: - Helpers

    private data class Outcome(val created: Boolean?, val code: String?, val detail: String?, val message: String?)

    private fun create(
        live: Any? = live(),
        id: Int = 400,
        content: Map<String, Any?> = emptyMap(),
        extra: Map<String, Any?> = emptyMap()
    ): Outcome {
        val c = mutableMapOf<String, Any?>(
            Definitions.NOTIFICATION_ID to id,
            Definitions.NOTIFICATION_CHANNEL_KEY to "live",
            Definitions.NOTIFICATION_TITLE to "Your order",
            Definitions.NOTIFICATION_BODY to "On the way"
        )
        c.putAll(content)
        val model = mutableMapOf<String, Any?>(Definitions.NOTIFICATION_CONTENT to c)
        if (live != null) model[LiveKeys.LIVE_ACTIVITY] = live
        model.putAll(extra)
        var outcome = Outcome(null, null, null, null)
        core.createNotification(model, onError = { code, message, details -> outcome = Outcome(null, code, details, message) }) {
            outcome = Outcome(it, null, null, null)
        }
        idle()
        return outcome
    }

    private fun idle() = shadowOf(Looper.getMainLooper()).idle()

    private fun live(
        activityId: String? = null,
        state: String = "active",
        progress: Map<String, Any?>? = null,
        timer: Map<String, Any?>? = null,
        metrics: List<Map<String, Any?>> = emptyList(),
        shortText: String? = null,
        accentColor: Int? = null,
        staleAt: Long? = null,
        alert: Boolean = false,
        dismissal: Any = "default"
    ): Map<String, Any?> = mutableMapOf<String, Any?>(
        LiveKeys.STATE to state,
        LiveKeys.METRICS to metrics,
        LiveKeys.ALERT to alert,
        LiveKeys.DISMISSAL to dismissal
    ).apply {
        activityId?.let { this[LiveKeys.ACTIVITY_ID] = it }
        progress?.let { this[LiveKeys.PROGRESS] = it }
        timer?.let { this[LiveKeys.TIMER] = it }
        shortText?.let { this[LiveKeys.SHORT_TEXT] = it }
        accentColor?.let { this[LiveKeys.ACCENT_COLOR] = it }
        staleAt?.let { this[LiveKeys.STALE_AT] = it }
    }

    private fun metric(label: String, value: String, unit: String? = null) =
        mutableMapOf<String, Any?>(LiveKeys.LABEL to label, LiveKeys.VALUE to value).apply { unit?.let { this[LiveKeys.UNIT] = it } }

    private fun shown(id: Int = 400): Notification? =
        shadowOf(manager()).getNotification(null, id)

    private fun text(n: Notification) = n.extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()

    private fun stateEvents() = streamed.map { it[LiveKeys.ACTIVITY_ID] to it[LiveKeys.STATE] }

    private fun call(method: String, arguments: Any? = null): Pair<Any?, String?> {
        var value: Any? = null
        var error: String? = null
        val handled = LiveMethodHandler(context) { it(false) }.handle(method, arguments, { value = it }) { _, _, details ->
            error = details as String?
        }
        assertTrue(handled)
        idle()
        return value to error
    }

    // MARK: - Model

    @Test fun parsesAValidBlockWithItsDefaults() {
        val (live, error) = LiveActivityModel.parse(mapOf<String, Any?>(), 7)
        assertNull(error)
        live!!
        assertEquals("7", live.activityId)
        assertFalse(live.ended)
        assertFalse(live.alert)
        assertEquals(LiveDismissal.System, live.dismissal)
        assertEquals("7", live.raw[LiveKeys.ACTIVITY_ID])
        assertEquals("active", live.raw[LiveKeys.STATE])
    }

    @Test fun parsesAPushBlockAsJsonWithStrings() {
        val json = """{"activityId":"ride","state":"ended","alert":"true","dismissal":"1800000005000",
            "staleAt":"1800000009000","metrics":[{"label":"Speed","value":"42","unit":"km/h"}],
            "progress":{"segments":[{"length":"30","color":4294901760},{"length":70}],"points":[{"position":"30"}]},
            "timer":{"end":"1800000060000","countDown":true}}"""
        val (live, error) = LiveActivityModel.parse(json, 1)
        assertNull(error)
        live!!
        assertEquals("ride", live.activityId)
        assertTrue(live.ended)
        assertTrue(live.alert)
        assertEquals(LiveDismissal.At(1_800_000_005_000), live.dismissal)
        assertEquals(1_800_000_009_000, live.staleAt)
        assertEquals(listOf(LiveSegment(30, 0xFFFF0000.toInt()), LiveSegment(70, null)), live.progress!!.segments)
        assertEquals(100, live.progress!!.total)
        assertEquals(LiveTimer(null, 1_800_000_060_000), live.timer)
        assertEquals("Speed 42 km/h", live.metrics.single().text)
    }

    @Test fun rejectsInvalidBlocksWithTheDartMessages() {
        fun error(block: Any?) = LiveActivityModel.parse(block, 1).second
        assertEquals("The liveActivity block must be a map", error(3))
        assertEquals("The live activity's activityId can't be empty", error(mapOf(LiveKeys.ACTIVITY_ID to " ")))
        assertEquals("The live activity's shortText can't be empty", error(mapOf(LiveKeys.SHORT_TEXT to "")))
        assertEquals("Unknown live activity state: paused", error(mapOf(LiveKeys.STATE to "paused")))
        assertEquals("A live activity has at most 3 metrics",
            error(mapOf(LiveKeys.METRICS to List(4) { metric("a", "1") })))
        assertEquals("A live activity metric needs a label", error(mapOf(LiveKeys.METRICS to listOf(metric(" ", "1")))))
        assertEquals("A live activity segment needs a positive length",
            error(mapOf(LiveKeys.PROGRESS to mapOf(LiveKeys.SEGMENTS to listOf(mapOf(LiveKeys.LENGTH to 0))))))
        assertEquals("A live activity point must sit within the segments (0 to 10)",
            error(mapOf(LiveKeys.PROGRESS to mapOf(
                LiveKeys.SEGMENTS to listOf(mapOf(LiveKeys.LENGTH to 10)),
                LiveKeys.POINTS to listOf(mapOf(LiveKeys.POSITION to 11))))))
        assertEquals("A live activity countdown must end after it starts",
            error(mapOf(LiveKeys.TIMER to mapOf(LiveKeys.START to 10, LiveKeys.END to 10))))
        assertEquals("The live activity timer needs a start or an end", error(mapOf(LiveKeys.TIMER to mapOf<String, Any?>())))
        assertEquals("Unknown live activity dismissal: later", error(mapOf(LiveKeys.DISMISSAL to "later")))
        assertEquals("The live activity alert must be a bool", error(mapOf(LiveKeys.ALERT to 3)))
        assertEquals("Unknown live activity layout: grid", error(mapOf(LiveKeys.LAYOUT to "grid")))
        assertEquals("The live activity androidLiveUpdate must be a bool", error(mapOf(LiveKeys.ANDROID_LIVE_UPDATE to 1)))
        assertEquals("The live activity's customLayout must be a resource name: lowercase letters, digits and _",
            error(mapOf(LiveKeys.CUSTOM_LAYOUT to "Focus-Timer")))
        assertEquals("A versus live activity needs exactly 2 metrics, one per side",
            error(mapOf(LiveKeys.LAYOUT to LiveKeys.LAYOUT_VERSUS, LiveKeys.METRICS to listOf(metric("a", "1")))))
    }

    @Test fun beforeAndroid16AVersusActivityIsAScoreboard() {
        val metrics = listOf(metric("LIO", "1"), metric("EAG", "0"))
        val block = live(shortText = "2nd half", metrics = metrics, accentColor = 0xFF2196F3.toInt(),
            timer = mapOf(LiveKeys.START to now - 60_000, LiveKeys.COUNT_DOWN to false))
            .toMutableMap().apply { this[LiveKeys.LAYOUT] = LiveKeys.LAYOUT_VERSUS }
        assertEquals(true, create(live = block).created)
        val n = shown()!!
        for (view in listOf(inflate(n.contentView), inflate(n.bigContentView))) {
            assertEquals("LIO", textOf(view, R.id.awn_vs_label_0))
            assertEquals("1", textOf(view, R.id.awn_vs_value_0))
            assertEquals("EAG", textOf(view, R.id.awn_vs_label_1))
            assertEquals("0", textOf(view, R.id.awn_vs_value_1))
            assertEquals("2nd half", textOf(view, R.id.awn_vs_short))
            assertTrue(visible(view, R.id.awn_vs_clock))
        }
        // Collapsed: the scoreboard only; expanded: the latest play below.
        assertFalse(visible(inflate(n.contentView), R.id.awn_vs_play))
        val expanded = inflate(n.bigContentView)
        assertTrue(visible(expanded, R.id.awn_vs_play))
        assertEquals("On the way", textOf(expanded, R.id.awn_vs_body))
    }

    @Test fun aVersusLineAndScore() {
        val (model, _) = LiveActivityModel.parse(mapOf(
            LiveKeys.LAYOUT to LiveKeys.LAYOUT_VERSUS, LiveKeys.SHORT_TEXT to "2nd half",
            LiveKeys.METRICS to listOf(metric("LIO", "1"), metric("EAG", "0"))), 1)
        assertTrue(model!!.versus)
        assertEquals(listOf("LIO 1 – 0 EAG · 2nd half"), LiveNotifications.extraLines(model, shortTextInBody = false))
        assertEquals("1–0", LiveNotifications.scoreOf(model))
    }

    // MARK: - Refusals

    @Test fun aMalformedActivityIsRefused() {
        val outcome = create(live = mapOf(LiveKeys.STATE to "paused"))
        assertEquals("INVALID_ARGUMENTS", outcome.code)
        assertEquals("arguments.invalid.notificationLiveActivity", outcome.detail)
        assertEquals("Unknown live activity state: paused", outcome.message)
        assertNull(shown())
    }

    @Test fun aScheduledActivityIsRefused() {
        val outcome = create(extra = mapOf(LiveKeys.SCHEDULE to mapOf("interval" to 60)))
        assertEquals("INVALID_ARGUMENTS", outcome.code)
        assertEquals("arguments.invalid.notificationLiveActivity.schedule", outcome.detail)
        assertNull(shown())
    }

    @Test fun aNotificationWithoutTheBlockKeepsTheCoreBehavior() {
        create(live = null, content = mapOf(Definitions.NOTIFICATION_PROGRESS to 50))
        val n = shown()!!
        assertEquals(0, n.flags and Notification.FLAG_ONGOING_EVENT)
        assertFalse(n.extras.containsKey(Notification.EXTRA_PROGRESS_MAX) && n.extras.getInt(Notification.EXTRA_PROGRESS_MAX) == 100)
        assertTrue(streamed.isEmpty())
        assertTrue(LiveActivities.list(context).isEmpty())
    }

    // MARK: - Before Android 16: the package's own layout

    /** The texts and visible views of a notification's custom layout. */
    private fun inflate(views: android.widget.RemoteViews): android.view.View =
        views.apply(context, android.widget.FrameLayout(context))

    private fun textOf(root: android.view.View, id: Int): String? =
        root.findViewById<android.widget.TextView>(id)
            ?.takeIf { it.visibility == android.view.View.VISIBLE }?.text?.toString()

    private fun visible(root: android.view.View, id: Int) =
        root.findViewById<android.view.View>(id)?.visibility == android.view.View.VISIBLE

    @Test fun beforeAndroid16AnActivityIsAnOngoingNotificationWithItsOwnLayout() {
        assertEquals(true, create(content = mapOf(Definitions.NOTIFICATION_PROGRESS to 60), live = live(
            progress = mapOf(LiveKeys.SEGMENTS to listOf(mapOf(LiveKeys.LENGTH to 50), mapOf(LiveKeys.LENGTH to 50))),
            shortText = "12 min",
            metrics = listOf(metric("Speed", "42", "km/h"), metric("Stops", "2")),
            accentColor = 0xFF2196F3.toInt()
        )).created)
        val n = shown()!!
        assertTrue(n.flags and Notification.FLAG_ONGOING_EVENT != 0)
        assertTrue(n.flags and Notification.FLAG_ONLY_ALERT_ONCE != 0)
        assertEquals(0, n.flags and Notification.FLAG_AUTO_CANCEL)
        assertEquals("android.app.Notification\$DecoratedCustomViewStyle", n.extras.getString(Notification.EXTRA_TEMPLATE))
        assertEquals(0xFF2196F3.toInt(), n.color)
        assertFalse(n.extras.getBoolean("android.requestPromotedOngoing"))

        val collapsed = inflate(n.contentView)
        assertEquals("12 min", textOf(collapsed, R.id.awn_live_short))
        assertTrue(visible(collapsed, R.id.awn_live_bar))
        // Collapsed, the bar takes the body's place.
        assertNull(textOf(collapsed, R.id.awn_live_body))

        val expanded = inflate(n.bigContentView)
        assertEquals("On the way", textOf(expanded, R.id.awn_live_body))
        assertEquals("12 min", textOf(expanded, R.id.awn_live_short))
        assertTrue(visible(expanded, R.id.awn_live_bar))
        assertTrue(visible(expanded, R.id.awn_live_metrics))
        assertEquals("42 km/h", textOf(expanded, R.id.awn_live_metric_value_0))
        assertEquals("Speed", textOf(expanded, R.id.awn_live_metric_label_0))
        assertEquals("2", textOf(expanded, R.id.awn_live_metric_value_1))
        assertEquals("Stops", textOf(expanded, R.id.awn_live_metric_label_1))
        assertFalse(visible(expanded, R.id.awn_live_metric_2))
    }

    @Test fun withoutProgressThereIsNoBarAndTheBodyShows() {
        create(live = live(timer = mapOf(LiveKeys.START to now - 60_000, LiveKeys.COUNT_DOWN to false)))
        val n = shown()!!
        assertTrue(n.flags and Notification.FLAG_ONGOING_EVENT != 0)
        val collapsed = inflate(n.contentView)
        assertFalse(visible(collapsed, R.id.awn_live_bar))
        assertEquals("On the way", textOf(collapsed, R.id.awn_live_body))
        assertFalse(visible(inflate(n.bigContentView), R.id.awn_live_metrics))
    }

    @org.robolectric.annotation.GraphicsMode(org.robolectric.annotation.GraphicsMode.Mode.NATIVE)
    @Test fun theBarIsSolidUpToTheProgressAndFadedAfter() {
        val (model, _) = LiveActivityModel.parse(live(progress = mapOf(
            LiveKeys.SEGMENTS to listOf(
                mapOf(LiveKeys.LENGTH to 50, LiveKeys.COLOR to 0xFFFF0000.toInt()),
                mapOf(LiveKeys.LENGTH to 50, LiveKeys.COLOR to 0xFF00FF00.toInt()))
        )), 1)
        val bar = LiveCustomLayout.bar(model!!, 25.0, 1f, 16f)
        val mid = bar.height / 2
        // A quarter in: inside the first segment, done → solid red.
        assertEquals(0xFFFF0000.toInt(), bar.getPixel(bar.width / 8, mid))
        // Three quarters in: the second segment, not reached → faded green.
        val after = bar.getPixel(bar.width * 3 / 4, mid)
        assertTrue(android.graphics.Color.green(after) >= 252 && android.graphics.Color.red(after) <= 3)
        assertTrue(android.graphics.Color.alpha(after) < 255)
    }

    @org.robolectric.annotation.GraphicsMode(org.robolectric.annotation.GraphicsMode.Mode.NATIVE)
    @Test fun anIndeterminateBarIsFadedThroughout() {
        val (model, _) = LiveActivityModel.parse(live(accentColor = 0xFF2196F3.toInt(), progress = mapOf()), 1)
        val bar = LiveCustomLayout.bar(model!!, null, 1f, 16f)
        val pixel = bar.getPixel(bar.width / 8, bar.height / 2)
        // Faded (premultiplied alpha: each channel within a unit or two).
        assertTrue(Math.abs(android.graphics.Color.red(pixel) - 0x21) <= 3)
        assertTrue(Math.abs(android.graphics.Color.green(pixel) - 0x96) <= 3)
        assertTrue(Math.abs(android.graphics.Color.blue(pixel) - 0xF3) <= 3)
        assertTrue(android.graphics.Color.alpha(pixel) < 255)
    }

    @Test fun aCountdownIsTheSystemsChronometerToItsEnd() {
        create(live = live(timer = mapOf(LiveKeys.END to now + 600_000, LiveKeys.COUNT_DOWN to true)))
        val n = shown()!!
        assertTrue(n.extras.getBoolean(Notification.EXTRA_SHOW_CHRONOMETER))
        assertTrue(n.extras.getBoolean(Notification.EXTRA_CHRONOMETER_COUNT_DOWN))
        assertEquals(now + 600_000, n.`when`)
    }

    @Test fun anElapsedTimerCountsUpFromItsStart() {
        create(live = live(timer = mapOf(LiveKeys.START to now - 60_000, LiveKeys.COUNT_DOWN to false)))
        val n = shown()!!
        assertTrue(n.extras.getBoolean(Notification.EXTRA_SHOW_CHRONOMETER))
        assertFalse(n.extras.getBoolean(Notification.EXTRA_CHRONOMETER_COUNT_DOWN))
        assertEquals(now - 60_000, n.`when`)
    }

    @Test fun anUpdateAlertsOnlyWhenAsked() {
        create(live = live(alert = true))
        assertEquals(0, shown()!!.flags and Notification.FLAG_ONLY_ALERT_ONCE)
    }

    // MARK: - Android 16+: Live Updates

    @Config(sdk = [36])
    @Test fun onAndroid16AnActivityIsAPromotedProgressStyle() {
        create(
            content = mapOf(
                Definitions.NOTIFICATION_PROGRESS to 50,
                Definitions.NOTIFICATION_BACKGROUND_COLOR to 0xFF000000.toInt()
            ),
            live = live(
                progress = mapOf(
                    LiveKeys.SEGMENTS to listOf(
                        mapOf(LiveKeys.LENGTH to 30, LiveKeys.COLOR to 0xFFFF0000.toInt()),
                        mapOf(LiveKeys.LENGTH to 70)
                    ),
                    LiveKeys.POINTS to listOf(mapOf(LiveKeys.POSITION to 30))
                ),
                shortText = "12 min",
                metrics = listOf(metric("Speed", "42", "km/h")),
                accentColor = 0xFF2196F3.toInt()
            )
        )
        val n = shown()!!
        assertTrue(n.extras.getBoolean("android.requestPromotedOngoing"))
        assertEquals("android.app.Notification\$ProgressStyle", n.extras.getString(Notification.EXTRA_TEMPLATE))
        assertEquals(2, n.extras.getParcelableArrayList<android.os.Bundle>("android.progressSegments")!!.size)
        assertEquals(1, n.extras.getParcelableArrayList<android.os.Bundle>("android.progressPoints")!!.size)
        assertEquals(100, n.extras.getInt(Notification.EXTRA_PROGRESS_MAX))
        assertEquals(50, n.extras.getInt(Notification.EXTRA_PROGRESS))
        assertEquals("12 min", n.shortCriticalText)
        // Promotion forbids colorized: the accent color is the color.
        assertFalse(n.extras.getBoolean(Notification.EXTRA_COLORIZED))
        assertEquals(0xFF2196F3.toInt(), n.color)
        assertTrue(n.flags and Notification.FLAG_ONGOING_EVENT != 0)
        // The chip carries the short text; the metrics go in the body.
        assertEquals("On the way\nSpeed 42 km/h", text(n))
    }

    @Config(sdk = [36])
    @Test fun onAndroid16WithoutLiveUpdatesItIsThePackagesOwnLayout() {
        val block = live(shortText = "12 min", progress = mapOf(LiveKeys.SEGMENTS to listOf(mapOf(LiveKeys.LENGTH to 100))))
            .toMutableMap().apply { this[LiveKeys.ANDROID_LIVE_UPDATE] = false }
        assertEquals(true, create(content = mapOf(Definitions.NOTIFICATION_PROGRESS to 60), live = block).created)
        val n = shown()!!
        assertFalse(n.extras.getBoolean("android.requestPromotedOngoing"))
        assertTrue(n.flags and Notification.FLAG_ONGOING_EVENT != 0)
        assertEquals("android.app.Notification\$DecoratedCustomViewStyle", n.extras.getString(Notification.EXTRA_TEMPLATE))
        assertEquals("12 min", textOf(inflate(n.contentView), R.id.awn_live_short))
    }

    @Config(sdk = [36])
    @Test fun aCustomLayoutIsTheAppsLayoutFilledByIdAndNeverPromoted() {
        // Any layout of the app's resources: here one of the package's own.
        val block = live(shortText = "12 min", metrics = listOf(metric("Speed", "42", "km/h")))
            .toMutableMap().apply { this[LiveKeys.CUSTOM_LAYOUT] = "awn_live_expanded" }
        assertEquals(true, create(live = block).created)
        val n = shown()!!
        assertFalse(n.extras.getBoolean("android.requestPromotedOngoing"))
        val collapsed = inflate(n.contentView)
        assertEquals("On the way", textOf(collapsed, R.id.awn_live_body))
        assertEquals("12 min", textOf(collapsed, R.id.awn_live_short))
        assertEquals("42 km/h", textOf(collapsed, R.id.awn_live_metric_value_0))
        assertEquals("Speed", textOf(collapsed, R.id.awn_live_metric_label_0))
        assertFalse(visible(collapsed, R.id.awn_live_metric_value_1))
    }

    @Test fun aCustomLayoutTheAppDoesNotHaveIsRefused() {
        val block = live().toMutableMap().apply { this[LiveKeys.CUSTOM_LAYOUT] = "no_such_layout" }
        val outcome = create(live = block)
        assertEquals("INVALID_ARGUMENTS", outcome.code)
        assertEquals("arguments.invalid.notificationLiveActivity", outcome.detail)
        assertNull(shown())
    }

    @Config(sdk = [36])
    @Test fun onAndroid16TheValueIsOnTheSegmentsScale() {
        create(
            content = mapOf(Definitions.NOTIFICATION_PROGRESS to 50),
            live = live(progress = mapOf(LiveKeys.SEGMENTS to listOf(mapOf(LiveKeys.LENGTH to 300), mapOf(LiveKeys.LENGTH to 100))))
        )
        val n = shown()!!
        assertEquals(400, n.extras.getInt(Notification.EXTRA_PROGRESS_MAX))
        assertEquals(200, n.extras.getInt(Notification.EXTRA_PROGRESS))
    }

    @Config(sdk = [36])
    @Test fun onAndroid16AnEndedActivityIsNoLongerPromoted() {
        create(content = mapOf(Definitions.NOTIFICATION_PROGRESS to 100), live = live(state = "ended", shortText = "Done"))
        val n = shown()!!
        assertFalse(n.extras.getBoolean("android.requestPromotedOngoing"))
        assertEquals(0, n.flags and Notification.FLAG_ONGOING_EVENT)
    }

    @Config(sdk = [36])
    @Test fun onAndroid16TheCapabilitiesHaveTheSystemSurface() {
        @Suppress("UNCHECKED_CAST")
        val caps = call(LiveKeys.METHOD_CAPABILITIES).first as Map<String, Any?>
        assertEquals(true, caps[LiveKeys.CAP_SYSTEM_SURFACE])
        assertEquals(true, caps[LiveKeys.CAP_PROGRESS_SEGMENTS])
        assertEquals(false, caps[LiveKeys.CAP_METRICS])
        assertEquals(true, caps[LiveKeys.CAP_BUTTONS])
        assertEquals(true, caps[LiveKeys.CAP_PUSH])
    }

    @Test fun beforeAndroid16TheCapabilitiesHaveTheLayoutsSegmentsAndMetrics() {
        @Suppress("UNCHECKED_CAST")
        val caps = call(LiveKeys.METHOD_CAPABILITIES).first as Map<String, Any?>
        assertEquals(false, caps[LiveKeys.CAP_SYSTEM_SURFACE])
        assertEquals(true, caps[LiveKeys.CAP_PROGRESS_SEGMENTS])
        assertEquals(true, caps[LiveKeys.CAP_METRICS])
    }

    @Test fun beforeAndroid16TheCollapsedViewHasTheRunningClock() {
        create(live = live(timer = mapOf(LiveKeys.END to now + 600_000, LiveKeys.COUNT_DOWN to true)))
        assertTrue(visible(inflate(shown()!!.contentView), R.id.awn_live_clock))
        create(live = live(state = "ended", timer = mapOf(LiveKeys.END to now + 600_000, LiveKeys.COUNT_DOWN to true)))
        assertFalse(visible(inflate(shown()!!.contentView), R.id.awn_live_clock))
    }

    // MARK: - Lifecycle

    @Test fun theActivityIdIsInThePayloadAndTheCoreEventsFire() {
        create(live = live(activityId = "order-1"), content = mapOf(Definitions.NOTIFICATION_PAYLOAD to mapOf("k" to "v")))
        val created = events.first { it.first == Definitions.EVENT_NOTIFICATION_CREATED }.second
        assertEquals(mapOf("k" to "v", "activityId" to "order-1"), created[Definitions.NOTIFICATION_PAYLOAD])
        assertTrue(events.any { it.first == Definitions.EVENT_NOTIFICATION_DISPLAYED })
    }

    @Test fun theDefaultActivityIdIsTheNotificationId() {
        create(id = 9)
        assertEquals(listOf(mapOf(LiveKeys.ACTIVITY_ID to "9", LiveKeys.STATE to "active")), LiveActivities.list(context))
    }

    @Test fun theSameIdUpdatesInPlace() {
        create(content = mapOf(Definitions.NOTIFICATION_PROGRESS to 10))
        create(content = mapOf(Definitions.NOTIFICATION_PROGRESS to 70, Definitions.NOTIFICATION_BODY to "Close"))
        assertEquals(1, manager().activeNotifications.size)
        assertEquals("Close", text(shown()!!))
        assertEquals(1, LiveActivities.list(context).size)
        assertTrue(streamed.isEmpty())
    }

    @Test fun anEndedActivityStaysAsItsFinalContentAndIsReportedOnce() {
        create()
        create(live = live(state = "ended"), content = mapOf(Definitions.NOTIFICATION_BODY to "Delivered"))
        create(live = live(state = "ended"), content = mapOf(Definitions.NOTIFICATION_BODY to "Delivered!"))
        val n = shown()!!
        assertEquals(0, n.flags and Notification.FLAG_ONGOING_EVENT)
        assertEquals("Delivered!", text(n))
        assertEquals(listOf("400" to "ended"), stateEvents())
        assertEquals(listOf(mapOf(LiveKeys.ACTIVITY_ID to "400", LiveKeys.STATE to "ended")), LiveActivities.list(context))
    }

    @Test fun anImmediateEndRemovesItAtOnce() {
        create()
        assertEquals(true, create(live = live(state = "ended", dismissal = "immediate")).created)
        assertNull(shown())
        assertEquals(listOf("400" to "ended", "400" to "dismissed"), stateEvents())
        assertTrue(LiveActivities.list(context).isEmpty())
    }

    @Test fun anEndAtATimeIsTheNotificationsTimeout() {
        create()
        create(live = live(state = "ended", dismissal = now + 5_000))
        assertEquals(5_000, shown()!!.timeoutAfter)
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(5_000))
        assertNull(shown())
        assertEquals(listOf("400" to "ended", "400" to "dismissed"), stateEvents())
    }

    @Test fun staleAtIsTheNotificationsTimeout() {
        create(live = live(staleAt = now + 10_000))
        assertEquals(10_000, shown()!!.timeoutAfter)
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(10_000))
        assertNull(shown())
        assertEquals(listOf("400" to "dismissed"), stateEvents())
    }

    @Test fun anActivityAlreadyStaleIsNotShown() {
        assertEquals(true, create(live = live(staleAt = now - 1)).created)
        assertNull(shown())
        assertEquals(listOf("400" to "dismissed"), stateEvents())
    }

    @Test fun liveActivityEndShowsTheFinalContentThenItsDismissal() {
        create(live = live(activityId = "a", timer = mapOf(LiveKeys.END to now + 60_000, LiveKeys.COUNT_DOWN to true)))
        val (value, error) = call(LiveKeys.METHOD_END, mapOf(LiveKeys.ACTIVITY_ID to "a", LiveKeys.DISMISSAL to "default"))
        assertNull(value)
        assertNull(error)
        val n = shown()!!
        assertEquals(0, n.flags and Notification.FLAG_ONGOING_EVENT)
        assertTrue(n.flags and Notification.FLAG_ONLY_ALERT_ONCE != 0)
        assertFalse(n.extras.getBoolean(Notification.EXTRA_SHOW_CHRONOMETER))
        assertEquals(listOf("a" to "ended"), stateEvents())
        assertEquals("ended", LiveActivities.list(context).single()[LiveKeys.STATE])
    }

    @Test fun liveActivityEndImmediateRemovesIt() {
        create(live = live(activityId = "a"))
        call(LiveKeys.METHOD_END, mapOf(LiveKeys.ACTIVITY_ID to "a", LiveKeys.DISMISSAL to "immediate"))
        assertNull(shown())
        assertEquals(listOf("a" to "ended", "a" to "dismissed"), stateEvents())
    }

    @Test fun liveActivityEndOfAnUnknownActivityDoesNothing() {
        assertEquals(null to null, call(LiveKeys.METHOD_END, mapOf(LiveKeys.ACTIVITY_ID to "x", LiveKeys.DISMISSAL to "default")))
        assertEquals(null to "arguments.invalid.liveActivityEnd", call(LiveKeys.METHOD_END, mapOf(LiveKeys.DISMISSAL to "default")))
    }

    // MARK: - Removal

    @Test fun theCoresCancelEndsItAtOnce() {
        create()
        core.cancel(400)
        assertNull(shown())
        assertEquals(listOf("400" to "dismissed"), stateEvents())
        assertTrue(LiveActivities.list(context).isEmpty())
    }

    @Test fun dismissingTheChannelOrAllEndsThem() {
        create(id = 1, live = live(activityId = "a"))
        create(id = 2, live = live(activityId = "b"))
        core.dismissByChannelKey("live")
        create(id = 3, live = live(activityId = "c"))
        core.cancelAll()
        assertEquals(setOf("a", "b", "c"), stateEvents().filter { it.second == "dismissed" }.map { it.first }.toSet())
        assertTrue(LiveActivities.list(context).isEmpty())
    }

    @Test fun theUsersSwipeOfAnEndedActivityIsReported() {
        create(live = live(state = "ended"))
        manager().cancel(400)
        val model = mapOf(
            Definitions.NOTIFICATION_CONTENT to mapOf(Definitions.NOTIFICATION_ID to 400, Definitions.NOTIFICATION_CHANNEL_KEY to "live")
        )
        DismissedNotificationReceiver().onReceive(context, Intent(Definitions.DISMISSED_NOTIFICATION).apply {
            putExtra(Definitions.NOTIFICATION_JSON, JsonUtils.getInstance().toJson(model))
        })
        idle()
        assertEquals(listOf("400" to "ended", "400" to "dismissed"), stateEvents())
    }

    @Test fun aPlainNotificationOnTheSameIdReplacesTheActivity() {
        create()
        create(live = null)
        assertEquals(listOf("400" to "dismissed"), stateEvents())
        assertEquals(0, shown()!!.flags and Notification.FLAG_ONGOING_EVENT)
    }

    @Test fun anotherActivityOnTheSameIdReplacesTheFirst() {
        create(live = live(activityId = "a"))
        create(live = live(activityId = "b"))
        assertEquals(listOf("a" to "dismissed"), stateEvents())
        assertEquals(listOf("b"), LiveActivities.list(context).map { it[LiveKeys.ACTIVITY_ID] })
    }

    @Test fun theSameActivityUnderAnotherIdMovesThere() {
        create(id = 1, live = live(activityId = "a"))
        create(id = 2, live = live(activityId = "a"))
        assertNull(shown(1))
        assertNotNull(shown(2))
        assertTrue(streamed.isEmpty())
    }

    // MARK: - Process death

    @Test fun theActivitiesSurviveTheProcess() {
        create(live = live(activityId = "a"))
        LiveActivities.forgetMemoryForTest()
        assertEquals(listOf(mapOf(LiveKeys.ACTIVITY_ID to "a", LiveKeys.STATE to "active")), LiveActivities.list(context))
        LiveActivities.forgetMemoryForTest()
        call(LiveKeys.METHOD_END, mapOf(LiveKeys.ACTIVITY_ID to "a", LiveKeys.DISMISSAL to "default"))
        assertEquals(0, shown()!!.flags and Notification.FLAG_ONGOING_EVENT)
        assertEquals(listOf("a" to "ended"), stateEvents())
        LiveActivities.forgetMemoryForTest()
        core.cancel(400)
        assertEquals(listOf("a" to "ended", "a" to "dismissed"), stateEvents())
    }

    @Test fun anActivityRemovedWhileTheProcessWasDeadIsForgotten() {
        create(live = live(activityId = "a"))
        manager().cancel(400)
        LiveActivities.forgetMemoryForTest()
        assertTrue(LiveActivities.list(context).isEmpty())
        assertTrue(streamed.isEmpty())
    }

    // MARK: - Methods

    @Test fun theOtherMethodsBeforeAndroid16() {
        @Suppress("UNCHECKED_CAST")
        val caps = call(LiveKeys.METHOD_CAPABILITIES).first as Map<String, Any?>
        assertEquals(false, caps[LiveKeys.CAP_SYSTEM_SURFACE])
        assertEquals(true, caps[LiveKeys.CAP_PROGRESS_SEGMENTS])
        assertEquals(true, caps[LiveKeys.CAP_BUTTONS])
        assertEquals(true, call(LiveKeys.METHOD_ARE_ENABLED).first)
        assertEquals(true, call(LiveKeys.METHOD_REQUEST_PERMISSION).first)
        assertNull(call(LiveKeys.METHOD_PUSH_TO_START_TOKEN).first)
        assertNull(call(LiveKeys.METHOD_PUSH_TOKEN, mapOf(LiveKeys.ACTIVITY_ID to "a")).first)
        assertFalse(LiveMethodHandler(context) {}.handle("somethingElse", null, {}))
    }
}
