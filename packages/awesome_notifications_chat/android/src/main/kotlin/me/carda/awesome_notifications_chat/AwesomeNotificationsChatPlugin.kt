package me.carda.awesome_notifications_chat

import io.flutter.embedding.engine.plugins.FlutterPlugin
import me.carda.android_awn_core.AwesomeMethodHandlerRegistry
import me.carda.android_awn_core.NotificationBuilderRegistry

/**
 * Chat decorator plugin (Android). Owns no method channel: it installs the
 * [ChatBuilder] in the core's decorator chain (between localization, which
 * translates first, and scheduling, which freezes the model last) and answers
 * the AwesomeNotificationsChat methods through the core's channel.
 */
class AwesomeNotificationsChatPlugin : FlutterPlugin {

    private var methodHandler: ChatMethodHandler? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        install()
        methodHandler = ChatMethodHandler(binding.applicationContext).also {
            AwesomeMethodHandlerRegistry.register(it)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodHandler?.let { AwesomeMethodHandlerRegistry.unregister(it) }
        methodHandler = null
    }

    companion object {
        /** Localization is 100 (outermost), scheduling 10 (innermost). */
        const val PRIORITY = 50
        @Volatile private var installed = false

        /** Puts the decorator in the core's chain, once per process. */
        @Synchronized
        fun install() {
            if (installed) return
            installed = true
            NotificationBuilderRegistry.register(priority = PRIORITY) { inner -> ChatBuilder(inner) }
        }
    }
}
