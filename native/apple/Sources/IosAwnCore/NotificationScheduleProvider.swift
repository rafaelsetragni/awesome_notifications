import Foundation
import UserNotifications

/// A decorator supplies the delivery *trigger* for a notification that carries a
/// `schedule`. The core stays schedule-agnostic: with no provider registered (or
/// no schedule on the notification), notifications are delivered immediately.
public protocol NotificationScheduleProvider: AnyObject {
    /// Returns the trigger for the given serialized notification model (which may
    /// hold a `schedule` map), or nil to deliver immediately.
    func trigger(for model: [String: Any]) -> UNNotificationTrigger?
}

/// Registry the core queries when creating a notification. The scheduling
/// decorator registers a provider here.
public final class NotificationScheduleManager {
    public static let shared = NotificationScheduleManager()
    private init() {}

    private var provider: NotificationScheduleProvider?

    public func register(provider: NotificationScheduleProvider) {
        self.provider = provider
    }

    public func unregister() {
        self.provider = nil
    }

    /// The trigger for this model, or nil (deliver immediately) when there is no
    /// provider or the notification has no schedule.
    func trigger(for model: [String: Any]) -> UNNotificationTrigger? {
        return provider?.trigger(for: model)
    }
}
