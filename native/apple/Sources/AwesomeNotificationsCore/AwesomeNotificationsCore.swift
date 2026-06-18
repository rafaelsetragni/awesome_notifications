import Foundation
import UserNotifications

/// Flutter-free notification engine for Apple platforms (iOS & macOS).
///
/// This type is intentionally free of any Flutter dependency: it is shared by the
/// Flutter plugin (app side) and, later, by the Notification Service Extension
/// (push side), which links this core *without* the Flutter engine.
///
/// This is the minimal slice — request permission, show a basic notification, dismiss.
/// Richer content (images, action buttons, grouping, badge…) is ported in next, from
/// the previous IosAwnCore implementation kept under `reference/`.
public final class AwesomeNotificationsCore {

    public static let shared = AwesomeNotificationsCore()
    private init() {}

    private var center: UNUserNotificationCenter { .current() }

    /// Ask the user for permission to show notifications.
    public func requestPermission(_ completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            completion(granted)
        }
    }

    /// Display a minimal local notification immediately.
    public func showNotification(id: Int, title: String?, body: String?) {
        let content = UNMutableNotificationContent()
        if let title = title { content.title = title }
        if let body = body { content.body = body }
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: String(id),
            content: content,
            trigger: nil // deliver right away
        )
        center.add(request, withCompletionHandler: nil)
    }

    /// Remove a delivered notification by id.
    public func dismiss(id: Int) {
        center.removeDeliveredNotifications(withIdentifiers: [String(id)])
    }
}
