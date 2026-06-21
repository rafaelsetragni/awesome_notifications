package me.carda.android_awn_core

/**
 * Decorator seam for the method channel: a handler can answer channel methods the
 * core doesn't implement (e.g. setLocalization/getLocalization), keeping the core
 * bridge unaware of the decorator.
 */
interface AwesomeMethodHandler {
    /**
     * Handle [method]; if handled, invoke [result] (with the value or null) and
     * return true. Return false to let other handlers / the core try.
     */
    fun handle(method: String, arguments: Any?, result: (Any?) -> Unit): Boolean
}

/** Registry of method handlers; decorators register here. */
object AwesomeMethodHandlerRegistry {
    private val handlers = mutableListOf<AwesomeMethodHandler>()

    fun register(handler: AwesomeMethodHandler) {
        if (!handlers.contains(handler)) handlers.add(handler)
    }

    fun unregister(handler: AwesomeMethodHandler) {
        handlers.remove(handler)
    }

    /** Returns true if some handler answered the method. */
    fun handle(method: String, arguments: Any?, result: (Any?) -> Unit): Boolean {
        for (handler in ArrayList(handlers)) {
            if (handler.handle(method, arguments, result)) return true
        }
        return false
    }
}
