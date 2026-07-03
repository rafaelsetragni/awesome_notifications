package me.carda.awesome_notifications_schedules

import io.flutter.embedding.engine.plugins.FlutterPlugin
import me.carda.android_awn_core.AwesomeNotifications

/**
 * Scheduling decorator plugin (Android). Owns no method channel: on attach it
 * plugs a [NotificationScheduler] into the core's scheduling seams
 * ([AwesomeNotifications.scheduleProvider] to register the AlarmManager delivery,
 * and [AwesomeNotifications.scheduleCanceller] so `cancel*` also cancels the
 * pending schedule). The core stays unaware of scheduling.
 */
class AwesomeNotificationsSchedulesPlugin : FlutterPlugin {

    private val scheduler = NotificationScheduler()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        AwesomeNotifications.scheduleProvider = scheduler
        AwesomeNotifications.scheduleCanceller = scheduler
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        AwesomeNotifications.scheduleProvider = null
        AwesomeNotifications.scheduleCanceller = null
    }
}
