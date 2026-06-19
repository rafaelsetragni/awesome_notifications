import Foundation
import UserNotifications

/// Flutter-free notification engine for Apple platforms (iOS & macOS).
///
/// This type is intentionally free of any Flutter dependency: it is shared by the
/// Flutter plugin (app side) and, later, by the Notification Service Extension
/// (push side), which links this core *without* the Flutter engine.
///
/// Delegates building/payload-injection/event-stamping to `NotificationBuilder`
/// and broadcasts lifecycle events through `AwesomeEventsReceiver`.
public final class AwesomeNotifications: NSObject, UNUserNotificationCenterDelegate {

    public static let shared = AwesomeNotifications()
    private override init() { super.init() }

    private var center: UNUserNotificationCenter { .current() }
    private let builder = NotificationBuilder.newInstance()

    /// iOS/macOS have no notification channels; we still keep the channel config
    /// (sound, importance, …) so later features can honor it per channelKey.
    private var channels: [String: [String: Any]] = [:]

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
        guard let key = channel[Definitions.NOTIFICATION_CHANNEL_KEY] as? String else { return }
        channels[key] = channel
    }

    /// Registers a category with `.customDismissAction` so the system reports
    /// when the user swipes a notification away (otherwise dismiss is silent).
    private func registerDefaultCategory() {
        let category = UNNotificationCategory(
            identifier: Definitions.DEFAULT_CATEGORY_IDENTIFIER,
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
        guard let built = builder.createNotificationContent(fromModel: notification) else {
            completion(false)
            return
        }

        let request = UNNotificationRequest(
            identifier: String(built.id),
            content: built.content,
            trigger: nil // deliver immediately
        )
        center.add(request) { [weak self] error in
            let created = error == nil
            if created, let self = self {
                let content = self.builder.contentMap(fromModel: notification)
                self.emit(
                    Definitions.EVENT_NOTIFICATION_CREATED,
                    self.builder.registerCreatedEvent(content, lifeCycle: "Foreground")
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
        if let model = builder.notificationModel(
            fromUserInfo: notification.request.content.userInfo
        ) {
            let content = builder.contentMap(fromModel: model)
            emit(
                Definitions.EVENT_NOTIFICATION_DISPLAYED,
                builder.registerDisplayedEvent(content, lifeCycle: "Foreground")
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
        if let model = builder.notificationModel(
            fromUserInfo: response.notification.request.content.userInfo
        ) {
            let content = builder.contentMap(fromModel: model)
            if response.actionIdentifier == UNNotificationDismissActionIdentifier {
                emit(
                    Definitions.EVENT_NOTIFICATION_DISMISSED,
                    builder.registerDismissedEvent(content, lifeCycle: "Foreground")
                )
            } else {
                // UNNotificationDefaultActionIdentifier (tap) or a button key.
                emit(
                    Definitions.EVENT_DEFAULT_ACTION,
                    builder.registerActionEvent(content, lifeCycle: "Foreground")
                )
            }
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
        AwesomeEventsReceiver.shared.notifyAwesomeEvent(eventType: eventName, content: data)
    }
}
