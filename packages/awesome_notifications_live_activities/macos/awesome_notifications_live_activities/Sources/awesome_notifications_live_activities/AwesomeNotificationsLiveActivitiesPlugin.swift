import FlutterMacOS
import AppKit
import IosAwnCore

/// Live activities plugin (macOS: no ActivityKit). Installs the live activity
/// builder (the notification replaced in place), the methods and the removal
/// hook, and streams the state changes on its EventChannel.
public class AwesomeNotificationsLiveActivitiesPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    public static func register(with registrar: FlutterPluginRegistrar) {
        LiveActivitiesInstaller.install()
        let events = FlutterEventChannel(name: LiveActivityKeys.eventsChannel, binaryMessenger: registrar.messenger)
        events.setStreamHandler(AwesomeNotificationsLiveActivitiesPlugin())
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        LiveActivityManager.shared.eventSink = { events($0) }
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        LiveActivityManager.shared.eventSink = nil
        return nil
    }
}
