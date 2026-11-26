import Foundation
import UserNotifications
import IosAwnCore

// Faithful port of the 0.12 IosAwnCore schedule models (NotificationCalendarModel,
// NotificationIntervalModel, RealDateTime, TimeZoneUtils). The 0.12 behavior on
// Apple is the contract, quirks included — e.g. "UTC" is not a valid schedule
// time zone there (Apple names it "GMT"), so it falls back to the device zone.

/// 0.12's `RealDateTime`: a wall clock (year…second) plus its time zone.
final class ScheduleDateTime {

    static let units: Set<Calendar.Component> =
        [.year, .month, .day, .hour, .minute, .second, .timeZone]

    /// 0.12's `RealDateTime.utcTimeZone` / `DateUtils.utcTimeZone` (named "GMT").
    static let utcTimeZone = TimeZone(secondsFromGMT: 0)!

    let dateComponents: DateComponents

    var timeZone: TimeZone { dateComponents.timeZone! }

    init(fromDateComponents dateComponents: DateComponents) {
        self.dateComponents = dateComponents
    }

    /// Now, in [timeZone] (the device zone when nil).
    convenience init(fromTimeZone timeZone: TimeZone?) {
        self.init(fromDate: Date(), inTimeZone: timeZone ?? TimeZone.current)
    }

    /// Now, in UTC.
    convenience init() {
        self.init(fromTimeZone: ScheduleDateTime.utcTimeZone)
    }

    convenience init(fromDate date: Date, inTimeZone timeZone: TimeZone) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        self.init(fromDateComponents: calendar.dateComponents(ScheduleDateTime.units, from: date))
    }

    convenience init?(fromDateText text: String, inTimeZone timeZone: TimeZone) {
        guard let date = ScheduleDateTime.stringToDate(text, timeZone: timeZone) else { return nil }
        self.init(fromDate: date, inTimeZone: timeZone)
    }

    convenience init?(fromDateText text: String, inTimeZone timeZoneId: String) {
        guard let timeZone = TimeZone(identifier: timeZoneId) else { return nil }
        self.init(fromDateText: text, inTimeZone: timeZone)
    }

    static func stringToDate(_ text: String?, timeZone: TimeZone?) -> Date? {
        guard let text = text, !text.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.timeZone = timeZone ?? TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: text)
    }

    var date: Date {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        return calendar.date(from: dateComponents)!
    }

    /// "yyyy-MM-dd HH:mm:ss <time zone identifier>", as 0.12 answered dates.
    var description: String {
        return String(
            format: "%04d-%02d-%02d %02d:%02d:%02d %@",
            dateComponents.year!, dateComponents.month!, dateComponents.day!,
            dateComponents.hour!, dateComponents.minute!, dateComponents.second!,
            timeZone.identifier)
    }

    static func < (lhs: ScheduleDateTime, rhs: ScheduleDateTime) -> Bool {
        return lhs.date < rhs.date
    }
}

/// 0.12's `TimeZoneUtils.getValidTimeZone`: accepts an offset ("-03:00", "+05")
/// or an identifier, and only when the resolved zone's identifier contains what
/// was given — so "UTC" (resolved as "GMT") is rejected (nil).
enum ScheduleTimeZones {
    static func validTimeZone(fromTimeZoneId timeZoneId: String?) -> TimeZone? {
        guard let timeZoneId = timeZoneId else { return nil }

        let pattern = #"^((\-|\+)?(\d{2}(:\d{2})?))|(\S+)$"#
        let matcher = matchList(timeZoneId, pattern)

        var finalTimeZone: TimeZone?
        if !matcher.isEmpty {
            let matches = matcher[0]
            if !matches[1].isEmpty {
                let finalTimeZoneId = "GMT" + (
                    (matches[2].isEmpty ? "+" : matches[2]) +
                    matches[3] +
                    (matches[4].isEmpty ? ":00" : ""))
                finalTimeZone = TimeZone(identifier: finalTimeZoneId)
            } else {
                finalTimeZone = TimeZone(identifier: matches[5])
            }
        }

        if finalTimeZone?.identifier.contains(timeZoneId) ?? false {
            return finalTimeZone
        }
        return nil
    }

    private static func matchList(_ text: String, _ pattern: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
        let nsString = text as NSString
        let results = regex.matches(in: text, options: [], range: NSMakeRange(0, nsString.length))
        return results.map { result in
            (0..<result.numberOfRanges).map {
                result.range(at: $0).location != NSNotFound
                    ? nsString.substring(with: result.range(at: $0))
                    : ""
            }
        }
    }
}

/// Reads a schedule map the way 0.12's `MapUtils.getValueOrDefault` did.
enum ScheduleValues {
    static func int(_ map: [String: Any], _ key: String) -> Int? {
        switch map[key] {
        case let value as Int: return value
        case let value as Double: return Int(value)
        case let value as Float: return Int(value)
        case let value as String: return Int(value) ?? 0
        default: return nil
        }
    }

    static func bool(_ map: [String: Any], _ key: String) -> Bool? {
        return map[key] as? Bool
    }

    static func timeZone(_ map: [String: Any]) -> TimeZone? {
        return ScheduleTimeZones.validTimeZone(fromTimeZoneId: map[ScheduleKeys.timeZone] as? String)
    }

    static func dateTime(_ map: [String: Any], _ key: String) -> ScheduleDateTime? {
        guard let text = map[key] as? String else { return nil }
        // 0.12's RealDateTime(fromDateText:defaultTimeZone:) with UTC default.
        let pattern = #"(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})( (\S+))?"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: text, range: NSRange(text.startIndex..., in: text))
        else { return nil }
        let ns = text as NSString
        let wallClock = ns.substring(with: match.range(at: 1))
        let zoneRange = match.range(at: 3)
        let zone = zoneRange.location == NSNotFound
            ? ScheduleDateTime.utcTimeZone
            : TimeZone(identifier: ns.substring(with: zoneRange)) ?? TimeZone.current
        return ScheduleDateTime(fromDateText: wallClock, inTimeZone: zone)
    }
}

/// 0.12's `NotificationScheduleModel`.
protocol ScheduleModel: AnyObject {
    var createdDate: ScheduleDateTime? { get set }
    var timeZone: TimeZone? { get set }
    var repeats: Bool? { get }

    func validate() throws
    func toMap() -> [String: Any]
    func getUNNotificationTrigger() -> UNNotificationTrigger?
    func getNextValidDate(referenceDate: ScheduleDateTime) -> ScheduleDateTime?
}

enum ScheduleModels {

    /// 0.12's `NotificationModel.extractNotificationSchedule`: no (or an empty)
    /// schedule map → nil; Android crontab keys throw; an `interval` key makes it
    /// an interval schedule, anything else a calendar.
    static func extract(fromNotification model: [String: Any]) throws -> ScheduleModel? {
        guard let map = model[ScheduleKeys.schedule] as? [String: Any], !map.isEmpty else {
            return nil
        }
        if map[ScheduleKeys.crontabExpression] != nil ||
            map[ScheduleKeys.preciseSchedules] != nil ||
            map[ScheduleKeys.initialDateTime] != nil ||
            map[ScheduleKeys.expirationDateTime] != nil {
            throw invalidArguments(
                "Crontab schedules are not available for iOS", ".crontab.ios")
        }
        return from(scheduleMap: map)
    }

    /// The schedule model of a schedule map (nil when the map is empty).
    static func from(scheduleMap map: [String: Any]) -> ScheduleModel? {
        if map.isEmpty { return nil }
        if map[ScheduleKeys.interval] != nil {
            return IntervalScheduleModel(fromMap: map)
        }
        return CalendarScheduleModel(fromMap: map)
    }

    static func invalidArguments(_ message: String, _ detail: String) -> AwesomeNotificationsException {
        return AwesomeNotificationsException(
            code: AwesomeNotificationsException.CODE_INVALID_ARGUMENTS,
            message: message,
            detailedCode: AwesomeNotificationsException.DETAILED_INVALID_ARGUMENTS + detail)
    }
}

/// 0.12's `NotificationCalendarModel`. The weekday is ISO (1 = Monday … 7 =
/// Sunday) on the wire and Apple's (1 = Sunday … 7 = Saturday) inside.
final class CalendarScheduleModel: ScheduleModel {
    var createdDate: ScheduleDateTime?
    var timeZone: TimeZone?

    var year: Int?
    var month: Int?
    var day: Int?
    var hour: Int?
    var minute: Int?
    var second: Int?
    var weekday: Int?
    var weekOfMonth: Int?
    var weekOfYear: Int?
    var repeats: Bool?

    init(fromMap map: [String: Any]) {
        createdDate = ScheduleValues.dateTime(map, ScheduleKeys.createdDate)
        timeZone = ScheduleValues.timeZone(map)

        year = ScheduleValues.int(map, ScheduleKeys.year)
        month = ScheduleValues.int(map, ScheduleKeys.month)
        day = ScheduleValues.int(map, ScheduleKeys.day)
        hour = ScheduleValues.int(map, ScheduleKeys.hour)
        minute = ScheduleValues.int(map, ScheduleKeys.minute)
        second = ScheduleValues.int(map, ScheduleKeys.second)
        weekday = ScheduleValues.int(map, ScheduleKeys.weekday)
        weekOfMonth = ScheduleValues.int(map, ScheduleKeys.weekOfMonth)
        weekOfYear = ScheduleValues.int(map, ScheduleKeys.weekOfYear)
        repeats = ScheduleValues.bool(map, ScheduleKeys.repeats) ?? false

        if (year ?? 0) < 0 { year = nil }
        if (month ?? 0) < 0 { month = nil }
        if (day ?? 0) < 0 { day = nil }
        if (hour ?? 0) < 0 { hour = nil }
        if (minute ?? 0) < 0 { minute = nil }
        if (second ?? 0) < 0 { second = nil }
        if (weekday ?? 0) < 0 { weekday = nil }
        if (weekOfMonth ?? 0) < 0 { weekOfMonth = nil }
        if (weekOfYear ?? 0) < 0 { weekOfYear = nil }

        // https://github.com/rafaelsetragni/awesome_notifications/issues/153#issuecomment-830732722
        if let isoWeekday = weekday {
            weekday = isoWeekday == 7 ? 1 : isoWeekday + 1
        }
    }

    func toMap() -> [String: Any] {
        var map: [String: Any] = [:]
        if let timeZone = timeZone { map[ScheduleKeys.timeZone] = timeZone.identifier }
        if let createdDate = createdDate { map[ScheduleKeys.createdDate] = createdDate.description }
        if let year = year { map[ScheduleKeys.year] = year }
        if let month = month { map[ScheduleKeys.month] = month }
        if let day = day { map[ScheduleKeys.day] = day }
        if let hour = hour { map[ScheduleKeys.hour] = hour }
        if let minute = minute { map[ScheduleKeys.minute] = minute }
        if let second = second { map[ScheduleKeys.second] = second }
        if let weekday = weekday { map[ScheduleKeys.weekday] = weekday == 1 ? 7 : weekday - 1 }
        if let weekOfMonth = weekOfMonth { map[ScheduleKeys.weekOfMonth] = weekOfMonth }
        if let weekOfYear = weekOfYear { map[ScheduleKeys.weekOfYear] = weekOfYear }
        if let repeats = repeats { map[ScheduleKeys.repeats] = repeats }
        return map
    }

    func validate() throws {
        if year == nil && month == nil && day == nil && hour == nil && minute == nil &&
            second == nil && weekday == nil && weekOfMonth == nil && weekOfYear == nil {
            throw ScheduleModels.invalidArguments(
                "At least one time condition is required", ".notificationCalendar")
        }

        func isBetween(_ value: Int, _ min: Int, _ max: Int) -> Bool {
            return value >= min && value <= max
        }
        if !(
            isBetween(year ?? 0, 0, 99999) &&
            isBetween(month ?? 1, 1, 12) &&
            isBetween(day ?? 1, 1, 31) &&
            isBetween(hour ?? 0, 0, 23) &&
            isBetween(minute ?? 0, 0, 59) &&
            isBetween(second ?? 0, 0, 59) &&
            isBetween(weekday ?? 1, 1, 7) &&
            isBetween(weekOfMonth ?? 1, 1, 6) &&
            isBetween(weekOfYear ?? 1, 1, 53)
        ) {
            throw ScheduleModels.invalidArguments(
                "The time conditions are invalid", ".notificationCalendar")
        }
    }

    func toDateComponents() -> DateComponents {
        return DateComponents(
            timeZone: timeZone ?? TimeZone.current,
            year: year, month: month, day: day,
            hour: hour, minute: minute, second: second,
            weekday: weekday, weekOfMonth: weekOfMonth, weekOfYear: weekOfYear)
    }

    func getUNNotificationTrigger() -> UNNotificationTrigger? {
        guard (try? validate()) != nil else { return nil }
        return UNCalendarNotificationTrigger(
            dateMatching: toDateComponents(), repeats: repeats ?? false)
    }

    func getNextValidDate(referenceDate: ScheduleDateTime) -> ScheduleDateTime? {
        guard let createdDate = createdDate else { return nil }
        let timeZone = self.timeZone ?? TimeZone.current
        let refDate = (repeats ?? true) ? createdDate : referenceDate

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        var components = toDateComponents()
        components.calendar = calendar
        components.timeZone = timeZone

        guard let next = calendar.nextDate(
            after: refDate.date, matching: components, matchingPolicy: .nextTime)
        else { return nil }
        return ScheduleDateTime(fromDate: next, inTimeZone: timeZone)
    }
}

/// 0.12's `NotificationIntervalModel`.
final class IntervalScheduleModel: ScheduleModel {
    var createdDate: ScheduleDateTime?
    var timeZone: TimeZone?

    var interval: Int?
    var repeats: Bool?

    init(fromMap map: [String: Any]) {
        timeZone = ScheduleValues.timeZone(map)
        createdDate = ScheduleValues.dateTime(map, ScheduleKeys.createdDate)
        interval = ScheduleValues.int(map, ScheduleKeys.interval)
        repeats = ScheduleValues.bool(map, ScheduleKeys.repeats) ?? false
    }

    func toMap() -> [String: Any] {
        var map: [String: Any] = [:]
        if let timeZone = timeZone { map[ScheduleKeys.timeZone] = timeZone.identifier }
        if let createdDate = createdDate { map[ScheduleKeys.createdDate] = createdDate.description }
        if let interval = interval { map[ScheduleKeys.interval] = interval }
        if let repeats = repeats { map[ScheduleKeys.repeats] = repeats }
        return map
    }

    func validate() throws {
        guard let interval = interval, interval >= 5 else {
            throw ScheduleModels.invalidArguments(
                "Interval is required and must be equal or greater than 5",
                ".notificationInterval.interval")
        }
        if (repeats ?? false) && interval < 60 {
            throw ScheduleModels.invalidArguments(
                "time interval must be at least 60 if repeating",
                ".notificationInterval.interval")
        }
    }

    func getUNNotificationTrigger() -> UNNotificationTrigger? {
        guard (try? validate()) != nil, let interval = interval else { return nil }
        return UNTimeIntervalNotificationTrigger(
            timeInterval: Double(interval), repeats: repeats ?? false)
    }

    func getNextValidDate(referenceDate: ScheduleDateTime) -> ScheduleDateTime? {
        guard let createdDate = createdDate, let interval = interval else { return nil }
        let timeZone = self.timeZone ?? TimeZone.current

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        if repeats ?? true {
            // The next interval multiple, counted from the created date.
            let elapsed = secondsSince1970(referenceDate.date) - secondsSince1970(createdDate.date)
            let intervals = interval == 0 ? 0 : Int(elapsed / Int64(interval))
            guard let next = calendar.date(
                byAdding: .second, value: (intervals + 1) * interval, to: createdDate.date)
            else { return nil }
            return ScheduleDateTime(fromDate: next, inTimeZone: timeZone)
        }

        guard let next = calendar.date(byAdding: .second, value: interval, to: createdDate.date)
        else { return nil }
        let nextDateTime = ScheduleDateTime(fromDate: next, inTimeZone: timeZone)
        if nextDateTime < referenceDate { return nil }
        return nextDateTime
    }

    /// 0.12's `Date.secondsSince1970` (rounded up).
    private func secondsSince1970(_ date: Date) -> Int64 {
        return Int64(date.timeIntervalSince1970.rounded(.up))
    }
}
