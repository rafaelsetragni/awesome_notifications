import Flutter
import UIKit
import IosAwnCore

/// Live activities plugin (iOS). Installs the live activity builder in the
/// core's decorator chain (ActivityKit on iOS 16.1+), the methods, the removal
/// hook and the buttons' handler, and streams the push tokens and the state
/// changes on its EventChannel.
public class AwesomeNotificationsLiveActivitiesPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    /// Optional: call it from `application(_:didFinishLaunchingWithOptions:)`
    /// so a button pressed while the app was killed reaches the core before
    /// the Flutter engine starts.
    @objc public static func registerAtLaunch() {
        LiveActivitiesInstaller.install()
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        LiveActivitiesInstaller.install()
        let events = FlutterEventChannel(name: LiveActivityKeys.eventsChannel, binaryMessenger: registrar.messenger())
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
