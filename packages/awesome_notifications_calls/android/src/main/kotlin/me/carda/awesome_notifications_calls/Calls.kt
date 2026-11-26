package me.carda.awesome_notifications_calls

import android.app.AlarmManager
import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.telecom.DisconnectCause
import android.util.Log
import androidx.core.app.NotificationManagerCompat
import java.util.concurrent.Executor
import java.util.concurrent.Executors
import me.carda.android_awn_core.ActionType
import me.carda.android_awn_core.AwesomeNotifications
import me.carda.android_awn_core.BuildOutcome
import me.carda.android_awn_core.CancelInterceptor
import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.JsonUtils
import me.carda.android_awn_core.NotificationActions
import me.carda.android_awn_core.NotificationBuilder
import me.carda.android_awn_core.NotificationBuilderRegistry

/**
 * The calls the system shows, by `callId`: keeps each call's notification,
 * foreground service, Telecom call and ring timer in its state, applies the
 * user's and the system's commands to them and delivers the commands to the
 * app (the core's action event and / or the events stream).
 */
internal object Calls {

    /** A live call and what its last notification carried. */
    class Entry(@Volatile var call: CallModel, @Volatile var model: Map<String, Any?>, @Volatile var notificationId: Int) {
        @Volatile var channelKey: String? = null
        @Volatile var groupKey: String? = null
        @Volatile var muted = false
        @Volatile var notification: Notification? = null
        @Volatile var ringTimer: Runnable? = null
    }

    private val entries = LinkedHashMap<String, Entry>()
    private val main by lazy { Handler(Looper.getMainLooper()) }

    // MARK: - Seams (replaced by the tests)

    /** Where `stream` commands go: set by the plugin while Dart listens. */
    @Volatile var streamSink: ((Map<String, Any?>) -> Unit)? = null

    /** Rebuilds a call's notification after a command (off the main thread: images). */
    @Volatile var executor: Executor = Executors.newSingleThreadExecutor()

    @Volatile var foreground: CallForeground = CallForeground.Service

    @Volatile var makeTelecom: (Context, CallTelecom.Listener) -> CallTelecom = CallTelecom::create

    /** The core, for the missed call notifications. */
    @Volatile var makeCore: (Context) -> AwesomeNotifications = { AwesomeNotifications(it) }

    @Volatile var clock: () -> Long = System::currentTimeMillis

    /** Told (on the main thread) whenever a call starts or ends. */
    @Volatile var onCallsChanged: (() -> Unit)? = null

    @Volatile private var telecom: CallTelecom? = null
    @Volatile private var core: AwesomeNotifications? = null

    private fun telecom(context: Context): CallTelecom = telecom ?: synchronized(this) {
        telecom ?: makeTelecom(context.applicationContext) { callId, action ->
            onSystemAction(context.applicationContext, callId, action)
        }.also { telecom = it }
    }

    private fun core(context: Context): AwesomeNotifications = core ?: synchronized(this) {
        core ?: makeCore(context.applicationContext).also { core = it }
    }

    fun entry(callId: String): Entry? = synchronized(entries) { entries[callId] }

    fun hasLiveCalls(): Boolean = synchronized(entries) { entries.isNotEmpty() }

    /** `callActiveCalls`: the calls the system shows now. */
    fun activeCalls(): List<Map<String, Any?>> = synchronized(entries) {
        entries.values.map { mapOf(CallKeys.CALL_ID to it.call.callId, CallKeys.STATE to it.call.state.name) }
    }

    // MARK: - Building (CallBuilder)

    /**
     * The model the core builds for a live call: the callId in the payload, the
     * layout taken over, the microphone state the package keeps.
     */
    fun prepare(model: Map<String, Any?>, call: CallModel): Map<String, Any?> {
        @Suppress("UNCHECKED_CAST")
        val content = (model[Definitions.NOTIFICATION_CONTENT] as? Map<String, Any?>).orEmpty().toMutableMap()
        @Suppress("UNCHECKED_CAST")
        val payload = (content[Definitions.NOTIFICATION_PAYLOAD] as? Map<String, Any?>)?.toMutableMap()
            ?: mutableMapOf()
        payload[CallKeys.PAYLOAD_CALL_ID] = call.callId
        content[Definitions.NOTIFICATION_PAYLOAD] = payload
        return model.toMutableMap().apply {
            this[Definitions.NOTIFICATION_CONTENT] = content
            this[CallKeys.CALL] = call.toMap()
            this[NotificationBuilder.CUSTOM_LAYOUT] = true
            this[CallKeys.MODEL_MUTED] = entry(call.callId)?.muted == true
            remove(CallKeys.MODEL_PLAIN)
        }
    }

    /**
     * The notification of a live call was built and is about to be posted: the
     * call's ringing, foreground service and Telecom call follow its state.
     */
    fun posted(context: Context, call: CallModel, outcome: BuildOutcome.Post) {
        val app = context.applicationContext
        @Suppress("UNCHECKED_CAST")
        val content = (outcome.model[Definitions.NOTIFICATION_CONTENT] as? Map<String, Any?>).orEmpty()
        var replaced: Int? = null
        val (entry, previous) = synchronized(entries) {
            val existing = entries[call.callId]
            val previous = existing?.call?.state
            val entry = existing ?: Entry(call, outcome.model, outcome.id).also { entries[call.callId] = it }
            if (entry.notificationId != outcome.id) replaced = entry.notificationId
            entry.call = call
            entry.model = outcome.model
            entry.notificationId = outcome.id
            entry.channelKey = content[Definitions.NOTIFICATION_CHANNEL_KEY] as? String
            entry.groupKey = content[Definitions.NOTIFICATION_GROUP_KEY] as? String
            entry.notification = outcome.notification
            entry to previous
        }
        // The same call under another notification id: one notification per call.
        replaced?.let {
            foreground.hide(app, it, null)
            NotificationManagerCompat.from(app).cancel(it)
        }

        if (call.state == CallState.incoming) {
            if (previous != CallState.incoming) scheduleRing(app, entry)
        } else {
            cancelRing(app, entry)
        }
        telecom(app).sync(call)
        foreground.show(app, outcome.id, entry.channelKey, outcome.notification, wait = false)
        if (previous == null) changed()
    }

    /** The app sent the call `ended` or `missed`: it's over (no command). */
    fun finish(context: Context, call: CallModel, notificationId: Int?, channelKey: String?) {
        val app = context.applicationContext
        val missed = call.state == CallState.missed
        val cause = if (missed) DisconnectCause.MISSED else DisconnectCause.LOCAL
        val entry = entry(call.callId)
        if (entry != null) {
            end(app, entry, cause)
        } else {
            cancelRingAlarm(app, call.callId)
            telecom(app).end(call.callId, cause)
            notificationId?.let { NotificationManagerCompat.from(app).cancel(it) }
        }
        if (missed && call.missedNotification) showMissed(app, call, entry?.channelKey ?: channelKey)
    }

    /** Ends the call everywhere (no command). */
    private fun end(context: Context, entry: Entry, cause: Int) {
        val removed = synchronized(entries) {
            if (entries[entry.call.callId] === entry) entries.remove(entry.call.callId) else null
        } ?: return
        cancelRing(context, removed)
        telecom(context).end(removed.call.callId, cause)
        val next = synchronized(entries) { entries.values.lastOrNull() }
            ?.let { live -> live.notification?.let { live.notificationId to it } }
        foreground.hide(context, removed.notificationId, next)
        NotificationManagerCompat.from(context).cancel(removed.notificationId)
        changed()
    }

    // MARK: - Channel methods

    /** `callEnd`: ends the call; `unanswered` also shows the missed notification. */
    fun endCall(context: Context, callId: String, reason: EndReason) {
        val app = context.applicationContext
        val cause = CallTelecom.causeOf(reason)
        val entry = entry(callId)
        if (entry == null) {
            cancelRingAlarm(app, callId)
            telecom(app).end(callId, cause)
            return
        }
        end(app, entry, cause)
        if (reason == EndReason.unanswered && entry.call.missedNotification) {
            showMissed(app, entry.call, entry.channelKey)
        }
    }

    // MARK: - Commands

    /**
     * A command of the user (a notification button) on [callId]: applied to the
     * system call first, then delivered. [sent] is the model the button carried
     * (the call may be unknown to a process started for this command).
     * [toActionEvent] false: the app is opened with the action (accept).
     */
    fun command(
        context: Context,
        action: CallAction,
        callId: String,
        sent: Map<String, Any?>?,
        toActionEvent: Boolean = true,
        onFinished: () -> Unit = {}
    ) {
        val app = context.applicationContext
        val entry = entry(callId)
        val model = entry?.model ?: sent ?: return onFinished()
        val call = entry?.call ?: CallModel.parse(model[CallKeys.CALL]).first ?: return onFinished()

        fun deliverAfter(updated: Map<String, Any?>) =
            deliver(app, updated, call, action, toActionEvent, onFinished)

        when (action) {
            CallAction.accept -> {
                if (call.state != CallState.incoming) return onFinished()
                val updated = withCall(model, call.toMap(CallState.ongoing, call.startedAt ?: clock()))
                cancelRingAlarm(app, callId)
                entry?.let { cancelRing(app, it) }
                repost(app, updated) { deliverAfter(updated) }
            }
            CallAction.decline, CallAction.hangUp -> {
                val cause = if (action == CallAction.decline) DisconnectCause.REJECTED else DisconnectCause.LOCAL
                if (entry != null) end(app, entry, cause) else {
                    cancelRingAlarm(app, callId)
                    idOf(model)?.let { NotificationManagerCompat.from(app).cancel(it) }
                }
                deliverAfter(model)
            }
            CallAction.mute, CallAction.unmute -> {
                val muted = action == CallAction.mute
                if (entry == null || entry.muted == muted) return onFinished()
                entry.muted = muted
                repost(app, entry.model) { deliverAfter(entry.model) }
            }
            CallAction.hold, CallAction.unhold -> {
                val to = if (action == CallAction.hold) CallState.held else CallState.ongoing
                val from = if (action == CallAction.hold) CallState.ongoing else CallState.held
                if (call.state != from) return onFinished()
                val updated = withCall(model, call.toMap(to))
                repost(app, updated) { deliverAfter(updated) }
            }
            CallAction.timeout -> timeout(app, callId, sent, onFinished)
            CallAction.audioActivated, CallAction.audioDeactivated -> onFinished()
        }
    }

    /** The system (Telecom: a headset, a car…) asked for [action]: as the user's command. */
    fun onSystemAction(context: Context, callId: String, action: CallAction) =
        main.post { command(context, action, callId, null) }

    /** The ring timed out: the call is over and missed. */
    fun timeout(context: Context, callId: String, sent: Map<String, Any?>?, onFinished: () -> Unit = {}) {
        val app = context.applicationContext
        val entry = entry(callId)
        val call: CallModel
        val model: Map<String, Any?>
        if (entry != null) {
            if (entry.call.state != CallState.incoming) return onFinished()
            call = entry.call
            model = entry.model
            end(app, entry, DisconnectCause.MISSED)
        } else {
            // The process died while ringing: the alarm still knows the call.
            model = sent ?: return onFinished()
            call = CallModel.parse(model[CallKeys.CALL]).first ?: return onFinished()
            cancelRingAlarm(app, callId)
            idOf(model)?.let { NotificationManagerCompat.from(app).cancel(it) }
        }
        if (call.missedNotification) showMissed(app, call, channelOf(model))
        deliver(app, model, call, CallAction.timeout, true, onFinished)
    }

    /** Delivers a command to the targets of [call]. */
    fun deliver(
        context: Context,
        model: Map<String, Any?>,
        call: CallModel,
        action: CallAction,
        toActionEvent: Boolean = true,
        onFinished: () -> Unit = {}
    ) {
        if (call.target.toStream) {
            streamSink?.let { sink ->
                val event = mapOf(
                    CallKeys.KIND to CallKeys.KIND_COMMAND,
                    CallKeys.ACTION to action.name,
                    CallKeys.CALL_ID to call.callId
                )
                if (Looper.myLooper() == Looper.getMainLooper()) sink(event) else main.post { sink(event) }
            }
        }
        if (call.target.toActionEvent && toActionEvent) {
            NotificationActions.dispatch(context, model, action.key, null, syntheticButton(action), onFinished)
        } else {
            onFinished()
        }
    }

    /** Keeps the notification (the package removes it itself) and reaches the app or a background isolate. */
    fun syntheticButton(action: CallAction, actionType: ActionType = ActionType.SilentAction): Map<String, Any?> = mapOf(
        Definitions.NOTIFICATION_BUTTON_KEY to action.key,
        Definitions.NOTIFICATION_ACTION_TYPE to actionType.name,
        Definitions.NOTIFICATION_AUTO_DISMISSIBLE to false
    )

    /** Rebuilds and posts a call's notification through the core's chain, then runs [then]. */
    private fun repost(context: Context, model: Map<String, Any?>, then: () -> Unit) {
        executor.execute {
            try {
                val outcome = NotificationBuilderRegistry.makeBuilder().build(context, model)
                if (outcome is BuildOutcome.Post) {
                    NotificationManagerCompat.from(context).notify(outcome.id, outcome.notification)
                }
            } catch (e: Exception) {
                Log.w(TAG, "The call notification could not be updated: ${e.message}")
            }
            then()
        }
    }

    // MARK: - Ring timer

    /**
     * Two timers: the Handler is exact while the process lives (the foreground
     * service keeps it alive); the alarm survives the process (a call that
     * rang with the app killed and the service not allowed). Whichever comes
     * first ends the call; the other is cancelled.
     */
    private fun scheduleRing(context: Context, entry: Entry) {
        cancelRing(context, entry)
        val callId = entry.call.callId
        val timer = Runnable { timeout(context, callId, null) }
        entry.ringTimer = timer
        main.postDelayed(timer, entry.call.ringTimeoutMs)

        val alarm = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val at = SystemClock.elapsedRealtime() + entry.call.ringTimeoutMs
        val pending = ringIntent(context, callId, entry.model)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarm.canScheduleExactAlarms()) {
                alarm.setAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, at, pending)
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarm.setExactAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, at, pending)
            } else {
                alarm.setExact(AlarmManager.ELAPSED_REALTIME_WAKEUP, at, pending)
            }
        } catch (e: SecurityException) {
            alarm.set(AlarmManager.ELAPSED_REALTIME_WAKEUP, at, pending)
        }
    }

    private fun cancelRing(context: Context, entry: Entry) {
        entry.ringTimer?.let { main.removeCallbacks(it) }
        entry.ringTimer = null
        cancelRingAlarm(context, entry.call.callId)
    }

    private fun cancelRingAlarm(context: Context, callId: String) {
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val pending = ringIntent(context, callId, null)
        alarm.cancel(pending)
        pending.cancel()
    }

    private fun ringIntent(context: Context, callId: String, model: Map<String, Any?>?): PendingIntent {
        val intent = Intent(context, CallCommandReceiver::class.java).apply {
            action = CallKeys.INTENT_TIMEOUT
            data = Uri.parse("awn-call://" + Uri.encode(callId) + "/timeout")
            putExtra(CallKeys.EXTRA_CALL_ID, callId)
            model?.let { putExtra(Definitions.NOTIFICATION_JSON, JsonUtils.getInstance().toJson(it)) }
        }
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) flags = flags or PendingIntent.FLAG_IMMUTABLE
        return PendingIntent.getBroadcast(context, ("timeout:$callId").hashCode(), intent, flags)
    }

    // MARK: - Missed notification

    /** Same id on every platform: Java's `String.hashCode` of `"missed:" + callId`, positive. */
    fun missedNotificationId(callId: String): Int = ("missed:$callId").hashCode() and 0x7FFFFFFF

    /** A regular core notification on the call's channel. */
    fun showMissed(context: Context, call: CallModel, channelKey: String?) {
        val content = mutableMapOf<String, Any?>(
            Definitions.NOTIFICATION_ID to missedNotificationId(call.callId),
            Definitions.NOTIFICATION_CHANNEL_KEY to channelKey,
            Definitions.NOTIFICATION_TITLE to call.displayName,
            Definitions.NOTIFICATION_BODY to call.text(
                if (call.video) CallKeys.TEXT_MISSED_VIDEO else CallKeys.TEXT_MISSED
            ),
            Definitions.NOTIFICATION_PAYLOAD to mapOf(CallKeys.PAYLOAD_CALL_ID to call.callId)
        )
        call.caller.avatar?.let { content[Definitions.NOTIFICATION_LARGE_ICON] = it }
        core(context).createNotification(mapOf(Definitions.NOTIFICATION_CONTENT to content)) {}
    }

    // MARK: - Removal

    /**
     * A call's notification left the status bar (the app's cancel / dismiss,
     * an action dismissing it, a swipe): the call ends, as `callEnd` does, without a command.
     */
    val cancelInterceptor = object : CancelInterceptor {
        override fun onDismiss(context: Context, id: Int) = endWhere(context) { it.notificationId == id }
        override fun onDismissAll(context: Context) = endWhere(context) { true }
        override fun onDismissByChannelKey(context: Context, channelKey: String) =
            endWhere(context) { it.channelKey == channelKey }
        override fun onDismissByGroupKey(context: Context, groupKey: String) =
            endWhere(context) { it.groupKey == groupKey }
    }

    private fun endWhere(context: Context, predicate: (Entry) -> Boolean) {
        val matched = synchronized(entries) { entries.values.filter(predicate) }
        matched.forEach { end(context.applicationContext, it, DisconnectCause.LOCAL) }
    }

    // MARK: - Helpers

    private fun changed() {
        val listener = onCallsChanged ?: return
        if (Looper.myLooper() == Looper.getMainLooper()) listener() else main.post(listener)
    }

    private fun withCall(model: Map<String, Any?>, call: Map<String, Any?>): Map<String, Any?> =
        model.toMutableMap().apply { this[CallKeys.CALL] = call }

    @Suppress("UNCHECKED_CAST")
    private fun contentOf(model: Map<String, Any?>): Map<String, Any?> =
        (model[Definitions.NOTIFICATION_CONTENT] as? Map<String, Any?>).orEmpty()

    private fun idOf(model: Map<String, Any?>): Int? = (contentOf(model)[Definitions.NOTIFICATION_ID] as? Number)?.toInt()

    private fun channelOf(model: Map<String, Any?>): String? =
        contentOf(model)[Definitions.NOTIFICATION_CHANNEL_KEY] as? String

    /** Test-only: forgets every call and seam. */
    internal fun resetForTest() {
        synchronized(entries) {
            entries.values.forEach { e -> e.ringTimer?.let { main.removeCallbacks(it) } }
            entries.clear()
        }
        telecom = null
        core = null
        streamSink = null
        onCallsChanged = null
    }

    private const val TAG = "AwnCalls"
}
