package me.carda.android_awn_core

/**
 * Static broadcaster the engine (and the dismiss BroadcastReceiver, which lives
 * outside the plugin instance) use to deliver lifecycle events to subscribers
 * (the Flutter plugin). Mirrors the original AndroidAwnCore `AwesomeEventsReceiver`.
 */
object AwesomeEventsReceiver {
    private val listeners = mutableListOf<AwesomeEventListener>()

    fun subscribe(listener: AwesomeEventListener) {
        if (!listeners.contains(listener)) listeners.add(listener)
    }

    fun unsubscribe(listener: AwesomeEventListener) {
        listeners.remove(listener)
    }

    fun notifyAwesomeEvent(eventType: String, content: Map<String, Any?>) {
        for (listener in ArrayList(listeners)) {
            listener.onNewAwesomeEvent(eventType, content)
        }
    }
}
