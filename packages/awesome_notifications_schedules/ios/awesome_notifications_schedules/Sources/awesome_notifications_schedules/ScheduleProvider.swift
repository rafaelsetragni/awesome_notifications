import Foundation
import UserNotifications
import IosAwnCore

/// Builds the delivery trigger for a notification that carries a `schedule`.
/// An `interval` schedule becomes a `UNTimeIntervalNotificationTrigger`; a
/// calendar schedule becomes a `UNCalendarNotificationTrigger`.
final class ScheduleProvider: NotificationScheduleProvider {

    private static let calendarKeys = [
        "era", "year", "month", "day", "hour", "minute", "second",
        "weekday", "weekOfMonth", "weekOfYear"
    ]

    func trigger(for model: [String: Any]) -> UNNotificationTrigger? {
        guard let schedule = model["schedule"] as? [String: Any] else { return nil }
        let repeats = (schedule["repeats"] as? Bool) ?? false

        // Interval schedule.
        if let interval = schedule["interval"] as? Int {
            guard interval > 0, !(repeats && interval < 60) else { return nil }
            return UNTimeIntervalNotificationTrigger(
                timeInterval: Double(interval), repeats: repeats)
        }

        // Calendar schedule — requires at least one date component.
        guard Self.calendarKeys.contains(where: { schedule[$0] != nil }) else { return nil }
        var components = DateComponents()
        if let tzId = schedule["timeZone"] as? String,
           let tz = TimeZone(identifier: tzId) {
            components.timeZone = tz
        } else {
            components.timeZone = TimeZone.current
        }
        components.era = schedule["era"] as? Int
        components.year = schedule["year"] as? Int
        components.month = schedule["month"] as? Int
        components.day = schedule["day"] as? Int
        components.hour = schedule["hour"] as? Int
        components.minute = schedule["minute"] as? Int
        components.second = schedule["second"] as? Int
        components.weekday = schedule["weekday"] as? Int
        components.weekOfMonth = schedule["weekOfMonth"] as? Int
        components.weekOfYear = schedule["weekOfYear"] as? Int
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
    }
}
