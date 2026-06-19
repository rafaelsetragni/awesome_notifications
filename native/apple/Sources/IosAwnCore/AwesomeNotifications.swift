import Foundation
import UserNotifications

/// Flutter-free notification engine for Apple platforms (iOS & macOS).
///
/// This type is intentionally free of any Flutter dependency: it is shared by the
/// Flutter plugin (app side) and, later, by the Notification Service Extension
/// (push side), which links this core *without* the Flutter engine.
///
/// Minimal slice: register channels, request/query permission, create (display) a
/// basic notification, dismiss/cancel, and emit the lifecycle events (created,
/// displayed, default action / tap, dismissed) back to the bridge.
public final class AwesomeNotifications: NSObject, UNUserNotificationCenterDelegate {

    public static let shared = AwesomeNotifications()
    private override init() { super.init() }

    private var center: UNUserNotificationCenter { .current() }

    /// iOS/macOS have no notification channels; we still keep the channel config
    /// (sound, importance, …) so later features can honor it per channelKey.
    private var channels: [String: [String: Any]] = [:]

    /// Event sink the Flutter bridge subscribes to. The core stays Flutter-free;
    /// the bridge forwards (eventName, payload) to the method channel. Emitted
    /// events: notificationCreated / notificationDisplayed / defaultAction /
    /// notificationDismissed.
    public var onEvent: ((_ eventName: String, _ data: [String: Any]) -> Void)?

    // MARK: - Initialization

    public func initialize(channels: [[String: Any]]) {
        // Receive willPresent / didReceive callbacks: foreground display, taps
        // and dismissals.
        center.delegate = self
        registerDefaultCategory()
        for channel in channels {
            registerChannel(channel)
        }
    }

    public func setChannel(_ channel: [String: Any]) {
        registerChannel(channel)
    }

    private func registerChannel(_ channel: [String: Any]) {
        guard let key = channel[Definitions.channelKey] as? String else { return }
        channels[key] = channel
    }

    /// Registers a category with `.customDismissAction` so the system reports
    /// when the user swipes a notification away (otherwise dismiss is silent).
    private func registerDefaultCategory() {
        let category = UNNotificationCategory(
            identifier: Definitions.defaultCategoryIdentifier,
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        center.getNotificationCategories { existing in
            self.center.setNotificationCategories(existing.union([category]))
        }
    }

    // MARK: - Permissions

    public func requestPermission(_ completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    public func isNotificationAllowed(_ completion: @escaping (Bool) -> Void) {
        center.getNotificationSettings { settings in
            let allowed = settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
            DispatchQueue.main.async { completion(allowed) }
        }
    }

    // MARK: - Create / display

    /// Builds and delivers a notification from a serialized `NotificationModel`
    /// (the same map produced by the Dart `NotificationModel.toMap()`).
    public func createNotification(
        _ notification: [String: Any],
        completion: @escaping (Bool) -> Void
    ) {
        guard
            let content = notification[Definitions.content] as? [String: Any],
            let id = AwesomeNotifications.readInt(content[Definitions.id])
        else {
            completion(false)
            return
        }

        let unContent = UNMutableNotificationContent()
        if let title = content[Definitions.title] as? String { unContent.title = title }
        if let body = content[Definitions.body] as? String { unContent.body = body }
        unContent.sound = .default
        unContent.categoryIdentifier = Definitions.defaultCategoryIdentifier
        // Stash the original content so the received/action maps can be rebuilt
        // when the notification is displayed, tapped or dismissed.
        unContent.userInfo = content.filter { !($0.value is NSNull) }

        let request = UNNotificationRequest(
            identifier: String(id),
            content: unContent,
            trigger: nil // deliver immediately
        )
        center.add(request) { [weak self] error in
            let created = error == nil
            if created {
                self?.emit(
                    Definitions.eventNotificationCreated,
                    self?.payload(content, [
                        Definitions.createdSource: "Local",
                        Definitions.createdLifeCycle: "Foreground"
                    ]) ?? content
                )
            }
            DispatchQueue.main.async { completion(created) }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if let content = notification.request.content.userInfo as? [String: Any] {
            emit(
                Definitions.eventNotificationDisplayed,
                payload(content, [Definitions.displayedLifeCycle: "Foreground"])
            )
        }
        if #available(iOS 14.0, macOS 11.0, *) {
            completionHandler([.banner, .list, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let content =
            (response.notification.request.content.userInfo as? [String: Any]) ?? [:]

        if response.actionIdentifier == UNNotificationDismissActionIdentifier {
            emit(
                Definitions.eventNotificationDismissed,
                payload(content, [Definitions.actionLifeCycle: "Foreground"])
            )
        } else {
            // UNNotificationDefaultActionIdentifier (tap) or a button key.
            emit(
                Definitions.eventDefaultAction,
                payload(content, [
                    Definitions.actionType: "Default",
                    Definitions.actionLifeCycle: "Foreground"
                ])
            )
        }
        completionHandler()
    }

    // MARK: - Dismiss / cancel

    public func dismiss(id: Int) {
        center.removeDeliveredNotifications(withIdentifiers: [String(id)])
    }

    public func cancel(id: Int) {
        let identifiers = [String(id)]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    public func dismissAllNotifications() {
        center.removeAllDeliveredNotifications()
    }

    public func cancelAll() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    // MARK: - Helpers

    private func emit(_ eventName: String, _ data: [String: Any]) {
        onEvent?(eventName, data)
    }

    /// Merges event-specific fields onto a copy of the stashed content map.
    private func payload(_ base: [String: Any], _ extra: [String: Any]) -> [String: Any] {
        var map = base.filter { !($0.value is NSNull) }
        for (key, value) in extra { map[key] = value }
        return map
    }

    /// Flutter encodes Dart ints as `Int` or `NSNumber` depending on the path;
    /// read either tolerantly.
    public static func readInt(_ value: Any?) -> Int? {
        if let intValue = value as? Int { return intValue }
        if let number = value as? NSNumber { return number.intValue }
        if let string = value as? String { return Int(string) }
        return nil
    }
}
