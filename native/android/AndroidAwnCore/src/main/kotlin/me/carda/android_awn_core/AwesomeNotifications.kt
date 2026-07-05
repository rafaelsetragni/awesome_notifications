package me.carda.android_awn_core

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.service.notification.StatusBarNotification
import androidx.core.app.NotificationManagerCompat
import java.util.concurrent.Executor
import java.util.concurrent.Executors

/**
 * Flutter-free notification engine for Android.
 *
 * Intentionally free of any Flutter dependency so it can be shared by the Flutter
 * plugin (app side) and background/headless entry points later. Delegates
 * building/payload-injection/event-stamping to `NotificationBuilder` and
 * broadcasts lifecycle events through `AwesomeEventsReceiver`.
 *
 * The [executor] runs the build off the main thread (image loading does I/O); it
 * is injectable so tests can drive `createNotification` synchronously.
 */
class AwesomeNotifications(
    private val context: Context,
    private val executor: Executor = Executors.newSingleThreadExecutor()
) {

    // For event stamping / content extraction. The build itself goes through the
    // decorator chain composed by NotificationBuilderRegistry (see createNotification).
    private val builder = NotificationBuilder.getNewBuilder()
    private val channels = mutableMapOf<String, Map<String, Any?>>()

    private val mainHandler = Handler(Looper.getMainLooper())

    // MARK: - Initialization

    fun initialize(channelList: List<Map<String, Any?>>) {
        channelList.forEach { setChannel(it) }
    }

    fun setChannel(channelData: Map<String, Any?>) {
        val key = channelData[Definitions.NOTIFICATION_CHANNEL_KEY] as? String ?: return
        channels[key] = channelData

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = channelData[Definitions.NOTIFICATION_CHANNEL_NAME] as? String ?: key
            val importance = NotificationImportance
                .from(channelData[Definitions.NOTIFICATION_IMPORTANCE] as? String)
                .toAndroidImportance()
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
                // Run the builder decorator chain (localization transforms the
                // model, scheduling may take over delivery, …). In the bare core
                // this is just the base builder, which posts immediately.
                when (val outcome =
                    NotificationBuilderRegistry.makeBuilder().build(context, rawNotification)) {
                    is BuildOutcome.Post -> {
                        NotificationManagerCompat.from(context)
                            .notify(outcome.id, outcome.notification)
                        val content = builder.contentMap(outcome.model)
                        AwesomeEventsReceiver.notifyAwesomeEvent(
                            Definitions.EVENT_NOTIFICATION_CREATED,
                            builder.registerCreatedEvent(content, NotificationLifeCycle.Foreground)
                        )
                        AwesomeEventsReceiver.notifyAwesomeEvent(
                            Definitions.EVENT_NOTIFICATION_DISPLAYED,
                            builder.registerDisplayedEvent(content, NotificationLifeCycle.Foreground)
                        )
                        true
                    }
                    // A decorator took over delivery (e.g. scheduled it for later).
                    BuildOutcome.Handled -> true
                    BuildOutcome.Invalid -> false
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
    // any pending scheduled creation). cancel* also notifies the registered
    // CancelInterceptors, so a decorator (e.g. scheduling) can drop its own state.

    fun dismiss(id: Int) = NotificationManagerCompat.from(context).cancel(id)

    fun dismissAll() = NotificationManagerCompat.from(context).cancelAll()

    fun dismissByChannelKey(channelKey: String) =
        cancelMatching { channelIdOf(it) == channelKey }

    fun dismissByGroupKey(groupKey: String) =
        cancelMatching { it.notification.group == groupKey }

    fun cancel(id: Int) {
        CancelInterceptorRegistry.onCancel(context, id)
        dismiss(id)
    }

    fun cancelAll() {
        CancelInterceptorRegistry.onCancelAll(context)
        dismissAll()
    }

    fun cancelByChannelKey(channelKey: String) {
        CancelInterceptorRegistry.onCancelByChannelKey(context, channelKey)
        dismissByChannelKey(channelKey)
    }

    fun cancelByGroupKey(groupKey: String) {
        CancelInterceptorRegistry.onCancelByGroupKey(context, groupKey)
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
}
