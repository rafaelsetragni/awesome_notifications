import Flutter
import UIKit
import IosAwnCore

/// Chat decorator plugin (iOS). Owns no method channel: it installs the
/// `ChatBuilder` in the core's decorator chain (between localization, which
/// translates first, and scheduling, which freezes the model last) and answers
/// the AwesomeNotificationsChat methods through the shared handler registry.
public class AwesomeNotificationsChatPlugin: NSObject, FlutterPlugin {

    private static let methodHandler = ChatMethodHandler()

    public static func register(with registrar: FlutterPluginRegistrar) {
        NotificationBuilderRegistry.shared.register(priority: ChatBuilder.priority) { inner in
            ChatBuilder(inner: inner)
        }
        AwesomeMethodHandlerRegistry.shared.register(handler: methodHandler)
    }
}
