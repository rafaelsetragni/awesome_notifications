import Flutter
import UIKit
import IosAwnCore

/// Thin Flutter bridge: translates method-channel calls into the Flutter-free
/// IosAwnCore engine. All notification logic lives in the core so it can be
/// shared with a Notification Service Extension later.
public class AwesomeNotificationsPlugin: NSObject, FlutterPlugin, AwesomeEventListener {

  private var channel: FlutterMethodChannel?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "awesome_notifications",
      binaryMessenger: registrar.messenger()
    )
    let instance = AwesomeNotificationsPlugin()
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)

    // Subscribe to core lifecycle events (created/displayed/tap/dismiss) and
    // forward them to Dart.
    AwesomeEventsReceiver.shared.subscribe(listener: instance)
  }

  private var core: AwesomeNotifications { AwesomeNotifications.shared }

  // MARK: - AwesomeEventListener

  public func onNewAwesomeEvent(eventType: String, content: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      self?.channel?.invokeMethod(eventType, arguments: content)
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {

    case "initialize":
      let args = call.arguments as? [String: Any]
      let channels = (args?[Definitions.INITIALIZE_CHANNELS] as? [[String: Any]]) ?? []
      core.initialize(channels: channels)
      result(true)

    case "getLocalTimeZoneIdentifier":
      result(TimeZone.current.identifier)

    case "getUtcTimeZoneIdentifier":
      result("UTC")

    case "setEventHandles":
      // Background isolate handles; foreground events are delivered live through
      // this channel, so we just acknowledge.
      result(true)

    case "isNotificationAllowed":
      core.isNotificationAllowed { result($0) }

    case "requestNotifications":
      // Dart expects back the list of permissions still MISSING after the
      // request (empty list = everything granted).
      let args = call.arguments as? [String: Any]
      let requested = (args?[Definitions.NOTIFICATION_PERMISSIONS] as? [String]) ?? []
      core.requestPermission { granted in
        result(granted ? [] : requested)
      }

    case "setNotificationChannel":
      if let args = call.arguments as? [String: Any] {
        core.setChannel(args)
      }
      result(true)

    case "createNewNotification":
      if let args = call.arguments as? [String: Any] {
        core.createNotification(args) { result($0) }
      } else {
        result(false)
      }

    case "dismissNotification":
      if let id = AwesomeNotifications.readInt(call.arguments) {
        core.dismiss(id: id)
      }
      result(true)

    case "cancelNotification":
      if let id = AwesomeNotifications.readInt(call.arguments) {
        core.cancel(id: id)
      }
      result(true)

    case "dismissAllNotifications":
      core.dismissAllNotifications()
      result(true)

    case "cancelAllNotifications":
      core.cancelAll()
      result(true)

    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
