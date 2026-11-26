package me.carda.awesome_notifications_calls

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Looper
import android.telecom.DisconnectCause
import androidx.test.core.app.ApplicationProvider
import java.util.concurrent.Executor
import java.util.concurrent.TimeUnit
import me.carda.android_awn_core.AwesomeEventListener
import me.carda.android_awn_core.AwesomeEventsReceiver
import me.carda.android_awn_core.AwesomeNotifications
import me.carda.android_awn_core.BackgroundActions
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

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CallsTest {

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

    /** The foreground service, as the test allows it. */
    private class FakeForeground : CallForeground {
        var allowed = true
        var showing: Int? = null
        val shown = mutableListOf<Pair<Int, Boolean>>()
        val hidden = mutableListOf<Int>()
        override fun show(context: Context, id: Int, channelKey: String?, notification: Notification, wait: Boolean): Boolean {
            shown.add(id to wait)
            if (allowed) showing = id
            return allowed
        }
        override fun isShowing(id: Int) = showing == id
        override fun hide(context: Context, id: Int, next: Pair<Int, Notification>?) {
            hidden.add(id)
            if (showing == id) showing = next?.first
        }
    }

    /** Telecom, recording what the package asks of it. */
    private class FakeTelecom(val listener: CallTelecom.Listener) : CallTelecom {
        override val isAvailable = true
        val synced = mutableListOf<Pair<String, CallState>>()
        val ended = mutableListOf<Pair<String, Int>>()
        override fun sync(call: CallModel) { synced.add(call.callId to call.state) }
        override fun end(callId: String, cause: Int) { ended.add(callId to cause) }
    }

    private val foreground = FakeForeground()
    private var telecom: FakeTelecom? = null

    private fun manager() = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    @Before fun setUp() {
        AwesomeNotificationsCallsPlugin.install()
        Calls.resetForTest()
        Calls.executor = direct
        Calls.foreground = foreground
        Calls.makeTelecom = { _, l -> FakeTelecom(l).also { telecom = it } }
        Calls.makeCore = { core }
        Calls.clock = { 1_000_000L }
        Calls.streamSink = { streamed.add(it) }
        manager().cancelAll()
        core.setChannel(
            mapOf(Definitions.NOTIFICATION_CHANNEL_KEY to "calls", Definitions.NOTIFICATION_CHANNEL_NAME to "Calls")
        )
        AwesomeEventsReceiver.subscribe(listener)
    }

    @After fun tearDown() {
        AwesomeEventsReceiver.unsubscribe(listener)
        BackgroundActions.executor = null
        Calls.resetForTest()
    }

    // MARK: - Helpers

    private data class Outcome(val created: Boolean?, val code: String?, val detail: String?, val message: String?)

    private fun create(
        call: Any? = call(),
        id: Int = 300,
        content: Map<String, Any?> = emptyMap(),
        extra: Map<String, Any?> = emptyMap()
    ): Outcome {
        val c = mutableMapOf<String, Any?>(
            Definitions.NOTIFICATION_ID to id,
            Definitions.NOTIFICATION_CHANNEL_KEY to "calls",
            Definitions.NOTIFICATION_TITLE to "Little Mary"
        )
        c.putAll(content)
        val model = mutableMapOf<String, Any?>(Definitions.NOTIFICATION_CONTENT to c)
        if (call != null) model[CallKeys.CALL] = call
        model.putAll(extra)
        var outcome = Outcome(null, null, null, null)
        core.createNotification(model, onError = { code, message, details -> outcome = Outcome(null, code, details, message) }) {
            outcome = Outcome(it, null, null, null)
        }
        idle()
        return outcome
    }

    private fun idle() = shadowOf(Looper.getMainLooper()).idle()

    private fun call(
        callId: String = "c-1",
        state: String = "incoming",
        video: Boolean = false,
        controls: List<String>? = listOf("accept", "decline", "hangUp", "mute", "hold"),
        target: String = "actionEvent",
        startedAt: Long? = null,
        ringTimeout: Long = 30_000,
        missedNotification: Boolean = true,
        groupName: String? = null
    ) = mutableMapOf<String, Any?>(
        "callId" to callId,
        "caller" to mapOf("key" to "little-mary", "name" to "Little Mary", "isBot" to false, "isImportant" to false),
        "handle" to "tel:+5511999999999",
        "video" to video,
        "state" to state,
        "ringTimeout" to ringTimeout,
        "missedNotification" to missedNotification,
        "commandTarget" to target,
        "systemCallUI" to true,
        "texts" to CallModel.DEFAULT_TEXTS
    ).apply {
        if (controls != null) this["controls"] = controls
        if (startedAt != null) this["startedAt"] = startedAt
        if (groupName != null) this["groupName"] = groupName
    }

    private fun notification(id: Int = 300): Notification =
        manager().activeNotifications.first { it.id == id }.notification

    private fun isShown(id: Int = 300) = manager().activeNotifications.any { it.id == id }

    private fun actions(id: Int = 300) = notification(id).actions.orEmpty().map { it.title.toString() }

    private fun template(n: Notification) = n.extras.getString(Notification.EXTRA_TEMPLATE)

    private fun actionEvents() = events.filter { it.first == Definitions.EVENT_DEFAULT_ACTION }.map { it.second }

    @Suppress("UNCHECKED_CAST")
    private fun payloadOf(content: Map<String, Any?>) = content[Definitions.NOTIFICATION_PAYLOAD] as Map<String, Any?>

    private fun commandIntent(action: CallAction, callId: String = "c-1"): Intent {
        val model = Calls.entry(callId)!!.model
        return Intent(context, CallCommandReceiver::class.java).apply {
            this.action = CallKeys.INTENT_COMMAND
            putExtra(CallKeys.EXTRA_ACTION, action.name)
            putExtra(CallKeys.EXTRA_CALL_ID, callId)
            putExtra(Definitions.NOTIFICATION_JSON, JsonUtils.getInstance().toJson(model))
        }
    }

    // MARK: - Parse / validate

    @Test fun parsesAValidCallWithItsDefaults() {
        val (call, error) = CallModel.parse(
            mapOf("callId" to "c", "caller" to mapOf("key" to "k", "name" to "N"), "state" to "incoming")
        )
        assertNull(error)
        call!!
        assertEquals(60_000L, call.ringTimeoutMs)
        assertTrue(call.missedNotification)
        assertEquals(CallControl.values().toSet(), call.controls)
        assertEquals(CommandTarget.actionEvent, call.target)
        assertEquals("Incoming call", call.text(CallKeys.TEXT_INCOMING))
        assertEquals("N", call.displayName)
        assertEquals("app:k", CoreTelecom.addressOf(call).toString())
    }

    @Test fun parsesAPushBlockAsJsonOrStrings() {
        val json = """{"callId":"c","caller":{"key":"k","name":"N"},"state":"ongoing","video":"true",
            |"startedAt":"1700000000000","ringTimeout":"5000","groupName":"Team",
            |"texts":{"ongoing":"Em chamada"}}""".trimMargin()
        val call = CallModel.parse(json).first!!
        assertTrue(call.video)
        assertEquals(1_700_000_000_000L, call.startedAt)
        assertEquals(5_000L, call.ringTimeoutMs)
        assertEquals("Team", call.displayName)
        assertEquals("Em chamada", call.text(CallKeys.TEXT_ONGOING))
        assertEquals("Calling…", call.text(CallKeys.TEXT_OUTGOING))
    }

    @Test fun rejectsInvalidBlocksWithTheDartMessages() {
        fun error(change: MutableMap<String, Any?>.() -> Unit) = CallModel.parse(call().apply(change)).second
        assertEquals("The call block must be a map", CallModel.parse(42).second)
        assertEquals("The call needs a non-empty callId", error { this["callId"] = " " })
        assertEquals("The call needs a caller with a key and a name", error { remove("caller") })
        assertEquals("The caller needs a non-empty key", error { this["caller"] = mapOf("key" to " ", "name" to "N") })
        assertEquals("The caller needs a non-empty name", error { this["caller"] = mapOf("key" to "k", "name" to "") })
        assertEquals(
            "The call handle can't be empty (leave it out to use the caller's key)",
            error { this["handle"] = " " }
        )
        assertEquals("The call groupName can't be empty", error { this["groupName"] = "" })
        assertEquals("Unknown call state: ringing", error { this["state"] = "ringing" })
        assertEquals("The ring timeout must be positive", error { this["ringTimeout"] = 0 })
        assertEquals("Unknown call control: speaker", error { this["controls"] = listOf("speaker") })
        assertEquals(
            "An incoming call needs the accept or the decline control",
            error { this["controls"] = listOf("hangUp") }
        )
        assertEquals("Unknown call commandTarget: push", error { this["commandTarget"] = "push" })
        assertEquals("The call video must be a bool", error { this["video"] = 3 })
        assertEquals("The call texts must be a map", error { this["texts"] = "x" })
    }

    @Test fun theMissedNotificationIdIsJavasHashOfMissedCallId() {
        assertEquals("missed:c-1".hashCode() and 0x7FFFFFFF, Calls.missedNotificationId("c-1"))
        // Same value as Dart's missedNotificationIdOf (web).
        var h = 0
        for (unit in "missed:c-1") h = 31 * h + unit.code
        assertEquals(h and 0x7FFFFFFF, Calls.missedNotificationId("c-1"))
    }

    // MARK: - Refusals and the core's own notifications

    @Test fun aMalformedCallIsRefused() {
        val outcome = create(call = call().apply { this["callId"] = "" })
        assertEquals("INVALID_ARGUMENTS", outcome.code)
        assertEquals("arguments.invalid.notificationCall", outcome.detail)
        assertEquals("The call needs a non-empty callId", outcome.message)
        assertFalse(isShown())
    }

    @Test fun aScheduledCallIsRefused() {
        val outcome = create(extra = mapOf("schedule" to mapOf("interval" to 60)))
        assertEquals("INVALID_ARGUMENTS", outcome.code)
        assertEquals("arguments.invalid.notificationCall.schedule", outcome.detail)
        assertFalse(isShown())
        assertTrue(foreground.shown.isEmpty())
    }

    @Test fun aCallCategoryWithoutACallBlockKeepsTheCoreBehavior() {
        assertEquals(true, create(call = null, content = mapOf("category" to "Call")).created)
        val n = notification()
        assertNull(template(n))
        assertTrue(n.flags and Notification.FLAG_INSISTENT != 0)
        assertTrue(n.flags and Notification.FLAG_NO_CLEAR != 0)
        assertNull(n.fullScreenIntent)
        assertNull(Calls.entry("c-1"))
        assertTrue(foreground.shown.isEmpty())
    }

    // MARK: - Incoming

    @Test fun anIncomingCallIsACallStyleWithAFullScreenIntent() {
        assertEquals(true, create(call = call(video = true)).created)
        val n = notification()
        assertEquals("android.app.Notification\$CallStyle", template(n))
        assertEquals(1, n.extras.getInt(Notification.EXTRA_CALL_TYPE)) // CALL_TYPE_INCOMING
        assertTrue(n.extras.getBoolean(Notification.EXTRA_CALL_IS_VIDEO))
        assertNotNull(n.fullScreenIntent)
        assertEquals(Notification.CATEGORY_CALL, n.category)
        assertEquals("Little Mary", n.extras.getCharSequence(Notification.EXTRA_TITLE).toString())
        assertEquals("Incoming video call", n.extras.getCharSequence(Notification.EXTRA_TEXT).toString())
        // Rings (the channel's sound, looping) until answered; can't be cleared.
        assertTrue(n.flags and Notification.FLAG_INSISTENT != 0)
        assertTrue(n.flags and Notification.FLAG_NO_CLEAR != 0)
        assertTrue(n.flags and Notification.FLAG_ONGOING_EVENT != 0)
        assertTrue(n.flags and Notification.FLAG_ONLY_ALERT_ONCE != 0)
        assertFalse(n.flags and Notification.FLAG_AUTO_CANCEL != 0)
        // The callId in the payload of the created event.
        val created = events.first { it.first == Definitions.EVENT_NOTIFICATION_CREATED }.second
        assertEquals("c-1", payloadOf(created)["callId"])
        // The service starts, without waiting: the full-screen intent is enough for CallStyle.
        assertEquals(listOf(300 to false), foreground.shown)
        assertEquals(listOf("c-1" to CallState.incoming), telecom!!.synced)
        assertEquals(listOf(mapOf("callId" to "c-1", "state" to "incoming")), Calls.activeCalls())
    }

    @Test fun anIncomingCallWithoutDeclineHasPlainButtons() {
        create(call = call(controls = listOf("accept")))
        val n = notification()
        assertNull(template(n))
        assertEquals(listOf("Accept"), actions())
        assertNotNull(n.fullScreenIntent)
    }

    @Test fun theSameCallIdUpdatesTheSameNotification() {
        create()
        val alarms = shadowOf(context.getSystemService(Context.ALARM_SERVICE) as AlarmManager)
        val scheduled = alarms.scheduledAlarms.size
        create(call = call().apply { this["texts"] = CallModel.DEFAULT_TEXTS + ("incoming" to "Ringing") })
        assertEquals(1, manager().activeNotifications.size)
        assertEquals("Ringing", notification().extras.getCharSequence(Notification.EXTRA_TEXT).toString())
        assertEquals(scheduled, alarms.scheduledAlarms.size)

        // Another notification id for the same call replaces the first.
        create(id = 301)
        assertFalse(isShown(300))
        assertTrue(isShown(301))
    }

    // MARK: - Ongoing / outgoing / held

    @Test fun anOngoingCallIsACallStyleOfTheForegroundServiceWithItsTimer() {
        assertEquals(true, create(call = call(state = "ongoing", startedAt = 1_234_000L), content = mapOf("category" to "Call")).created)
        val n = notification()
        assertEquals("android.app.Notification\$CallStyle", template(n))
        assertEquals(2, n.extras.getInt(Notification.EXTRA_CALL_TYPE)) // CALL_TYPE_ONGOING
        assertNull(n.fullScreenIntent)
        assertTrue(n.extras.getBoolean(Notification.EXTRA_SHOW_CHRONOMETER))
        assertEquals(1_234_000L, n.`when`)
        // Never insistent, even with the Call category (the core's 0.12 flags).
        assertFalse(n.flags and Notification.FLAG_INSISTENT != 0)
        assertTrue(n.flags and Notification.FLAG_NO_CLEAR != 0)
        assertEquals("Ongoing call", n.extras.getCharSequence(Notification.EXTRA_TEXT).toString())
        // The service was in the foreground before the core posted it.
        assertEquals(300 to true, foreground.shown.first())
        // CallStyle: hang up and one more button.
        assertEquals(listOf("Hang Up", "Mute"), actions())
    }

    @Test fun onlyTheRingingCallUsesTheAppsChannelTheOthersAreSilent() {
        create()
        assertEquals("calls", notification().channelId)
        for (state in listOf("ongoing", "held", "outgoing")) {
            create(call = call(state = state))
            val n = notification()
            // The package's silent channel: answering stops the looping ring.
            assertEquals(SilentCallChannel.ID, n.channelId)
            assertNull(n.sound)
            val channel = manager().getNotificationChannel(SilentCallChannel.ID)
            assertNull(channel.sound)
            assertFalse(channel.shouldVibrate())
        }
    }

    @Test fun withoutTheServiceAnOngoingCallHasPlainButtons() {
        foreground.allowed = false
        assertEquals(true, create(call = call(state = "ongoing", startedAt = 1_234_000L)).created)
        val n = notification()
        assertNull(template(n))
        assertEquals(listOf("Hang up", "Mute", "Hold"), actions())
        assertTrue(n.extras.getBoolean(Notification.EXTRA_SHOW_CHRONOMETER))
    }

    @Config(sdk = [30])
    @Test fun beforeAndroid12CallStyleNeedsNoService() {
        foreground.allowed = false
        create(call = call(state = "ongoing"))
        assertTrue(foreground.shown.none { it.second })
        assertTrue(isShown())
    }

    @Test fun anOutgoingCallIsSilentWithoutATimer() {
        create(call = call(state = "outgoing"))
        val n = notification()
        assertEquals("android.app.Notification\$CallStyle", template(n))
        assertEquals("Calling…", n.extras.getCharSequence(Notification.EXTRA_TEXT).toString())
        assertFalse(n.extras.getBoolean(Notification.EXTRA_SHOW_CHRONOMETER))
        assertFalse(n.flags and Notification.FLAG_INSISTENT != 0)
        assertNull(n.fullScreenIntent)
        assertFalse(actions().contains("Hold"))
    }

    @Test fun aGroupCallShowsTheGroupsName() {
        create(call = call(groupName = "Family"))
        assertEquals("Family", notification().extras.getCharSequence(Notification.EXTRA_TITLE).toString())
    }

    // MARK: - Ended / missed

    @Test fun anEndedCallIsRemovedWithoutACommand() {
        create()
        events.clear()
        assertEquals(true, create(call = call(state = "ended")).created)
        assertFalse(isShown())
        assertNull(Calls.entry("c-1"))
        assertEquals(listOf("c-1" to DisconnectCause.LOCAL), telecom!!.ended)
        assertTrue(300 in foreground.hidden)
        assertTrue(actionEvents().isEmpty())
        assertTrue(streamed.isEmpty())
        assertTrue(Calls.activeCalls().isEmpty())
    }

    @Test fun aMissedCallShowsTheMissedNotification() {
        create(call = call(video = true))
        events.clear()
        create(call = call(state = "missed", video = true))
        assertFalse(isShown())
        val missedId = Calls.missedNotificationId("c-1")
        val n = notification(missedId)
        assertEquals("Little Mary", n.extras.getCharSequence(Notification.EXTRA_TITLE).toString())
        assertEquals("Missed video call", n.extras.getCharSequence(Notification.EXTRA_TEXT).toString())
        assertNull(template(n))
        assertTrue(n.actions.isNullOrEmpty())
        assertTrue(n.flags and Notification.FLAG_AUTO_CANCEL != 0)
        val created = events.first { it.first == Definitions.EVENT_NOTIFICATION_CREATED }.second
        assertEquals(missedId, created[Definitions.NOTIFICATION_ID])
        assertEquals("c-1", payloadOf(created)["callId"])
        assertEquals(listOf("c-1" to DisconnectCause.MISSED), telecom!!.ended)
        assertTrue(actionEvents().isEmpty())
    }

    @Test fun aMissedCallWithoutMissedNotificationShowsNothing() {
        create()
        create(call = call(state = "missed", missedNotification = false))
        assertTrue(manager().activeNotifications.isEmpty())
    }

    // MARK: - Ring timeout

    @Test fun theRingTimeoutEndsTheCallAsMissedAndEmitsTimeout() {
        create(call = call(ringTimeout = 30_000))
        val alarms = shadowOf(context.getSystemService(Context.ALARM_SERVICE) as AlarmManager)
        assertNotNull(alarms.nextScheduledAlarm)
        events.clear()

        shadowOf(Looper.getMainLooper()).idleFor(29, TimeUnit.SECONDS)
        assertTrue(isShown())
        shadowOf(Looper.getMainLooper()).idleFor(2, TimeUnit.SECONDS)

        assertFalse(isShown())
        assertTrue(isShown(Calls.missedNotificationId("c-1")))
        assertEquals(listOf("c-1" to DisconnectCause.MISSED), telecom!!.ended)
        val action = actionEvents().single()
        assertEquals("awn.call.timeout", action[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED])
        assertEquals("c-1", payloadOf(action)["callId"])
        // The backup alarm went with the call.
        assertNull(alarms.nextScheduledAlarm)
    }

    @Test fun theTimeoutAlarmWorksWhenTheProcessForgotTheCall() {
        create()
        val model = Calls.entry("c-1")!!.model
        Calls.resetForTest()
        Calls.makeTelecom = { _, l -> FakeTelecom(l).also { telecom = it } }
        Calls.makeCore = { core }
        events.clear()
        CallCommandReceiver().onReceive(context, Intent(context, CallCommandReceiver::class.java).apply {
            action = CallKeys.INTENT_TIMEOUT
            putExtra(CallKeys.EXTRA_CALL_ID, "c-1")
            putExtra(Definitions.NOTIFICATION_JSON, JsonUtils.getInstance().toJson(model))
        })
        idle()
        assertFalse(isShown())
        assertTrue(isShown(Calls.missedNotificationId("c-1")))
        assertEquals("awn.call.timeout", actionEvents().single()[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED])
    }

    @Test fun anAnsweredCallDoesNotTimeOut() {
        create()
        Calls.command(context, CallAction.accept, "c-1", null)
        idle()
        events.clear()
        shadowOf(Looper.getMainLooper()).idleFor(60, TimeUnit.SECONDS)
        assertTrue(isShown())
        assertTrue(actionEvents().isEmpty())
        assertNull(shadowOf(context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).nextScheduledAlarm)
    }

    // MARK: - Commands

    @Test fun acceptMakesTheCallOngoingThenDeliversIt() {
        create()
        events.clear()
        Calls.command(context, CallAction.accept, "c-1", null)
        idle()
        val entry = Calls.entry("c-1")!!
        assertEquals(CallState.ongoing, entry.call.state)
        assertEquals(1_000_000L, entry.call.startedAt)
        val n = notification()
        assertEquals(2, n.extras.getInt(Notification.EXTRA_CALL_TYPE))
        assertFalse(n.flags and Notification.FLAG_INSISTENT != 0)
        assertEquals(1_000_000L, n.`when`)
        assertEquals("c-1" to CallState.ongoing, telecom!!.synced.last())
        val action = actionEvents().single()
        assertEquals("awn.call.accept", action[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED])
        assertEquals("c-1", payloadOf(action)["callId"])
        // Applying the same command twice does nothing.
        Calls.command(context, CallAction.accept, "c-1", null)
        idle()
        assertEquals(1, actionEvents().size)
    }

    @Test fun declineFromTheNotificationEndsTheCallAndReachesTheApp() {
        create()
        events.clear()
        CallCommandReceiver().onReceive(context, commandIntent(CallAction.decline))
        idle()
        assertFalse(isShown())
        assertNull(Calls.entry("c-1"))
        assertEquals(listOf("c-1" to DisconnectCause.REJECTED), telecom!!.ended)
        assertEquals("awn.call.decline", actionEvents().single()[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED])
        assertFalse(isShown(Calls.missedNotificationId("c-1")))
    }

    @Test fun hangUpEndsTheCall() {
        create(call = call(state = "ongoing"))
        CallCommandReceiver().onReceive(context, commandIntent(CallAction.hangUp))
        idle()
        assertFalse(isShown())
        assertEquals(listOf("c-1" to DisconnectCause.LOCAL), telecom!!.ended)
        assertEquals("awn.call.hangUp", actionEvents().single()[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED])
    }

    @Test fun muteAndHoldToggleTheNotification() {
        create(call = call(state = "ongoing"))
        CallCommandReceiver().onReceive(context, commandIntent(CallAction.mute))
        idle()
        assertEquals(listOf("Hang Up", "Unmute"), actions())
        CallCommandReceiver().onReceive(context, commandIntent(CallAction.hold))
        idle()
        assertEquals(CallState.held, Calls.entry("c-1")!!.call.state)
        assertEquals(listOf("Hang Up", "Resume"), actions())
        assertEquals("c-1" to CallState.held, telecom!!.synced.last())
        CallCommandReceiver().onReceive(context, commandIntent(CallAction.unhold))
        CallCommandReceiver().onReceive(context, commandIntent(CallAction.unmute))
        idle()
        assertEquals(listOf("Hang Up", "Mute"), actions())
        assertEquals(CallState.ongoing, Calls.entry("c-1")!!.call.state)
        assertEquals(
            listOf("awn.call.mute", "awn.call.hold", "awn.call.unhold", "awn.call.unmute"),
            actionEvents().map { it[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED] }
        )
    }

    @Test fun streamCommandsGoToTheEventChannelOnly() {
        create(call = call(target = "stream"))
        events.clear()
        CallCommandReceiver().onReceive(context, commandIntent(CallAction.decline))
        idle()
        assertEquals(listOf(mapOf("kind" to "command", "action" to "decline", "callId" to "c-1")), streamed)
        assertTrue(actionEvents().isEmpty())
    }

    @Test fun bothTargetsGetTheCommand() {
        create(call = call(target = "both", state = "ongoing"))
        events.clear()
        CallCommandReceiver().onReceive(context, commandIntent(CallAction.hangUp))
        idle()
        assertEquals("hangUp", streamed.single()["action"])
        assertEquals(1, actionEvents().size)
    }

    @Test fun withTheAppKilledTheCommandRunsInABackgroundIsolate() {
        create()
        val intent = commandIntent(CallAction.decline)
        AwesomeEventsReceiver.unsubscribe(listener)
        val background = mutableListOf<Map<String, Any?>>()
        BackgroundActions.executor = BackgroundActions.Executor { _, action, done -> background.add(action); done() }
        // A new process: only the intent knows the call.
        Calls.resetForTest()
        Calls.makeTelecom = { _, l -> FakeTelecom(l).also { telecom = it } }
        CallCommandReceiver().onReceive(context, intent)
        idle()
        assertFalse(isShown())
        assertEquals("awn.call.decline", background.single()[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED])
        assertEquals("Terminated", background.single()[Definitions.NOTIFICATION_ACTION_LIFECYCLE])
    }

    @Test fun theSystemsCommandsAreAppliedAndDelivered() {
        create()
        events.clear()
        telecom!!.listener.onSystemAction("c-1", CallAction.accept)
        idle()
        assertEquals(CallState.ongoing, Calls.entry("c-1")!!.call.state)
        telecom!!.listener.onSystemAction("c-1", CallAction.mute)
        idle()
        assertTrue(Calls.entry("c-1")!!.muted)
        telecom!!.listener.onSystemAction("c-1", CallAction.hangUp)
        idle()
        assertFalse(isShown())
        assertEquals(
            listOf("awn.call.accept", "awn.call.mute", "awn.call.hangUp"),
            actionEvents().map { it[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED] }
        )
    }

    // MARK: - Removal

    @Test fun cancellingTheNotificationEndsTheCallWithoutACommand() {
        create()
        events.clear()
        core.cancel(300)
        assertFalse(isShown())
        assertNull(Calls.entry("c-1"))
        assertEquals(listOf("c-1" to DisconnectCause.LOCAL), telecom!!.ended)
        assertTrue(actionEvents().isEmpty())
        // The ring timer went too.
        shadowOf(Looper.getMainLooper()).idleFor(60, TimeUnit.SECONDS)
        assertTrue(manager().activeNotifications.isEmpty())
    }

    @Test fun dismissingTheChannelEndsItsCalls() {
        create()
        core.dismissByChannelKey("calls")
        assertNull(Calls.entry("c-1"))
    }

    // MARK: - Methods

    private fun invoke(method: String, arguments: Any? = null, requested: Boolean = false): Pair<Boolean, Any?> {
        var value: Any? = "unset"
        val handled = CallMethodHandler(context) { it(requested) }.handle(method, arguments, { value = it }) { code, _, _ ->
            value = "error:$code"
        }
        idle()
        return handled to value
    }

    @Test fun callEndUnansweredShowsTheMissedNotification() {
        create()
        val (handled, value) = invoke("callEnd", mapOf("callId" to "c-1", "reason" to "unanswered"))
        assertTrue(handled)
        assertEquals(true, value)
        assertFalse(isShown())
        assertTrue(isShown(Calls.missedNotificationId("c-1")))
        assertEquals(listOf("c-1" to DisconnectCause.MISSED), telecom!!.ended)
    }

    @Test fun callEndRemoteEndedShowsNothing() {
        create(call = call(state = "ongoing"))
        invoke("callEnd", mapOf("callId" to "c-1", "reason" to "remoteEnded"))
        assertTrue(manager().activeNotifications.isEmpty())
        assertEquals(listOf("c-1" to DisconnectCause.REMOTE), telecom!!.ended)
        assertEquals("error:INVALID_ARGUMENTS", invoke("callEnd", mapOf("reason" to "failed")).second)
    }

    @Test fun theOtherMethods() {
        create()
        assertEquals(listOf(mapOf("callId" to "c-1", "state" to "incoming")), invoke("callActiveCalls").second)
        assertEquals(true to null, invoke("callVoipToken"))
        assertTrue(invoke("callCanUseFullScreenIntent").second is Boolean)
        @Suppress("UNCHECKED_CAST")
        val capabilities = invoke("callCapabilities").second as Map<String, Any?>
        assertEquals(true, capabilities["systemCallUI"])
        assertEquals(true, capabilities["muteAndHold"])
        assertEquals(true, capabilities["push"])
        assertFalse(invoke("mediaStop").first)
    }

    @Config(sdk = [33])
    @Test fun fullScreenIntentsAreAllowedBeforeAndroid14() {
        assertEquals(true, invoke("callCanUseFullScreenIntent").second)
        assertEquals(true, invoke("callRequestFullScreenIntent").second)
    }

    // MARK: - Foreground service

    @Test fun theServiceEntersTheForegroundWithTheCallAndLeaves() {
        val n = android.app.Notification.Builder(context, "calls").setSmallIcon(android.R.drawable.sym_call_incoming).build()
        CallService.pending[300] = n
        val controller = Robolectric.buildService(
            CallService::class.java,
            Intent(context, CallService::class.java).putExtra(CallKeys.EXTRA_NOTIFICATION_ID, 300)
        ).create().startCommand(0, 1)
        val service = controller.get()
        assertEquals(300, service.foregroundId)
        assertTrue(CallForeground.Service.isShowing(300))
        assertEquals(n, shadowOf(service).lastForegroundNotification)

        CallForeground.Service.hide(context, 300, null)
        assertNull(service.foregroundId)
        assertTrue(shadowOf(service).isStoppedBySelf)
        controller.destroy()
        assertNull(CallService.instance)
    }

    @Test fun aServiceStartedForAnEndedCallLeavesAtOnce() {
        CallService.pending.remove(301)
        val service = Robolectric.buildService(
            CallService::class.java,
            Intent(context, CallService::class.java)
                .putExtra(CallKeys.EXTRA_NOTIFICATION_ID, 301)
                .putExtra(CallKeys.EXTRA_CHANNEL_KEY, "calls")
        ).create().startCommand(0, 1).get()
        assertTrue(shadowOf(service).isStoppedBySelf)
        assertNull(service.foregroundId)
    }

    // MARK: - Answer activity

    @Test fun answeringOpensTheAppWithTheAcceptAction() {
        create()
        val model = Calls.entry("c-1")!!.model
        val intent = Intent(context, CallAnswerActivity::class.java).apply {
            putExtra(CallKeys.EXTRA_CALL_ID, "c-1")
            putExtra(Definitions.NOTIFICATION_JSON, JsonUtils.getInstance().toJson(model))
        }
        val activity = Robolectric.buildActivity(CallAnswerActivity::class.java, intent).create().get()
        idle()
        assertTrue(activity.isFinishing)
        assertEquals(CallState.ongoing, Calls.entry("c-1")!!.call.state)
        // The action event comes with the app (the core's foreground button), not from here.
        assertTrue(actionEvents().isEmpty())
    }
}
