import Foundation
import IosAwnCore
#if canImport(UIKit)
import UIKit
#endif

/// Answers the AwesomeNotificationsLiveActivities channel methods on iOS and
/// macOS.
public final class LiveActivityMethodHandler: AwesomeMethodHandler {

    private let manager: () -> LiveActivityManager
    #if canImport(UIKit)
    private var settingsObserver: NSObjectProtocol?
    #endif

    public init(manager: @escaping () -> LiveActivityManager = { .shared }) {
        self.manager = manager
    }

    public func handle(method: String, arguments: Any?, result: @escaping (Any?) -> Void) -> Bool {
        let map = arguments as? [String: Any] ?? [:]
        switch method {
        case LiveActivityKeys.methodEnd:
            if let activityId = map[LiveActivityKeys.activityId] as? String {
                let dismissal = LiveActivityDismissal.parse(map[LiveActivityKeys.dismissal]) ?? .system
                onMain { self.manager().end(activityId, dismissal: dismissal) }
            }
            result(nil)
        case LiveActivityKeys.methodList:
            result(onMain { self.manager().activities() })
        case LiveActivityKeys.methodCapabilities:
            result(onMain { self.manager().capabilities })
        case LiveActivityKeys.methodAreEnabled:
            result(onMain { self.manager().areEnabled })
        case LiveActivityKeys.methodRequestPermission:
            onMain { self.requestPermission(result) }
        case LiveActivityKeys.methodPushToStartToken:
            result(onMain { self.manager().pushToStartToken })
        case LiveActivityKeys.methodPushToken:
            let activityId = map[LiveActivityKeys.activityId] as? String
            result(onMain { activityId.flatMap { self.manager().pushToken($0) } })
        default:
            return false
        }
        return true
    }

    /// iOS: the app's Settings page (its Live Activities switch) when they
    /// are off, then whether they are on when the user comes back.
    private func requestPermission(_ result: @escaping (Any?) -> Void) {
        let manager = self.manager()
        #if canImport(UIKit) && !os(watchOS)
        guard !manager.areEnabled, let url = URL(string: UIApplication.openSettingsURLString) else {
            result(manager.areEnabled)
            return
        }
        if let observer = settingsObserver { NotificationCenter.default.removeObserver(observer) }
        settingsObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            if let observer = self?.settingsObserver { NotificationCenter.default.removeObserver(observer) }
            self?.settingsObserver = nil
            result(manager.areEnabled)
        }
        UIApplication.shared.open(url) { [weak self] opened in
            guard !opened, let observer = self?.settingsObserver else { return }
            NotificationCenter.default.removeObserver(observer)
            self?.settingsObserver = nil
            result(manager.areEnabled)
        }
        #else
        result(manager.areEnabled)
        #endif
    }

    private func onMain<T>(_ work: () -> T) -> T {
        Thread.isMainThread ? work() : DispatchQueue.main.sync(execute: work)
    }
}
