import Foundation

/// Composes the notification-builder **decorator chain**.
///
/// Decorators register a factory with a `priority`; the core asks for the
/// composed builder — the base wrapped by every decorator in **ascending
/// priority** order, so a higher-priority decorator ends up *outermost* and its
/// `build` runs first. This makes the build order predictable regardless of the
/// order the decorators registered in.
public final class NotificationBuilderRegistry {
    public static let shared = NotificationBuilderRegistry()
    private init() {}

    private struct Entry {
        let priority: Int
        let make: (NotificationBuilder) -> NotificationBuilder
    }
    private var entries: [Entry] = []

    /// Registers a builder decorator. A higher `priority` wraps later — ending up
    /// outermost, so its `build` runs before lower-priority ones.
    public func register(
        priority: Int,
        factory: @escaping (NotificationBuilder) -> NotificationBuilder
    ) {
        entries.append(Entry(priority: priority, make: factory))
    }

    /// The composed builder: the base wrapped by every registered decorator,
    /// folded in ascending priority order.
    public func makeBuilder() -> NotificationBuilder {
        var builder = NotificationBuilder()
        for entry in entries.sorted(by: { $0.priority < $1.priority }) {
            builder = entry.make(builder)
        }
        return builder
    }

    /// Test-only: clears registered decorators so tests start from a clean chain.
    func clearForTest() {
        entries.removeAll()
    }
}
