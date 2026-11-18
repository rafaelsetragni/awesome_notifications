import Foundation

/// Routes the `awesome_notifications` method-channel protocol to the engine.
/// A call fails by answering an `AwesomeNotificationsException`, which the
/// bridges turn into a `FlutterError`.
///
/// Flutter-free and shared by the iOS and macOS plugin bridges, which only adapt
/// `result` to `FlutterResult`, answer platform-specific methods (e.g.
/// `getPlatformVersion`) and report `FlutterMethodNotImplemented` when this
/// returns false. Methods the core doesn't know fall through to the decorators
/// registered in `AwesomeMethodHandlerRegistry`.
public final class AwesomeMethodRouter {

    public static let shared = AwesomeMethodRouter()
    init() {}

    private var core: AwesomeNotifications { AwesomeNotifications.shared }
    private let mapUtils = MapUtils.shared

    /// Handles `method`; calls `result` exactly once and returns true, or
    /// returns false (without calling `result`) when nobody implements it.
    public func handle(
        method: String,
        arguments: Any?,
        result: @escaping (Any?) -> Void
    ) -> Bool {
        switch method {

        case "initialize":
            let args = arguments as? [String: Any]
            let channels = (args?[Definitions.INITIALIZE_CHANNELS] as? [[String: Any]]) ?? []
            core.initialize(channels: channels)
            result(true)

        case "getLocalTimeZoneIdentifier":
            result(TimeZone.current.identifier)

        case "getUtcTimeZoneIdentifier":
            result(Definitions.UTC_TIMEZONE)

        case "setEventHandles":
            // Background isolate handles; foreground events are delivered live
            // through the channel, so we just acknowledge.
            result(true)

        case "getInitialAction":
            // The action that launched the app (killed state), or nil.
            let removeFromEvents = arguments as? Bool ?? false
            core.getInitialAction(removeFromEvents: removeFromEvents) { result($0) }

        case "isNotificationAllowed":
            core.isNotificationAllowed { result($0) }

        case "requestNotifications":
            // Dart expects back the permissions still MISSING after the request
            // (empty list = everything granted).
            let args = arguments as? [String: Any]
            let requested = (args?[Definitions.NOTIFICATION_PERMISSIONS] as? [String]) ?? []
            core.requestPermission { granted in result(granted ? [] : requested) }

        case "setNotificationChannel":
            if let args = arguments as? [String: Any] { core.setChannel(args) }
            result(true)

        case "createNewNotification":
            if let args = arguments as? [String: Any] {
                core.createNotification(
                    args, completion: { result($0) }, failure: { result($0) })
            } else {
                result(false)
            }

        case "dismissNotification":
            if let id = mapUtils.getInt(arguments) { core.dismiss(id: id) }
            result(true)

        case "cancelNotification":
            if let id = mapUtils.getInt(arguments) { core.cancel(id: id) }
            result(true)

        case "dismissNotificationsByChannelKey":
            if let key = arguments as? String { core.dismissByChannelKey(key) }
            result(true)

        case "cancelNotificationsByChannelKey":
            if let key = arguments as? String { core.cancelByChannelKey(key) }
            result(true)

        case "dismissNotificationsByGroupKey":
            if let key = arguments as? String { core.dismissByGroupKey(key) }
            result(true)

        case "cancelNotificationsByGroupKey":
            if let key = arguments as? String { core.cancelByGroupKey(key) }
            result(true)

        case "dismissAllNotifications":
            core.dismissAllNotifications()
            result(true)

        case "cancelAllNotifications":
            core.cancelAll()
            result(true)

        default:
            // Let registered decorators (e.g. localization) answer their own methods.
            return AwesomeMethodHandlerRegistry.shared.handle(
                method: method,
                arguments: arguments,
                result: result
            )
        }
        return true
    }
}
