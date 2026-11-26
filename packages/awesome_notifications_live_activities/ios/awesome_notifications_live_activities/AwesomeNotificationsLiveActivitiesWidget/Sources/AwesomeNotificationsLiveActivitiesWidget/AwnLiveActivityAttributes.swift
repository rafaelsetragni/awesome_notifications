import Foundation
#if os(iOS) && canImport(ActivityKit)
import ActivityKit
#endif

/// The fixed part of an awesome live activity: which activity it is and the
/// App Group whose container holds its images. Shared by the app (which starts
/// the activity) and its Widget Extension (which draws it).
public struct AwnLiveActivityAttributes: Codable, Hashable {
    public typealias ContentState = AwnLiveActivityState

    /// The app's activityId (the notification id when the app set none).
    public var activityId: String
    /// The App Group of the images (nil: the activity has no images).
    public var appGroup: String?

    public init(activityId: String, appGroup: String? = nil) {
        self.activityId = activityId
        self.appGroup = appGroup
    }
}

#if os(iOS) && canImport(ActivityKit)
@available(iOS 16.1, *)
extension AwnLiveActivityAttributes: ActivityAttributes {}
#endif

/// What an activity shows now: the notification's layout, in compact fields
/// (ActivityKit limits an update to 4 KB). A push that updates the activity
/// sends this same JSON as its `content-state`. Dates are milliseconds since
/// the epoch (UTC), colors ARGB integers, images file names in the App Group's
/// `AwnLiveActivities` folder.
public struct AwnLiveActivityState: Codable, Hashable {

    /// A part of the progress bar.
    public struct Segment: Codable, Hashable {
        public var length: Int
        public var color: Int?
        public init(length: Int, color: Int? = nil) {
            self.length = length
            self.color = color
        }
    }

    /// A mark on the progress bar, within the segments' total length.
    public struct Point: Codable, Hashable {
        public var position: Int
        public var color: Int?
        public init(position: Int, color: Int? = nil) {
            self.position = position
            self.color = color
        }
    }

    /// A labeled value.
    public struct Metric: Codable, Hashable {
        public var label: String
        public var value: String
        public var unit: String?
        public init(label: String, value: String, unit: String? = nil) {
            self.label = label
            self.value = value
            self.unit = unit
        }
    }

    /// One of the notification's action buttons.
    public struct Button: Codable, Hashable {
        public var key: String
        public var label: String
        /// The button opens the app (its action type is `Default`).
        public var openApp: Bool?
        /// Drawn in red (`isDangerousOption`).
        public var destructive: Bool?
        public init(key: String, label: String, openApp: Bool? = nil, destructive: Bool? = nil) {
            self.key = key
            self.label = label
            self.openApp = openApp
            self.destructive = destructive
        }
    }

    public var title: String?
    public var body: String?
    /// 0 to 100; nil with [bar] true: indeterminate.
    public var progress: Double?
    /// The activity has a progress bar.
    public var bar: Bool?
    public var segments: [Segment]?
    public var points: [Point]?
    public var trackerIcon: String?
    public var startIcon: String?
    public var endIcon: String?
    public var largeIcon: String?
    /// Milliseconds since the epoch (UTC).
    public var timerStart: Double?
    public var timerEnd: Double?
    public var countDown: Bool?
    public var metrics: [Metric]?
    public var shortText: String?
    /// ARGB.
    public var accentColor: Int?
    public var buttons: [Button]?
    /// The activity is over (its final content).
    public var ended: Bool?

    public init(
        title: String? = nil, body: String? = nil, progress: Double? = nil, bar: Bool? = nil,
        segments: [Segment]? = nil, points: [Point]? = nil, trackerIcon: String? = nil,
        startIcon: String? = nil, endIcon: String? = nil, largeIcon: String? = nil,
        timerStart: Double? = nil, timerEnd: Double? = nil, countDown: Bool? = nil,
        metrics: [Metric]? = nil, shortText: String? = nil, accentColor: Int? = nil,
        buttons: [Button]? = nil, ended: Bool? = nil
    ) {
        self.title = title
        self.body = body
        self.progress = progress
        self.bar = bar
        self.segments = segments
        self.points = points
        self.trackerIcon = trackerIcon
        self.startIcon = startIcon
        self.endIcon = endIcon
        self.largeIcon = largeIcon
        self.timerStart = timerStart
        self.timerEnd = timerEnd
        self.countDown = countDown
        self.metrics = metrics
        self.shortText = shortText
        self.accentColor = accentColor
        self.buttons = buttons
        self.ended = ended
    }

    /// The timer's start / end as dates.
    public var timerStartDate: Date? { timerStart.map { Date(timeIntervalSince1970: $0 / 1000) } }
    public var timerEndDate: Date? { timerEnd.map { Date(timeIntervalSince1970: $0 / 1000) } }

    /// The total length of the segments (100 without segments).
    public var totalLength: Int {
        let total = (segments ?? []).reduce(0) { $0 + max($1.length, 0) }
        return total > 0 ? total : 100
    }

    /// The progress as a fraction (0 to 1), nil when indeterminate.
    public var fraction: Double? {
        guard let progress = progress else { return nil }
        return min(max(progress / 100, 0), 1)
    }
}

/// Where the images of the activities live: the App Group container's
/// `AwnLiveActivities` folder.
public enum AwnLiveActivityImages {
    public static let folder = "AwnLiveActivities"

    /// The folder in [appGroup]'s container (nil without access to it).
    public static func directory(appGroup: String?) -> URL? {
        guard let group = appGroup, !group.isEmpty,
              let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)
        else { return nil }
        return container.appendingPathComponent(folder, isDirectory: true)
    }

    /// The name of an image's small copy (for the compact Dynamic Island).
    public static func smallName(_ name: String?) -> String? {
        guard let name = name, name.hasSuffix(".png") else { return name }
        return String(name.dropLast(4)) + "-small.png"
    }

    /// The file of an image name, in [appGroup]'s folder.
    public static func file(_ name: String?, appGroup: String?) -> URL? {
        guard let name = name, !name.isEmpty, !name.contains("/"),
              let directory = directory(appGroup: appGroup) else { return nil }
        return directory.appendingPathComponent(name)
    }
}
