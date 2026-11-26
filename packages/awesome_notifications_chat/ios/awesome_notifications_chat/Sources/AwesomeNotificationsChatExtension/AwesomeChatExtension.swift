import Foundation
import IosAwnCore

/// Chat messages in a Notification Service Extension: a push carrying a
/// conversation becomes a communication notification (iOS only accepts that
/// from an extension for pushes).
public enum AwesomeChatExtension {
    private static let lock = NSLock()
    private static var registered = false

    /// Puts the chat builder in the extension's builder chain. Call it from
    /// `registerAddOns()`.
    public static func register() {
        lock.lock(); defer { lock.unlock() }
        guard !registered else { return }
        registered = true
        NotificationBuilderRegistry.shared.register(priority: ChatBuilder.priority) { inner in
            ChatBuilder(inner: inner)
        }
    }
}
