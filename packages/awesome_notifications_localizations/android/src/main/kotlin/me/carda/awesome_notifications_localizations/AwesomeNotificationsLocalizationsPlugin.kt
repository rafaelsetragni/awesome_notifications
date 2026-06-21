package me.carda.awesome_notifications_localizations

import io.flutter.embedding.engine.plugins.FlutterPlugin
import me.carda.android_awn_core.AwesomeMethodHandlerRegistry
import me.carda.android_awn_core.NotificationContentManager

/**
 * Localizations decorator plugin. It owns no method channel: on attach it
 * registers a content transformer (translates the notification at build time)
 * and a method handler (setLocalization/getLocalization) into the core's
 * decorator seams. The core stays unaware of localization.
 */
class AwesomeNotificationsLocalizationsPlugin : FlutterPlugin {

    private val manager = LocalizationManager.getInstance()
    private val transformer = LocalizationTransformer(manager)
    private val methodHandler = LocalizationMethodHandler(manager)

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        manager.init(binding.applicationContext)
        NotificationContentManager.register(transformer)
        AwesomeMethodHandlerRegistry.register(methodHandler)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        NotificationContentManager.unregister(transformer)
        AwesomeMethodHandlerRegistry.unregister(methodHandler)
    }
}
