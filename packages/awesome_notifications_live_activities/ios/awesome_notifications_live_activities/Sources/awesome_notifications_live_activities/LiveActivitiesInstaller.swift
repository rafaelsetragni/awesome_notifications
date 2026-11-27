import Foundation
import IosAwnCore
#if canImport(AwesomeNotificationsLiveActivitiesWidget)
import AwesomeNotificationsLiveActivitiesWidget
#endif

/// Installs the package in the core (Flutter-free, idempotent): the builder,
/// the methods, the removal hook and, on iOS, the activities' buttons and the
/// adoption of the activities started by push.
public enum LiveActivitiesInstaller {

    private static var installed = false
    static let methodHandler = LiveActivityMethodHandler()

    public static func install() {
        let work = {
            guard !installed else { return }
            installed = true
            NotificationBuilderRegistry.shared.register(priority: LiveActivityBuilder.priority) { inner in
                LiveActivityBuilder(inner: inner)
            }
            AwesomeMethodHandlerRegistry.shared.register(handler: methodHandler)
            // The app's dismiss / cancel of an activity's notification ends it.
            NotificationRemovalRegistry.shared.register(listener: LiveActivityManager.shared)
            // The activities' buttons (iOS 17+): the core's action event.
            AwnLiveActivityButtons.handler = { activityId, buttonKey in
                LiveActivityManager.shared.buttonPressed(activityId, buttonKey: buttonKey)
            }
            LiveActivityManager.shared.start()
        }
        if Thread.isMainThread { work() } else { DispatchQueue.main.sync(execute: work) }
    }
}
