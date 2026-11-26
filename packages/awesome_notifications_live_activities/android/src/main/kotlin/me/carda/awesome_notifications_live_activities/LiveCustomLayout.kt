package me.carda.awesome_notifications_live_activities

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.os.Build
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import me.carda.android_awn_core.BitmapUtils
import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.HtmlUtils

/**
 * Android < 16 (no Live Updates): the activity in a layout of its own, inside
 * the system's decorated notification (which keeps the header, with the app,
 * the running clock, and the buttons). It mirrors Android 16's Live Update:
 * the short text next to the title, the segmented bar with its points (the
 * part done in full color, the rest faded), and the metrics in columns.
 */
internal object LiveCustomLayout {

    private val metricSlots = listOf(
        Triple(R.id.awn_live_metric_0, R.id.awn_live_metric_value_0, R.id.awn_live_metric_label_0),
        Triple(R.id.awn_live_metric_1, R.id.awn_live_metric_value_1, R.id.awn_live_metric_label_1),
        Triple(R.id.awn_live_metric_2, R.id.awn_live_metric_value_2, R.id.awn_live_metric_label_2),
    )

    /** The collapsed and the expanded views. */
    fun views(
        context: Context,
        live: LiveActivityModel,
        content: Map<String, Any?>,
        value: Double?,
        hasBar: Boolean
    ): Pair<RemoteViews, RemoteViews> {
        val collapsed = RemoteViews(context.packageName, R.layout.awn_live_collapsed)
        val expanded = RemoteViews(context.packageName, R.layout.awn_live_expanded)
        val title = HtmlUtils.fromHtml(content[Definitions.NOTIFICATION_TITLE] as? String)
        val body = HtmlUtils.fromHtml(content[Definitions.NOTIFICATION_BODY] as? String)
        val accent = live.accentColor

        for (views in listOf(collapsed, expanded)) {
            views.setTextViewText(R.id.awn_live_title, title ?: "")
            text(views, R.id.awn_live_body, body)
            text(views, R.id.awn_live_short, live.shortText)
            accent?.let { views.setTextColor(R.id.awn_live_short, it) }
        }
        clock(collapsed, live)
        // Collapsed: the bar takes the body's place when there is one.
        if (hasBar) collapsed.setViewVisibility(R.id.awn_live_body, View.GONE)

        if (hasBar) {
            val density = context.resources.displayMetrics.density
            collapsed.setImageViewBitmap(R.id.awn_live_bar, bar(live, value, density, 12f))
            collapsed.setViewVisibility(R.id.awn_live_bar, View.VISIBLE)
            expanded.setImageViewBitmap(R.id.awn_live_bar, bar(live, value, density, 16f))
            expanded.setViewVisibility(R.id.awn_live_bar, View.VISIBLE)
        }

        image(context, content[Definitions.NOTIFICATION_LARGE_ICON] as? String)?.let {
            expanded.setImageViewBitmap(R.id.awn_live_image, it)
            expanded.setViewVisibility(R.id.awn_live_image, View.VISIBLE)
        }

        if (live.metrics.isNotEmpty()) {
            expanded.setViewVisibility(R.id.awn_live_metrics, View.VISIBLE)
            metricSlots.forEachIndexed { i, (slot, valueId, labelId) ->
                val metric = live.metrics.getOrNull(i)
                if (metric == null) {
                    expanded.setViewVisibility(slot, View.GONE)
                } else {
                    val unit = metric.unit?.takeIf { it.isNotEmpty() }?.let { " $it" } ?: ""
                    expanded.setTextViewText(valueId, metric.value + unit)
                    expanded.setTextViewText(labelId, metric.label)
                }
            }
        }
        return collapsed to expanded
    }

    /**
     * The running clock, collapsed (Android 12+ shows the header, and its
     * clock, only expanded): a countdown to the end, or the time since the start.
     */
    private fun clock(views: RemoteViews, live: LiveActivityModel) {
        val timer = live.timer ?: return
        if (live.ended) return
        val target = timer.end ?: timer.start ?: return
        val base = SystemClock.elapsedRealtime() + (target - System.currentTimeMillis())
        views.setChronometer(R.id.awn_live_clock, base, null, true)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            views.setChronometerCountDown(R.id.awn_live_clock, timer.end != null)
        }
        views.setViewVisibility(R.id.awn_live_clock, View.VISIBLE)
    }

    private fun text(views: RemoteViews, id: Int, text: CharSequence?) {
        if (text.isNullOrEmpty()) {
            views.setViewVisibility(id, View.GONE)
        } else {
            views.setTextViewText(id, text)
            views.setViewVisibility(id, View.VISIBLE)
        }
    }

    private fun image(context: Context, source: String?): Bitmap? {
        if (source.isNullOrEmpty()) return null
        return try {
            BitmapUtils.getInstance().getBitmapFromSource(context, source, false)
        } catch (_: Exception) {
            null
        }
    }

    /**
     * The bar, drawn as Android 16's ProgressStyle draws it: each segment a
     * rounded line, in its color (the accent color without segments), thick
     * and solid up to the progress, thin and faded after it (all faded when
     * indeterminate); the points as rounded squares on top.
     */
    fun bar(live: LiveActivityModel, value: Double?, density: Float, heightDp: Float): Bitmap {
        val width = (320 * density).toInt().coerceAtLeast(1)
        val height = (heightDp * density).toInt().coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)

        val progress = live.progress
        val fallback = live.accentColor ?: DEFAULT_COLOR
        val segments = progress?.segments.orEmpty().ifEmpty { listOf(LiveSegment(100, fallback)) }
        val total = segments.sumOf { it.length }.toFloat()
        val done = value?.let { (it.coerceIn(0.0, 100.0) / 100.0 * total).toFloat() }

        val pointSize = height * 0.75f
        val gap = 2 * density
        val thick = height * 0.4f
        val thin = height * 0.2f
        val mid = height / 2f
        // Room for the points at the ends.
        val left = pointSize / 2
        val usable = width - pointSize
        fun x(position: Float) = left + usable * position / total

        var start = 0f
        for (segment in segments) {
            val end = start + segment.length
            val color = segment.color ?: fallback
            val x0 = x(start) + if (start > 0) gap / 2 else 0f
            val x1 = x(end) - if (end < total) gap / 2 else 0f
            val split = done?.coerceIn(start, end)?.let { x(it) }
            if (split != null && split > x0) {
                paint.color = color
                canvas.drawRoundRect(RectF(x0, mid - thick / 2, minOf(split, x1), mid + thick / 2), thick / 2, thick / 2, paint)
            }
            val restFrom = if (split != null) maxOf(split, x0) else x0
            if (x1 > restFrom) {
                paint.color = faded(color)
                canvas.drawRoundRect(RectF(restFrom, mid - thin / 2, x1, mid + thin / 2), thin / 2, thin / 2, paint)
            }
            start = end
        }

        for (point in progress?.points.orEmpty()) {
            val cx = x(point.position.toFloat())
            val reached = done != null && point.position <= done
            paint.color = point.color ?: fallback
            if (!reached) paint.color = blend(paint.color)
            val half = pointSize / 2
            canvas.drawRoundRect(RectF(cx - half, mid - half, cx + half, mid + half), half / 2, half / 2, paint)
        }
        return bitmap
    }

    private const val DEFAULT_COLOR = 0xFF7B0AC4.toInt()

    private fun faded(color: Int) =
        Color.argb((Color.alpha(color) * 0.4f).toInt(), Color.red(color), Color.green(color), Color.blue(color))

    /** A point not reached yet: its color lightened, still opaque (it sits on the bar). */
    private fun blend(color: Int): Int {
        fun mix(c: Int) = (c + (255 - c) * 0.5f).toInt()
        return Color.rgb(mix(Color.red(color)), mix(Color.green(color)), mix(Color.blue(color)))
    }
}
