package me.carda.android_awn_core

/**
 * Static event sink the Flutter bridge subscribes to.
 *
 * The core (and the BroadcastReceiver that handles dismissals) emit lifecycle
 * events here; the plugin sets [emitter] to forward them to the Flutter method
 * channel on the main thread. Static because a BroadcastReceiver lives outside
 * the plugin instance and must still reach the channel.
 */
object AwesomeEventSink {
    @Volatile
    var emitter: ((eventName: String, data: Map<String, Any?>) -> Unit)? = null

    fun emit(eventName: String, data: Map<String, Any?>) {
        emitter?.invoke(eventName, data)
    }
}
