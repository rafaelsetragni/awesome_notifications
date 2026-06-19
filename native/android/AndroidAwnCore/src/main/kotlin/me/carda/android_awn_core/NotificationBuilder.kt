package me.carda.android_awn_core

import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/**
 * Builds notifications from a serialized `NotificationModel`, injects the full
 * model into the tap/dismiss PendingIntents so it can be recovered later, and
 * stamps the lifecycle events (created/displayed/pressed/dismissed).
 *
 * Created via a factory (an instance with injected helpers — not static utility
 * methods), mirroring the original AndroidAwnCore `NotificationBuilder`.
 */
class NotificationBuilder private constructor(
    private val stringUtils: StringUtils,
    private val mapUtils: MapUtils,
    private val jsonUtils: JsonUtils
) {
    companion object {
        fun getNewBuilder(): NotificationBuilder =
            NotificationBuilder(
                StringUtils.getInstance(),
                MapUtils.getInstance(),
                JsonUtils.getInstance()
            )
    }

    // MARK: - Build

    /** Builds an Android notification from a serialized model, or null if invalid. */
    fun build(context: Context, model: Map<String, Any?>): Notification? {
        val content = contentMap(model)
        val id = mapUtils.getInt(content[Definitions.NOTIFICATION_ID]) ?: return null
        val channelKey =
            mapUtils.getString(content[Definitions.NOTIFICATION_CHANNEL_KEY]) ?: return null

        val builder = NotificationCompat.Builder(context, channelKey)
            .setSmallIcon(context.applicationInfo.icon)
            .setAutoCancel(true)
            .setContentIntent(contentIntent(context, id, model))
            .setDeleteIntent(deleteIntent(context, id, model))

        val title = mapUtils.getString(content[Definitions.NOTIFICATION_TITLE])
        if (!stringUtils.isNullOrEmpty(title)) builder.setContentTitle(title)
        val body = mapUtils.getString(content[Definitions.NOTIFICATION_BODY])
        if (!stringUtils.isNullOrEmpty(body)) builder.setContentText(body)

        return builder.build()
    }

    fun notificationId(model: Map<String, Any?>): Int? =
        mapUtils.getInt(contentMap(model)[Definitions.NOTIFICATION_ID])

    @Suppress("UNCHECKED_CAST")
    fun contentMap(model: Map<String, Any?>): Map<String, Any?> =
        (model[Definitions.NOTIFICATION_CONTENT] as? Map<String, Any?>) ?: emptyMap()

    // MARK: - Payload injection (tap / dismiss)

    /** Tap intent: launches the app carrying the full model JSON. */
    private fun contentIntent(context: Context, id: Int, model: Map<String, Any?>): PendingIntent {
        val launch = context.packageManager
            .getLaunchIntentForPackage(context.packageName) ?: Intent()
        launch.action = Definitions.SELECT_NOTIFICATION
        launch.putExtra(Definitions.NOTIFICATION_JSON, jsonUtils.toJson(model))
        launch.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(context, id, launch, pendingFlags())
    }

    /** Dismiss intent: fired on swipe-away; DismissedNotificationReceiver emits. */
    private fun deleteIntent(context: Context, id: Int, model: Map<String, Any?>): PendingIntent {
        val intent = Intent(context, DismissedNotificationReceiver::class.java).apply {
            action = Definitions.DISMISSED_NOTIFICATION
            putExtra(Definitions.NOTIFICATION_JSON, jsonUtils.toJson(model))
        }
        return PendingIntent.getBroadcast(context, id, intent, pendingFlags())
    }

    private fun pendingFlags(): Int {
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }
        return flags
    }

    /** Rebuilds the model map from an intent's NOTIFICATION_JSON extra. */
    fun notificationModel(intent: Intent): Map<String, Any?>? {
        val json = intent.getStringExtra(Definitions.NOTIFICATION_JSON) ?: return null
        return jsonUtils.fromJson(json)
    }

    // MARK: - Event registration (stamps date + lifecycle on the content)

    fun registerCreatedEvent(content: Map<String, Any?>, lifeCycle: String): Map<String, Any?> =
        content + mapOf(
            Definitions.NOTIFICATION_CREATED_DATE to now(),
            Definitions.NOTIFICATION_CREATED_LIFECYCLE to lifeCycle,
            Definitions.NOTIFICATION_CREATED_SOURCE to "Local"
        )

    fun registerDisplayedEvent(content: Map<String, Any?>, lifeCycle: String): Map<String, Any?> =
        content + mapOf(
            Definitions.NOTIFICATION_DISPLAYED_DATE to now(),
            Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE to lifeCycle
        )

    fun registerActionEvent(content: Map<String, Any?>, lifeCycle: String): Map<String, Any?> =
        content + mapOf(
            Definitions.NOTIFICATION_ACTION_DATE to now(),
            Definitions.NOTIFICATION_ACTION_LIFECYCLE to lifeCycle,
            Definitions.NOTIFICATION_ACTION_TYPE to "Default"
        )

    fun registerDismissedEvent(content: Map<String, Any?>, lifeCycle: String): Map<String, Any?> =
        content + mapOf(
            Definitions.NOTIFICATION_DISMISSED_DATE to now(),
            Definitions.NOTIFICATION_ACTION_LIFECYCLE to lifeCycle
        )

    private fun now(): String {
        val formatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US)
        formatter.timeZone = TimeZone.getTimeZone("UTC")
        return formatter.format(Date())
    }
}
