import Foundation
import UserNotifications
import IosAwnCore

/// Answers the schedule-only channel methods of `AwesomeNotificationsSchedules`
/// (iOS + macOS). Registered in the core's `AwesomeMethodHandlerRegistry`, so the
/// core bridge stays unaware of scheduling.
///
/// On Apple a schedule IS a pending `UNNotificationRequest`: cancelling a
/// schedule removes the pending request and leaves any delivered notification
/// with the same id on screen (that is what distinguishes it from `cancel*`).
final class ScheduleMethodHandler: AwesomeMethodHandler {

    enum Method {
        static let cancelSchedule = "cancelSchedule"
        static let cancelSchedulesByChannelKey = "cancelSchedulesByChannelKey"
        static let cancelSchedulesByGroupKey = "cancelSchedulesByGroupKey"
        static let cancelAllSchedules = "cancelAllSchedules"
        static let listAllSchedules = "listAllSchedules"
        static let getNextDate = "getNextDate"
    }
    static let fixedDateKey = "fixedDate"

    private var center: UNUserNotificationCenter { .current() }
    private let builder = NotificationBuilder.newInstance()

    func handle(method: String, arguments: Any?, result: @escaping (Any?) -> Void) -> Bool {
        switch method {
        case Method.cancelSchedule:
            if let id = MapUtils.shared.getInt(arguments) {
                center.removePendingNotificationRequests(withIdentifiers: [String(id)])
            }
            result(true)

        case Method.cancelSchedulesByChannelKey:
            removePending(matching: Definitions.NOTIFICATION_CHANNEL_KEY, value: arguments as? String)
            result(true)

        case Method.cancelSchedulesByGroupKey:
            removePending(matching: Definitions.NOTIFICATION_GROUP_KEY, value: arguments as? String)
            result(true)

        case Method.cancelAllSchedules:
            center.removeAllPendingNotificationRequests()
            result(true)

        case Method.listAllSchedules:
            center.getPendingNotificationRequests { [builder] requests in
                let models = requests.compactMap {
                    builder.notificationModel(fromUserInfo: $0.content.userInfo)
                }
                DispatchQueue.main.async { result(models) }
            }

        case Method.getNextDate:
            let args = arguments as? [String: Any] ?? [:]
            let schedule = args[ScheduleKeys.schedule] as? [String: Any] ?? [:]
            let fixed = (args[Self.fixedDateKey] as? String).flatMap(ScheduleDates.parse) ?? Date()
            result(ScheduleDates.nextDate(of: schedule, after: fixed).map(ScheduleDates.format))

        default:
            return false
        }
        return true
    }

    private func removePending(matching key: String, value: String?) {
        guard let value = value else { return }
        center.getPendingNotificationRequests { [builder, center] requests in
            let ids = requests.filter {
                let model = builder.notificationModel(fromUserInfo: $0.content.userInfo) ?? [:]
                let content = builder.contentMap(fromModel: model)
                return (content[key] as? String) == value
            }.map(\.identifier)
            if !ids.isEmpty { center.removePendingNotificationRequests(withIdentifiers: ids) }
        }
    }
}

/// Next-fire-date math for `getNextDate`, using the same interpretation of the
/// schedule as `ScheduleBuilder`'s triggers. Dates travel as UTC
/// `yyyy-MM-dd HH:mm:ss`, like every other date of the plugin.
enum ScheduleDates {

    static func nextDate(of schedule: [String: Any], after fixed: Date) -> Date? {
        if let interval = ScheduleBuilder.validInterval(schedule) {
            return fixed.addingTimeInterval(Double(interval))
        }
        guard schedule[ScheduleKeys.interval] == nil,
              let components = ScheduleBuilder.calendarComponents(schedule) else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = ScheduleBuilder.timeZone(schedule)
        return calendar.nextDate(after: fixed, matching: components, matchingPolicy: .nextTime)
    }

    static func parse(_ string: String) -> Date? { formatter.date(from: string) }

    static func format(_ date: Date) -> String { formatter.string(from: date) }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
}
