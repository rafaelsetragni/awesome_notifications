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
        registerCategory(category)
    }

    /// Adds a category to the notification center, keeping the existing ones.
    private func registerCategory(_ category: UNNotificationCategory) {
        center.getNotificationCategories { existing in
            // Replace any same-identifier category, then add the new one.
            let kept = existing.filter { $0.identifier != category.identifier }
            self.center.setNotificationCategories(Set(kept).union([category]))
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
        _ rawNotification: [String: Any],
        completion: @escaping (Bool) -> Void
    ) {
        // Build off the main thread (image loading does I/O).
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // Let registered decorators (e.g. localization) transform the model
            // once; the build, events and stored payload all use the result.
            let notification = NotificationContentManager.shared.apply(to: rawNotification)
            guard let built = self.builder.createNotificationContent(fromModel: notification) else {
                DispatchQueue.main.async { completion(false) }
                return
            }

            // Register the per-notification action-button category (if any) so
            // iOS shows the buttons and reports which one was pressed.
            if let category = self.builder.actionCategory(forModel: notification) {
                self.registerCategory(category)
            }

            let request = UNNotificationRequest(
                identifier: String(built.id),
                content: built.content,
                trigger: nil // deliver immediately
            )
            self.center.add(request) { error in
                let created = error == nil
                if created {
                    let content = self.builder.contentMap(fromModel: notification)
                    self.emit(
                        Definitions.EVENT_NOTIFICATION_CREATED,
                        self.builder.registerCreatedEvent(content, lifeCycle: "Foreground")
                    )
                }
                DispatchQueue.main.async { completion(created) }
            }
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
            var content = builder.contentMap(fromModel: model)
            let actionId = response.actionIdentifier
            let systemDismiss = actionId == UNNotificationDismissActionIdentifier
            let defaultTap = actionId == UNNotificationDefaultActionIdentifier
            // Anything else is one of our button keys.
            let buttonKey = (systemDismiss || defaultTap) ? "" : actionId
            let pressedButton = builder.findButton(inModel: model, key: buttonKey)

            // Carry the pressed button key + any typed text back to Dart.
            if !buttonKey.isEmpty {
                content[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED] = buttonKey
                if let textResponse = response as? UNTextInputNotificationResponse {
                    content[Definitions.NOTIFICATION_BUTTON_KEY_INPUT] = textResponse.userText
                }
            }

            // A swipe, a DismissAction notification, or a DismissAction button all
            // count as a dismissal.
            let isDismiss = systemDismiss
                || (buttonKey.isEmpty && builder.isDismissAction(content))
                || builder.buttonActionType(pressedButton).hasSuffix("DismissAction")

            if isDismiss {
                if !systemDismiss, let id = builder.readId(content) {
                    dismiss(id: id)
                }
                emit(
                    Definitions.EVENT_NOTIFICATION_DISMISSED,
                    builder.registerDismissedEvent(content, lifeCycle: "Foreground")
                )
            } else {
                // Default tap, or a non-dismiss button. Auto-dismiss the button's
                // notification when requested (a plain tap is auto-dismissed by iOS).
                if !buttonKey.isEmpty,
                   builder.shouldButtonAutoDismiss(pressedButton),
                   let id = builder.readId(content) {
                    dismiss(id: id)
                }
                emit(
                    Definitions.EVENT_DEFAULT_ACTION,
                    builder.registerActionEvent(
                        content,
                        lifeCycle: "Foreground",
                        actionType: builder.buttonActionType(pressedButton)
                    )
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

    // dismiss* removes the visible notification (keeps the schedule); cancel* also
    // removes the pending request (which will be the schedule once that exists).

    public func dismissByChannelKey(_ channelKey: String) {
        removeDelivered(matchingKey: Definitions.NOTIFICATION_CHANNEL_KEY, value: channelKey)
    }

    public func dismissByGroupKey(_ groupKey: String) {
        removeDelivered(matchingKey: Definitions.NOTIFICATION_GROUP_KEY, value: groupKey)
    }

    public func cancelByChannelKey(_ channelKey: String) {
        removeDelivered(matchingKey: Definitions.NOTIFICATION_CHANNEL_KEY, value: channelKey)
        removePending(matchingKey: Definitions.NOTIFICATION_CHANNEL_KEY, value: channelKey)
    }

    public func cancelByGroupKey(_ groupKey: String) {
        removeDelivered(matchingKey: Definitions.NOTIFICATION_GROUP_KEY, value: groupKey)
        removePending(matchingKey: Definitions.NOTIFICATION_GROUP_KEY, value: groupKey)
    }

    // MARK: - Helpers

    private func emit(_ eventName: String, _ data: [String: Any]) {
        AwesomeEventsReceiver.shared.notifyAwesomeEvent(eventType: eventName, content: data)
    }

    /// Reads a stored content string (channelKey/groupKey) from a notification's
    /// injected payload.
    private func contentString(_ userInfo: [AnyHashable: Any], _ key: String) -> String? {
        guard let model = builder.notificationModel(fromUserInfo: userInfo) else {
            return nil
        }
        return builder.contentMap(fromModel: model)[key] as? String
    }

    private func removeDelivered(matchingKey key: String, value: String) {
        center.getDeliveredNotifications { [weak self] delivered in
            guard let self = self else { return }
            let ids = delivered
                .filter { self.contentString($0.request.content.userInfo, key) == value }
                .map { $0.request.identifier }
            if !ids.isEmpty {
                self.center.removeDeliveredNotifications(withIdentifiers: ids)
            }
        }
    }

    private func removePending(matchingKey key: String, value: String) {
        center.getPendingNotificationRequests { [weak self] pending in
            guard let self = self else { return }
            let ids = pending
                .filter { self.contentString($0.content.userInfo, key) == value }
                .map { $0.identifier }
            if !ids.isEmpty {
                self.center.removePendingNotificationRequests(withIdentifiers: ids)
            }
        }
    }
}
