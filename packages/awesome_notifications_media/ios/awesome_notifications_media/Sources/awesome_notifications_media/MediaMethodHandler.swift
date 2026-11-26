import Foundation
import IosAwnCore

/// Answers the AwesomeNotificationsMedia channel methods on iOS and macOS.
public final class MediaMethodHandler: AwesomeMethodHandler {

    private let sessions: () -> MediaSessions

    public init(sessions: @escaping () -> MediaSessions = { .shared }) {
        self.sessions = sessions
    }

    /// What Now Playing shows here.
    public static var capabilities: [String: Bool] {
        #if os(macOS)
        let lockScreen = false
        #else
        let lockScreen = true
        #endif
        return ["seekBar": true, "artwork": true, "customButtons": false, "lockScreen": lockScreen]
    }

    public func handle(method: String, arguments: Any?, result: @escaping (Any?) -> Void) -> Bool {
        switch method {
        case MediaKeys.methodStop:
            if let id = arguments as? String { sessions().stop(id) }
            result(nil)
        case MediaKeys.methodUpdatePosition:
            if let map = arguments as? [String: Any],
               let id = map[MediaKeys.sessionId] as? String,
               let position = (map[MediaKeys.position] as? NSNumber)?.intValue {
                sessions().updatePosition(id, position: position)
            }
            result(nil)
        case MediaKeys.methodCapabilities:
            result(MediaMethodHandler.capabilities)
        default:
            return false
        }
        return true
    }
}
