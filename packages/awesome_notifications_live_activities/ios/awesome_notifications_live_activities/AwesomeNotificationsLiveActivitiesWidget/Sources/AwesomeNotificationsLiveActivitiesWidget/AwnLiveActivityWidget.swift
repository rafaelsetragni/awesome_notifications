#if os(iOS) && canImport(ActivityKit) && canImport(WidgetKit)
import ActivityKit
import SwiftUI
import WidgetKit
#if canImport(AppIntents)
import AppIntents
#endif

/// The Live Activity of awesome_notifications_live_activities: add it to the
/// app's Widget Extension, as the only line of its `WidgetBundle`:
///
/// ```swift
/// import AwesomeNotificationsLiveActivitiesWidget
/// import SwiftUI
/// import WidgetKit
///
/// @main
/// struct LiveActivityBundle: WidgetBundle {
///     var body: some Widget { AwnLiveActivityWidget() }
/// }
/// ```
///
/// It draws the notification's title, body, large icon, progress, timer,
/// metrics and buttons on the Lock Screen and in the Dynamic Island.
@available(iOS 16.1, *)
public struct AwnLiveActivityWidget: Widget {

    public init() {}

    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: AwnLiveActivityAttributes.self) { context in
            AwnLiveActivityWidget.lockScreen(context)
        } dynamicIsland: { context in
            AwnLiveActivityWidget.dynamicIsland(context)
        }
    }

    /// The package's Lock Screen view of an activity: an app's own widget
    /// calls it for the activities it doesn't draw itself.
    @ViewBuilder
    public static func lockScreen(_ context: ActivityViewContext<AwnLiveActivityAttributes>) -> some View {
        Group {
            if context.state.isVersus {
                AwnVersusLockScreenView(attributes: context.attributes, state: context.state,
                                        stale: AwnLiveActivityWidget.isStale(context))
            } else {
                AwnLockScreenView(attributes: context.attributes, state: context.state,
                                  stale: AwnLiveActivityWidget.isStale(context))
            }
        }
        .activitySystemActionForegroundColor(AwnColors.accent(context.state))
    }

    /// The package's Dynamic Island of an activity: an app's own widget
    /// returns it for the activities it doesn't draw itself.
    public static func dynamicIsland(_ context: ActivityViewContext<AwnLiveActivityAttributes>) -> DynamicIsland {

            let state = context.state
            let attributes = context.attributes
            let accent = AwnColors.accent(state)
            if state.isVersus {
                return AwnLiveActivityWidget.versusIsland(attributes: attributes, state: state)
            }
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    // Only a picture: a placeholder would narrow the title.
                    if AwnImage.exists(state.largeIcon, appGroup: attributes.appGroup) {
                        AwnLeadingIcon(attributes: attributes, state: state, size: 40)
                            .padding(.leading, 4)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    AwnTrailingText(state: state, font: .headline)
                        .foregroundColor(accent)
                        .minimumScaleFactor(0.6)
                        .frame(minWidth: 64, maxWidth: 96, alignment: .trailing)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        if let title = state.title {
                            Text(title).font(.headline).lineLimit(1)
                        }
                        if let body = state.body {
                            Text(body).font(.subheadline).foregroundColor(.secondary).lineLimit(2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        AwnProgressView(attributes: attributes, state: state)
                        AwnMetricsView(state: state, compact: true)
                        AwnButtonsView(attributes: attributes, state: state, compact: true)
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                AwnLeadingIcon(attributes: attributes, state: state, size: 24)
            } compactTrailing: {
                AwnTrailingText(state: state, font: .caption, shortTextFirst: true)
                    .foregroundColor(accent)
                    .frame(maxWidth: 52)
            } minimal: {
                AwnMinimalView(attributes: attributes, state: state)
            }
            .keylineTint(accent)
    }

    /// The scoreboard in the Dynamic Island: each side's picture and value
    /// at its end, the short text and the clock in the middle, the body below.
    static func versusIsland(attributes: AwnLiveActivityAttributes, state: AwnLiveActivityState) -> DynamicIsland {
        let accent = AwnColors.accent(state)
        let metrics = state.metrics ?? []
        let left = metrics[0], right = metrics[1]
        return DynamicIsland {
            DynamicIslandExpandedRegion(.leading) {
                AwnVersusSide(attributes: attributes, metric: left, trailing: false, logo: 36, score: .title)
                    .padding(.leading, 4)
            }
            DynamicIslandExpandedRegion(.trailing) {
                AwnVersusSide(attributes: attributes, metric: right, trailing: true, logo: 36, score: .title)
                    .padding(.trailing, 4)
            }
            DynamicIslandExpandedRegion(.center) {
                AwnVersusCenter(state: state)
            }
            DynamicIslandExpandedRegion(.bottom) {
                VStack(spacing: 6) {
                    if let body = state.body {
                        Text(body).font(.caption).foregroundColor(.secondary).lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    AwnButtonsView(attributes: attributes, state: state, compact: true)
                }
                .padding(.horizontal, 4)
            }
        } compactLeading: {
            AwnVersusCompact(attributes: attributes, metric: left, trailing: false)
        } compactTrailing: {
            AwnVersusCompact(attributes: attributes, metric: right, trailing: true)
        } minimal: {
            Text("\(left.value)-\(right.value)")
                .font(.caption2.monospacedDigit()).fontWeight(.bold)
                .minimumScaleFactor(0.5).lineLimit(1)
                .foregroundColor(accent)
        }
        .keylineTint(accent)
    }

    static func isStale(_ context: ActivityViewContext<AwnLiveActivityAttributes>) -> Bool {
        if #available(iOS 16.2, *) { return context.isStale }
        return false
    }
}

// MARK: - Colors and images

@available(iOS 16.1, *)
public enum AwnColors {
    /// An ARGB integer as a color.
    public static func color(_ argb: Int?) -> Color? {
        guard let argb = argb else { return nil }
        let value = UInt32(truncatingIfNeeded: argb)
        return Color(.sRGB,
                     red: Double((value >> 16) & 0xFF) / 255,
                     green: Double((value >> 8) & 0xFF) / 255,
                     blue: Double(value & 0xFF) / 255,
                     opacity: Double((value >> 24) & 0xFF) / 255)
    }

    /// The activity's accent color (the app's accent color without one).
    public static func accent(_ state: AwnLiveActivityState) -> Color {
        color(state.accentColor) ?? .accentColor
    }
}

/// An image of the activity (`largeIcon`, a metric's `image`, the progress
/// icons), from the App Group: `AwnImage(name: state.largeIcon, appGroup:
/// context.attributes.appGroup)`.
@available(iOS 16.1, *)
public struct AwnImage: View {
    let name: String?
    let appGroup: String?
    /// The small copy (the compact and minimal Dynamic Island draw nothing
    /// from an image larger than they are).
    var small = false

    public init(name: String?, appGroup: String?, small: Bool = false) {
        self.name = name
        self.appGroup = appGroup
        self.small = small
    }

    public var body: some View {
        if let file = AwnLiveActivityImages.file(small ? AwnLiveActivityImages.smallName(name) : name,
                                                 appGroup: appGroup),
           let image = UIImage(contentsOfFile: file.path) {
            Image(uiImage: image).resizable().aspectRatio(contentMode: .fit)
        }
    }

    public static func exists(_ name: String?, appGroup: String?) -> Bool {
        guard let file = AwnLiveActivityImages.file(name, appGroup: appGroup) else { return false }
        return FileManager.default.fileExists(atPath: file.path)
    }
}

// MARK: - Lock Screen

@available(iOS 16.1, *)
struct AwnLockScreenView: View {
    let attributes: AwnLiveActivityAttributes
    let state: AwnLiveActivityState
    let stale: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                if AwnImage.exists(state.largeIcon, appGroup: attributes.appGroup) {
                    AwnImage(name: state.largeIcon, appGroup: attributes.appGroup)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                VStack(alignment: .leading, spacing: 2) {
                    if let title = state.title {
                        Text(title).font(.headline).lineLimit(2)
                    }
                    if let body = state.body {
                        Text(body).font(.subheadline).foregroundColor(.secondary).lineLimit(2)
                    }
                }
                Spacer(minLength: 0)
                AwnTrailingText(state: state, font: .title2)
                    .foregroundColor(AwnColors.accent(state))
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: 100, alignment: .trailing)
            }
            AwnProgressView(attributes: attributes, state: state)
            AwnMetricsView(state: state, compact: false)
            AwnButtonsView(attributes: attributes, state: state)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .opacity(stale ? 0.6 : 1)
    }
}

// MARK: - Versus (scoreboard)

/// Two sides facing each other: each side's picture at its end, its label
/// over its value; the short text and the clock in one line between them;
/// the body (the latest play) below, in a card beside the large icon, with
/// the accent color as a bar.
@available(iOS 16.1, *)
struct AwnVersusLockScreenView: View {
    let attributes: AwnLiveActivityAttributes
    let state: AwnLiveActivityState
    let stale: Bool

    var body: some View {
        let metrics = state.metrics ?? []
        // The Lock Screen gives an activity 160 pt: the scoreboard, two lines
        // of play and a row of small buttons fit.
        VStack(spacing: 8) {
            HStack(alignment: .center, spacing: 0) {
                AwnVersusSide(attributes: attributes, metric: metrics[0], trailing: false, logo: 36,
                              score: .system(size: 32, weight: .medium))
                Spacer(minLength: 8)
                AwnVersusCenter(state: state)
                Spacer(minLength: 8)
                AwnVersusSide(attributes: attributes, metric: metrics[1], trailing: true, logo: 36,
                              score: .system(size: 32, weight: .medium))
            }
            if let body = state.body {
                HStack(alignment: .center, spacing: 12) {
                    if AwnImage.exists(state.largeIcon, appGroup: attributes.appGroup) {
                        AwnImage(name: state.largeIcon, appGroup: attributes.appGroup)
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    }
                    Text(body).font(.footnote).lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    RoundedRectangle(cornerRadius: 2).fill(AwnColors.accent(state))
                        .frame(width: 4, height: 24)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.primary.opacity(0.1)))
            }
            AwnButtonsView(attributes: attributes, state: state, compact: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .opacity(stale ? 0.6 : 1)
    }
}

/// One side: its picture at the outer end, its label centered over its value.
@available(iOS 16.1, *)
struct AwnVersusSide: View {
    let attributes: AwnLiveActivityAttributes
    let metric: AwnLiveActivityState.Metric
    let trailing: Bool
    let logo: CGFloat
    let score: Font

    var body: some View {
        HStack(spacing: 16) {
            if !trailing { picture }
            VStack(alignment: .center, spacing: 0) {
                Text(metric.label).font(.caption2).fontWeight(.semibold).lineLimit(1)
                Text(metric.value).font(score.monospacedDigit()).lineLimit(1).minimumScaleFactor(0.5)
            }
            if trailing { picture }
        }
    }

    @ViewBuilder private var picture: some View {
        if AwnImage.exists(metric.image, appGroup: attributes.appGroup) {
            AwnImage(name: metric.image, appGroup: attributes.appGroup)
                .frame(width: logo, height: logo)
                .clipShape(RoundedRectangle(cornerRadius: logo / 4, style: .continuous))
        }
    }
}

/// The middle, in one line: the short text (the period), then the clock.
@available(iOS 16.1, *)
struct AwnVersusCenter: View {
    let state: AwnLiveActivityState

    var body: some View {
        HStack(spacing: 4) {
            if let text = state.shortText {
                Text(text).fontWeight(.semibold)
            }
            if state.ended != true, let timer = AwnTimerText(state: state) {
                timer.monospacedDigit().foregroundColor(.secondary)
                    .frame(maxWidth: 48)
            }
        }
        .font(.footnote)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
}

/// A side in the compact Dynamic Island: its small picture and its value.
@available(iOS 16.1, *)
struct AwnVersusCompact: View {
    let attributes: AwnLiveActivityAttributes
    let metric: AwnLiveActivityState.Metric
    let trailing: Bool

    var body: some View {
        HStack(spacing: 4) {
            if !trailing { picture }
            Text(metric.value).font(.caption.monospacedDigit()).fontWeight(.bold).lineLimit(1)
            if trailing { picture }
        }
    }

    @ViewBuilder private var picture: some View {
        if AwnImage.exists(metric.image, appGroup: attributes.appGroup) {
            AwnImage(name: metric.image, appGroup: attributes.appGroup, small: true)
                .frame(width: 20, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        } else {
            Text(metric.label).font(.caption2).foregroundColor(.secondary).lineLimit(1)
        }
    }
}

// MARK: - Pieces

/// The timer, else the short text, else the progress in percent.
@available(iOS 16.1, *)
struct AwnTrailingText: View {
    let state: AwnLiveActivityState
    let font: Font
    /// The compact Dynamic Island: the short text first (it is made for it).
    var shortTextFirst = false

    var body: some View {
        if shortTextFirst, let text = state.shortText {
            Text(text).font(font).fontWeight(.semibold).lineLimit(1)
        } else if state.ended != true, let timer = AwnTimerText(state: state) {
            timer.font(font.monospacedDigit()).multilineTextAlignment(.trailing).lineLimit(1)
        } else if let text = state.shortText {
            Text(text).font(font).fontWeight(.semibold).lineLimit(1)
        } else if let fraction = state.fraction {
            Text("\(Int((fraction * 100).rounded()))%").font(font.monospacedDigit()).lineLimit(1)
        }
    }
}

/// The system-driven clock: a countdown to the end, or the time since the
/// start (nil without a timer).
@available(iOS 16.1, *)
public func AwnTimerText(state: AwnLiveActivityState) -> Text? {
    if state.countDown == true || (state.timerEnd != nil && state.countDown != false) {
        guard let end = state.timerEndDate else { return nil }
        let start = min(state.timerStartDate ?? Date(), end)
        return Text(timerInterval: start...end, countsDown: true)
    }
    guard let start = state.timerStartDate else { return nil }
    return Text(start, style: .timer)
}

/// The large icon, else the progress ring, else the accent dot.
@available(iOS 16.1, *)
struct AwnLeadingIcon: View {
    let attributes: AwnLiveActivityAttributes
    let state: AwnLiveActivityState
    let size: CGFloat

    var body: some View {
        if AwnImage.exists(state.largeIcon, appGroup: attributes.appGroup) {
            AwnImage(name: state.largeIcon, appGroup: attributes.appGroup, small: size < 32)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size / 4, style: .continuous))
        } else if state.bar == true || state.fraction != nil {
            AwnRing(state: state).frame(width: size * 0.8, height: size * 0.8)
        } else {
            Circle().fill(AwnColors.accent(state)).frame(width: size / 2, height: size / 2)
        }
    }
}

@available(iOS 16.1, *)
struct AwnRing: View {
    let state: AwnLiveActivityState

    var body: some View {
        let accent = AwnColors.accent(state)
        ZStack {
            Circle().stroke(accent.opacity(0.3), lineWidth: 3)
            Circle()
                .trim(from: 0, to: CGFloat(state.fraction ?? 0))
                .stroke(accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

@available(iOS 16.1, *)
struct AwnMinimalView: View {
    let attributes: AwnLiveActivityAttributes
    let state: AwnLiveActivityState

    var body: some View {
        if state.bar == true || state.fraction != nil {
            AwnRing(state: state).padding(2)
        } else {
            AwnLeadingIcon(attributes: attributes, state: state, size: 22)
        }
    }
}

/// The progress bar: segments in their colors, points, the tracker icon at
/// the value, and the start / end icons. Driven by the timer when there is no
/// value and the timer has a start and an end.
@available(iOS 16.1, *)
public struct AwnProgressView: View {
    let attributes: AwnLiveActivityAttributes
    let state: AwnLiveActivityState

    public init(attributes: AwnLiveActivityAttributes, state: AwnLiveActivityState) {
        self.attributes = attributes
        self.state = state
    }

    public var body: some View {
        let accent = AwnColors.accent(state)
        if state.progress == nil, state.ended != true,
           let start = state.timerStartDate, let end = state.timerEndDate, end > start {
            ProgressView(timerInterval: start...end, countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .tint(accent)
        } else if state.bar == true || state.progress != nil {
            HStack(spacing: 8) {
                if AwnImage.exists(state.startIcon, appGroup: attributes.appGroup) {
                    AwnImage(name: state.startIcon, appGroup: attributes.appGroup).frame(width: 20, height: 20)
                }
                AwnTrack(attributes: attributes, state: state, accent: accent)
                if AwnImage.exists(state.endIcon, appGroup: attributes.appGroup) {
                    AwnImage(name: state.endIcon, appGroup: attributes.appGroup).frame(width: 20, height: 20)
                }
            }
        }
    }
}

@available(iOS 16.1, *)
struct AwnTrack: View {
    let attributes: AwnLiveActivityAttributes
    let state: AwnLiveActivityState
    let accent: Color

    private var hasTracker: Bool { AwnImage.exists(state.trackerIcon, appGroup: attributes.appGroup) }

    var body: some View {
        let total = CGFloat(state.totalLength)
        let segments = (state.segments ?? []).filter { $0.length > 0 }
        let fraction = CGFloat(state.fraction ?? 0)
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            ZStack(alignment: .leading) {
                bar(segments: segments, total: total, width: width, dimmed: true)
                bar(segments: segments, total: total, width: width, dimmed: false)
                    .mask(alignment: .leading) {
                        Rectangle().frame(width: width * fraction)
                    }
                ForEach(Array((state.points ?? []).enumerated()), id: \.offset) { _, point in
                    Circle()
                        .fill(AwnColors.color(point.color) ?? Color.white)
                        .overlay(Circle().stroke(accent, lineWidth: 1.5))
                        .frame(width: 8, height: 8)
                        .position(x: width * CGFloat(point.position) / total, y: height / 2)
                }
                if hasTracker, state.progress != nil {
                    AwnImage(name: state.trackerIcon, appGroup: attributes.appGroup)
                        .frame(width: 20, height: 20)
                        .position(x: min(max(width * fraction, 10), width - 10), y: height / 2)
                }
            }
        }
        .frame(height: hasTracker ? 20 : 8)
    }

    @ViewBuilder
    private func bar(segments: [AwnLiveActivityState.Segment], total: CGFloat, width: CGFloat,
                     dimmed: Bool) -> some View {
        if segments.isEmpty {
            Capsule().fill(dimmed ? accent.opacity(0.25) : accent).frame(height: 6)
        } else {
            let spacing: CGFloat = 2
            let usable = max(width - spacing * CGFloat(segments.count - 1), 0)
            HStack(spacing: spacing) {
                ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                    let color = AwnColors.color(segment.color) ?? accent
                    Capsule()
                        .fill(dimmed ? color.opacity(0.25) : color)
                        .frame(width: usable * CGFloat(segment.length) / total, height: 6)
                }
            }
        }
    }
}

@available(iOS 16.1, *)
struct AwnMetricsView: View {
    let state: AwnLiveActivityState
    let compact: Bool

    var body: some View {
        let metrics = Array((state.metrics ?? []).prefix(3))
        if !metrics.isEmpty, compact {
            // One line: "42 km/h Speed · 2 Stops".
            Text(metrics.map { metric in
                [metric.value, metric.unit ?? "", metric.label].filter { !$0.isEmpty }.joined(separator: " ")
            }.joined(separator: " · "))
            .font(.caption.monospacedDigit())
            .foregroundColor(.secondary)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if !metrics.isEmpty {
            HStack(alignment: .top, spacing: 12) {
                ForEach(Array(metrics.enumerated()), id: \.offset) { _, metric in
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(metric.value)
                                .font((compact ? Font.subheadline : Font.title3).monospacedDigit())
                                .fontWeight(.semibold)
                            if let unit = metric.unit {
                                Text(unit).font(.caption).foregroundColor(.secondary)
                            }
                        }
                        .lineLimit(1)
                        Text(metric.label).font(.caption2).foregroundColor(.secondary).lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

/// The notification's buttons (iOS 17+, App Intents run in the app): they
/// reach `onActionReceivedMethod` like any notification button.
@available(iOS 16.1, *)
public struct AwnButtonsView: View {
    let attributes: AwnLiveActivityAttributes
    let state: AwnLiveActivityState
    var compact = false

    public init(attributes: AwnLiveActivityAttributes, state: AwnLiveActivityState, compact: Bool = false) {
        self.attributes = attributes
        self.state = state
        self.compact = compact
    }

    public var body: some View {
        if #available(iOS 17.0, *), state.ended != true, let buttons = state.buttons, !buttons.isEmpty {
            HStack(spacing: 8) {
                ForEach(Array(buttons.prefix(3).enumerated()), id: \.offset) { _, button in
                    AwnButton(activityId: attributes.activityId, button: button,
                              accent: AwnColors.accent(state), compact: compact)
                }
            }
        }
    }
}

@available(iOS 17.0, *)
struct AwnButton: View {
    let activityId: String
    let button: AwnLiveActivityState.Button
    let accent: Color
    var compact = false

    var body: some View {
        let color: Color = button.destructive == true ? .red : accent
        if button.openApp == true {
            Button(intent: AwnLiveActivityOpenAppIntent(activityId: activityId, buttonKey: button.key)) {
                label
            }
            .buttonStyle(.borderedProminent)
            .controlSize(compact ? .small : .regular)
            .tint(color)
        } else {
            Button(intent: AwnLiveActivityButtonIntent(activityId: activityId, buttonKey: button.key)) {
                label
            }
            .buttonStyle(.bordered)
            .controlSize(compact ? .small : .regular)
            .tint(color)
        }
    }

    private var label: some View {
        Text(button.label).font(compact ? .caption : .subheadline).fontWeight(.semibold).lineLimit(1)
            .frame(maxWidth: .infinity)
    }
}
#endif
