import Foundation
import UserNotifications

/// Critical-alert availability and request, ported from 0.12.1
/// (`CriticalAlertUtils`, IosAwnCore 1151650 + 19f2bf9).
///
/// The availability is resolved asynchronously *before* a notification is
/// built ([ensureAvailabilityResolved]) and cached, so the synchronous check the
/// builder makes ([canDeliverCriticalAlerts]) is a pure cache read that never
/// blocks — also inside a Notification Service Extension.
public enum CriticalAlertUtils {

    private static let lock = NSLock()
    private static var cachedCanDeliver: Bool?

    /// Caches whether critical alerts can be delivered (the user enabled them,
    /// which also requires the critical-alerts entitlement).
    public static func updateCache(from settings: UNNotificationSettings) {
        setCache(settings.criticalAlertSetting == .enabled)
    }

    public static func clearCache() {
        setCache(nil)
    }

    /// Whether critical alerts can be delivered right now: a non-blocking cache
    /// read, `false` while it was never resolved.
    public static func canDeliverCriticalAlerts() -> Bool {
        lock.lock(); defer { lock.unlock() }
        return cachedCanDeliver ?? false
    }

    /// Resolves the availability into the cache (asynchronously, without
    /// blocking) and then runs [then]: immediately when already cached,
    /// otherwise once the notification settings were read.
    public static func ensureAvailabilityResolved(_ then: @escaping () -> Void) {
        lock.lock()
        let cached = cachedCanDeliver
        lock.unlock()
        if cached != nil {
            then()
            return
        }
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            updateCache(from: settings)
            then()
        }
    }

    /// Whether the notification's *channel* requests critical alerts. Critical
    /// is a channel-level capability (0.12.1): a `criticalAlert` key in the
    /// notification content is ignored.
    public static func isCriticalAlertRequested(channel: [String: Any]?) -> Bool {
        return MapUtils.shared.getBool(channel?[Definitions.NOTIFICATION_CHANNEL_CRITICAL_ALERTS]) ?? false
    }

    static func setCache(_ value: Bool?) {
        lock.lock(); defer { lock.unlock() }
        cachedCanDeliver = value
    }
}
