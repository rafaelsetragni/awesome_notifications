import Foundation
import UserNotifications
import IosAwnCore

/// Builder decorator that adds a delivery **trigger** to a notification carrying
/// a `schedule`. It inherits the core `NotificationBuilder`, overrides `build`,
/// delegates content building to the wrapped builder (`next`), then attaches a
/// `UNTimeIntervalNotificationTrigger` (interval) or `UNCalendarNotificationTrigger`
/// (calendar). Without a schedule it just delegates (immediate delivery).
final class ScheduleBuilder: NotificationBuilder {

    override func build(model: [String: Any]) -> BuiltNotification? {
        // When this notification is actually schedulable, stamp the created source
        // as "Schedule" before the base builder stamps its default ("Local"). The
        // base's stamp is a no-op once the created date is set, so this wins.
        let seeded = ScheduleBuilder.trigger(for: model) != nil
            ? stampCreatedLifecycle(into: model, source: .schedule)
            : model
        guard let built = next(seeded) else { return nil }
        guard let trigger = ScheduleBuilder.trigger(for: built.model) else { return built }
        return BuiltNotification(
            id: built.id, content: built.content, trigger: trigger, model: built.model)
    }

    static func trigger(for model: [String: Any]) -> UNNotificationTrigger? {
        guard let schedule = model[ScheduleKeys.schedule] as? [String: Any] else { return nil }
        let repeats = (schedule[ScheduleKeys.repeats] as? Bool) ?? false

        if let interval = schedule[ScheduleKeys.interval] as? Int {
            guard interval > 0, !(repeats && interval < 60) else { return nil }
            return UNTimeIntervalNotificationTrigger(
                timeInterval: Double(interval), repeats: repeats)
        }

        guard ScheduleKeys.calendarComponents.contains(where: { schedule[$0] != nil })
        else { return nil }
        var c = DateComponents()
        if let tzId = schedule[ScheduleKeys.timeZone] as? String,
           let tz = TimeZone(identifier: tzId) {
            c.timeZone = tz
        } else {
            c.timeZone = TimeZone.current
        }
        c.era = schedule[ScheduleKeys.era] as? Int
        c.year = schedule[ScheduleKeys.year] as? Int
        c.month = schedule[ScheduleKeys.month] as? Int
        c.day = schedule[ScheduleKeys.day] as? Int
        c.hour = schedule[ScheduleKeys.hour] as? Int
        c.minute = schedule[ScheduleKeys.minute] as? Int
        c.second = schedule[ScheduleKeys.second] as? Int
        c.weekday = schedule[ScheduleKeys.weekday] as? Int
        c.weekOfMonth = schedule[ScheduleKeys.weekOfMonth] as? Int
        c.weekOfYear = schedule[ScheduleKeys.weekOfYear] as? Int
        return UNCalendarNotificationTrigger(dateMatching: c, repeats: repeats)
    }
}
