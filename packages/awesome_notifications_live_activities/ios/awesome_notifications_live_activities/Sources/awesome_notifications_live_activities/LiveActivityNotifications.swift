import Foundation
import CryptoKit
import IosAwnCore
#if canImport(AwesomeNotificationsLiveActivitiesWidget)
import AwesomeNotificationsLiveActivitiesWidget
#endif

/// The models of the live activities (pure functions, no system call): the
/// validated model, the activity's content state and the notification shown
/// where there is no ActivityKit (macOS, iOS below 16.1).
public enum LiveActivityNotifications {

    /// A validated live activity model.
    public struct Prepared {
        public let activity: NotificationLiveActivity
        /// The model with the activityId in its payload (the core reports it
        /// in the created / displayed events).
        public let model: [String: Any]
        public let notificationId: Int?
    }

    static func invalid(_ message: String, _ detail: String) -> AwesomeNotificationsException {
        AwesomeNotificationsException(
            code: AwesomeNotificationsException.CODE_INVALID_ARGUMENTS,
            message: message,
            detailedCode: AwesomeNotificationsException.DETAILED_INVALID_ARGUMENTS + detail)
    }

    static func content(_ model: [String: Any]) -> [String: Any] {
        (model[Definitions.NOTIFICATION_CONTENT] as? [String: Any]) ?? [:]
    }

    private static func text(_ value: Any?) -> String? {
        guard let text = value as? String, !text.isEmpty else { return nil }
        return text
    }

    /// Validates a model. Nil when it has no `liveActivity` block. Throws the
    /// contract's refusals.
    public static func prepare(_ model: [String: Any]) throws -> Prepared? {
        guard let block = model[LiveActivityKeys.liveActivity], !(block is NSNull) else { return nil }
        if let schedule = model[LiveActivityKeys.schedule], !(schedule is NSNull) {
            throw invalid("Live activities can't be scheduled", LiveActivityKeys.invalidSchedule)
        }
        var content = self.content(model)
        let notificationId = MapUtils.shared.getInt(content[Definitions.NOTIFICATION_ID])
        let (parsed, error) = NotificationLiveActivity.parse(block, notificationId: notificationId)
        guard let activity = parsed else {
            throw invalid(error ?? "Invalid live activity", LiveActivityKeys.invalidLiveActivity)
        }
        var payload: [String: Any] = [:]
        for (key, value) in (content[Definitions.NOTIFICATION_PAYLOAD] as? [String: Any]) ?? [:] {
            payload[key] = value
        }
        payload[LiveActivityKeys.payloadActivityId] = activity.activityId
        content[Definitions.NOTIFICATION_PAYLOAD] = payload
        var prepared = model
        prepared[Definitions.NOTIFICATION_CONTENT] = content
        return Prepared(activity: activity, model: prepared, notificationId: notificationId)
    }

    /// The content's progress (0 to 100), nil when indeterminate.
    static func progressValue(_ model: [String: Any]) -> Double? {
        let raw = content(model)[LiveActivityKeys.contentProgress]
        guard let number = raw as? NSNumber, !(raw is Bool) else { return nil }
        return min(max(number.doubleValue, 0), 100)
    }

    // MARK: - ActivityKit (iOS)

    /// The activity's content state. [image] turns an image reference
    /// (`asset://`, `https://`…) into its file name in the App Group (nil
    /// when it can't).
    public static func contentState(_ prepared: Prepared,
                                    image: (String?) -> String? = { _ in nil }) -> AwnLiveActivityState {
        let activity = prepared.activity
        let content = self.content(prepared.model)
        let progress = progressValue(prepared.model)
        var state = AwnLiveActivityState()
        state.title = text(content[Definitions.NOTIFICATION_TITLE])
        state.body = text(content[Definitions.NOTIFICATION_BODY])
        state.progress = progress
        if activity.progress != nil || progress != nil { state.bar = true }
        if let bar = activity.progress {
            if !bar.segments.isEmpty {
                state.segments = bar.segments.map { .init(length: $0.length, color: $0.color) }
            }
            if !bar.points.isEmpty {
                state.points = bar.points.map { .init(position: $0.position, color: $0.color) }
            }
            state.trackerIcon = image(bar.trackerIcon)
            state.startIcon = image(bar.startIcon)
            state.endIcon = image(bar.endIcon)
        }
        state.largeIcon = image(text(content[Definitions.NOTIFICATION_LARGE_ICON]))
        if let timer = activity.timer {
            state.timerStart = timer.start
            state.timerEnd = timer.end
            state.countDown = timer.countDown
        }
        if !activity.metrics.isEmpty {
            state.metrics = activity.metrics.map {
                .init(label: $0.label, value: $0.value, unit: $0.unit, image: activity.versus || activity.customLayout != nil ? image($0.image) : nil)
            }
        }
        if activity.versus { state.layout = AwnLiveActivityState.layoutVersus }
        state.customLayout = activity.customLayout
        state.shortText = activity.shortText
        state.accentColor = activity.accentColor
        let buttons = buttonStates(prepared.model)
        if !buttons.isEmpty { state.buttons = buttons }
        if activity.state == .ended { state.ended = true }
        return state
    }

    /// The notification's enabled buttons, as the widget draws them.
    static func buttonStates(_ model: [String: Any]) -> [AwnLiveActivityState.Button] {
        let buttons = (model[Definitions.NOTIFICATION_BUTTONS] as? [[String: Any]]) ?? []
        return buttons.compactMap { button in
            guard let key = text(button[Definitions.NOTIFICATION_BUTTON_KEY]),
                  MapUtils.shared.getBool(button[Definitions.NOTIFICATION_BUTTON_ENABLED] ?? "") ?? true
            else { return nil }
            let label = text(button[Definitions.NOTIFICATION_BUTTON_LABEL]) ?? key
            let actionType = ActionType.from(MapUtils.shared.getString(button[Definitions.NOTIFICATION_ACTION_TYPE]))
            let dangerous = MapUtils.shared.getBool(button[Definitions.NOTIFICATION_IS_DANGEROUS_OPTION] ?? "") ?? false
            return .init(key: key, label: label,
                         openApp: actionType == .default ? true : nil,
                         destructive: dangerous ? true : nil)
        }
    }

    /// The bytes ActivityKit receives for an activity: its attributes and its
    /// content state, as JSON.
    public static func payloadSize(_ state: AwnLiveActivityState, _ attributes: AwnLiveActivityAttributes) -> Int {
        let encoder = JSONEncoder()
        let stateBytes = (try? encoder.encode(state))?.count ?? 0
        let attributesBytes = (try? encoder.encode(attributes))?.count ?? 0
        return stateBytes + attributesBytes
    }

    /// Refuses an activity over ActivityKit's 4 KB.
    public static func checkSize(_ state: AwnLiveActivityState, _ attributes: AwnLiveActivityAttributes) throws {
        let size = payloadSize(state, attributes)
        if size > LiveActivityKeys.maxPayloadBytes {
            throw invalid("The live activity's content is \(size) bytes, over the 4 KB iOS allows "
                          + "(shorten the texts or remove buttons / metrics)", LiveActivityKeys.invalidLiveActivity)
        }
    }

    /// The file name of an image in the App Group: the same for the same
    /// reference, so an update reuses it.
    public static func imageFileName(_ source: String) -> String {
        let digest = SHA256.hash(data: Data(source.utf8))
        return digest.prefix(12).map { String(format: "%02x", $0) }.joined() + ".png"
    }

    // MARK: - The notification (macOS, iOS below 16.1)

    /// The body with what a notification can't draw, as the web does: the
    /// progress (ten cells and the percentage) with the short text, the timer
    /// (when it ends or started) and the metrics. Absent parts are left out.
    public static func foldedBody(_ prepared: Prepared, timeFormatter: DateFormatter = defaultTimeFormatter())
        -> String {
        let activity = prepared.activity
        var lines: [String] = []
        if let body = text(content(prepared.model)[Definitions.NOTIFICATION_BODY]) { lines.append(body) }
        var status: [String] = []
        if let progress = progressValue(prepared.model) { status.append(progressLine(progress)) }
        if let shortText = activity.shortText { status.append(shortText) }
        if !status.isEmpty { lines.append(status.joined(separator: " · ")) }
        if let timer = activity.timer {
            if let end = timer.end {
                lines.append("Ends at " + timeFormatter.string(from: Date(timeIntervalSince1970: end / 1000)))
            } else if let start = timer.start {
                lines.append("Started at " + timeFormatter.string(from: Date(timeIntervalSince1970: start / 1000)))
            }
        }
        let metrics = activity.metrics.map { metric in
            [metric.label, metric.value, metric.unit ?? ""].filter { !$0.isEmpty }.joined(separator: " ")
        }
        if !metrics.isEmpty { lines.append(metrics.joined(separator: " · ")) }
        return lines.joined(separator: "\n")
    }

    /// Ten cells and the percentage: `▰▰▰▰▰▰▱▱▱▱ 60%`.
    public static func progressLine(_ progress: Double) -> String {
        let percent = Int(min(max(progress, 0), 100).rounded())
        let filled = Int((Double(percent) / 10).rounded())
        return String(repeating: "▰", count: filled) + String(repeating: "▱", count: 10 - filled) + " \(percent)%"
    }

    /// HH:mm in the device's time zone (as the web).
    public static func defaultTimeFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }

    /// The activity as a notification, replaced in place (same id): the body
    /// with the folded lines, sound only on the first post or an alerting
    /// update.
    public static func notificationModel(_ prepared: Prepared, firstPost: Bool,
                                         timeFormatter: DateFormatter = defaultTimeFormatter()) -> [String: Any] {
        var model = prepared.model
        var content = self.content(model)
        content[Definitions.NOTIFICATION_BODY] = foldedBody(prepared, timeFormatter: timeFormatter)
        if !(firstPost || prepared.activity.alert) {
            content[Definitions.NOTIFICATION_PLAY_SOUND] = false
        }
        model[Definitions.NOTIFICATION_CONTENT] = content
        return model
    }

    /// The model of an activity the app never sent (started by push): its
    /// activityId in the payload, its id from the activityId.
    public static func syntheticModel(activityId: String) -> [String: Any] {
        [Definitions.NOTIFICATION_CONTENT: [
            Definitions.NOTIFICATION_ID: Int(activityId) ?? javaHash(activityId),
            Definitions.NOTIFICATION_PAYLOAD: [LiveActivityKeys.payloadActivityId: activityId]
        ] as [String: Any]]
    }

    /// Java's `String.hashCode() & 0x7FFFFFFF` (same id on every platform).
    static func javaHash(_ text: String) -> Int {
        var hash: Int32 = 0
        for unit in text.utf16 { hash = 31 &* hash &+ Int32(unit) }
        return Int(hash & 0x7FFF_FFFF)
    }

    /// The notification id of a model.
    static func id(_ model: [String: Any]) -> Int? {
        MapUtils.shared.getInt(content(model)[Definitions.NOTIFICATION_ID])
    }

    /// Whether a removal (the core's dismiss / cancel) covers [model].
    public static func matches(_ removal: NotificationRemoval, model: [String: Any]) -> Bool {
        let content = self.content(model)
        switch removal {
        case .all: return true
        case .id(let id): return self.id(model) == id
        case .channelKey(let key): return content[Definitions.NOTIFICATION_CHANNEL_KEY] as? String == key
        case .groupKey(let key): return content[Definitions.NOTIFICATION_GROUP_KEY] as? String == key
        }
    }
}
