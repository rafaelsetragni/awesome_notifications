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
/// Arguments, answers and errors follow the 0.12 Apple plugin.
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
            guard let id = arguments as? Int, id >= 0 else {
                result(ScheduleModels.invalidArguments("Invalid id value", ".dismiss.id"))
                break
            }
            center.removePendingNotificationRequests(withIdentifiers: [String(id)])
            result(true)

        case Method.cancelSchedulesByChannelKey:
            guard let channelKey = arguments as? String else {
                result(ScheduleModels.invalidArguments(
                    "Invalid channel key value", ".dismiss.channelKey"))
                break
            }
            removePending(matching: Definitions.NOTIFICATION_CHANNEL_KEY, value: channelKey) {
                result(true)
            }

        case Method.cancelSchedulesByGroupKey:
            guard let groupKey = arguments as? String else {
                result(ScheduleModels.invalidArguments(
                    "Invalid group key value", ".dismiss.groupKey"))
                break
            }
            removePending(matching: Definitions.NOTIFICATION_GROUP_KEY, value: groupKey) {
                result(true)
            }

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
            result(ScheduleMethodHandler.nextDate(arguments as? [String: Any] ?? [:]))

        default:
            return false
        }
        return true
    }

    /// 0.12's `channelMethodGetNextDate` + `AwesomeNotifications.getNextValidDate`:
    /// the fixed date's wall clock is read in the `timeZone` argument (UTC —
    /// "GMT" — when absent), the schedule is computed in its own time zone (the
    /// device's when invalid or absent) and the answer is that zone's wall clock
    /// plus its identifier, e.g. "2026-07-05 05:31:30 America/Sao_Paulo".
    static func nextDate(_ arguments: [String: Any]) -> String? {
        guard let fixedDate = arguments[fixedDateKey] as? String,
              let scheduleData = arguments[ScheduleKeys.schedule] as? [String: Any],
              let schedule = ScheduleModels.from(scheduleMap: scheduleData)
        else { return nil }

        let timeZoneName = arguments[ScheduleKeys.timeZone] as? String
            ?? ScheduleDateTime.utcTimeZone.identifier
        let fixedDateTime = ScheduleDateTime(fromDateText: fixedDate, inTimeZone: timeZoneName)
            ?? ScheduleDateTime()
        schedule.createdDate = fixedDateTime
        return schedule.getNextValidDate(referenceDate: fixedDateTime)?.description
    }

    /// Removes the pending requests whose content has [key] == [value], then
    /// calls [completion] (after the removal was requested, so a listing made
    /// next no longer sees them).
    private func removePending(
        matching key: String, value: String, completion: @escaping () -> Void
    ) {
        center.getPendingNotificationRequests { [builder, center] requests in
            let ids = requests.filter {
                let model = builder.notificationModel(fromUserInfo: $0.content.userInfo) ?? [:]
                let content = builder.contentMap(fromModel: model)
                return (content[key] as? String) == value
            }.map(\.identifier)
            if !ids.isEmpty { center.removePendingNotificationRequests(withIdentifiers: ids) }
            DispatchQueue.main.async { completion() }
        }
    }
}
