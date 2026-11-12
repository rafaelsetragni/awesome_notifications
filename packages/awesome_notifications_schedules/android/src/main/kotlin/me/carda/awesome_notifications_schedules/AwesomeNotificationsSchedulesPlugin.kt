package me.carda.awesome_notifications_schedules

import io.flutter.embedding.engine.plugins.FlutterPlugin
import me.carda.android_awn_core.CancelInterceptorRegistry
import me.carda.android_awn_core.NotificationBuilderRegistry

/**
 * Scheduling decorator plugin (Android). Owns no method channel: on attach it
 * installs a [ScheduleBuilder] into the core's builder decorator chain (LOW
 * priority = innermost, so content decorators like localization transform the
 * model first) and a [ScheduleCancelInterceptor] so `cancel*` also drops the
 * pending AlarmManager schedule. The core stays unaware of scheduling; without
 * this decorator a notification carrying a `schedule` is delivered immediately.
 */
class AwesomeNotificationsSchedulesPlugin : FlutterPlugin {

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        NotificationBuilderRegistry.register(priority = 10) { inner -> ScheduleBuilder(inner) }
        CancelInterceptorRegistry.register(ScheduleCancelInterceptor())
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // Registries are process-global singletons keyed to the shared core; the
        // decorators stay installed for the process lifetime.
    }
}
