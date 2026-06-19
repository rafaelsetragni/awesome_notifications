import Foundation
import UserNotifications

/// Flutter-free notification engine for Apple platforms (iOS & macOS).
///
/// This type is intentionally free of any Flutter dependency: it is shared by the
/// Flutter plugin (app side) and, later, by the Notification Service Extension
/// (push side), which links this core *without* the Flutter engine.
///
/// Minimal slice: register channels, request/query permission, create (display) a
/// basic notification, dismiss/cancel. Richer content (images, action buttons,
/// grouping, badge, scheduling…) is layered on next.
public final class AwesomeNotifications: NSObject, UNUserNotificationCenterDelegate {

    public static let shared = AwesomeNotifications()
    private override init() { super.init() }

    private var center: UNUserNotificationCenter { .current() }

    /// iOS/macOS have no notification channels; we still keep the channel config
    /// (sound, importance, …) so later features can honor it per channelKey.
    private var channels: [String: [String: Any]] = [:]

    // MARK: - Initialization

    public func initialize(channels: [[String: Any]]) {
        // Receive willPresent callbacks so notifications also show while the app
        // is in the foreground.
        center.delegate = self
        for channel in channels {
            registerChannel(channel)
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if #available(iOS 14.0, macOS 11.0, *) {
            completionHandler([.banner, .list, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }

    public func setChannel(_ channel: [String: Any]) {
        registerChannel(channel)
    }

    private func registerChannel(_ channel: [String: Any]) {
        guard let key = channel[Definitions.channelKey] as? String else { return }
        channels[key] = channel
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
        if let payload = content[Definitions.payload] as? [String: Any] {
            unContent.userInfo = payload.compactMapValues { $0 }
        }
        unContent.sound = .default

        let request = UNNotificationRequest(
            identifier: String(id),
            content: unContent,
            trigger: nil // deliver immediately
        )
        center.add(request) { error in
            DispatchQueue.main.async { completion(error == nil) }
        }
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

    /// Flutter encodes Dart ints as `Int` or `NSNumber` depending on the path;
    /// read either tolerantly.
    public static func readInt(_ value: Any?) -> Int? {
        if let intValue = value as? Int { return intValue }
        if let number = value as? NSNumber { return number.intValue }
        if let string = value as? String { return Int(string) }
        return nil
    }
}
