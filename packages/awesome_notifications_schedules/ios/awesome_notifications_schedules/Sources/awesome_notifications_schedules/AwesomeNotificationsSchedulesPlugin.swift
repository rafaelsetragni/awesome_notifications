import Flutter
import UIKit
import IosAwnCore

/// Scheduling decorator plugin (iOS). Owns no method channel: on registration it
/// installs a `ScheduleBuilder` into the core's builder decorator chain (low
/// priority = innermost, so content decorators like localization run first). The
/// core stays unaware of scheduling; without this decorator a notification with a
/// `schedule` is delivered immediately.
public class AwesomeNotificationsSchedulesPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        NotificationBuilderRegistry.shared.register(priority: 10) { inner in
            ScheduleBuilder(inner: inner)
        }
    }
}
