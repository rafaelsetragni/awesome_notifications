import Flutter
import UIKit
import IosAwnCore

/// Scheduling decorator plugin (iOS).
///
/// Owns no method channel: on registration it plugs a schedule provider into the
/// core's `NotificationScheduleManager` — the same IosAwnCore singleton the base
/// plugin's engine reads from (both plugins depend on the same IosAwnCore
/// package). The core stays unaware of scheduling; without this decorator a
/// notification with a `schedule` is simply delivered immediately.
public class AwesomeNotificationsSchedulesPlugin: NSObject, FlutterPlugin {

    // Retained for the process lifetime so the registry keeps working.
    private static let provider = ScheduleProvider()

    public static func register(with registrar: FlutterPluginRegistrar) {
        NotificationScheduleManager.shared.register(provider: provider)
    }
}
