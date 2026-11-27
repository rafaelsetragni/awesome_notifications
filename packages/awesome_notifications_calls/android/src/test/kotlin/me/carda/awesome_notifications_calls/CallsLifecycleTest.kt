package me.carda.awesome_notifications_calls

import android.app.Activity
import android.app.AlarmManager
import android.app.Application
import android.app.Notification
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.telecom.DisconnectCause
import android.view.WindowManager
import androidx.core.app.NotificationManagerCompat
import androidx.test.core.app.ApplicationProvider
import me.carda.android_awn_core.Definitions
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
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowAlarmManager

/**
 * The paths of a call's life the main suite leaves out: ends of calls the
 * process doesn't know, the timeout and audio commands, the removals of every
 * notification or a group, listeners told off the main thread, the exact ring
 * alarm, the Answer activity opening the app, and the channel's error-less handle.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CallsLifecycleTest {

    private val context: Application = ApplicationProvider.getApplicationContext()
    private val h = CallsHarness(context)

    @Before fun setUp() = h.setUp()

    @After fun tearDown() {
        ShadowAlarmManager.setCanScheduleExactAlarms(false)
        h.tearDown()
    }

    private fun model(callId: String = "c-1") = Calls.entry(callId)!!.model

    private fun parsed(call: Map<String, Any?>) = CallModel.parse(call).first!!

    private fun plainNotification(id: Int) {
        val n = Notification.Builder(context, "calls").setSmallIcon(android.R.drawable.sym_call_incoming).build()
        NotificationManagerCompat.from(context).notify(id, n)
    }

    // MARK: - Ends of unknown calls

    @Test fun finishingAMissedCallTheProcessDoesntKnow() {
        plainNotification(77)
        Calls.finish(context, parsed(h.call(callId = "c-2", state = "missed")), 77, "calls")
        h.idle()
        assertFalse(h.isShown(77))
        assertEquals(listOf("c-2" to DisconnectCause.MISSED), h.telecom!!.ended)
        assertTrue(h.isShown(Calls.missedNotificationId("c-2")))
    }

    @Test fun finishingAnEndedCallTheProcessDoesntKnowShowsNothing() {
        Calls.finish(context, parsed(h.call(callId = "c-2", state = "ended")), null, null)
        h.idle()
        assertEquals(listOf("c-2" to DisconnectCause.LOCAL), h.telecom!!.ended)
        assertTrue(h.manager().activeNotifications.isEmpty())
    }

    @Test fun finishingAKnownCallEndsItOnItsChannel() {
        assertEquals(true, h.create())
        Calls.finish(context, parsed(h.call(state = "missed")), 300, "other")
        h.idle()
        assertNull(Calls.entry("c-1"))
        assertFalse(h.isShown(300))
        val missed = h.manager().activeNotifications.first { it.id == Calls.missedNotificationId("c-1") }
        assertEquals("calls", missed.notification.channelId)
    }

    @Test fun endingACallTheProcessDoesntKnowStillEndsTheSystemCall() {
        Calls.endCall(context, "nobody", EndReason.failed)
        assertEquals(listOf("nobody" to DisconnectCause.REMOTE), h.telecom!!.ended)
        assertFalse(Calls.hasLiveCalls())
    }

    // MARK: - Commands

    @Test fun theTimeoutCommandEndsARingingCallAsMissed() {
        assertEquals(true, h.create())
        var finished = false
        Calls.command(context, CallAction.timeout, "c-1", null) { finished = true }
        h.idle()
        assertTrue(finished)
        assertNull(Calls.entry("c-1"))
        assertEquals(listOf("c-1" to DisconnectCause.MISSED), h.telecom!!.ended)
        assertTrue(h.isShown(Calls.missedNotificationId("c-1")))
    }

    @Test fun audioCommandsOnlyFinish() {
        assertEquals(true, h.create())
        for (action in listOf(CallAction.audioActivated, CallAction.audioDeactivated)) {
            var finished = false
            Calls.command(context, action, "c-1", null) { finished = true }
            assertTrue(finished)
        }
        assertEquals(CallState.incoming, Calls.entry("c-1")!!.call.state)
        assertTrue(h.telecom!!.ended.isEmpty())
    }

    @Test fun theSystemsActionsRunAsTheUsersCommands() {
        assertEquals(true, h.create())
        h.telecom!!.listener.onSystemAction("c-1", CallAction.decline)
        assertNotNull(Calls.entry("c-1")) // posted to the main thread
        h.idle()
        assertNull(Calls.entry("c-1"))
        assertEquals(listOf("c-1" to DisconnectCause.REJECTED), h.telecom!!.ended)
    }

    @Test fun deliveringToTheStreamOffTheMainThreadPostsTheEvent() {
        val call = parsed(h.call(target = "stream"))
        val worker = Thread { Calls.deliver(context, emptyMap(), call, CallAction.hangUp) }
        worker.start()
        worker.join()
        assertTrue(h.streamed.isEmpty())
        h.idle()
        assertEquals(listOf(mapOf("kind" to "command", "action" to "hangUp", "callId" to "c-1")), h.streamed)
    }

    // MARK: - Removal

    @Test fun dismissingEveryNotificationEndsEveryCall() {
        assertEquals(true, h.create())
        assertEquals(true, h.create(call = h.call(callId = "c-2"), id = 301))
        h.core.dismissAll()
        h.idle()
        assertFalse(Calls.hasLiveCalls())
        assertEquals(setOf("c-1", "c-2"), h.telecom!!.ended.map { it.first }.toSet())
    }

    @Test fun dismissingAGroupEndsOnlyItsCalls() {
        assertEquals(true, h.create(content = mapOf(Definitions.NOTIFICATION_GROUP_KEY to "team")))
        assertEquals(true, h.create(call = h.call(callId = "c-2"), id = 301))
        h.core.dismissByGroupKey("team")
        h.idle()
        assertNull(Calls.entry("c-1"))
        assertNotNull(Calls.entry("c-2"))
    }

    // MARK: - Listeners

    @Test fun callsChangedOffTheMainThreadAreToldOnIt() {
        assertEquals(true, h.create())
        var told = 0
        var onMain = false
        Calls.onCallsChanged = {
            told++
            onMain = android.os.Looper.myLooper() == android.os.Looper.getMainLooper()
        }
        val worker = Thread { Calls.endCall(context, "c-1", EndReason.remoteEnded) }
        worker.start()
        worker.join()
        assertEquals(0, told)
        h.idle()
        assertEquals(1, told)
        assertTrue(onMain)
    }

    // MARK: - Ring alarm

    @Test fun theRingAlarmIsExactWhenTheAppMayScheduleExactAlarms() {
        ShadowAlarmManager.setCanScheduleExactAlarms(true)
        assertEquals(true, h.create())
        val alarm = shadowOf(context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).nextScheduledAlarm!!
        assertNotNull(alarm)
        assertEquals(AlarmManager.ELAPSED_REALTIME_WAKEUP, alarm.type)
        assertTrue(alarm.isAllowWhileIdle)
        assertEquals(ShadowAlarmManager.WINDOW_EXACT, alarm.windowLengthMs)
    }

    // MARK: - Parse

    @Test fun parseRejectsMalformedBlocks() {
        assertEquals("The call block must be a map", CallModel.parse("{not json").second)
        assertEquals(
            "The call missedNotification must be a bool",
            CallModel.parse(h.call(extra = mapOf("missedNotification" to "maybe"))).second
        )
        assertEquals("The call controls must be a list", CallModel.parse(h.call(extra = mapOf("controls" to "accept"))).second)
        assertEquals(
            "The call startedAt must be milliseconds",
            CallModel.parse(h.call(extra = mapOf("startedAt" to listOf(1)))).second
        )
    }

    // MARK: - Method handler

    @Test fun theErrorlessHandleAnswersAnInvalidCallWithNull() {
        val values = mutableListOf<Any?>()
        val handled = CallMethodHandler(context) { it(false) }.handle(CallKeys.METHOD_END, mapOf<String, Any?>(), { values.add(it) })
        assertTrue(handled)
        assertEquals(listOf<Any?>(null), values)
    }

    // MARK: - Answer activity

    private fun registerLauncher() {
        val launcher = ComponentName(context.packageName, "me.carda.example.MainActivity")
        val pm = shadowOf(context.packageManager)
        pm.addActivityIfNotPresent(launcher)
        pm.addIntentFilterForActivity(
            launcher,
            IntentFilter(Intent.ACTION_MAIN).apply { addCategory(Intent.CATEGORY_LAUNCHER) }
        )
    }

    private fun answerIntent(callId: String = "c-1", model: Map<String, Any?>? = model(callId)) =
        Intent(context, CallAnswerActivity::class.java).apply {
            putExtra(CallKeys.EXTRA_CALL_ID, callId)
            if (model != null) putExtra(Definitions.NOTIFICATION_JSON, JsonUtils.getInstance().toJson(model))
        }

    private fun answer(intent: Intent): Pair<CallAnswerActivity, Intent?> {
        val activity = Robolectric.buildActivity(CallAnswerActivity::class.java, intent).create().get()
        h.idle()
        assertTrue(activity.isFinishing)
        return activity to shadowOf(activity).nextStartedActivity
    }

    @Test fun answeringOpensTheLaunchActivityWithTheAcceptButtonAction() {
        registerLauncher()
        assertEquals(true, h.create())
        val (activity, opened) = answer(answerIntent())
        assertTrue(shadowOf(activity).showWhenLocked)
        assertNotNull(opened)
        opened!!
        assertEquals("me.carda.example.MainActivity", opened.component?.className)
        assertEquals("c-1", opened.getStringExtra(CallKeys.EXTRA_CALL_ID))
        assertEquals(Definitions.NOTIFICATION_BUTTON_ACTION_PREFIX + "_awn.call.accept", opened.action)
        assertEquals("awn.call.accept", opened.getStringExtra(Definitions.NOTIFICATION_BUTTON_KEY_PRESSED))
        assertTrue(opened.flags and Intent.FLAG_ACTIVITY_NEW_TASK != 0)
        assertTrue(opened.flags and Intent.FLAG_ACTIVITY_SINGLE_TOP != 0)
        assertTrue(opened.flags and Intent.FLAG_ACTIVITY_CLEAR_TOP != 0)
        val sent = JsonUtils.getInstance().fromJson(opened.getStringExtra(Definitions.NOTIFICATION_JSON)!!)
        @Suppress("UNCHECKED_CAST")
        val buttons = sent[Definitions.NOTIFICATION_BUTTONS] as List<Map<String, Any?>>
        val accept = buttons.last()
        assertEquals("awn.call.accept", accept[Definitions.NOTIFICATION_BUTTON_KEY])
        assertEquals("Default", accept[Definitions.NOTIFICATION_ACTION_TYPE])
        assertEquals(false, accept[Definitions.NOTIFICATION_AUTO_DISMISSIBLE])
        assertEquals(CallState.ongoing, Calls.entry("c-1")!!.call.state)
    }

    @Test fun answeringAStreamCallOpensTheAppWithoutAnAction() {
        registerLauncher()
        assertEquals(true, h.create(call = h.call(target = "stream")))
        val (_, opened) = answer(answerIntent())
        opened!!
        assertEquals(Intent.ACTION_MAIN, opened.action)
        assertFalse(opened.hasExtra(Definitions.NOTIFICATION_JSON))
        assertEquals("c-1", opened.getStringExtra(CallKeys.EXTRA_CALL_ID))
        assertEquals(listOf(mapOf("kind" to "command", "action" to "accept", "callId" to "c-1")), h.streamed)
    }

    @Test fun answeringACallAlreadyInProgressOnlyOpensTheApp() {
        registerLauncher()
        assertEquals(true, h.create(call = h.call(state = "ongoing")))
        val (_, opened) = answer(answerIntent())
        opened!!
        assertEquals(Intent.ACTION_MAIN, opened.action)
        assertEquals("c-1", opened.getStringExtra(CallKeys.EXTRA_CALL_ID))
        assertEquals(CallState.ongoing, Calls.entry("c-1")!!.call.state)
    }

    @Test fun answeringWithoutALaunchActivityOpensNothing() {
        assertEquals(true, h.create(call = h.call(state = "ongoing")))
        assertNull(answer(answerIntent()).second)
    }

    @Test fun answeringAnUnknownCallWithAnInvalidBlockDoesNothing() {
        registerLauncher()
        val model = mapOf<String, Any?>(
            Definitions.NOTIFICATION_CONTENT to mapOf(Definitions.NOTIFICATION_ID to 5, Definitions.NOTIFICATION_CHANNEL_KEY to "calls"),
            CallKeys.CALL to mapOf("callId" to "x")
        )
        assertNull(answer(answerIntent("x", model)).second)
        assertNull(answer(Intent(context, CallAnswerActivity::class.java)).second)
    }

    @Config(sdk = [26])
    @Test fun beforeAndroid81TheAnswerActivityUsesTheWindowFlag() {
        assertEquals(true, h.create())
        val (activity, _) = answer(answerIntent())
        assertTrue(activity.window.attributes.flags and WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED != 0)
    }
}
