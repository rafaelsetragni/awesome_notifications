package me.carda.awesome_notifications_live_activities

import me.carda.android_awn_core.JsonUtils

/** A part of the progress bar: its relative [length], in its own [color] (ARGB). */
internal data class LiveSegment(val length: Int, val color: Int?)

/** A mark on the progress bar, at [position] in the segments' total length. */
internal data class LivePoint(val position: Int, val color: Int?)

internal data class LiveProgress(
    val segments: List<LiveSegment>,
    val points: List<LivePoint>,
    val trackerIcon: String?,
    val startIcon: String?,
    val endIcon: String?
) {
    /** The bar's length: the segments' lengths summed, 100 without segments. */
    val total: Int get() = if (segments.isEmpty()) 100 else segments.sumOf { it.length }
}

/** A clock the system runs: counts down to [end], or up from [start] (UTC milliseconds). */
internal data class LiveTimer(val start: Long?, val end: Long?) {
    val countDown: Boolean get() = end != null
}

internal data class LiveMetric(val label: String, val value: String, val unit: String?, val image: String? = null) {
    /** `Speed 42 km/h`, as the other platforms write it. */
    val text: String get() = listOfNotNull(label, value, unit).filter { it.isNotEmpty() }.joinToString(" ")
}

/** Dart `LiveActivityDismissal`: `default`, `immediate` or a time (UTC milliseconds). */
internal sealed class LiveDismissal {
    object System : LiveDismissal()
    object Immediate : LiveDismissal()
    data class At(val ms: Long) : LiveDismissal()

    fun toValue(): Any = when (this) {
        System -> LiveKeys.DISMISSAL_DEFAULT
        Immediate -> LiveKeys.DISMISSAL_IMMEDIATE
        is At -> ms
    }

    companion object {
        /** Null when [value] isn't a dismissal. */
        fun from(value: Any?): LiveDismissal? = when (value) {
            null, LiveKeys.DISMISSAL_DEFAULT -> System
            LiveKeys.DISMISSAL_IMMEDIATE -> Immediate
            is Number -> At(value.toLong())
            is String -> value.toLongOrNull()?.let { At(it) }
            else -> null
        }
    }
}

/** The `liveActivity` block of a model, validated as `NotificationLiveActivity.validate` does. */
internal data class LiveActivityModel(
    val activityId: String,
    val ended: Boolean,
    val progress: LiveProgress?,
    val timer: LiveTimer?,
    val metrics: List<LiveMetric>,
    /** Drawn as a scoreboard (`LiveActivityLayout.versus`): exactly two metrics. */
    val versus: Boolean,
    val shortText: String?,
    val accentColor: Int?,
    /** UTC milliseconds. */
    val staleAt: Long?,
    val alert: Boolean,
    /** Android 16+: a Live Update (promoted); false: the package's own layout. */
    val liveUpdate: Boolean,
    /** The app's layout resource name (`res/layout/<name>.xml`), drawn instead of the package's. */
    val customLayout: String?,
    val dismissal: LiveDismissal,
    /** The block as received, with its defaults filled in (what the model carries on). */
    val raw: Map<String, Any?>
) {
    /** The block with the activity ended by [dismissal] (`liveActivityEnd`): silent. */
    fun ending(dismissal: LiveDismissal): Map<String, Any?> = raw.toMutableMap().apply {
        this[LiveKeys.STATE] = LiveKeys.STATUS_ENDED
        this[LiveKeys.DISMISSAL] = dismissal.toValue()
        this[LiveKeys.ALERT] = false
    }

    companion object {
        /**
         * Parses the block, or returns why it is invalid (the Dart messages).
         * The activityId defaults to [notificationId]. A push may carry the
         * block as a JSON string, with strings for its booleans and numbers.
         */
        fun parse(block: Any?, notificationId: Int): Pair<LiveActivityModel?, String?> {
            val map = mapOf(block) ?: return null to "The liveActivity block must be a map"

            fun text(key: String, what: String): Pair<String?, String?> {
                val value = map[key] ?: return null to null
                if (value !is String || value.trim().isEmpty()) return null to "The live activity's $what can't be empty"
                return value to null
            }

            val (id, idError) = text(LiveKeys.ACTIVITY_ID, "activityId")
            if (idError != null) return null to idError
            val activityId = id ?: notificationId.toString()
            val (shortText, shortError) = text(LiveKeys.SHORT_TEXT, "shortText")
            if (shortError != null) return null to shortError
            val (_, channelError) = text(LiveKeys.PUSH_CHANNEL, "pushChannel")
            if (channelError != null) return null to channelError

            val state = map[LiveKeys.STATE] ?: LiveKeys.STATUS_ACTIVE
            if (state != LiveKeys.STATUS_ACTIVE && state != LiveKeys.STATUS_ENDED)
                return null to "Unknown live activity state: $state"

            val rawMetrics = listOf(map[LiveKeys.METRICS] ?: emptyList<Any?>())
                ?: return null to "The live activity metrics must be a list"
            if (rawMetrics.size > 3) return null to "A live activity has at most 3 metrics"
            val metrics = rawMetrics.map { raw ->
                val metric = raw as? Map<*, *> ?: return null to "A live activity metric must be a map"
                val label = metric[LiveKeys.LABEL] as? String
                if (label == null || label.trim().isEmpty()) return null to "A live activity metric needs a label"
                val value = metric[LiveKeys.VALUE] as? String ?: return null to "A live activity metric needs a value"
                val unit = metric[LiveKeys.UNIT]
                if (unit != null && unit !is String) return null to "A live activity metric unit must be a string"
                val image = metric[LiveKeys.IMAGE]
                if (image != null && image !is String) return null to "A live activity metric image must be a string"
                LiveMetric(label, value, unit as String?, image as String?)
            }
            val layout = map[LiveKeys.LAYOUT] ?: LiveKeys.LAYOUT_STANDARD
            if (layout != LiveKeys.LAYOUT_STANDARD && layout != LiveKeys.LAYOUT_VERSUS)
                return null to "Unknown live activity layout: $layout"
            val versus = layout == LiveKeys.LAYOUT_VERSUS
            if (versus && metrics.size != 2) return null to "A versus live activity needs exactly 2 metrics, one per side"

            val progress = map[LiveKeys.PROGRESS]?.let { rawProgress ->
                val p = mapOf(rawProgress) ?: return null to "The live activity progress must be a map"
                val rawSegments = listOf(p[LiveKeys.SEGMENTS] ?: emptyList<Any?>())
                val rawPoints = listOf(p[LiveKeys.POINTS] ?: emptyList<Any?>())
                if (rawSegments == null || rawPoints == null)
                    return null to "The live activity segments and points must be lists"
                val segments = rawSegments.map { raw ->
                    val length = number((raw as? Map<*, *>)?.get(LiveKeys.LENGTH))
                    if (length == null || length.toDouble() <= 0) return null to "A live activity segment needs a positive length"
                    LiveSegment(length.toInt(), color((raw as Map<*, *>)[LiveKeys.COLOR]))
                }
                val total = if (segments.isEmpty()) 100 else segments.sumOf { it.length }
                val points = rawPoints.map { raw ->
                    val position = number((raw as? Map<*, *>)?.get(LiveKeys.POSITION))
                    if (position == null || position.toDouble() < 0 || position.toDouble() > total)
                        return null to "A live activity point must sit within the segments (0 to $total)"
                    LivePoint(position.toInt(), color((raw as Map<*, *>)[LiveKeys.COLOR]))
                }
                LiveProgress(
                    segments, points,
                    p[LiveKeys.TRACKER_ICON] as? String,
                    p[LiveKeys.START_ICON] as? String,
                    p[LiveKeys.END_ICON] as? String
                )
            }

            val timer = map[LiveKeys.TIMER]?.let { rawTimer ->
                val t = mapOf(rawTimer) ?: return null to "The live activity timer must be a map"
                val rawStart = t[LiveKeys.START]
                val rawEnd = t[LiveKeys.END]
                val start = rawStart?.let { number(it)?.toLong() ?: return null to "The live activity timer start and end must be milliseconds" }
                val end = rawEnd?.let { number(it)?.toLong() ?: return null to "The live activity timer start and end must be milliseconds" }
                if (start == null && end == null) return null to "The live activity timer needs a start or an end"
                if (start != null && end != null && end <= start) return null to "A live activity countdown must end after it starts"
                LiveTimer(start, end)
            }

            for (key in listOf(LiveKeys.STALE_AT, LiveKeys.RELEVANCE, LiveKeys.ACCENT_COLOR)) {
                if (map[key] != null && number(map[key]) == null) return null to "The live activity $key must be a number"
            }
            val alert = bool(map[LiveKeys.ALERT], false) ?: return null to "The live activity alert must be a bool"
            val liveUpdate = bool(map[LiveKeys.ANDROID_LIVE_UPDATE], true)
                ?: return null to "The live activity androidLiveUpdate must be a bool"
            val customLayout = map[LiveKeys.CUSTOM_LAYOUT]?.let {
                if (it !is String || !Regex("^[a-z][a-z0-9_]*$").matches(it))
                    return null to "The live activity's customLayout must be a resource name: lowercase letters, digits and _"
                it
            }
            val dismissal = LiveDismissal.from(map[LiveKeys.DISMISSAL])
                ?: return null to "Unknown live activity dismissal: ${map[LiveKeys.DISMISSAL]}"

            @Suppress("UNCHECKED_CAST")
            val raw = (map as Map<String, Any?>).toMutableMap().apply {
                this[LiveKeys.ACTIVITY_ID] = activityId
                this[LiveKeys.STATE] = state
                this[LiveKeys.METRICS] = rawMetrics
                this[LiveKeys.ALERT] = alert
                this[LiveKeys.DISMISSAL] = dismissal.toValue()
            }
            return LiveActivityModel(
                activityId = activityId,
                ended = state == LiveKeys.STATUS_ENDED,
                progress = progress,
                timer = timer,
                metrics = metrics,
                versus = versus,
                shortText = shortText,
                accentColor = color(map[LiveKeys.ACCENT_COLOR]),
                staleAt = number(map[LiveKeys.STALE_AT])?.toLong(),
                alert = alert,
                liveUpdate = liveUpdate,
                customLayout = customLayout,
                dismissal = dismissal,
                raw = raw
            ) to null
        }

        private fun mapOf(value: Any?): Map<*, *>? = when (value) {
            is Map<*, *> -> value
            is String -> try {
                JsonUtils.getInstance().fromJson(value)
            } catch (_: Exception) {
                null
            }
            else -> null
        }

        private fun listOf(value: Any?): List<*>? = when (value) {
            is List<*> -> value
            is String -> try {
                JsonUtils.getInstance().fromJson("{\"list\":$value}")["list"] as? List<*>
            } catch (_: Exception) {
                null
            }
            else -> null
        }

        private fun bool(value: Any?, default: Boolean): Boolean? = when (value) {
            null -> default
            is Boolean -> value
            "true" -> true
            "false" -> false
            else -> null
        }

        private fun number(value: Any?): Number? = when (value) {
            is Number -> value
            is String -> value.toLongOrNull() ?: value.toDoubleOrNull()
            else -> null
        }

        /** An ARGB int (Dart's `toARGB32`, which a JSON push may carry as a long). */
        private fun color(value: Any?): Int? = number(value)?.toLong()?.toInt()
    }
}
