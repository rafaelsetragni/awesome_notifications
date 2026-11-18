package me.carda.awesome_notifications_schedules

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import me.carda.android_awn_core.AwesomeMethodHandlerRegistry
import me.carda.android_awn_core.CancelInterceptorRegistry
import me.carda.android_awn_core.NotificationBuilderRegistry

/**
 * Scheduling decorator plugin (Android). Owns no method channel: on attach it
 * installs a [ScheduleBuilder] into the core's builder decorator chain (LOW
 * priority = innermost, so content decorators like localization transform the
 * model first), a [ScheduleCancelInterceptor] so `cancel*` also cancels the
 * matching schedules, and a [ScheduleMethodHandler] answering the
 * schedule-management channel methods. The core stays unaware of scheduling.
 */
class AwesomeNotificationsSchedulesPlugin : FlutterPlugin {

    private var methodHandler: ScheduleMethodHandler? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val context = binding.applicationContext
        if (!installed) {
            installed = true
            NotificationBuilderRegistry.register(priority = 10) { inner -> ScheduleBuilder(inner) }
            CancelInterceptorRegistry.register(cancelInterceptor)
        }
        methodHandler = ScheduleMethodHandler(context).also {
            AwesomeMethodHandlerRegistry.register(it)
        }
        refreshSchedules(context)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // The builder/cancel decorators are process-global and stay installed for
        // the process lifetime; only this engine's method handler goes away.
        methodHandler?.let { AwesomeMethodHandlerRegistry.unregister(it) }
        methodHandler = null
    }

    /**
     * 0.12 re-armed the stored schedules when the plugin was initialized; the
     * decorator does it when it is attached (app start), off the main thread.
     */
    private fun refreshSchedules(context: Context) {
        Thread {
            try {
                NotificationScheduler.refreshScheduledNotifications(context)
            } catch (e: Exception) {
                Log.e("AwnSchedulesPlugin", e.message ?: e.toString())
            }
        }.start()
    }

    companion object {
        @Volatile private var installed = false
        private val cancelInterceptor = ScheduleCancelInterceptor()
    }
}
