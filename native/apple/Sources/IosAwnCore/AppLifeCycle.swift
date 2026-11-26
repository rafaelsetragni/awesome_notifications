import Foundation

/// The app's current lifecycle, as the original core's `LifeCycleManager`: the
/// platform bridge (iOS / macOS plugin) feeds it from the app's state changes,
/// and the core stamps it on the events it registers (created, and displayed
/// while the app is running). Kept here, Flutter- and UIKit/AppKit-free, so the
/// core stays usable without an application object (e.g. an app extension).
public enum AppLifeCycle {

    private static let lock = NSLock()
    private static var value: NotificationLifeCycle = .foreground

    public static var current: NotificationLifeCycle {
        get { lock.lock(); defer { lock.unlock() }; return value }
        set { lock.lock(); value = newValue; lock.unlock() }
    }
}
