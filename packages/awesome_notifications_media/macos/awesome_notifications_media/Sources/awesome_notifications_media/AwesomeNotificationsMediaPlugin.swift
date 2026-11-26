import FlutterMacOS
import AppKit
import IosAwnCore

/// Media decorator plugin (macOS). Installs the `MediaBuilder` in the core's
/// decorator chain, answers the AwesomeNotificationsMedia methods through the
/// shared handler registry and streams the commands on its EventChannel.
public class AwesomeNotificationsMediaPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    private static let methodHandler = MediaMethodHandler()

    public static func register(with registrar: FlutterPluginRegistrar) {
        NotificationBuilderRegistry.shared.register(priority: MediaBuilder.priority) { inner in
            MediaBuilder(inner: inner)
        }
        AwesomeMethodHandlerRegistry.shared.register(handler: methodHandler)
        // The app's dismiss / cancel of a session's notification ends it.
        NotificationRemovalRegistry.shared.register(listener: MediaSessions.shared)
        let events = FlutterEventChannel(name: MediaKeys.commandsChannel, binaryMessenger: registrar.messenger)
        events.setStreamHandler(AwesomeNotificationsMediaPlugin())
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        MediaSessions.shared.streamSink = { events($0) }
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        MediaSessions.shared.streamSink = nil
        return nil
    }
}
