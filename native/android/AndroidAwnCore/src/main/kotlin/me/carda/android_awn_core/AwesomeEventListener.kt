package me.carda.android_awn_core

/**
 * Listener for notification lifecycle events. Mirrors the original
 * AndroidAwnCore `AwesomeEventListener`: the Flutter plugin implements it and
 * forwards each event to the method channel.
 */
interface AwesomeEventListener {
    fun onNewAwesomeEvent(eventType: String, content: Map<String, Any?>)
}
