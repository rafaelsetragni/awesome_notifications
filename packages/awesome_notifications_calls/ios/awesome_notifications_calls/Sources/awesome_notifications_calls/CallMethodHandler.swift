import Foundation
import IosAwnCore

/// Answers the AwesomeNotificationsCalls channel methods on iOS and macOS.
public final class CallMethodHandler: AwesomeMethodHandler {

    private let manager: () -> CallManager

    public init(manager: @escaping () -> CallManager = { .shared }) {
        self.manager = manager
    }

    /// What the call UI can do here: CallKit on iOS (lock screen, mute and
    /// hold, VoIP pushes); a notification on macOS.
    public static var capabilities: [String: Bool] {
        #if os(iOS)
        return ["systemCallUI": true, "lockScreen": true, "muteAndHold": true, "push": true]
        #else
        return ["systemCallUI": false, "lockScreen": false, "muteAndHold": false, "push": false]
        #endif
    }

    public func handle(method: String, arguments: Any?, result: @escaping (Any?) -> Void) -> Bool {
        switch method {
        case CallKeys.methodEnd:
            let map = arguments as? [String: Any] ?? [:]
            if let callId = map[CallKeys.callId] as? String {
                let reason = CallEndReason.from(name: map[CallKeys.reason] as? String) ?? .remoteEnded
                onMain { self.manager().end(callId, reason: reason) }
            }
            result(nil)
        case CallKeys.methodActiveCalls:
            result(onMain { self.manager().activeCalls() })
        case CallKeys.methodVoipToken:
            result(onMain { self.manager().voipToken })
        case CallKeys.methodCanUseFullScreenIntent, CallKeys.methodRequestFullScreenIntent:
            result(true)
        case CallKeys.methodCapabilities:
            result(CallMethodHandler.capabilities)
        default:
            return false
        }
        return true
    }

    private func onMain<T>(_ work: () -> T) -> T {
        Thread.isMainThread ? work() : DispatchQueue.main.sync(execute: work)
    }
}
