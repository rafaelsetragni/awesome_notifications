import Foundation
import IosAwnCore
#if canImport(AwesomeNotificationsLiveActivitiesWidget)
import AwesomeNotificationsLiveActivitiesWidget
#endif

/// Takes over the models with a `liveActivity` block. Where ActivityKit runs
/// (iOS 16.1+) no notification is posted: the activity starts / updates /
/// ends, the core still reports it created and displayed, and the create
/// call answers true. Elsewhere (macOS, iOS below 16.1, or when ActivityKit
/// refuses it) the notification is posted, replaced in place.
public final class LiveActivityBuilder: NotificationBuilder {

    /// Below localization (100), media (40) and calls (35), above scheduling
    /// (10): texts are translated first, and a live activity is refused
    /// before a schedule is applied.
    public static let priority = 30

    /// One live activity model at a time: an update can't overtake its start.
    private static let lock = NSLock()

    private let manager: () -> LiveActivityManager
    private let images: () -> LiveActivityImageStore

    public init(inner: NotificationBuilder?,
                manager: @escaping () -> LiveActivityManager = { .shared },
                images: @escaping () -> LiveActivityImageStore = { .shared }) {
        self.manager = manager
        self.images = images
        super.init(inner: inner)
    }

    public override func build(model: [String: Any]) throws -> BuiltNotification? {
        guard let prepared = try LiveActivityNotifications.prepare(model) else {
            return try next(model)
        }
        LiveActivityBuilder.lock.lock()
        defer { LiveActivityBuilder.lock.unlock() }
        let activityId = prepared.activity.activityId
        let presentation = onMain { self.manager().presentation(for: activityId) }
        if presentation == .activity {
            // Images first, here (downloads), off the main thread.
            let store = images()
            let state = LiveActivityNotifications.contentState(prepared) { store.store($0) }
            let attributes = AwnLiveActivityAttributes(activityId: activityId, appGroup: store.appGroup)
            try LiveActivityNotifications.checkSize(state, attributes)
            let shown = onMain { self.manager().applyActivity(prepared, attributes: attributes, state: state) }
            if shown { return .handled(model: stampHandledLifecycle(into: prepared.model)) }
        }
        switch onMain({ self.manager().applyNotification(prepared) }) {
        case .post(let notification):
            return try next(notification)
        case .removed:
            return .handled(model: stampHandledLifecycle(into: prepared.model))
        }
    }

    private func onMain<T>(_ work: () -> T) -> T {
        Thread.isMainThread ? work() : DispatchQueue.main.sync(execute: work)
    }
}
