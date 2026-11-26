import FlutterMacOS
import AppKit
import IosAwnCore

/// Calls plugin (macOS: no CallKit, no PushKit). Installs the call builder
/// in the core's decorator chain (calls shown as time-sensitive notifications
/// with their buttons), the call methods and the removal / action hooks, and
/// streams the commands on its EventChannel.
public class AwesomeNotificationsCallsPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    public static func register(with registrar: FlutterPluginRegistrar) {
        CallsInstaller.install()
        let events = FlutterEventChannel(name: CallKeys.eventsChannel, binaryMessenger: registrar.messenger)
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
