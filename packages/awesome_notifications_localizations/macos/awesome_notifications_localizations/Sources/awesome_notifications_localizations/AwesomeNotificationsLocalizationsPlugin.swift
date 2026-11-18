import Cocoa
import FlutterMacOS
import IosAwnCore

/// Localizations decorator plugin (macOS). Same as iOS: owns no method channel
/// of its own and, on registration, installs a `LocalizationBuilder` into the
/// shared IosAwnCore builder chain (high priority = outermost) and the
/// setLocalization/getLocalization handler. The other sources are symlinks to
/// the iOS ones, so both Apple platforms translate exactly the same way.
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
