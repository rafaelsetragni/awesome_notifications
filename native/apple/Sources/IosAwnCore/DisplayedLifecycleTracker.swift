import Foundation

/// Remembers which notifications the system displayed while the app was running
/// (`willPresent`), and in which lifecycle, so the later action / dismiss events
/// report the real displayed lifecycle instead of the one predicted at creation.
///
/// A scheduled notification is stored with a predicted `displayedLifeCycle` of
/// terminated (nobody knows the app state at fire time). When it actually fires
/// with the app open, `willPresent` records it here and `didReceive` corrects the
/// content it delivers. Without a record (displayed while the app was not
/// running) the stored prediction stands.
final class DisplayedLifecycleTracker {

    private var displayedInApp: [Int: (date: String, lifeCycle: NotificationLifeCycle)] = [:]
    private let lock = NSLock()

    /// Records that notification `id` was displayed at `date`, in `lifeCycle`.
    func recordDisplay(id: Int, date: String, lifeCycle: NotificationLifeCycle) {
        lock.lock(); defer { lock.unlock() }
        displayedInApp[id] = (date, lifeCycle)
    }

    /// `content` with the real displayed date/lifecycle when `id` was displayed
    /// with the app running; unchanged otherwise. Consumes the record.
    func resolve(_ content: [String: Any], id: Int?) -> [String: Any] {
        guard let id = id else { return content }
        lock.lock()
        let display = displayedInApp.removeValue(forKey: id)
        lock.unlock()
        guard let display = display else { return content }
        var resolved = content
        resolved[Definitions.NOTIFICATION_DISPLAYED_DATE] = display.date
        resolved[Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE] = display.lifeCycle.rawValue
        return resolved
    }

    /// Drops the record of notification `id` (removed without an action).
    func forget(id: Int) {
        lock.lock(); defer { lock.unlock() }
        displayedInApp.removeValue(forKey: id)
    }

    /// Drops every record.
    func forgetAll() {
        lock.lock(); defer { lock.unlock() }
        displayedInApp.removeAll()
    }
}
