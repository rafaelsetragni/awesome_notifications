import Foundation
import UserNotifications
import IosAwnCore

/// The system's call UI (CallKit on iOS), behind a protocol so the call logic
/// runs and is tested without it. Every method is an app-driven change: the
/// user's own actions come back through `CallManager.system…`.
public protocol CallSystem: AnyObject {
    /// A new incoming call (`reportNewIncomingCall`).
    func reportIncoming(_ call: NotificationCall, uuid: UUID, completion: @escaping (Error?) -> Void)
    /// New details of a call the system shows (`reportCall(with:updated:)`).
    func update(_ call: NotificationCall, uuid: UUID)
    /// A call the app starts (`CXStartCallAction`), connecting.
    func startOutgoing(_ call: NotificationCall, uuid: UUID)
    /// An outgoing call got connected (`reportOutgoingCall(with:connectedAt:)`).
    func reportConnected(uuid: UUID, at date: Date)
    /// The app answered (`CXAnswerCallAction`).
    func answer(uuid: UUID)
    /// The app put the call on hold or resumed it (`CXSetHeldCallAction`).
    func setHeld(uuid: UUID, onHold: Bool)
    /// The call is over (`reportCall(with:endedAt:reason:)`).
    func reportEnded(uuid: UUID, reason: CallEndReason)
}

/// A ring timer.
public protocol CallTimer: AnyObject {
    func cancel()
}

final class DispatchCallTimer: CallTimer {
    private var item: DispatchWorkItem?
    init(seconds: TimeInterval, fire: @escaping () -> Void) {
        let item = DispatchWorkItem(block: fire)
        self.item = item
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: item)
    }
    func cancel() {
        item?.cancel()
        item = nil
    }
}

/// The calls the package shows and their states, the ring timers, and the
/// delivery of the commands. Main thread only.
public final class CallManager {

    public static let shared = CallManager()

    /// How a call is shown.
    public enum Presentation: Equatable {
        /// The system's call UI (CallKit).
        case systemCall
        /// A notification with the call's buttons (macOS, iOS with
        /// `systemCallUI: false`).
        case notification
    }

    /// The action event of a command: (model, buttonKey, input, button).
    public typealias Dispatcher = ([String: Any], String, String?, [String: Any]) -> Void
    public typealias TimerFactory = (TimeInterval, @escaping () -> Void) -> CallTimer

    struct Entry {
        var call: NotificationCall
        /// The call's model (callId in the payload), as the events report it.
        var model: [String: Any]
        let presentation: Presentation
        let appTitle: String?
        let appBody: String?
        var timer: CallTimer?
        var muted = false
        var uuid: UUID { CallIds.uuid(call.callId) }
    }

    private var entries: [String: Entry] = [:]

    private let systemFactory: (CallManager) -> CallSystem?
    private var systemStore: CallSystem?
    private var systemMade = false
    let dispatch: Dispatcher
    let createNotification: ([String: Any]) -> Void
    let removeNotification: (Int) -> Void
    let makeTimer: TimerFactory
    let now: () -> Date

    /// The event channel's sink while Dart listens.
    public var eventSink: (([String: Any]) -> Void)? {
        didSet {
            if let sink = eventSink, let token = voipToken {
                sink([CallKeys.kind: CallKeys.kindVoipToken, CallKeys.token: token])
            }
        }
    }

    /// The PushKit VoIP token (hex), iOS.
    public var voipToken: String? {
        didSet {
            guard let token = voipToken, token != oldValue else { return }
            eventSink?([CallKeys.kind: CallKeys.kindVoipToken, CallKeys.token: token])
        }
    }

    public convenience init() {
        self.init(
            system: { manager in
                #if os(iOS)
                return CallKitSystem(manager: manager)
                #else
                return nil
                #endif
            },
            dispatch: { model, key, input, button in
                AwesomeNotifications.shared.dispatchAction(
                    model: model, buttonKey: key, input: input, button: button)
            },
            createNotification: { model in
                AwesomeNotifications.shared.createNotification(model) { _ in }
            },
            removeNotification: { id in
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [String(id)])
            },
            timer: { seconds, fire in DispatchCallTimer(seconds: seconds, fire: fire) },
            now: Date.init)
    }

    init(system: @escaping (CallManager) -> CallSystem?,
         dispatch: @escaping Dispatcher,
         createNotification: @escaping ([String: Any]) -> Void,
         removeNotification: @escaping (Int) -> Void,
         timer: @escaping TimerFactory,
         now: @escaping () -> Date) {
        self.systemFactory = system
        self.dispatch = dispatch
        self.createNotification = createNotification
        self.removeNotification = removeNotification
        self.makeTimer = timer
        self.now = now
    }

    /// The system call UI, created on first use (nil without one).
    var system: CallSystem? {
        if !systemMade {
            systemMade = true
            systemStore = systemFactory(self)
        }
        return systemStore
    }

    /// Whether this platform has a system call UI (made on first use).
    public var hasSystemCallUI: Bool { system != nil }

    /// How a call is shown here: as it already is, else by its `systemCallUI`.
    public func presentation(for call: NotificationCall) -> Presentation {
        if let entry = entries[call.callId] { return entry.presentation }
        return call.systemCallUI && system != nil ? .systemCall : .notification
    }

    // MARK: - The app's models

    /// Applies a call model (created through the core) to the call.
    public func apply(_ prepared: CallNotifications.Prepared) {
        let call = prepared.call
        let previous = entries[call.callId]
        let presentation = self.presentation(for: call)
        switch call.state {
        case .ended:
            finish(call.callId, fallback: prepared.model, presentation: presentation, reason: .remoteEnded)
            return
        case .missed:
            finish(call.callId, fallback: prepared.model, presentation: presentation, reason: .unanswered)
            if call.missedNotification { createNotification(CallNotifications.missedModel(call, callModel: prepared.model)) }
            return
        default:
            break
        }

        var entry = Entry(call: call, model: prepared.model, presentation: presentation,
                          appTitle: prepared.appTitle, appBody: prepared.appBody,
                          timer: nil, muted: previous?.muted ?? false)
        if call.state == .ongoing || call.state == .held {
            // Keeps the timer's base of a call answered through the package.
            entry.call.startedAt = call.startedAt ?? previous?.call.startedAt
            entry.model[CallKeys.call] = entry.call.toMap()
        }
        if call.state == .incoming {
            // A call already ringing keeps its timer: an update doesn't ring longer.
            if previous?.call.state == .incoming, let timer = previous?.timer {
                entry.timer = timer
            } else {
                previous?.timer?.cancel()
                entry.timer = ringTimer(call)
            }
        } else {
            previous?.timer?.cancel()
        }
        entries[call.callId] = entry
        if presentation == .systemCall { drive(entry, from: previous?.call.state) }
    }

    /// Moves the system call from its previous state to the entry's.
    private func drive(_ entry: Entry, from previous: CallState?) {
        guard let system = system else { return }
        let call = entry.call
        let uuid = entry.uuid
        let connectedAt = call.startedAt.map { Date(timeIntervalSince1970: Double($0) / 1000) } ?? now()
        switch call.state {
        case .incoming:
            if previous == nil {
                system.reportIncoming(call, uuid: uuid) { [weak self] error in
                    guard error != nil else { return }
                    // Refused (Do Not Disturb, blocked…): the call is gone.
                    self?.drop(call.callId)
                }
            } else {
                system.update(call, uuid: uuid)
            }
        case .outgoing:
            if previous == nil { system.startOutgoing(call, uuid: uuid) } else { system.update(call, uuid: uuid) }
        case .ongoing, .held:
            switch previous {
            case nil:
                system.startOutgoing(call, uuid: uuid)
                system.reportConnected(uuid: uuid, at: connectedAt)
            case .incoming?:
                system.answer(uuid: uuid)
            case .outgoing?:
                system.reportConnected(uuid: uuid, at: connectedAt)
            default:
                system.update(call, uuid: uuid)
            }
            let onHold = call.state == .held
            if onHold != (previous == .held) { system.setHeld(uuid: uuid, onHold: onHold) }
        case .ended, .missed:
            break
        }
    }

    private func ringTimer(_ call: NotificationCall) -> CallTimer {
        let callId = call.callId
        return makeTimer(Double(call.ringTimeout) / 1000) { [weak self] in self?.timeout(callId) }
    }

    /// Ends a call without a command: the system call or its notification.
    @discardableResult
    private func finish(_ callId: String, fallback: [String: Any]?, presentation: Presentation,
                        reason: CallEndReason) -> Entry? {
        let entry = entries.removeValue(forKey: callId)
        entry?.timer?.cancel()
        switch entry?.presentation ?? presentation {
        case .systemCall:
            system?.reportEnded(uuid: CallIds.uuid(callId), reason: reason)
        case .notification:
            if let id = CallNotifications.id(entry?.model ?? fallback ?? [:]) { removeNotification(id) }
        }
        return entry
    }

    /// Forgets a call the system refused.
    private func drop(_ callId: String) {
        entries.removeValue(forKey: callId)?.timer?.cancel()
    }

    // MARK: - Timeout, end

    func timeout(_ callId: String) {
        guard let entry = entries[callId], entry.call.state == .incoming else { return }
        entries[callId]?.timer = nil
        finish(callId, fallback: nil, presentation: entry.presentation, reason: .unanswered)
        if entry.call.missedNotification {
            createNotification(CallNotifications.missedModel(entry.call, callModel: entry.model))
        }
        deliver(entry, .timeout)
    }

    /// The app's `callEnd`: ends the call everywhere, without a command. An
    /// unanswered call shows the missed notification (if it allows it).
    public func end(_ callId: String, reason: CallEndReason) {
        guard let entry = entries[callId] else {
            // Not known here (the app restarted): end the system call anyway.
            if hasSystemCallUI { system?.reportEnded(uuid: CallIds.uuid(callId), reason: reason) }
            return
        }
        finish(callId, fallback: nil, presentation: entry.presentation, reason: reason)
        if reason == .unanswered, entry.call.missedNotification {
            createNotification(CallNotifications.missedModel(entry.call, callModel: entry.model))
        }
    }

    /// The calls shown now.
    public func activeCalls() -> [[String: Any]] {
        entries.values
            .sorted { $0.call.callId < $1.call.callId }
            .map { [CallKeys.callId: $0.call.callId, CallKeys.state: $0.call.state.rawValue] }
    }

    func state(_ callId: String) -> CallState? { entries[callId]?.call.state }
    func entry(_ callId: String) -> Entry? { entries[callId] }

    /// The app removed notifications (cancel / dismiss): their calls end,
    /// without a command.
    public func remove(_ removal: NotificationRemoval) {
        let ids = entries.filter { _, entry in
            let content = CallNotifications.content(entry.model)
            switch removal {
            case .all: return true
            case .id(let id): return CallNotifications.id(entry.model) == id
            case .channelKey(let key): return content[Definitions.NOTIFICATION_CHANNEL_KEY] as? String == key
            case .groupKey(let key): return content[Definitions.NOTIFICATION_GROUP_KEY] as? String == key
            }
        }.keys
        for id in ids {
            guard let entry = entries.removeValue(forKey: id) else { continue }
            entry.timer?.cancel()
            // The core removes the notification itself.
            if entry.presentation == .systemCall { system?.reportEnded(uuid: entry.uuid, reason: .remoteEnded) }
        }
    }

    // MARK: - VoIP pushes

    /// A call from a VoIP push: reported to the system at once (iOS requires
    /// it before the push's completion), whatever its state; the model then
    /// goes through the core, which applies it.
    public func reportPushed(_ prepared: CallNotifications.Prepared, completion: @escaping () -> Void) {
        guard let system = system else { completion(); return }
        var call = prepared.call
        call.systemCallUI = true
        let callId = call.callId
        if entries[callId] != nil {
            // Already shown: reported again for iOS, whose refusal changes nothing.
            system.reportIncoming(call, uuid: CallIds.uuid(callId)) { _ in completion() }
            return
        }
        call.state = .incoming
        var entry = Entry(call: call, model: prepared.model, presentation: .systemCall,
                          appTitle: prepared.appTitle, appBody: prepared.appBody, timer: nil)
        entry.timer = ringTimer(call)
        entries[callId] = entry
        system.reportIncoming(call, uuid: entry.uuid) { [weak self] error in
            if error != nil { self?.drop(callId) }
            completion()
        }
    }

    // MARK: - The user's actions

    /// Applies a user's action to the call first, then delivers it. With
    /// [actionEvent] false the core emits the action event itself.
    @discardableResult
    func userAction(_ callId: String, _ action: CallAction, actionEvent: Bool = true) -> Bool {
        guard var entry = entries[callId] else { return false }
        switch action {
        case .accept:
            guard entry.call.state == .incoming else { return false }
            entry.timer?.cancel()
            entry.timer = nil
            entry.call.state = .ongoing
            if entry.call.startedAt == nil { entry.call.startedAt = Int((now().timeIntervalSince1970 * 1000).rounded()) }
            entry.model[CallKeys.call] = entry.call.toMap()
            entries[callId] = entry
            if entry.presentation == .notification {
                // Shown again as ongoing, with Hang up.
                createNotification(CallNotifications.updated(
                    entry.model, call: entry.call, appTitle: entry.appTitle, appBody: entry.appBody))
            }
        case .decline, .hangUp:
            entries.removeValue(forKey: callId)
            entry.timer?.cancel()
            if entry.presentation == .notification, let id = CallNotifications.id(entry.model) {
                removeNotification(id)
            }
        case .mute, .unmute:
            entries[callId]?.muted = action == .mute
        case .hold, .unhold:
            entries[callId]?.call.state = action == .hold ? .held : .ongoing
        case .timeout, .audioActivated, .audioDeactivated:
            break
        }
        deliver(entry, action, actionEvent: actionEvent)
        return true
    }

    /// Sends a command to the call's targets.
    func deliver(_ entry: Entry, _ action: CallAction, actionEvent: Bool = true) {
        let target = entry.call.commandTarget
        if target.toStream, let sink = eventSink {
            sink(CallManager.streamEvent(action, callId: entry.call.callId))
        }
        if actionEvent, target.toActionEvent {
            dispatch(entry.model, action.key, nil, CallManager.button(action))
        }
    }

    /// The EventChannel event of a command.
    public static func streamEvent(_ action: CallAction, callId: String) -> [String: Any] {
        [CallKeys.kind: CallKeys.kindCommand, CallKeys.action: action.rawValue, CallKeys.callId: callId]
    }

    /// The synthetic button of a command's action event: Accept opens the
    /// app, nothing dismisses the call's notification.
    public static func button(_ action: CallAction) -> [String: Any] {
        [
            Definitions.NOTIFICATION_BUTTON_KEY: action.key,
            Definitions.NOTIFICATION_ACTION_TYPE:
                (action == .accept ? ActionType.default : ActionType.silentAction).rawValue,
            Definitions.NOTIFICATION_AUTO_DISMISSIBLE: false
        ]
    }

    // MARK: - The system call UI's actions

    private func callId(_ uuid: UUID) -> String? {
        entries.first { $0.value.uuid == uuid }?.key
    }

    /// The user answered in the system UI. False for an unknown call.
    public func systemAnswered(_ uuid: UUID) -> Bool {
        guard let id = callId(uuid), let entry = entries[id] else { return false }
        // Not ringing any more: the app's own answer coming back.
        if entry.call.state == .incoming { userAction(id, .accept) }
        return true
    }

    /// The user ended the call in the system UI: declined while it rang,
    /// hung up afterwards. Calls the app ended already are ignored.
    public func systemEnded(_ uuid: UUID) {
        guard let id = callId(uuid), let entry = entries[id] else { return }
        userAction(id, entry.call.state == .incoming ? .decline : .hangUp)
    }

    /// The user (or the app, coming back) put the call on hold or resumed it.
    public func systemHeld(_ uuid: UUID, onHold: Bool) -> Bool {
        guard let id = callId(uuid), let entry = entries[id] else { return false }
        if (entry.call.state == .held) != onHold { userAction(id, onHold ? .hold : .unhold) }
        return true
    }

    public func systemMuted(_ uuid: UUID, muted: Bool) -> Bool {
        guard let id = callId(uuid), let entry = entries[id] else { return false }
        if entry.muted != muted { userAction(id, muted ? .mute : .unmute) }
        return true
    }

    /// The system activated / deactivated the call's audio session: told to
    /// the call in progress (one call at a time).
    public func systemAudio(activated: Bool) {
        let calls = entries.values.filter { $0.presentation == .systemCall }
        let current = calls.first { $0.call.state != .incoming } ?? calls.first
        guard let entry = current else { return }
        deliver(entry, activated ? .audioActivated : .audioDeactivated)
    }

    /// The system reset its calls: they are all gone, without a command.
    public func systemReset() {
        for (id, entry) in entries where entry.presentation == .systemCall {
            entry.timer?.cancel()
            entries.removeValue(forKey: id)
        }
    }

    // MARK: - Notification buttons

    /// A button of a call notification was used (the core's action seam).
    /// Returns whether the core should emit its action event.
    public func notificationAction(model: [String: Any], buttonKey: String) -> Bool {
        guard let action = CallAction.from(key: buttonKey),
              let prepared = try? CallNotifications.prepare(model) else { return true }
        let callId = prepared.call.callId
        if entries[callId] == nil {
            // The app was not running: the call comes back from its notification.
            guard prepared.call.state.isActive else { return true }
            entries[callId] = Entry(call: prepared.call, model: prepared.model, presentation: .notification,
                                    appTitle: prepared.appTitle, appBody: prepared.appBody, timer: nil)
        }
        userAction(callId, action, actionEvent: false)
        return prepared.call.commandTarget.toActionEvent
    }
}

extension CallManager: NotificationRemovalListener {
    public func onNotificationsRemoved(_ removal: NotificationRemoval, cancel: Bool) {
        if Thread.isMainThread { remove(removal) } else { DispatchQueue.main.async { self.remove(removal) } }
    }
}

extension CallManager: NotificationActionInterceptor {
    public func onNotificationAction(model: [String: Any], buttonKey: String) -> Bool {
        if Thread.isMainThread { return notificationAction(model: model, buttonKey: buttonKey) }
        return DispatchQueue.main.sync { notificationAction(model: model, buttonKey: buttonKey) }
    }
}
