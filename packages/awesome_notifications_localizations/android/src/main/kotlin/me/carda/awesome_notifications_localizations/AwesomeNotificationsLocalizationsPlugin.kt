package me.carda.awesome_notifications_localizations

import io.flutter.embedding.engine.plugins.FlutterPlugin
import me.carda.android_awn_core.AwesomeMethodHandlerRegistry
import me.carda.android_awn_core.NotificationBuilderRegistry

/**
 * Localizations decorator plugin. It owns no method channel: on attach it installs
 * a [LocalizationBuilder] into the core's builder decorator chain (HIGH priority =
 * outermost, so it translates the model before lower-priority decorators like
 * scheduling see it) and registers a method handler (setLocalization/
 * getLocalization). The core stays unaware of localization.
 */
class AwesomeNotificationsLocalizationsPlugin : FlutterPlugin {

    private val manager = LocalizationManager.getInstance()
    private val transformer = LocalizationTransformer(manager)
    private val methodHandler = LocalizationMethodHandler(manager)

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        manager.init(binding.applicationContext)
        NotificationBuilderRegistry.register(priority = 100) { inner ->
            LocalizationBuilder(inner, transformer)
        }
        AwesomeMethodHandlerRegistry.register(methodHandler)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        AwesomeMethodHandlerRegistry.unregister(methodHandler)
    }
}
