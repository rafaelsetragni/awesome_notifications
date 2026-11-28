package me.carda.android_awn_core

/**
 * Composes the notification-builder **decorator chain**.
 *
 * Decorators register a factory with a `priority`; the core asks for the composed
 * builder — the base wrapped by every decorator in **ascending priority** order,
 * so a higher-priority decorator ends up *outermost* and its [NotificationBuilder.build]
 * runs first. This makes the build order predictable regardless of the order the
 * decorators registered in. In the bare core (no decorators) it returns the base
 * builder, which posts every notification immediately.
 */
object NotificationBuilderRegistry {

    private data class Entry(
        val priority: Int,
        val make: (NotificationBuilder) -> NotificationBuilder
    )

    private val entries = mutableListOf<Entry>()

    /**
     * Registers a builder decorator. A higher [priority] wraps later — ending up
     * outermost, so its `build` runs before lower-priority ones.
     */
    fun register(priority: Int, factory: (NotificationBuilder) -> NotificationBuilder) {
        entries.add(Entry(priority, factory))
    }

    /** The composed builder: the base folded through every decorator, ascending. */
    fun makeBuilder(): NotificationBuilder {
        var builder = NotificationBuilder.getNewBuilder()
        for (entry in entries.sortedBy { it.priority }) {
            builder = entry.make(builder)
        }
        return builder
    }

    /** Test-only: clears registered decorators so tests start from a clean chain. */
    internal fun clearForTest() {
        entries.clear()
    }
}
