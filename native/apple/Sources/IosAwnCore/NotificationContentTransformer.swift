import Foundation

/// Decorator seam for the builder: a transformer gets the full notification model
/// (content + localizations + …) *before* it is built and returns a possibly
/// modified model. The core builder runs every registered transformer without
/// knowing what they do — this is how decorators (e.g. localization) extend the
/// notification without the core depending on them.
public protocol NotificationContentTransformer: AnyObject {
    func transform(_ model: [String: Any]) -> [String: Any]
}

/// Registry of content transformers. Decorators register here (statically, since
/// the build happens off any plugin instance).
public final class NotificationContentManager {
    public static let shared = NotificationContentManager()
    private init() {}

    private var transformers: [NotificationContentTransformer] = []

    public func register(transformer: NotificationContentTransformer) {
        if !transformers.contains(where: { $0 === transformer }) {
            transformers.append(transformer)
        }
    }

    public func unregister(transformer: NotificationContentTransformer) {
        transformers.removeAll { $0 === transformer }
    }

    /// Applies every registered transformer, in registration order.
    func apply(to model: [String: Any]) -> [String: Any] {
        var result = model
        for transformer in transformers {
            result = transformer.transform(result)
        }
        return result
    }
}
