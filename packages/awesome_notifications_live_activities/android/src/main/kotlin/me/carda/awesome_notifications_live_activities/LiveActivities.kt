package me.carda.awesome_notifications_live_activities

import android.app.NotificationManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationManagerCompat
import java.util.concurrent.Executor
import java.util.concurrent.Executors
import me.carda.android_awn_core.BuildOutcome
import me.carda.android_awn_core.CancelInterceptor
import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.JsonUtils
import me.carda.android_awn_core.NotificationBuilder
import me.carda.android_awn_core.NotificationBuilderRegistry

/**
 * The activities the app shows, by `activityId`: each one's notification and
 * last model, kept in the app's preferences so `liveActivityList` and
 * `liveActivityEnd` work in a process started after the app was killed (a
 * push, a swipe). Reports the ends and the removals on the events stream.
 */
internal object LiveActivities {

    /** A shown activity and what its last notification carried. */
    class Entry(
        val activityId: String,
        @Volatile var notificationId: Int,
        @Volatile var ended: Boolean,
        @Volatile var model: Map<String, Any?>
    ) {
        @Volatile var channelKey: String? = null
        @Volatile var groupKey: String? = null
        @Volatile var timer: Runnable? = null

        fun toJson(): String = JsonUtils.getInstance().toJson(
            mapOf(
                NOTIFICATION_ID to notificationId,
                ENDED to ended,
                MODEL to model,
                Definitions.NOTIFICATION_CHANNEL_KEY to channelKey,
                Definitions.NOTIFICATION_GROUP_KEY to groupKey
            )
        )
    }

    private val entries = LinkedHashMap<String, Entry>()
    @Volatile private var loaded = false
    private val main by lazy { Handler(Looper.getMainLooper()) }

    // MARK: - Seams (replaced by the tests)

    /** Where the state events go: set by the plugin while Dart listens. */
    @Volatile var streamSink: ((Map<String, Any?>) -> Unit)? = null

    /** Rebuilds an activity's notification for `liveActivityEnd` (off the main thread: images). */
    @Volatile var executor: Executor = Executors.newSingleThreadExecutor()

    @Volatile var clock: () -> Long = System::currentTimeMillis

    // MARK: - Registry

    private fun prefs(context: Context): SharedPreferences =
        context.applicationContext.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

    /** Reads the persisted activities, once per process. */
    private fun load(context: Context) {
        if (loaded) return
        synchronized(entries) {
            if (loaded) return
            loaded = true
            for ((activityId, json) in prefs(context).all) {
                try {
                    val map = JsonUtils.getInstance().fromJson(json as? String ?: continue)
                    @Suppress("UNCHECKED_CAST")
                    val entry = Entry(
                        activityId,
                        (map[NOTIFICATION_ID] as? Number)?.toInt() ?: continue,
                        map[ENDED] == true,
                        map[MODEL] as? Map<String, Any?> ?: continue
                    )
                    entry.channelKey = map[Definitions.NOTIFICATION_CHANNEL_KEY] as? String
                    entry.groupKey = map[Definitions.NOTIFICATION_GROUP_KEY] as? String
                    entries[activityId] = entry
                } catch (e: Exception) {
                    Log.w(TAG, "A saved live activity could not be read: ${e.message}")
                }
            }
        }
    }

    private fun save(context: Context, entry: Entry) =
        prefs(context).edit().putString(entry.activityId, entry.toJson()).apply()

    private fun forget(context: Context, activityId: String) =
        prefs(context).edit().remove(activityId).apply()

    fun entry(context: Context, activityId: String): Entry? {
        load(context)
        return synchronized(entries) { entries[activityId] }
    }

    // MARK: - Building (LiveBuilder)

    /** The model the core builds: the activityId in the payload, the block with its defaults, the layout taken over. */
    fun prepare(model: Map<String, Any?>, live: LiveActivityModel): Map<String, Any?> {
        @Suppress("UNCHECKED_CAST")
        val content = (model[Definitions.NOTIFICATION_CONTENT] as? Map<String, Any?>).orEmpty().toMutableMap()
        @Suppress("UNCHECKED_CAST")
        val payload = (content[Definitions.NOTIFICATION_PAYLOAD] as? Map<String, Any?>)?.toMutableMap()
            ?: mutableMapOf()
        payload[LiveKeys.PAYLOAD_ACTIVITY_ID] = live.activityId
        content[Definitions.NOTIFICATION_PAYLOAD] = payload
        return model.toMutableMap().apply {
            this[Definitions.NOTIFICATION_CONTENT] = content
            this[LiveKeys.LIVE_ACTIVITY] = live.raw
            this[NotificationBuilder.CUSTOM_LAYOUT] = true
        }
    }

    /**
     * The notification of an activity was built and is about to be posted:
     * the registry follows it, an end is reported once, and the activity
     * leaves at its `staleAt` or its dismissal time.
     */
    fun posted(context: Context, live: LiveActivityModel, outcome: BuildOutcome.Post) {
        val app = context.applicationContext
        load(app)
        @Suppress("UNCHECKED_CAST")
        val content = (outcome.model[Definitions.NOTIFICATION_CONTENT] as? Map<String, Any?>).orEmpty()
        var replacedId: Int? = null
        val (entry, wasEnded, others) = synchronized(entries) {
            // Another activity on the same notification is replaced by this one.
            val others = entries.values.filter { it.activityId != live.activityId && it.notificationId == outcome.id }
            val existing = entries[live.activityId]
            val wasEnded = existing?.ended
            val entry = existing ?: Entry(live.activityId, outcome.id, live.ended, outcome.model)
                .also { entries[live.activityId] = it }
            if (entry.notificationId != outcome.id) replacedId = entry.notificationId
            entry.notificationId = outcome.id
            entry.ended = live.ended
            entry.model = outcome.model
            entry.channelKey = content[Definitions.NOTIFICATION_CHANNEL_KEY] as? String
            entry.groupKey = content[Definitions.NOTIFICATION_GROUP_KEY] as? String
            Triple(entry, wasEnded, others)
        }
        others.forEach { removed(app, it, cancel = false) }
        // The same activity under another notification id: one notification per activity.
        replacedId?.let { NotificationManagerCompat.from(app).cancel(it) }
        save(app, entry)
        if (live.ended && wasEnded != true) emit(live.activityId, LiveKeys.STATUS_ENDED)
        scheduleRemoval(app, entry, live)
    }

    /**
     * An activity that leaves as soon as it's sent (ended with an `immediate`
     * or past dismissal, or past its `staleAt`): an end is reported, then the
     * removal; nothing is posted.
     */
    fun goneAtOnce(context: Context, live: LiveActivityModel, notificationId: Int) {
        val app = context.applicationContext
        val entry = entry(app, live.activityId)
        if (live.ended && entry?.ended != true) emit(live.activityId, LiveKeys.STATUS_ENDED)
        if (entry != null) removed(app, entry, cancel = true)
        else {
            NotificationManagerCompat.from(app).cancel(notificationId)
            emit(live.activityId, LiveKeys.STATUS_DISMISSED)
        }
    }

    /** A notification without a live activity was posted on [notificationId]: the activity there is over. */
    fun replacedByPlain(context: Context, notificationId: Int) {
        val app = context.applicationContext
        load(app)
        val matched = synchronized(entries) { entries.values.filter { it.notificationId == notificationId } }
        matched.forEach { removed(app, it, cancel = false) }
    }

    // MARK: - Channel methods

    /** `liveActivityEnd`: shows the final content (silently), then applies [dismissal]. */
    fun end(context: Context, activityId: String, dismissal: LiveDismissal, then: () -> Unit = {}) {
        val app = context.applicationContext
        val entry = entry(app, activityId) ?: return then()
        val live = LiveActivityModel.parse(entry.model[LiveKeys.LIVE_ACTIVITY], entry.notificationId).first
            ?: return then()
        val model = entry.model.toMutableMap().apply { this[LiveKeys.LIVE_ACTIVITY] = live.ending(dismissal) }
        executor.execute {
            try {
                val outcome = NotificationBuilderRegistry.makeBuilder().build(app, model)
                if (outcome is BuildOutcome.Post) {
                    NotificationManagerCompat.from(app).notify(outcome.id, outcome.notification)
                }
            } catch (e: Exception) {
                Log.w(TAG, "The live activity could not be ended: ${e.message}")
            }
            then()
        }
    }

    /** `liveActivityList`: the activities whose notification is still shown. */
    fun list(context: Context): List<Map<String, Any?>> {
        val app = context.applicationContext
        load(app)
        val shown = shownIds(app)
        val all = synchronized(entries) { entries.values.toList() }
        // Removed while the process was dead (no dismiss intent): forgotten quietly.
        val gone = if (shown == null) emptyList() else all.filter { it.notificationId !in shown }
        gone.forEach { forgetQuietly(app, it) }
        return (all - gone.toSet()).map {
            mapOf(
                LiveKeys.ACTIVITY_ID to it.activityId,
                LiveKeys.STATE to if (it.ended) LiveKeys.STATUS_ENDED else LiveKeys.STATUS_ACTIVE
            )
        }
    }

    private fun shownIds(context: Context): Set<Int>? = try {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.activeNotifications.map { it.id }.toSet()
    } catch (e: Exception) {
        null
    }

    // MARK: - Removal

    /**
     * An activity's notification left the status bar (the app's cancel /
     * dismiss, an action dismissing it, the user's swipe, the system's
     * timeout): the activity is over and reported dismissed.
     */
    val cancelInterceptor = object : CancelInterceptor {
        override fun onDismiss(context: Context, id: Int) = removeWhere(context) { it.notificationId == id }
        override fun onDismissAll(context: Context) = removeWhere(context) { true }
        override fun onDismissByChannelKey(context: Context, channelKey: String) =
            removeWhere(context) { it.channelKey == channelKey }
        override fun onDismissByGroupKey(context: Context, groupKey: String) =
            removeWhere(context) { it.groupKey == groupKey }
    }

    private fun removeWhere(context: Context, predicate: (Entry) -> Boolean) {
        val app = context.applicationContext
        load(app)
        val matched = synchronized(entries) { entries.values.filter(predicate) }
        matched.forEach { removed(app, it, cancel = false) }
    }

    /** Drops [entry] (once) and reports it dismissed; [cancel] also removes its notification. */
    private fun removed(context: Context, entry: Entry, cancel: Boolean) {
        val dropped = synchronized(entries) {
            if (entries[entry.activityId] === entry) entries.remove(entry.activityId) else null
        }
        entry.timer?.let { main.removeCallbacks(it) }
        entry.timer = null
        if (cancel) NotificationManagerCompat.from(context).cancel(entry.notificationId)
        if (dropped == null) return
        forget(context, entry.activityId)
        emit(entry.activityId, LiveKeys.STATUS_DISMISSED)
    }

    private fun forgetQuietly(context: Context, entry: Entry) {
        synchronized(entries) { if (entries[entry.activityId] === entry) entries.remove(entry.activityId) }
        entry.timer?.let { main.removeCallbacks(it) }
        forget(context, entry.activityId)
    }

    /**
     * While the process lives, removes the activity at its `staleAt` (active)
     * or its dismissal time (ended), and reports it. The notification's own
     * timeout (`setTimeoutAfter`) removes it with the process dead.
     */
    private fun scheduleRemoval(context: Context, entry: Entry, live: LiveActivityModel) {
        entry.timer?.let { main.removeCallbacks(it) }
        entry.timer = null
        val at = removalAt(live) ?: return
        val timer = Runnable { removed(context, entry, cancel = true) }
        entry.timer = timer
        main.postDelayed(timer, maxOf(0L, at - clock()))
    }

    /** When the activity leaves by itself: its `staleAt`, or, ended, its dismissal time (whichever is first). */
    fun removalAt(live: LiveActivityModel): Long? {
        val dismissAt = if (live.ended) (live.dismissal as? LiveDismissal.At)?.ms else null
        return listOfNotNull(live.staleAt, dismissAt).minOrNull()
    }

    // MARK: - Events

    fun emit(activityId: String, state: String) {
        val sink = streamSink ?: return
        val event = mapOf(LiveKeys.KIND to LiveKeys.KIND_STATE, LiveKeys.ACTIVITY_ID to activityId, LiveKeys.STATE to state)
        if (Looper.myLooper() == Looper.getMainLooper()) sink(event) else main.post { sink(event) }
    }

    /** Test-only: forgets every activity and seam (the persisted ones too). */
    internal fun resetForTest(context: Context) {
        synchronized(entries) {
            entries.values.forEach { e -> e.timer?.let { main.removeCallbacks(it) } }
            entries.clear()
        }
        prefs(context).edit().clear().commit()
        loaded = false
        streamSink = null
    }

    /** Test-only: as a new process would, forgets what's in memory (not what's saved). */
    internal fun forgetMemoryForTest() {
        synchronized(entries) { entries.clear() }
        loaded = false
    }

    private const val PREFERENCES = "awesome_notifications_live_activities"
    private const val NOTIFICATION_ID = "notificationId"
    private const val ENDED = "ended"
    private const val MODEL = "model"
    private const val TAG = "AwnLiveActivities"
}
