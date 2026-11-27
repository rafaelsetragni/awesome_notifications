import Foundation
import IosAwnCore

/// Keys of the `liveActivity` block, the channel methods and the event channel
/// (same names as the Dart `LiveActivityKeys`).
public enum LiveActivityKeys {
    public static let liveActivity = "liveActivity"

    public static let activityId = "activityId"
    public static let state = "state"
    public static let progress = "progress"
    public static let timer = "timer"
    public static let metrics = "metrics"
    public static let shortText = "shortText"
    public static let accentColor = "accentColor"
    public static let staleAt = "staleAt"
    public static let relevance = "relevance"
    public static let alert = "alert"
    public static let dismissal = "dismissal"
    public static let pushChannel = "pushChannel"
    public static let layout = "layout"
    public static let layoutVersus = "versus"
    public static let customLayout = "customLayout"

    public static let segments = "segments"
    public static let points = "points"
    public static let trackerIcon = "trackerIcon"
    public static let startIcon = "startIcon"
    public static let endIcon = "endIcon"
    public static let length = "length"
    public static let position = "position"
    public static let color = "color"

    public static let start = "start"
    public static let end = "end"
    public static let countDown = "countDown"

    public static let label = "label"
    public static let value = "value"
    public static let unit = "unit"
    public static let image = "image"

    public static let dismissalDefault = "default"
    public static let dismissalImmediate = "immediate"

    /// Added to the content payload: which activity an action came from.
    public static let payloadActivityId = "activityId"

    public static let methodEnd = "liveActivityEnd"
    public static let methodList = "liveActivityList"
    public static let methodCapabilities = "liveActivityCapabilities"
    public static let methodAreEnabled = "liveActivityAreEnabled"
    public static let methodRequestPermission = "liveActivityRequestPermission"
    public static let methodPushToStartToken = "liveActivityPushToStartToken"
    public static let methodPushToken = "liveActivityPushToken"

    public static let eventsChannel = "awesome_notifications_live_activities/events"
    public static let kind = "kind"
    public static let kindPushToStartToken = "pushToStartToken"
    public static let kindPushToken = "pushToken"
    public static let kindState = "state"
    public static let token = "token"

    public static let capSystemSurface = "systemSurface"
    public static let capProgressSegments = "progressSegments"
    public static let capMetrics = "metrics"
    public static let capButtons = "buttons"
    public static let capPush = "push"

    /// The content's progress (0 to 100), the activity's value.
    public static let contentProgress = "progress"
    /// A model with a `schedule` entry can't be a live activity.
    public static let schedule = "schedule"

    /// Detailed codes of the refusals.
    public static let invalidLiveActivity = ".notificationLiveActivity"
    public static let invalidSchedule = ".notificationLiveActivity.schedule"

    /// Info.plist key of the App Group whose container holds the images.
    public static let appGroupInfoKey = "AwnLiveActivitiesAppGroup"

    /// ActivityKit's limit for an activity's data, in bytes.
    public static let maxPayloadBytes = 4096
}

/// What the app asks for an activity (Dart `LiveActivityState`).
public enum LiveActivityState: String {
    case active, ended
}

/// Where an activity is in its life, as the system reports it (Dart
/// `LiveActivityStatus`).
public enum LiveActivityStatus: String {
    case active, stale, ended, dismissed
}

/// When an ended activity goes away (Dart `LiveActivityDismissal`).
public enum LiveActivityDismissal: Equatable {
    /// The system's: iOS keeps it up to 4 hours; elsewhere it stays.
    case system
    case immediate
    case at(Date)

    /// From its wire value: `default`, `immediate` or milliseconds (UTC). Nil
    /// for anything else.
    public static func parse(_ value: Any?) -> LiveActivityDismissal? {
        if value == nil || value is NSNull { return .system }
        if let text = value as? String {
            switch text {
            case LiveActivityKeys.dismissalDefault: return .system
            case LiveActivityKeys.dismissalImmediate: return .immediate
            default: return nil
            }
        }
        if value is Bool { return nil }
        if let number = value as? NSNumber {
            return .at(Date(timeIntervalSince1970: number.doubleValue / 1000))
        }
        return nil
    }

    public var wireValue: Any {
        switch self {
        case .system: return LiveActivityKeys.dismissalDefault
        case .immediate: return LiveActivityKeys.dismissalImmediate
        case .at(let date): return Int((date.timeIntervalSince1970 * 1000).rounded())
        }
    }
}

/// A part of the progress bar.
public struct LiveActivitySegment: Equatable {
    public var length: Int
    public var color: Int?
}

/// A mark on the progress bar.
public struct LiveActivityPoint: Equatable {
    public var position: Int
    public var color: Int?
}

/// How the progress bar looks.
public struct LiveActivityProgress: Equatable {
    public var segments: [LiveActivitySegment] = []
    public var points: [LiveActivityPoint] = []
    public var trackerIcon: String?
    public var startIcon: String?
    public var endIcon: String?

    /// The segments' total length (100 without segments).
    public var total: Int {
        segments.isEmpty ? 100 : segments.reduce(0) { $0 + $1.length }
    }
}

/// A system-driven clock (milliseconds since the epoch, UTC).
public struct LiveActivityTimer: Equatable {
    public var start: Double?
    public var end: Double?
    public var countDown: Bool
}

/// A labeled value.
public struct LiveActivityMetric: Equatable {
    public var label: String
    public var value: String
    public var unit: String?
    /// The side's picture in the versus layout.
    public var image: String? = nil
}

/// The `liveActivity` block of a notification model.
public struct NotificationLiveActivity: Equatable {
    /// The app's id, else the notification id.
    public var activityId: String
    public var state: LiveActivityState = .active
    public var progress: LiveActivityProgress?
    public var timer: LiveActivityTimer?
    public var metrics: [LiveActivityMetric] = []
    /// Drawn as a scoreboard (`LiveActivityLayout.versus`).
    public var versus = false
    /// The app's own layout name, drawn by the app's widget.
    public var customLayout: String?
    public var shortText: String?
    public var accentColor: Int?
    /// Milliseconds since the epoch (UTC).
    public var staleAt: Double?
    public var relevance: Double?
    public var alert = false
    public var dismissal: LiveActivityDismissal = .system
    public var pushChannel: String?

    public var staleDate: Date? { staleAt.map { Date(timeIntervalSince1970: $0 / 1000) } }

    /// Parses and validates a block (the Dart model's rules, checked again);
    /// [notificationId] is the default activityId. Returns the error message
    /// when the block is invalid.
    public static func parse(_ block: Any?, notificationId: Int?) -> (NotificationLiveActivity?, String?) {
        guard let map = block as? [String: Any] else { return (nil, "The liveActivity block must be a map") }
        func value(_ key: String) -> Any? {
            let raw = map[key]
            return raw is NSNull ? nil : raw
        }
        func string(_ key: String) -> (String?, Bool) {
            guard let raw = value(key) else { return (nil, true) }
            guard let text = raw as? String else { return (nil, false) }
            return (text, true)
        }
        func number(_ raw: Any?) -> Double? {
            guard let raw = raw, !(raw is NSNull), !(raw is Bool), let number = raw as? NSNumber else { return nil }
            return number.doubleValue
        }
        func int(_ raw: Any?) -> Int? { number(raw).map { Int($0) } }

        let (ownId, idOk) = string(LiveActivityKeys.activityId)
        guard idOk else { return (nil, "The live activity's activityId must be a string") }
        let activityId: String
        if let ownId = ownId {
            guard !ownId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return (nil, "The live activity's activityId can't be empty (leave it out to use the notification id)")
            }
            activityId = ownId
        } else {
            guard let id = notificationId else { return (nil, "A live activity needs a notification id") }
            activityId = String(id)
        }
        var activity = NotificationLiveActivity(activityId: activityId)

        if let raw = value(LiveActivityKeys.state) {
            guard let name = raw as? String, let state = LiveActivityState(rawValue: name) else {
                return (nil, "Unknown live activity state: \(raw)")
            }
            activity.state = state
        }

        if let raw = value(LiveActivityKeys.progress) {
            guard let progressMap = raw as? [String: Any] else { return (nil, "The live activity's progress must be a map") }
            var progress = LiveActivityProgress()
            for item in (progressMap[LiveActivityKeys.segments] as? [Any]) ?? [] {
                guard let segment = item as? [String: Any], let length = int(segment[LiveActivityKeys.length]) else {
                    return (nil, "A live activity segment needs a length")
                }
                guard length > 0 else { return (nil, "A live activity segment needs a positive length") }
                progress.segments.append(LiveActivitySegment(length: length, color: int(segment[LiveActivityKeys.color])))
            }
            for item in (progressMap[LiveActivityKeys.points] as? [Any]) ?? [] {
                guard let point = item as? [String: Any], let position = int(point[LiveActivityKeys.position]) else {
                    return (nil, "A live activity point needs a position")
                }
                guard position >= 0, position <= progress.total else {
                    return (nil, "A live activity point must sit within the segments (0 to \(progress.total))")
                }
                progress.points.append(LiveActivityPoint(position: position, color: int(point[LiveActivityKeys.color])))
            }
            progress.trackerIcon = progressMap[LiveActivityKeys.trackerIcon] as? String
            progress.startIcon = progressMap[LiveActivityKeys.startIcon] as? String
            progress.endIcon = progressMap[LiveActivityKeys.endIcon] as? String
            activity.progress = progress
        }

        if let raw = value(LiveActivityKeys.timer) {
            guard let timerMap = raw as? [String: Any] else { return (nil, "The live activity's timer must be a map") }
            let start = number(timerMap[LiveActivityKeys.start])
            let end = number(timerMap[LiveActivityKeys.end])
            let countDown = (timerMap[LiveActivityKeys.countDown] as? Bool) ?? (end != nil)
            if countDown, end == nil { return (nil, "A live activity countdown needs an end") }
            if !countDown, start == nil { return (nil, "A live activity elapsed timer needs a start") }
            if let start = start, let end = end, end <= start {
                return (nil, "A live activity countdown must end after it starts")
            }
            activity.timer = LiveActivityTimer(start: start, end: end, countDown: countDown)
        }

        if let raw = value(LiveActivityKeys.metrics) {
            guard let list = raw as? [Any] else { return (nil, "The live activity's metrics must be a list") }
            guard list.count <= 3 else { return (nil, "A live activity has at most 3 metrics") }
            for item in list {
                guard let metric = item as? [String: Any],
                      let label = metric[LiveActivityKeys.label] as? String,
                      !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    return (nil, "A live activity metric needs a label")
                }
                let metricValue = (metric[LiveActivityKeys.value] as? String)
                    ?? number(metric[LiveActivityKeys.value]).map { String($0) } ?? ""
                activity.metrics.append(LiveActivityMetric(
                    label: label, value: metricValue, unit: metric[LiveActivityKeys.unit] as? String,
                    image: metric[LiveActivityKeys.image] as? String))
            }
        }

        if let raw = value(LiveActivityKeys.layout) {
            guard let name = raw as? String, name == "standard" || name == LiveActivityKeys.layoutVersus else {
                return (nil, "Unknown live activity layout: \(raw)")
            }
            activity.versus = name == LiveActivityKeys.layoutVersus
            if activity.versus, activity.metrics.count != 2 {
                return (nil, "A versus live activity needs exactly 2 metrics, one per side")
            }
        }

        let (customLayout, customOk) = string(LiveActivityKeys.customLayout)
        guard customOk, customLayout.map({ $0.range(of: "^[a-z][a-z0-9_]*$", options: .regularExpression) != nil }) ?? true
        else {
            return (nil, "The live activity's customLayout must be a resource name: lowercase letters, digits and _")
        }
        activity.customLayout = customLayout

        let (shortText, shortOk) = string(LiveActivityKeys.shortText)
        guard shortOk else { return (nil, "The live activity's shortText must be a string") }
        if let text = shortText, text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return (nil, "The live activity's shortText can't be empty")
        }
        activity.shortText = shortText

        let (channel, channelOk) = string(LiveActivityKeys.pushChannel)
        guard channelOk else { return (nil, "The live activity's pushChannel must be a string") }
        if let channel = channel, channel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return (nil, "The live activity's pushChannel can't be empty")
        }
        activity.pushChannel = channel

        activity.accentColor = int(value(LiveActivityKeys.accentColor))
        activity.staleAt = number(value(LiveActivityKeys.staleAt))
        activity.relevance = number(value(LiveActivityKeys.relevance))
        activity.alert = (value(LiveActivityKeys.alert) as? Bool) ?? false
        guard let dismissal = LiveActivityDismissal.parse(value(LiveActivityKeys.dismissal)) else {
            return (nil, "Unknown live activity dismissal: \(value(LiveActivityKeys.dismissal) ?? "")")
        }
        activity.dismissal = dismissal
        return (activity, nil)
    }
}
