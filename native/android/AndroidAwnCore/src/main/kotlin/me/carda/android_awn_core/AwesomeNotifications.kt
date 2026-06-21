package me.carda.android_awn_core

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.service.notification.StatusBarNotification
import androidx.core.app.NotificationManagerCompat
import java.util.concurrent.Executors

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

    // Notifications are built off the main thread (image loading does I/O).
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    companion object {
        /**
         * Registered by the scheduling decorator so `cancel*` also cancels the
         * pending scheduled creation (AlarmManager). Null in the bare core, where
         * cancel then coincides with dismiss.
         */
        var scheduleCanceller: ScheduleCanceller? = null
    }

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

    /**
     * Builds and posts a notification from a serialized `NotificationModel`. Runs
     * on a background thread (image loading does I/O) and reports the result on
     * the main thread.
     */
    fun createNotification(rawNotification: Map<String, Any?>, callback: (Boolean) -> Unit) {
        executor.execute {
            val created = try {
                // Let registered decorators (e.g. localization) transform the model
                // once; the build, events and stored payload all use the result.
                val notification = NotificationContentManager.apply(rawNotification)
                val androidNotification = builder.build(context, notification)
                val id = builder.notificationId(notification)

                if (androidNotification != null && id != null) {
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
                } else {
                    false
                }
            } catch (_: SecurityException) {
                // POST_NOTIFICATIONS not granted (Android 13+).
                false
            }
            mainHandler.post { callback(created) }
        }
    }

    // MARK: - Dismiss / cancel

    // dismiss* only removes the visible notification from the status bar (keeps
    // any pending scheduled creation). cancel* also cancels the schedule, via the
    // scheduleCanceller registered by the scheduling decorator.

    fun dismiss(id: Int) = NotificationManagerCompat.from(context).cancel(id)

    fun dismissAll() = NotificationManagerCompat.from(context).cancelAll()

    fun dismissByChannelKey(channelKey: String) =
        cancelMatching { channelIdOf(it) == channelKey }

    fun dismissByGroupKey(groupKey: String) =
        cancelMatching { it.notification.group == groupKey }

    fun cancel(id: Int) {
        scheduleCanceller?.cancelSchedule(context, id)
        dismiss(id)
    }

    fun cancelAll() {
        scheduleCanceller?.cancelAllSchedules(context)
        dismissAll()
    }

    fun cancelByChannelKey(channelKey: String) {
        scheduleCanceller?.cancelSchedulesByChannelKey(context, channelKey)
        dismissByChannelKey(channelKey)
    }

    fun cancelByGroupKey(groupKey: String) {
        scheduleCanceller?.cancelSchedulesByGroupKey(context, groupKey)
        dismissByGroupKey(groupKey)
    }

    // MARK: - Helpers

    private fun notificationManager(): NotificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    /** Cancels the app's active notifications matching [predicate]. */
    private fun cancelMatching(predicate: (StatusBarNotification) -> Boolean) {
        val manager = notificationManager()
        manager.activeNotifications
            .filter(predicate)
            .forEach { manager.cancel(it.id) }
    }

    private fun channelIdOf(sbn: StatusBarNotification): String? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) sbn.notification.channelId
        else null

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
