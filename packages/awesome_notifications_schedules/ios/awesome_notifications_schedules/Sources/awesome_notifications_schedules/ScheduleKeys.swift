import Foundation

/// Keys of the `schedule` block a notification carries. They match the strings
/// the Dart schedule models (`NotificationInterval`/`NotificationCalendar`)
/// serialize — the single source of truth for this decorator, so there are no
/// magic strings in the scheduling code.
enum ScheduleKeys {
    static let schedule = "schedule"
    static let interval = "interval"
    static let repeats = "repeats"
    static let allowWhileIdle = "allowWhileIdle"
    static let timeZone = "timeZone"
    static let era = "era"
    static let year = "year"
    static let month = "month"
    static let day = "day"
    static let hour = "hour"
    static let minute = "minute"
    static let second = "second"
    static let weekday = "weekday"
    static let weekOfMonth = "weekOfMonth"
    static let weekOfYear = "weekOfYear"
    /// The reference date 0.12 stored in (and listed with) every schedule.
    static let createdDate = "createdDate"
    /// Android-only (crontab) schedule keys, rejected on Apple like 0.12 did.
    static let crontabExpression = "crontabExpression"
    static let preciseSchedules = "preciseSchedules"
    static let initialDateTime = "initialDateTime"
    static let expirationDateTime = "expirationDateTime"
}
