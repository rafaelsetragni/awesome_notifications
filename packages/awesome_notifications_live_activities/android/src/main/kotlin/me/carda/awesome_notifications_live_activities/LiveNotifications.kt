package me.carda.awesome_notifications_live_activities

import android.content.Context
import android.os.Build
import android.text.SpannableStringBuilder
import androidx.core.app.NotificationCompat
import androidx.core.graphics.drawable.IconCompat
import me.carda.android_awn_core.BitmapUtils
import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.HtmlUtils

/**
 * Draws an activity on the core's builder, after the core applied the
 * content (title, body, large icon, buttons, channel options):
 *
 * - Android 16+ (API 36): a Live Update. Promoted ongoing while active
 *   (`setRequestPromotedOngoing`), ProgressStyle with the segments, points
 *   and icons, the short text as the status bar chip
 *   (`setShortCriticalText`). Never colorized (promotion forbids it): the
 *   accent color is the notification's color. The metrics go in the body
 *   (MetricStyle is Android 17, not in this compile SDK).
 * - Before, or with `androidLiveUpdate` false: an ongoing notification drawn
 *   by the package's own layout
 *   ([LiveCustomLayout]) inside the system's decorated notification, which
 *   mirrors the Live Update: short text, segmented bar with its points,
 *   metrics in columns.
 *
 * Everywhere: the timer is the system's chronometer (counting down to its
 * end, or up from its start); only the first post alerts, unless `alert`;
 * `staleAt` (active) or the dismissal time (ended) is the notification's
 * timeout. An ended activity shows its final content, not ongoing, with no
 * running clock.
 */
internal object LiveNotifications {

    /** Android 16: Live Updates (ProgressStyle, promoted ongoing). */
    const val PROMOTED_SDK = 36

    fun render(context: Context, live: LiveActivityModel, model: Map<String, Any?>, builder: NotificationCompat.Builder) {
        @Suppress("UNCHECKED_CAST")
        val content = (model[Definitions.NOTIFICATION_CONTENT] as? Map<String, Any?>).orEmpty()
        val active = !live.ended
        // Android 16+ promotes only the system's styles: a Live Update, or
        // (androidLiveUpdate false) the package's own layout, not promoted.
        // A custom layout is never promoted either.
        val promoted = Build.VERSION.SDK_INT >= PROMOTED_SDK && live.liveUpdate && live.customLayout == null

        builder.setOnlyAlertOnce(!live.alert)
            .setOngoing(active)
        // An active activity stays until it ends: a tap opens the app only.
        if (active) builder.setAutoCancel(false)
        live.accentColor?.let { builder.setColor(it) }

        val value = progressOf(content[Definitions.NOTIFICATION_PROGRESS])
        val hasBar = live.progress != null || value != null
        if (promoted) {
            builder.setColorized(false)
                .setRequestPromotedOngoing(active)
            // The chip: the score of a versus activity (its short text, the
            // period, goes in the body), else the short text.
            (if (live.versus) scoreOf(live) else live.shortText)?.let { builder.setShortCriticalText(it) }
            if (hasBar) builder.setStyle(progressStyle(context, live, value))
        } else {
            // No Live Updates: the package's own layout, inside the system's
            // decorated notification (header, running clock and buttons).
            val (collapsed, expanded) = LiveCustomLayout.views(context, live, content, value, hasBar)
            builder.setStyle(NotificationCompat.DecoratedCustomViewStyle())
                .setCustomContentView(collapsed)
                .setCustomBigContentView(expanded)
                .setCustomHeadsUpContentView(collapsed)
                // The layout draws the image itself (expanded), not twice.
                .setLargeIcon(null as android.graphics.Bitmap?)
        }

        setTimer(live, builder)
        setTimeout(live, builder)
        if (!promoted) return

        val lines = extraLines(live, shortTextInBody = false)
        if (lines.isNotEmpty()) {
            val text = SpannableStringBuilder()
            // The body as the core draws it (0.12 `setBody`: HTML). A versus
            // activity's score goes first: the collapsed view shows it.
            val body = HtmlUtils.fromHtml(content[Definitions.NOTIFICATION_BODY] as? String)
                ?.takeIf { it.isNotEmpty() }
            if (live.versus) {
                text.append(lines.joinToString("\n"))
                body?.let { text.append('\n').append(it) }
            } else {
                body?.let { text.append(it).append('\n') }
                text.append(lines.joinToString("\n"))
            }
            builder.setContentText(text)
        }
    }

    /** What the system can't draw, as text: the short text (before Android 16) and the metrics. */
    fun extraLines(live: LiveActivityModel, shortTextInBody: Boolean): List<String> {
        val lines = mutableListOf<String>()
        if (live.versus) {
            // `LIO 1 – 2 EAG · 2nd half`
            val (left, right) = live.metrics
            lines.add(listOfNotNull("${left.label} ${left.value} – ${right.value} ${right.label}", live.shortText)
                .joinToString(" · "))
            return lines
        }
        if (shortTextInBody) live.shortText?.let { lines.add(it) }
        if (live.metrics.isNotEmpty()) lines.add(live.metrics.joinToString(" · ") { it.text })
        return lines
    }

    /** A versus activity's score, `1–2`. */
    fun scoreOf(live: LiveActivityModel): String = "${live.metrics[0].value}–${live.metrics[1].value}"

    /** ProgressStyle: the segments (one in the accent color without any), the points, the icons. */
    fun progressStyle(context: Context, live: LiveActivityModel, value: Double?): NotificationCompat.ProgressStyle {
        val progress = live.progress
        val style = NotificationCompat.ProgressStyle()
        val segments = progress?.segments.orEmpty()
        if (segments.isEmpty()) {
            style.addProgressSegment(NotificationCompat.ProgressStyle.Segment(100).apply {
                live.accentColor?.let { setColor(it) }
            })
        } else {
            segments.forEach { s ->
                style.addProgressSegment(NotificationCompat.ProgressStyle.Segment(s.length).apply {
                    s.color?.let { setColor(it) }
                })
            }
        }
        progress?.points.orEmpty().forEach { p ->
            style.addProgressPoint(NotificationCompat.ProgressStyle.Point(p.position).apply {
                p.color?.let { setColor(it) }
            })
        }
        val total = progress?.total ?: 100
        if (value == null) {
            style.setProgressIndeterminate(true)
        } else {
            style.setProgress(Math.round(value.coerceIn(0.0, 100.0) / 100.0 * total).toInt())
        }
        icon(context, progress?.trackerIcon)?.let { style.setProgressTrackerIcon(it) }
        icon(context, progress?.startIcon)?.let { style.setProgressStartIcon(it) }
        icon(context, progress?.endIcon)?.let { style.setProgressEndIcon(it) }
        return style
    }

    /** An active activity's clock: a countdown to its end, or the time since its start. */
    private fun setTimer(live: LiveActivityModel, builder: NotificationCompat.Builder) {
        val timer = live.timer ?: return
        if (live.ended) {
            builder.setUsesChronometer(false).setChronometerCountDown(false)
            return
        }
        builder.setShowWhen(true).setUsesChronometer(true)
        if (timer.end != null) {
            builder.setChronometerCountDown(true).setWhen(timer.end)
        } else {
            builder.setChronometerCountDown(false).setWhen(timer.start!!)
        }
    }

    /** Removed at its `staleAt` (or, ended, its dismissal time), with the app killed too. */
    private fun setTimeout(live: LiveActivityModel, builder: NotificationCompat.Builder) {
        val at = LiveActivities.removalAt(live) ?: return
        builder.setTimeoutAfter(maxOf(1L, at - LiveActivities.clock()))
    }

    /** An image of the core's sources (`resource://`, `asset://`, `file://`, `https://`). */
    private fun icon(context: Context, source: String?): IconCompat? {
        if (source.isNullOrEmpty()) return null
        val bitmaps = BitmapUtils.getInstance()
        if (source.startsWith("resource://")) {
            val id = bitmaps.getDrawableResourceId(context, source)
            if (id != 0) return IconCompat.createWithResource(context, id)
        }
        return bitmaps.getBitmapFromSource(context, source, false)?.let { IconCompat.createWithBitmap(it) }
    }

    /** `content.progress` (0 to 100): a number, or a numeric text; else null (indeterminate). */
    fun progressOf(value: Any?): Double? = when (value) {
        is Number -> value.toDouble()
        is String -> value.toDoubleOrNull()
        else -> null
    }
}
