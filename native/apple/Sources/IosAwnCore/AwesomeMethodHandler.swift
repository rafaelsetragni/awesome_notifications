import Foundation

/// Decorator seam for the method channel: a handler can answer channel methods
/// the core doesn't implement (e.g. setLocalization/getLocalization), keeping the
/// core bridge unaware of the decorator. Flutter-free — the bridge adapts
/// `result` to `FlutterResult`.
public protocol AwesomeMethodHandler: AnyObject {
    /// Handle `method`; if handled, call `result` (with the value or nil) and
    /// return true. Return false to let other handlers / the core try.
    func handle(
        method: String,
        arguments: Any?,
        result: @escaping (Any?) -> Void
    ) -> Bool
}

/// Registry of method handlers. Decorators register here.
public final class AwesomeMethodHandlerRegistry {
    public static let shared = AwesomeMethodHandlerRegistry()
    private init() {}

    private var handlers: [AwesomeMethodHandler] = []

    public func register(handler: AwesomeMethodHandler) {
        if !handlers.contains(where: { $0 === handler }) {
            handlers.append(handler)
        }
    }

    public func unregister(handler: AwesomeMethodHandler) {
        handlers.removeAll { $0 === handler }
    }

    /// Returns true if some handler answered the method.
    public func handle(
        method: String,
        arguments: Any?,
        result: @escaping (Any?) -> Void
    ) -> Bool {
        for handler in handlers {
            if handler.handle(method: method, arguments: arguments, result: result) {
                return true
            }
        }
        return false
    }
}
