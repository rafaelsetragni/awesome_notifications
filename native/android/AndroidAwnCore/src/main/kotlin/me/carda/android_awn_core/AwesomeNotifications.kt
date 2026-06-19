package me.carda.android_awn_core

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationManagerCompat

/**
 * Flutter-free notification engine for Android.
 *
 * Intentionally free of any Flutter dependency so it can be shared by the Flutter
 * plugin (app side) and background/headless entry points later. Delegates
 * building/payload-injection/event-stamping to `NotificationBuilder` and
 * broadcasts lifecycle events through `AwesomeEventsReceiver`.
 */
class AwesomeNotifications(private val context: Context) {

    private val builder = NotificationBuilder.getNewBuilder()
    private val channels = mutableMapOf<String, Map<String, Any?>>()

    // MARK: - Initialization

    fun initialize(channelList: List<Map<String, Any?>>) {
        channelList.forEach { setChannel(it) }
    }

    fun setChannel(channelData: Map<String, Any?>) {
        val key = channelData[Definitions.NOTIFICATION_CHANNEL_KEY] as? String ?: return
        channels[key] = channelData

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = channelData[Definitions.NOTIFICATION_CHANNEL_NAME] as? String ?: key
            val importance = readImportance(channelData[Definitions.NOTIFICATION_IMPORTANCE])
            val channel = NotificationChannel(key, name, importance)
            (channelData[Definitions.NOTIFICATION_CHANNEL_DESCRIPTION] as? String)?.let {
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
        val androidNotification = builder.build(context, notification) ?: return false
        val id = builder.notificationId(notification) ?: return false

        return try {
            NotificationManagerCompat.from(context).notify(id, androidNotification)
            val content = builder.contentMap(notification)
            AwesomeEventsReceiver.notifyAwesomeEvent(
                Definitions.EVENT_NOTIFICATION_CREATED,
                builder.registerCreatedEvent(content, "Foreground")
            )
            AwesomeEventsReceiver.notifyAwesomeEvent(
                Definitions.EVENT_NOTIFICATION_DISPLAYED,
                builder.registerDisplayedEvent(content, "Foreground")
            )
            true
        } catch (_: SecurityException) {
            // POST_NOTIFICATIONS not granted (Android 13+).
            false
        }
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
}
