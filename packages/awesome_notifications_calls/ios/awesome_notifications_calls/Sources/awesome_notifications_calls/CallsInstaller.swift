import Foundation
import IosAwnCore

/// Installs the package in the core (Flutter-free, idempotent): the builder,
/// the methods, the removal and action hooks and, on iOS, PushKit. Runs from
/// the plugin's registration, or earlier from the app delegate so a VoIP push
/// that launches the app finds it ready before the Flutter engine.
public enum CallsInstaller {

    private static var installed = false
    static let methodHandler = CallMethodHandler()

    public static func install() {
        let work = {
            guard !installed else { return }
            installed = true
            NotificationBuilderRegistry.shared.register(priority: CallBuilder.priority) { inner in
                CallBuilder(inner: inner)
            }
            AwesomeMethodHandlerRegistry.shared.register(handler: methodHandler)
            // The app's dismiss / cancel of a call's notification ends the call.
            NotificationRemovalRegistry.shared.register(listener: CallManager.shared)
            // The call notifications' buttons (macOS, systemCallUI: false).
            NotificationActionInterceptorRegistry.shared.register(interceptor: CallManager.shared)
            #if os(iOS)
            CallVoipPush.shared.start()
            #endif
        }
        if Thread.isMainThread { work() } else { DispatchQueue.main.sync(execute: work) }
    }
}
