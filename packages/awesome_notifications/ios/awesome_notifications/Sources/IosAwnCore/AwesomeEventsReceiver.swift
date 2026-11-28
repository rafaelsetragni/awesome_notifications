import Foundation

/// Broadcaster the engine uses to deliver lifecycle events to its subscribers
/// (the Flutter plugin). Mirrors the original IosAwnCore `AwesomeEventsReceiver`.
public final class AwesomeEventsReceiver {
    public static let shared = AwesomeEventsReceiver()
    private init() {}

    private var listeners: [AwesomeEventListener] = []

    @discardableResult
    public func subscribe(listener: AwesomeEventListener) -> AwesomeEventsReceiver {
        if !listeners.contains(where: { $0 === listener }) {
            listeners.append(listener)
        }
        return self
    }

    public func unsubscribe(listener: AwesomeEventListener) {
        listeners.removeAll { $0 === listener }
    }

    func notifyAwesomeEvent(eventType: String, content: [String: Any]) {
        for listener in listeners {
            listener.onNewAwesomeEvent(eventType: eventType, content: content)
        }
    }
}
