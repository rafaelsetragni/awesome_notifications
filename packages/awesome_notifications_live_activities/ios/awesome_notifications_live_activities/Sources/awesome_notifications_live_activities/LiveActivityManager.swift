import Foundation
import UserNotifications
import IosAwnCore
#if canImport(AwesomeNotificationsLiveActivitiesWidget)
import AwesomeNotificationsLiveActivitiesWidget
#endif

/// What alerts on an ActivityKit update (an update with `alert: true`).
public struct LiveActivityAlert: Equatable {
    public let title: String
    public let body: String
}

/// The system's live activities (ActivityKit on iOS 16.1+), behind a protocol
/// so the logic runs and is tested without it. The system reports its changes
/// back through `LiveActivityManager.system…`.
public protocol LiveActivitySystem: AnyObject {
    /// The user allows live activities.
    var areEnabled: Bool { get }
    /// The activities have buttons (iOS 17+).
    var supportsButtons: Bool { get }
    /// The push-to-start token (hex), iOS 17.2+.
    var pushToStartToken: String? { get }
    /// Starts the activity, or updates the one shown. Throws when the system
    /// refuses to start it.
    func show(attributes: AwnLiveActivityAttributes, state: AwnLiveActivityState,
              activity: NotificationLiveActivity, alert: LiveActivityAlert?) throws
    /// Ends the activity: with [state] as its final content (nil: the content
    /// shown, marked ended).
    func end(_ activityId: String, state: AwnLiveActivityState?, dismissal: LiveActivityDismissal)
    /// The activities the system shows (push-started ones too).
    func activities() -> [(activityId: String, status: LiveActivityStatus)]
    /// An activity's push token (hex).
    func pushToken(_ activityId: String) -> String?
}

/// A timer of an ended activity's dismissal or its staleAt (notifications).
public protocol LiveActivityTimerHandle: AnyObject {
    func cancel()
}

final class DispatchLiveActivityTimer: LiveActivityTimerHandle {
    private var item: DispatchWorkItem?
    init(seconds: TimeInterval, fire: @escaping () -> Void) {
        let item = DispatchWorkItem(block: fire)
        self.item = item
        DispatchQueue.main.asyncAfter(deadline: .now() + max(seconds, 0), execute: item)
    }
    func cancel() {
        item?.cancel()
        item = nil
    }
}

/// The last model of each activity, kept so a button pressed after the app
/// restarted still finds its notification.
public final class LiveActivityModelStore {
    private let defaults: UserDefaults
    private let key = "awn.liveActivities.models"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func save(_ activityId: String, model: [String: Any]) {
        guard let json = JsonUtils.shared.toJson(model) else { return }
        var all = defaults.dictionary(forKey: key) as? [String: String] ?? [:]
        all[activityId] = json
        defaults.set(all, forKey: key)
    }

    public func load(_ activityId: String) -> [String: Any]? {
        let all = defaults.dictionary(forKey: key) as? [String: String] ?? [:]
        return JsonUtils.shared.fromJson(all[activityId])
    }

    public func remove(_ activityId: String) {
        var all = defaults.dictionary(forKey: key) as? [String: String] ?? [:]
        guard all.removeValue(forKey: activityId) != nil else { return }
        defaults.set(all, forKey: key)
    }
}

/// The live activities the package shows and their states, the events, and
/// the buttons. Main thread only.
public final class LiveActivityManager {

    public static let shared = LiveActivityManager()

    /// How an activity is shown.
    public enum Presentation: Equatable {
        /// A Live Activity (ActivityKit).
        case activity
        /// Its notification, replaced in place (macOS, iOS below 16.1, or
        /// when ActivityKit refused it).
        case notification
    }

    /// What the builder does with an activity shown as a notification.
    public enum NotificationOutcome {
        /// Post this model (same id: replaced in place).
        case post([String: Any])
        /// Nothing to post (ended with an immediate dismissal).
        case removed
    }

    public typealias Dispatcher = ([String: Any], String) -> Void
    public typealias TimerFactory = (TimeInterval, @escaping () -> Void) -> LiveActivityTimerHandle

    struct Entry {
        var activity: NotificationLiveActivity
        var model: [String: Any]
        let presentation: Presentation
        var status: LiveActivityStatus
        var state: AwnLiveActivityState?
        var timer: LiveActivityTimerHandle?
    }

    private var entries: [String: Entry] = [:]
    /// The last status reported of each activity (an event per change).
    private var reported: [String: LiveActivityStatus] = [:]
    private var pushTokens: [String: String] = [:]

    private let systemFactory: (LiveActivityManager) -> LiveActivitySystem?
    private var systemStore: LiveActivitySystem?
    private var systemMade = false
    let dispatch: Dispatcher
    let removeNotification: (Int) -> Void
    let makeTimer: TimerFactory
    let now: () -> Date
    let store: LiveActivityModelStore

    /// The event channel's sink while Dart listens. Gets the known tokens.
    public var eventSink: (([String: Any]) -> Void)? {
        didSet {
            guard let sink = eventSink else { return }
            if let token = pushToStartToken {
                sink([LiveActivityKeys.kind: LiveActivityKeys.kindPushToStartToken, LiveActivityKeys.token: token])
            }
            for (activityId, token) in pushTokens.sorted(by: { $0.key < $1.key }) {
                sink([LiveActivityKeys.kind: LiveActivityKeys.kindPushToken,
                      LiveActivityKeys.activityId: activityId, LiveActivityKeys.token: token])
            }
        }
    }

    /// The push-to-start token (hex), iOS 17.2+.
    public private(set) var pushToStartToken: String?

    public convenience init() {
        self.init(
            system: { manager in
                #if os(iOS) && canImport(ActivityKit)
                if #available(iOS 16.1, *) { return ActivityKitSystem(manager: manager) }
                #endif
                return nil
            },
            dispatch: { model, key in
                AwesomeNotifications.shared.dispatchAction(model: model, buttonKey: key)
            },
            removeNotification: { id in
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [String(id)])
            },
            timer: { seconds, fire in DispatchLiveActivityTimer(seconds: seconds, fire: fire) },
            now: Date.init,
            store: LiveActivityModelStore())
    }

    init(system: @escaping (LiveActivityManager) -> LiveActivitySystem?,
         dispatch: @escaping Dispatcher,
         removeNotification: @escaping (Int) -> Void,
         timer: @escaping TimerFactory,
         now: @escaping () -> Date,
         store: LiveActivityModelStore) {
        self.systemFactory = system
        self.dispatch = dispatch
        self.removeNotification = removeNotification
        self.makeTimer = timer
        self.now = now
        self.store = store
    }

    /// The system's live activities, made on first use (nil without them).
    var system: LiveActivitySystem? {
        if !systemMade {
            systemMade = true
            systemStore = systemFactory(self)
        }
        return systemStore
    }

    /// Starts the system part (adopts the activities started by push).
    public func start() { _ = system }

    /// How an activity is shown: as it already is, else as a Live Activity
    /// where the system has them.
    public func presentation(for activityId: String) -> Presentation {
        if let entry = entries[activityId], entry.status == .active || entry.status == .stale {
            return entry.presentation
        }
        return system != nil ? .activity : .notification
    }

    // MARK: - The app's models

    /// Starts / updates / ends a Live Activity. False when the system refused
    /// to start it (the caller shows the notification instead).
    public func applyActivity(_ prepared: LiveActivityNotifications.Prepared,
                              attributes: AwnLiveActivityAttributes,
                              state: AwnLiveActivityState) -> Bool {
        guard let system = system else { return false }
        let activity = prepared.activity
        let activityId = activity.activityId
        let previous = entries[activityId]
        let running = previous.map { $0.status == .active || $0.status == .stale } ?? false
        previous?.timer?.cancel()

        if activity.state == .ended {
            system.end(activityId, state: state, dismissal: activity.dismissal)
            entries[activityId] = Entry(activity: activity, model: prepared.model, presentation: .activity,
                                        status: .ended, state: state, timer: nil)
            store.remove(activityId)
            return true
        }

        let alert: LiveActivityAlert? = running && activity.alert
            ? LiveActivityAlert(title: state.title ?? "", body: state.body ?? "") : nil
        do {
            try system.show(attributes: attributes, state: state, activity: activity, alert: alert)
        } catch {
            NSLog("[AwesomeNotificationsLiveActivities] ActivityKit refused \(activityId): \(error). "
                  + "Showing its notification instead.")
            return false
        }
        if !running { reported[activityId] = .active }
        entries[activityId] = Entry(activity: activity, model: prepared.model, presentation: .activity,
                                    status: .active, state: state, timer: nil)
        store.save(activityId, model: prepared.model)
        return true
    }

    /// The activity as its notification, replaced in place: what to post.
    public func applyNotification(_ prepared: LiveActivityNotifications.Prepared) -> NotificationOutcome {
        let activity = prepared.activity
        let activityId = activity.activityId
        let previous = entries[activityId]
        let running = previous.map { $0.status == .active || $0.status == .stale } ?? false
        previous?.timer?.cancel()
        let model = LiveActivityNotifications.notificationModel(prepared, firstPost: !running)
        var entry = Entry(activity: activity, model: prepared.model, presentation: .notification,
                          status: activity.state == .ended ? .ended : .active, state: nil, timer: nil)
        if activity.state == .ended {
            entries[activityId] = entry
            store.remove(activityId)
            report(activityId, .ended)
            if dismissNotification(activityId, dismissal: activity.dismissal) { return .removed }
            return .post(model)
        }
        if !running { reported[activityId] = .active }
        if let staleAt = activity.staleDate {
            // No stale look in a notification: it goes away (as on Android).
            entry.timer = makeTimer(staleAt.timeIntervalSince(now())) { [weak self] in
                self?.dropNotification(activityId)
            }
        }
        entries[activityId] = entry
        store.save(activityId, model: prepared.model)
        return .post(model)
    }

    /// Applies an ended notification's dismissal. True when it is gone now.
    private func dismissNotification(_ activityId: String, dismissal: LiveActivityDismissal) -> Bool {
        switch dismissal {
        case .system:
            return false
        case .immediate:
            dropNotification(activityId)
            return true
        case .at(let date):
            entries[activityId]?.timer = makeTimer(date.timeIntervalSince(now())) { [weak self] in
                self?.dropNotification(activityId)
            }
            return false
        }
    }

    /// Removes an activity's notification: it is gone.
    private func dropNotification(_ activityId: String) {
        guard let entry = entries.removeValue(forKey: activityId) else { return }
        entry.timer?.cancel()
        if let id = LiveActivityNotifications.id(entry.model) { removeNotification(id) }
        store.remove(activityId)
        report(activityId, .dismissed)
    }

    /// The app's `end`: the activity shows its last content (ended) until
    /// [dismissal].
    public func end(_ activityId: String, dismissal: LiveActivityDismissal) {
        guard let entry = entries[activityId], entry.presentation == .notification else {
            // A Live Activity (also one started by push, or before a restart).
            var state = entries[activityId]?.state
            state?.ended = true
            system?.end(activityId, state: state, dismissal: dismissal)
            if entries[activityId] != nil {
                entries[activityId]?.status = .ended
                entries[activityId]?.state = state
            }
            store.remove(activityId)
            return
        }
        entry.timer?.cancel()
        entries[activityId]?.timer = nil
        entries[activityId]?.status = .ended
        store.remove(activityId)
        report(activityId, .ended)
        _ = dismissNotification(activityId, dismissal: dismissal)
    }

    /// The activities shown now: the system's, then the notifications.
    public func activities() -> [[String: Any]] {
        var result: [(String, LiveActivityStatus)] = system?.activities().map { ($0.activityId, $0.status) } ?? []
        let known = Set(result.map { $0.0 })
        for (activityId, entry) in entries where entry.presentation == .notification && !known.contains(activityId) {
            result.append((activityId, entry.status))
        }
        return result
            .filter { $0.1 != .dismissed }
            .sorted { $0.0 < $1.0 }
            .map { [LiveActivityKeys.activityId: $0.0, LiveActivityKeys.state: $0.1.rawValue] }
    }

    /// What live activities look like here.
    public var capabilities: [String: Bool] {
        let hasSystem = system != nil
        return [
            LiveActivityKeys.capSystemSurface: hasSystem,
            LiveActivityKeys.capProgressSegments: hasSystem,
            LiveActivityKeys.capMetrics: hasSystem,
            // The notification's buttons, or the activity's (iOS 17+).
            LiveActivityKeys.capButtons: hasSystem ? (system?.supportsButtons ?? false) : true,
            LiveActivityKeys.capPush: hasSystem
        ]
    }

    public var areEnabled: Bool { system?.areEnabled ?? true }

    public func pushToken(_ activityId: String) -> String? {
        pushTokens[activityId] ?? system?.pushToken(activityId)
    }

    func entry(_ activityId: String) -> Entry? { entries[activityId] }

    // MARK: - The core's removals

    /// The app removed notifications (cancel / dismiss): their activities end
    /// at once. Removing all ends the push-started ones too.
    public func remove(_ removal: NotificationRemoval) {
        let matching = entries.filter { LiveActivityNotifications.matches(removal, model: $0.value.model) }
        for (activityId, entry) in matching {
            entries.removeValue(forKey: activityId)
            entry.timer?.cancel()
            store.remove(activityId)
            switch entry.presentation {
            case .activity:
                if entry.status != .dismissed { system?.end(activityId, state: nil, dismissal: .immediate) }
            case .notification:
                // The core removes the notification itself.
                if entry.status == .active || entry.status == .stale { report(activityId, .ended) }
                report(activityId, .dismissed)
            }
        }
        if removal == .all, let system = system {
            for (activityId, status) in system.activities() where status != .dismissed && matching[activityId] == nil {
                system.end(activityId, state: nil, dismissal: .immediate)
            }
        }
    }

    // MARK: - Buttons (iOS 17+ App Intents)

    /// A button of an activity was pressed: the core's action event, as the
    /// notification's button would emit it.
    public func buttonPressed(_ activityId: String, buttonKey: String) {
        let model = entries[activityId]?.model
            ?? store.load(activityId)
            ?? LiveActivityNotifications.syntheticModel(activityId: activityId)
        dispatch(model, buttonKey)
    }

    // MARK: - The system's reports

    /// The system changed an activity's state (also one started by push).
    public func systemStatusChanged(_ activityId: String, _ status: LiveActivityStatus) {
        if var entry = entries[activityId], entry.presentation == .activity {
            if status == .dismissed {
                entries.removeValue(forKey: activityId)
                store.remove(activityId)
            } else {
                entry.status = status
                entries[activityId] = entry
                if status == .ended { store.remove(activityId) }
            }
        }
        if status == .ended || status == .dismissed { pushTokens.removeValue(forKey: activityId) }
        // Gone before it reported ended (immediate dismissal): ended first.
        if status == .dismissed, let last = reported[activityId], last == .active || last == .stale {
            report(activityId, .ended)
        }
        report(activityId, status)
    }

    public func systemPushToken(_ activityId: String, token: String) {
        guard pushTokens[activityId] != token else { return }
        pushTokens[activityId] = token
        eventSink?([LiveActivityKeys.kind: LiveActivityKeys.kindPushToken,
                    LiveActivityKeys.activityId: activityId, LiveActivityKeys.token: token])
    }

    public func systemPushToStartToken(_ token: String) {
        guard pushToStartToken != token else { return }
        pushToStartToken = token
        eventSink?([LiveActivityKeys.kind: LiveActivityKeys.kindPushToStartToken, LiveActivityKeys.token: token])
    }

    /// A state event, once per change (`active` is never an event).
    private func report(_ activityId: String, _ status: LiveActivityStatus) {
        guard reported[activityId] != status else { return }
        reported[activityId] = status
        guard status != .active else { return }
        eventSink?(LiveActivityManager.stateEvent(activityId, status))
    }

    public static func stateEvent(_ activityId: String, _ status: LiveActivityStatus) -> [String: Any] {
        [LiveActivityKeys.kind: LiveActivityKeys.kindState,
         LiveActivityKeys.activityId: activityId,
         LiveActivityKeys.state: status.rawValue]
    }
}

extension LiveActivityManager: NotificationRemovalListener {
    public func onNotificationsRemoved(_ removal: NotificationRemoval, cancel: Bool) {
        if Thread.isMainThread { remove(removal) } else { DispatchQueue.main.async { self.remove(removal) } }
    }
}
