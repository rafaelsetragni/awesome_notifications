import Flutter
import UIKit
import IosAwnCore

/// Localizations decorator plugin (iOS).
///
/// Owns no method channel: on registration it installs a `LocalizationBuilder`
/// into the core's builder decorator chain (HIGH priority = outermost, so it
/// translates the model before lower-priority decorators like scheduling see it)
/// and plugs a method handler (setLocalization/getLocalization) into the shared
/// method-handler registry. Both plugins depend on the same IosAwnCore package, so
/// these are the same singletons the base plugin's engine reads from. The core
/// stays unaware of localization.
public class AwesomeNotificationsLocalizationsPlugin: NSObject, FlutterPlugin {

    // Retained for the lifetime of the process so the registry keeps working.
    private static let methodHandler = LocalizationMethodHandler()

    public static func register(with registrar: FlutterPluginRegistrar) {
        NotificationBuilderRegistry.shared.register(priority: 100) { inner in
            LocalizationBuilder(inner: inner)
        }
        AwesomeMethodHandlerRegistry.shared.register(handler: methodHandler)
    }
}
