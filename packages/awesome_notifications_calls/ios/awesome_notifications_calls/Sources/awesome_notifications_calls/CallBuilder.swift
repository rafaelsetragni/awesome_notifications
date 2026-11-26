import Foundation
import IosAwnCore

/// Takes over the models with a `call` block. With the system call UI
/// (CallKit) no notification is posted: the core still reports the call
/// created and displayed, and the create call answers true. Without it
/// (macOS, `systemCallUI: false`) the call is posted as a time-sensitive
/// notification with its buttons. An ended / missed call posts nothing.
public final class CallBuilder: NotificationBuilder {

    /// Below media (40), above scheduling (10): localization translates first,
    /// and a call is refused before a schedule is applied.
    public static let priority = 35

    private let manager: () -> CallManager

    public init(inner: NotificationBuilder?, manager: @escaping () -> CallManager = { .shared }) {
        self.manager = manager
        super.init(inner: inner)
    }

    public override func build(model: [String: Any]) throws -> BuiltNotification? {
        guard let prepared = try CallNotifications.prepare(model) else {
            return try next(model)
        }
        // The calls live on the main thread (CallKit's queue); the core
        // builds on a background one, which waits for the call to be applied.
        let presentation: CallManager.Presentation = onMain {
            let manager = self.manager()
            let presentation = manager.presentation(for: prepared.call)
            manager.apply(prepared)
            return presentation
        }
        if presentation == .systemCall || !prepared.call.state.isActive {
            return .handled(model: stampHandledLifecycle(into: prepared.model))
        }
        return try next(CallNotifications.notificationModel(prepared))
    }

    private func onMain<T>(_ work: () -> T) -> T {
        Thread.isMainThread ? work() : DispatchQueue.main.sync(execute: work)
    }
}
