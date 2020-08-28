
import Flutter
import UIKit

public class SwiftAwesomeNotificationsPlugin: NSObject, FlutterPlugin {

  static var appLifeCycle:NotificationLifeCycle = NotificationLifeCycle.AppKilled

  private static func checkGooglePlayServices() -> Bool {
    return true
  }

  public static func getApplicationLifeCycle() -> NotificationLifeCycle {
    // TODO NEED IMPLEMENTATION
    return NotificationLifeCycle.AppKilled
  }

  private static func requestPermissions() -> Bool {
    return NotificationBuilder.requestPermissions()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: Definitions.CHANNEL_FLUTTER_PLUGIN, binaryMessenger: registrar.messenger())
    let instance = SwiftAwesomeNotificationsPlugin()

    instance.initializeFlutterPlugin(registrar: registrar, channel: channel)
  }

  private func initializeFlutterPlugin(registrar: FlutterPluginRegistrar, channel: FlutterMethodChannel) {
      registrar.addMethodCallDelegate(self, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

    switch call.method {
      
      case Definitions.BROADCAST_FCM_TOKEN:
        onHandlecastNewFcmToken(call: call, result: result);
        return;

      case Definitions.BROADCAST_CREATED_NOTIFICATION:
        onHandlecastNotificationCreated(call: call, result: result);
        return;

      case Definitions.BROADCAST_DISPLAYED_NOTIFICATION:
        onHandlecastNotificationDisplayed(call: call, result: result);
        return;

      case Definitions.BROADCAST_KEEP_ON_TOP:
        onHandlecastKeepOnTopActionNotification(call: call, result: result);
        return;

      default:
        result(FlutterError.init(code: "methodNotFound", message: "method not found", details: call.method));
        return;      
    }
  }

  private func onHandlecastNewFcmToken(call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(nil);
  }

  private func onHandlecastNotificationCreated(call: FlutterMethodCall, result: @escaping FlutterResult) {
    // TODO MISSING IMPLEMENTATION
    result(nil);
  }

  private func onHandlecastKeepOnTopActionNotification(call: FlutterMethodCall, result: @escaping FlutterResult) {
    // TODO MISSING IMPLEMENTATION
    result(nil);
  }

  private func onHandlecastNotificationDisplayed(call: FlutterMethodCall, result: @escaping FlutterResult) {
    // TODO MISSING IMPLEMENTATION
    result(nil);
  }
}
