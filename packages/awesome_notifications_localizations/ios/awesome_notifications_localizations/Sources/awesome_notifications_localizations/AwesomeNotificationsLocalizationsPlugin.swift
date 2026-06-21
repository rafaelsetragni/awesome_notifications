import Flutter
import UIKit

/// Localizations decorator plugin (iOS).
///
/// TODO(iOS): not wired yet — this is a no-op placeholder so the package exposes
/// the iOS platform with the same structure as the base plugin.
///
/// On Android this plugin registers, on engine attach, a content transformer
/// (translates the notification at build time) and a method handler
/// (setLocalization/getLocalization) into the core's decorator seams — see the
/// Kotlin `AwesomeNotificationsLocalizationsPlugin`. The iOS equivalent needs the
/// IosAwnCore decorator seams (`NotificationContentManager` /
/// `AwesomeMethodHandlerRegistry`) to be shared across plugins via Swift Package
/// Manager first. Until that cross-plugin sharing lands, calling
/// `setLocalization` on iOS resolves to no handler (returns not-implemented).
public class AwesomeNotificationsLocalizationsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // No-op until the iOS core decorator seams are shared via SPM.
  }
}
