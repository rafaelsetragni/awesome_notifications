import Foundation

/// The channels the app registered (iOS and macOS have no system channels):
/// their configuration (importance, sound, critical alerts, …) is honored per
/// `channelKey` while building, as the 0.12 `ChannelManager` did. Thread safe:
/// notifications are built off the main thread.
public final class ChannelManager {

    public static let shared = ChannelManager()
    private init() {}

    private let lock = NSLock()
    private var channels: [String: [String: Any]] = [:]

    /// Registers (or replaces) a channel by its `channelKey`.
    public func setChannel(_ channel: [String: Any]) {
        guard let key = channel[Definitions.NOTIFICATION_CHANNEL_KEY] as? String else { return }
        lock.lock(); defer { lock.unlock() }
        channels[key] = channel
    }

    /// The channel registered with [key], or nil.
    public func channel(forKey key: String?) -> [String: Any]? {
        guard let key = key else { return nil }
        lock.lock(); defer { lock.unlock() }
        return channels[key]
    }

    /// Test-only: forgets every channel.
    func clearForTest() {
        lock.lock(); defer { lock.unlock() }
        channels.removeAll()
    }
}
