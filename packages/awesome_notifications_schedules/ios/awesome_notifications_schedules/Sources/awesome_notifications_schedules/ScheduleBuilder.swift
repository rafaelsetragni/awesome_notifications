import Foundation
import UserNotifications
import IosAwnCore

/// Builder decorator that adds a delivery **trigger** to a notification carrying
/// a `schedule`. It inherits the core `NotificationBuilder`, overrides `build`,
/// delegates content building to the wrapped builder (`next`), then attaches a
/// `UNTimeIntervalNotificationTrigger` (interval) or `UNCalendarNotificationTrigger`
/// (calendar). Without a schedule it just delegates (immediate delivery).
///
/// Behaves exactly like 0.12 on Apple (`NotificationSenderAndScheduler` +
/// `NotificationBuilder.createNotification`):
///  - an invalid schedule throws (the call fails with INVALID_ARGUMENTS);
///  - a schedule without a next fire date is not created (false);
///  - the schedule's time zone defaults to the device's (and an identifier
///    Apple doesn't name the same way, like "UTC", falls back to it too); the
///    stored schedule carries that time zone and the created date, which is
///    what `listScheduledNotifications` answers.
final class ScheduleBuilder: NotificationBuilder {

    override func build(model: [String: Any]) throws -> BuiltNotification? {
        guard let schedule = try ScheduleModels.extract(fromNotification: model) else {
            return try next(model)
        }
        guard let (trigger, prepared) = try ScheduleBuilder.prepare(model, schedule) else {
            return nil
        }
        // Stamp the created source as "Schedule" before the base builder stamps
        // its default ("Local"); the base's stamp is a no-op once it is set.
        let seeded = stampCreatedLifecycle(into: prepared, source: .schedule)
        guard let built = try next(seeded) else { return nil }
        return BuiltNotification(
            id: built.id, content: built.content, trigger: trigger, model: built.model)
    }

    /// Validates [schedule], resolves its time zone and created date, and returns
    /// its trigger with the model carrying the resolved schedule — or nil when
    /// the schedule has no next fire date (0.12 then answered false).
    static func prepare(
        _ model: [String: Any],
        _ schedule: ScheduleModel
    ) throws -> (UNNotificationTrigger, [String: Any])? {
        try schedule.validate()

        let timeZone = schedule.timeZone ?? TimeZone.current
        schedule.timeZone = timeZone
        schedule.createdDate = ScheduleDateTime(fromTimeZone: timeZone)

        guard let trigger = schedule.getUNNotificationTrigger(),
              nextTriggerDate(trigger) != nil
        else { return nil }

        var prepared = model
        prepared[ScheduleKeys.schedule] = schedule.toMap()
        return (trigger, prepared)
    }

    static func nextTriggerDate(_ trigger: UNNotificationTrigger) -> Date? {
        if let calendar = trigger as? UNCalendarNotificationTrigger {
            return calendar.nextTriggerDate()
        }
        if let interval = trigger as? UNTimeIntervalNotificationTrigger {
            return interval.nextTriggerDate()
        }
        return nil
    }
}
