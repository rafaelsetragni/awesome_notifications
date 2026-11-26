import Foundation

/// What a dismiss / cancel call removed.
public enum NotificationRemoval: Equatable {
    case id(Int)
    case all
    case channelKey(String)
    case groupKey(String)
}

/// Generic hook letting a decorator react when the app removes notifications
/// through the core (dismiss* / cancel*): a decorator that delivers without a
/// system notification (media in Now Playing) keeps state the notification
/// center doesn't know about. Apple counterpart of Android's CancelInterceptor.
public protocol NotificationRemovalListener: AnyObject {
    /// `cancel` is true for cancel* (schedules too), false for dismiss*.
    func onNotificationsRemoved(_ removal: NotificationRemoval, cancel: Bool)
}

/// Registry of removal listeners; decorators register here. The core notifies
/// them before it touches the notification center.
public final class NotificationRemovalRegistry {
    public static let shared = NotificationRemovalRegistry()
    private init() {}

    private var listeners: [NotificationRemovalListener] = []
    private let lock = NSLock()

    public func register(listener: NotificationRemovalListener) {
        lock.lock(); defer { lock.unlock() }
        if !listeners.contains(where: { $0 === listener }) { listeners.append(listener) }
    }

    public func unregister(listener: NotificationRemovalListener) {
        lock.lock(); defer { lock.unlock() }
        listeners.removeAll { $0 === listener }
    }

    public func notify(_ removal: NotificationRemoval, cancel: Bool) {
        lock.lock()
        let current = listeners
        lock.unlock()
        for listener in current { listener.onNotificationsRemoved(removal, cancel: cancel) }
    }
}
