package me.carda.android_awn_core

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * Flutter-free notification engine for Android.
 *
 * Intentionally free of any Flutter dependency so it can be shared by the Flutter
 * plugin (app side) and background/headless entry points later. Reads the same
 * serialized maps the Dart side sends over the method channel.
 *
 * Minimal slice: register channels, query permission, create (display) a basic
 * notification, dismiss/cancel. Permission *requesting* needs an Activity and is
 * handled by the bridge; richer content is layered on next.
 */
class AwesomeNotifications(private val context: Context) {

    private val channels = mutableMapOf<String, Map<String, Any?>>()

    // MARK: - Initialization

    fun initialize(channelList: List<Map<String, Any?>>) {
        channelList.forEach { setChannel(it) }
    }

    fun setChannel(channelData: Map<String, Any?>) {
        val key = channelData[Definitions.CHANNEL_KEY] as? String ?: return
        channels[key] = channelData

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = channelData[Definitions.CHANNEL_NAME] as? String ?: key
            val importance = readImportance(channelData[Definitions.IMPORTANCE])
            val channel = NotificationChannel(key, name, importance)
            (channelData[Definitions.CHANNEL_DESCRIPTION] as? String)?.let {
                channel.description = it
            }
            notificationManager().createNotificationChannel(channel)
        }
    }

    // MARK: - Permissions

    fun isNotificationAllowed(): Boolean =
        NotificationManagerCompat.from(context).areNotificationsEnabled()

    // MARK: - Create / display

    /** Builds and posts a notification from a serialized `NotificationModel`. */
    fun createNotification(notification: Map<String, Any?>): Boolean {
        @Suppress("UNCHECKED_CAST")
        val content = notification[Definitions.CONTENT] as? Map<String, Any?> ?: return false
        val id = readInt(content[Definitions.ID]) ?: return false
        val channelKey = content[Definitions.CHANNEL_KEY] as? String ?: return false

        val builder = NotificationCompat.Builder(context, channelKey)
            .setSmallIcon(context.applicationInfo.icon)
            .setAutoCancel(true)
            .setContentIntent(buildContentIntent(id, content))
            .setDeleteIntent(buildDeleteIntent(id, content))
        (content[Definitions.TITLE] as? String)?.let { builder.setContentTitle(it) }
        (content[Definitions.BODY] as? String)?.let { builder.setContentText(it) }

        return try {
            NotificationManagerCompat.from(context).notify(id, builder.build())
            AwesomeEventSink.emit(
                Definitions.EVENT_NOTIFICATION_CREATED,
                received(content, Definitions.CREATED_LIFECYCLE)
            )
            AwesomeEventSink.emit(
                Definitions.EVENT_NOTIFICATION_DISPLAYED,
                received(content, Definitions.DISPLAYED_LIFECYCLE)
            )
            true
        } catch (_: SecurityException) {
            // POST_NOTIFICATIONS not granted (Android 13+).
            false
        }
    }

    /** Content map enriched with the event-specific lifecycle/source fields. */
    private fun received(content: Map<String, Any?>, lifeCycleKey: String): Map<String, Any?> =
        content + mapOf(
            lifeCycleKey to "Foreground",
            Definitions.CREATED_SOURCE to "Local"
        )

    /** Tap intent: launches the app; the bridge reports it as a defaultAction. */
    private fun buildContentIntent(id: Int, content: Map<String, Any?>): PendingIntent {
        val launch = context.packageManager
            .getLaunchIntentForPackage(context.packageName) ?: Intent()
        launch.action = Definitions.ACTION_SELECT_NOTIFICATION
        launch.putExtra(Definitions.NOTIFICATION_JSON, MapJson.toJson(content))
        launch.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(context, id, launch, pendingIntentFlags())
    }

    /** Dismiss intent: fired on swipe-away; DismissedNotificationReceiver emits. */
    private fun buildDeleteIntent(id: Int, content: Map<String, Any?>): PendingIntent {
        val intent = Intent(context, DismissedNotificationReceiver::class.java).apply {
            action = Definitions.ACTION_DISMISSED_NOTIFICATION
            putExtra(Definitions.NOTIFICATION_JSON, MapJson.toJson(content))
        }
        return PendingIntent.getBroadcast(context, id, intent, pendingIntentFlags())
    }

    private fun pendingIntentFlags(): Int {
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }
        return flags
    }

    // MARK: - Dismiss / cancel

    fun dismiss(id: Int) = NotificationManagerCompat.from(context).cancel(id)

    fun cancel(id: Int) = dismiss(id)

    fun dismissAll() = NotificationManagerCompat.from(context).cancelAll()

    fun cancelAll() = dismissAll()

    // MARK: - Helpers

    private fun notificationManager(): NotificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    /** Maps the Dart `NotificationImportance` name to an Android importance. */
    private fun readImportance(value: Any?): Int =
        when ((value as? String)?.substringAfterLast('.')?.lowercase()) {
            "none" -> NotificationManager.IMPORTANCE_NONE
            "min" -> NotificationManager.IMPORTANCE_MIN
            "low" -> NotificationManager.IMPORTANCE_LOW
            "high", "max" -> NotificationManager.IMPORTANCE_HIGH
            else -> NotificationManager.IMPORTANCE_DEFAULT
        }

    companion object {
        /** Flutter encodes Dart ints as Int/Long/Double depending on the path. */
        fun readInt(value: Any?): Int? = when (value) {
            is Int -> value
            is Number -> value.toInt()
            is String -> value.toIntOrNull()
            else -> null
        }
    }
}
