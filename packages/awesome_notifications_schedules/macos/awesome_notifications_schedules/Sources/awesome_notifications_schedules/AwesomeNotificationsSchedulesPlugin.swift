import Cocoa
import FlutterMacOS
import IosAwnCore

/// Scheduling decorator plugin (macOS). Same as iOS: owns no method channel of its own and,
/// on registration, installs a `ScheduleBuilder` into the shared IosAwnCore
/// builder chain (low priority = innermost). ScheduleBuilder/ScheduleKeys are
/// symlinks to the iOS sources (UserNotifications triggers are shared).
public class AwesomeNotificationsSchedulesPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    NotificationBuilderRegistry.shared.register(priority: 10) { inner in
      ScheduleBuilder(inner: inner)
    }
    // cancelSchedule*, listAllSchedules and getNextDate.
    AwesomeMethodHandlerRegistry.shared.register(handler: ScheduleMethodHandler())
  }
}
