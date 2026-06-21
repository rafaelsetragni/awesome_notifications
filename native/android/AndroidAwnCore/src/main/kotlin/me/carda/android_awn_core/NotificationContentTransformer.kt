package me.carda.android_awn_core

/**
 * Decorator seam for the builder: a transformer gets the full notification model
 * (content + localizations + …) *before* it is built and returns a possibly
 * modified model. The core runs every registered transformer without knowing
 * what they do — this is how decorators (e.g. localization) extend the
 * notification without the core depending on them.
 */
interface NotificationContentTransformer {
    fun transform(model: Map<String, Any?>): Map<String, Any?>
}

/** Registry of content transformers; decorators register here (statically). */
object NotificationContentManager {
    private val transformers = mutableListOf<NotificationContentTransformer>()

    fun register(transformer: NotificationContentTransformer) {
        if (!transformers.contains(transformer)) transformers.add(transformer)
    }

    fun unregister(transformer: NotificationContentTransformer) {
        transformers.remove(transformer)
    }

    /** Applies every registered transformer, in registration order. */
    fun apply(model: Map<String, Any?>): Map<String, Any?> {
        var result = model
        for (transformer in ArrayList(transformers)) {
            result = transformer.transform(result)
        }
        return result
    }
}
