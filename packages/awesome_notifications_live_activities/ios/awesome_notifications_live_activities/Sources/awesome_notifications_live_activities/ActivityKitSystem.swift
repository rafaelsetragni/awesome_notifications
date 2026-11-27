#if os(iOS) && canImport(ActivityKit)
import Foundation
import ActivityKit
#if canImport(AwesomeNotificationsLiveActivitiesWidget)
import AwesomeNotificationsLiveActivitiesWidget
#endif

/// The Live Activities of ActivityKit (iOS 16.1+). Adopts the activities it
/// didn't start (by push, or before the app restarted) so their states and
/// tokens reach the manager. The changes of one activity run in order.
@available(iOS 16.1, *)
final class ActivityKitSystem: LiveActivitySystem {

    typealias Attributes = AwnLiveActivityAttributes

    private weak var manager: LiveActivityManager?
    /// The activities observed, by ActivityKit id.
    private var observed: Set<String> = []
    /// The last change queued for each activity (ActivityKit id).
    private var queues: [String: Task<Void, Never>] = [:]
    /// The activities this app started, by activityId (ActivityKit's list
    /// catches up with a new one later).
    private var started: [String: Activity<Attributes>] = [:]

    init(manager: LiveActivityManager) {
        self.manager = manager
        for activity in Activity<Attributes>.activities { adopt(activity) }
        Task { [weak self] in
            for await activity in Activity<Attributes>.activityUpdates {
                await MainActor.run { self?.adopt(activity) }
            }
        }
        if #available(iOS 17.2, *) {
            if let token = Activity<Attributes>.pushToStartToken {
                manager.systemPushToStartToken(ActivityKitSystem.hex(token))
            }
            Task { [weak self] in
                for await token in Activity<Attributes>.pushToStartTokenUpdates {
                    await MainActor.run { self?.manager?.systemPushToStartToken(ActivityKitSystem.hex(token)) }
                }
            }
        }
    }

    static func hex(_ data: Data) -> String { data.map { String(format: "%02x", $0) }.joined() }

    static func status(_ state: ActivityState) -> LiveActivityStatus {
        switch state {
        case .active, .pending: return .active
        case .ended: return .ended
        case .dismissed: return .dismissed
        case .stale: return .stale
        @unknown default: return .active
        }
    }

    /// Follows an activity's states and push tokens.
    private func adopt(_ activity: Activity<Attributes>) {
        guard !observed.contains(activity.id) else { return }
        observed.insert(activity.id)
        let activityId = activity.attributes.activityId
        Task { [weak self] in
            for await state in activity.activityStateUpdates {
                await MainActor.run {
                    self?.manager?.systemStatusChanged(activityId, ActivityKitSystem.status(state))
                    if state == .dismissed { self?.forget(activity.id) }
                }
            }
        }
        Task { [weak self] in
            for await token in activity.pushTokenUpdates {
                await MainActor.run { self?.manager?.systemPushToken(activityId, token: ActivityKitSystem.hex(token)) }
            }
        }
        if let token = activity.pushToken {
            manager?.systemPushToken(activityId, token: ActivityKitSystem.hex(token))
        }
    }

    private func forget(_ id: String) {
        observed.remove(id)
        queues.removeValue(forKey: id)
    }

    /// The activity of an activityId still on screen.
    private func find(_ activityId: String, includeEnded: Bool = false) -> Activity<Attributes>? {
        let candidates = (started[activityId].map { [$0] } ?? []) + Activity<Attributes>.activities
        return candidates.first { activity in
            guard activity.attributes.activityId == activityId else { return false }
            switch activity.activityState {
            case .active, .pending, .stale: return true
            case .ended: return includeEnded
            default: return false
            }
        }
    }

    /// Runs [work] after the activity's previous change.
    private func enqueue(_ activity: Activity<Attributes>, _ work: @escaping () async -> Void) {
        let previous = queues[activity.id]
        let activityId = activity.attributes.activityId
        queues[activity.id] = Task {
            await previous?.value
            await work()
            // A button's press waits for this to let the app sleep again.
            AwnLiveActivityButtons.activityChanged(activityId)
        }
    }

    var areEnabled: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    var supportsButtons: Bool {
        if #available(iOS 17.0, *) { return true }
        return false
    }

    var pushToStartToken: String? {
        if #available(iOS 17.2, *) { return Activity<Attributes>.pushToStartToken.map(ActivityKitSystem.hex) }
        return nil
    }

    func show(attributes: AwnLiveActivityAttributes, state: AwnLiveActivityState,
              activity: NotificationLiveActivity, alert: LiveActivityAlert?) throws {
        if let current = find(attributes.activityId) {
            enqueue(current) {
                if #available(iOS 16.2, *) {
                    let content = ActivityContent(state: state, staleDate: activity.staleDate,
                                                  relevanceScore: activity.relevance ?? 0)
                    let configuration = alert.map {
                        AlertConfiguration(title: LocalizedStringResource(stringLiteral: $0.title),
                                           body: LocalizedStringResource(stringLiteral: $0.body),
                                           sound: .default)
                    }
                    await current.update(content, alertConfiguration: configuration)
                } else {
                    await current.update(using: state)
                }
            }
            return
        }
        let started: Activity<Attributes>
        do {
            started = try request(attributes, state, activity, pushType: pushType(activity))
        } catch {
            // Without the push entitlement ActivityKit refuses push updates:
            // started without them.
            started = try request(attributes, state, activity, pushType: nil)
        }
        self.started[attributes.activityId] = started
        adopt(started)
        AwnLiveActivityButtons.activityChanged(attributes.activityId)
    }

    private func pushType(_ activity: NotificationLiveActivity) -> PushType {
        if #available(iOS 18.0, *), let channel = activity.pushChannel { return .channel(channel) }
        return .token
    }

    private func request(_ attributes: Attributes, _ state: AwnLiveActivityState,
                         _ activity: NotificationLiveActivity, pushType: PushType?) throws -> Activity<Attributes> {
        if #available(iOS 16.2, *) {
            let content = ActivityContent(state: state, staleDate: activity.staleDate,
                                          relevanceScore: activity.relevance ?? 0)
            return try Activity<Attributes>.request(attributes: attributes, content: content, pushType: pushType)
        }
        return try Activity<Attributes>.request(attributes: attributes, contentState: state, pushType: pushType)
    }

    func end(_ activityId: String, state: AwnLiveActivityState?, dismissal: LiveActivityDismissal) {
        guard let current = find(activityId, includeEnded: dismissal == .immediate) else { return }
        let policy: ActivityUIDismissalPolicy
        switch dismissal {
        case .system: policy = .default
        case .immediate: policy = .immediate
        case .at(let date): policy = .after(date)
        }
        enqueue(current) {
            if #available(iOS 16.2, *) {
                var final = state ?? current.content.state
                final.ended = true
                await current.end(ActivityContent(state: final, staleDate: nil), dismissalPolicy: policy)
            } else {
                var final = state ?? current.contentState
                final.ended = true
                await current.end(using: final, dismissalPolicy: policy)
            }
        }
    }

    func activities() -> [(activityId: String, status: LiveActivityStatus)] {
        Activity<Attributes>.activities.map { ($0.attributes.activityId, ActivityKitSystem.status($0.activityState)) }
    }

    func pushToken(_ activityId: String) -> String? {
        find(activityId, includeEnded: true)?.pushToken.map(ActivityKitSystem.hex)
    }
}
#endif
