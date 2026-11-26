import Foundation
import UserNotifications

/// Turns a push into the core's notification model (the FCM add-on registers
/// one). Answers nil when the push is not its own.
public protocol RemoteModelProvider: AnyObject {
    func model(from request: UNNotificationRequest) -> [String: Any]?
}

/// The providers the service extension asks, in registration order.
public final class RemoteModelProviderRegistry {
    public static let shared = RemoteModelProviderRegistry()
    private init() {}

    private let lock = NSLock()
    private var providers: [RemoteModelProvider] = []

    public func register(_ provider: RemoteModelProvider) {
        lock.lock(); defer { lock.unlock() }
        if !providers.contains(where: { $0 === provider }) { providers.append(provider) }
    }

    public func model(from request: UNNotificationRequest) -> [String: Any]? {
        lock.lock()
        let current = providers
        lock.unlock()
        for provider in current {
            if let model = provider.model(from: request) { return model }
        }
        return nil
    }

    func clearForTest() {
        lock.lock(); defer { lock.unlock() }
        providers.removeAll()
    }
}

/// Base class of an app's Notification Service Extension (iOS / macOS).
///
/// A push with `"mutable-content": 1` reaches the extension before it is shown.
/// The extension rebuilds it through the same builder chain the app uses, so
/// the add-ons apply their rendering here too (e.g. awesome_notifications_chat
/// turns a chat message into a communication notification, which iOS only
/// accepts from an extension for pushes):
///
/// ```swift
/// import IosAwnCore
/// import AwesomeNotificationsFcmExtension
/// import AwesomeNotificationsChatExtension
///
/// class NotificationService: AwesomeServiceExtension {
///     override func registerAddOns() {
///         AwesomeFcmExtension.register()
///         AwesomeChatExtension.register()
///     }
/// }
/// ```
///
/// A push no provider recognizes, or one the chain rejects, is shown as it
/// arrived.
open class AwesomeServiceExtension: UNNotificationServiceExtension {

    private static let lock = NSLock()
    private static var addOnsRegistered = false

    private let handlerLock = NSLock()
    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttempt: UNNotificationContent?

    /// Registers the add-ons the extension needs (their model providers and
    /// builders). Called once per extension process.
    open func registerAddOns() {}

    open override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        Self.lock.lock()
        if !Self.addOnsRegistered {
            Self.addOnsRegistered = true
            Self.lock.unlock()
            registerAddOns()
        } else {
            Self.lock.unlock()
        }

        self.contentHandler = contentHandler
        bestAttempt = request.content
        // Resolve the critical-alert availability first (async, never
        // blocking): the extension has no app to have warmed it (0.12.1).
        CriticalAlertUtils.ensureAvailabilityResolved {
            self.deliver(Self.render(request))
        }
    }

    open override func serviceExtensionTimeWillExpire() {
        if let content = bestAttempt { deliver(content) }
    }

    /// Hands [content] to the system once (the render and the expiry may race).
    private func deliver(_ content: UNNotificationContent) {
        handlerLock.lock()
        let handler = contentHandler
        contentHandler = nil
        handlerLock.unlock()
        handler?(content)
    }

    /// The content to show for a push: rebuilt through the builder chain, or
    /// the push's own content when it is not an awesome notification.
    public static func render(_ request: UNNotificationRequest) -> UNNotificationContent {
        guard let model = RemoteModelProviderRegistry.shared.model(from: request) else {
            return request.content
        }
        let builder = NotificationBuilderRegistry.shared.makeBuilder()
        do {
            guard let chained = try builder.build(model: model) else { return request.content }
            let built = builder.stampDisplayed(on: chained)
            if let category = builder.actionCategory(forModel: built.model) {
                registerCategory(category)
            }
            return built.content
        } catch let exception as AwesomeNotificationsException {
            NSLog("[AwesomeNotifications] service extension: %@ (%@)",
                  exception.message, exception.detailedCode)
            return request.content
        } catch {
            NSLog("[AwesomeNotifications] service extension: %@", "\(error)")
            return request.content
        }
    }

    /// Adds the notification's button category to the registered ones, so iOS
    /// shows its buttons (the extension has no app to register it).
    private static func registerCategory(_ category: UNNotificationCategory) {
        let center = UNUserNotificationCenter.current()
        let done = DispatchSemaphore(value: 0)
        center.getNotificationCategories { existing in
            var categories = existing.filter { $0.identifier != category.identifier }
            categories.insert(category)
            center.setNotificationCategories(categories)
            done.signal()
        }
        _ = done.wait(timeout: .now() + 2)
    }
}
