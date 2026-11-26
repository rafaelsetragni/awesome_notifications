import Flutter
import UIKit
import IosAwnCore

/// Calls plugin (iOS). Installs the call builder in the core's decorator
/// chain, the call methods, the removal / action hooks and PushKit, and
/// streams the commands and the VoIP token on its EventChannel.
public class AwesomeNotificationsCallsPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    /// Call it from `application(_:didFinishLaunchingWithOptions:)` when the
    /// app receives VoIP pushes: a push that launches the app (killed) must
    /// find PushKit and CallKit ready, and the Flutter engine (where the
    /// plugin registers) may start later, or not at all in the background.
    @objc public static func registerAtLaunch() {
        CallsInstaller.install()
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        CallsInstaller.install()
        let events = FlutterEventChannel(name: CallKeys.eventsChannel, binaryMessenger: registrar.messenger())
        events.setStreamHandler(AwesomeNotificationsCallsPlugin())
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        CallManager.shared.eventSink = { events($0) }
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        CallManager.shared.eventSink = nil
        return nil
    }
}
