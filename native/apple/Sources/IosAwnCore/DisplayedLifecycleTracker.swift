import Foundation

/// Remembers which notifications the system displayed while the app was in the
/// foreground (`willPresent`), so the later action / dismiss events report the
/// real displayed lifecycle instead of the one predicted at creation time.
///
/// A scheduled notification is stored with a predicted `displayedLifeCycle` of
/// terminated (nobody knows the app state at fire time). When it actually fires
/// with the app open, `willPresent` records it here and `didReceive` corrects the
/// content it delivers. Without a record (displayed while the app was not in the
/// foreground) the stored prediction stands.
final class DisplayedLifecycleTracker {

    private var displayedInForeground: [Int: String] = [:]  // id → displayed date
    private let lock = NSLock()

    /// Records that notification `id` was displayed in the foreground at `date`.
    func recordForegroundDisplay(id: Int, date: String) {
        lock.lock(); defer { lock.unlock() }
        displayedInForeground[id] = date
    }

    /// `content` with the real displayed date/lifecycle when `id` was displayed in
    /// the foreground; unchanged otherwise. Consumes the record.
    func resolve(_ content: [String: Any], id: Int?) -> [String: Any] {
        guard let id = id else { return content }
        lock.lock()
        let date = displayedInForeground.removeValue(forKey: id)
        lock.unlock()
        guard let date = date else { return content }
        var resolved = content
        resolved[Definitions.NOTIFICATION_DISPLAYED_DATE] = date
        resolved[Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE] =
            NotificationLifeCycle.foreground.rawValue
        return resolved
    }

    /// Drops the record of notification `id` (removed without an action).
    func forget(id: Int) {
        lock.lock(); defer { lock.unlock() }
        displayedInForeground.removeValue(forKey: id)
    }

    /// Drops every record.
    func forgetAll() {
        lock.lock(); defer { lock.unlock() }
        displayedInForeground.removeAll()
    }
}
