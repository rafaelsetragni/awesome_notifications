import Foundation

/// Lets an add-on see one of its notification's buttons being used before the
/// core emits its action / dismiss event: a call's Accept button turns the
/// call ongoing, for instance. The add-on can also keep the core from emitting
/// the event, when that command goes elsewhere (the calls' command stream).
/// With nothing registered the core behaves exactly as before.
public protocol NotificationActionInterceptor: AnyObject {
    /// [model] is the notification's stored model, [buttonKey] the button used
    /// (never empty). Returns false to keep the core from emitting the event.
    func onNotificationAction(model: [String: Any], buttonKey: String) -> Bool
}

/// Registry of action interceptors; add-ons register here.
public final class NotificationActionInterceptorRegistry {
    public static let shared = NotificationActionInterceptorRegistry()
    private init() {}

    private var interceptors: [NotificationActionInterceptor] = []
    private let lock = NSLock()

    public func register(interceptor: NotificationActionInterceptor) {
        lock.lock(); defer { lock.unlock() }
        if !interceptors.contains(where: { $0 === interceptor }) { interceptors.append(interceptor) }
    }

    public func unregister(interceptor: NotificationActionInterceptor) {
        lock.lock(); defer { lock.unlock() }
        interceptors.removeAll { $0 === interceptor }
    }

    /// Tells every interceptor; the event is emitted unless one of them says no.
    public func shouldEmit(model: [String: Any], buttonKey: String) -> Bool {
        lock.lock()
        let current = interceptors
        lock.unlock()
        var emit = true
        for interceptor in current where !interceptor.onNotificationAction(model: model, buttonKey: buttonKey) {
            emit = false
        }
        return emit
    }
}
