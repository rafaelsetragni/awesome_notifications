package me.carda.awesome_notifications_media

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import me.carda.android_awn_core.AwesomeMethodHandlerRegistry
import me.carda.android_awn_core.CancelInterceptorRegistry
import me.carda.android_awn_core.NotificationBuilderRegistry

/**
 * Media decorator plugin (Android). Installs the [MediaBuilder] in the core's
 * decorator chain, answers the AwesomeNotificationsMedia methods through the
 * core's channel and streams the live commands on its own EventChannel.
 */
class AwesomeNotificationsMediaPlugin : FlutterPlugin, EventChannel.StreamHandler {

    private var methodHandler: MediaMethodHandler? = null
    private var events: EventChannel? = null
    private var sink: ((Map<String, Any?>) -> Unit)? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        install()
        methodHandler = MediaMethodHandler(binding.applicationContext).also {
            AwesomeMethodHandlerRegistry.register(it)
        }
        events = EventChannel(binding.binaryMessenger, MediaKeys.COMMANDS_CHANNEL).also {
            it.setStreamHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodHandler?.let { AwesomeMethodHandlerRegistry.unregister(it) }
        methodHandler = null
        events?.setStreamHandler(null)
        events = null
        stopListening()
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        val sink: (Map<String, Any?>) -> Unit = { events.success(it) }
        this.sink = sink
        MediaSessions.streamSink = sink
    }

    override fun onCancel(arguments: Any?) = stopListening()

    /** Another engine (a background isolate) may be the one listening. */
    private fun stopListening() {
        if (MediaSessions.streamSink === sink) MediaSessions.streamSink = null
        sink = null
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
            NotificationBuilderRegistry.register(priority = PRIORITY) { inner -> MediaBuilder(inner) }
            CancelInterceptorRegistry.register(MediaSessions.cancelInterceptor)
        }
    }
}
