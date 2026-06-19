import Flutter
import UIKit
import IosAwnCore

/// Thin Flutter bridge: translates method-channel calls into the Flutter-free
/// IosAwnCore engine. All notification logic lives in the core so it can be
/// shared with a Notification Service Extension later.
public class AwesomeNotificationsPlugin: NSObject, FlutterPlugin {

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "awesome_notifications",
      binaryMessenger: registrar.messenger()
    )
    let instance = AwesomeNotificationsPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  private var core: AwesomeNotifications { AwesomeNotifications.shared }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {

    case "initialize":
      let args = call.arguments as? [String: Any]
      let channels = (args?[Definitions.initializeChannels] as? [[String: Any]]) ?? []
      core.initialize(channels: channels)
      result(true)

    case "getLocalTimeZoneIdentifier":
      result(TimeZone.current.identifier)

    case "getUtcTimeZoneIdentifier":
      result("UTC")

    case "isNotificationAllowed":
      core.isNotificationAllowed { result($0) }

    case "requestNotifications":
      core.requestPermission { result($0) }

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
