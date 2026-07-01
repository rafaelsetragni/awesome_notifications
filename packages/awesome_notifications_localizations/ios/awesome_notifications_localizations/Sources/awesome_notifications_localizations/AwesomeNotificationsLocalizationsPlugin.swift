import Flutter
import UIKit
import IosAwnCore

/// Localizations decorator plugin (iOS).
///
/// Owns no method channel: on registration it plugs a content transformer
/// (translates the notification at build time) and a method handler
/// (setLocalization/getLocalization) into the core's decorator seams — the same
/// IosAwnCore singletons the base plugin's engine reads from (both plugins depend
/// on the same IosAwnCore package). The core stays unaware of localization.
public class AwesomeNotificationsLocalizationsPlugin: NSObject, FlutterPlugin {

    // Retained for the lifetime of the process so the registries keep working.
    private static let transformer = LocalizationTransformer()
    private static let methodHandler = LocalizationMethodHandler()

    public static func register(with registrar: FlutterPluginRegistrar) {
        NotificationContentManager.shared.register(transformer: transformer)
        AwesomeMethodHandlerRegistry.shared.register(handler: methodHandler)
    }
}
