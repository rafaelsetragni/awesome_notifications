import Foundation
#if os(iOS) && canImport(AppIntents)
import AppIntents
#endif

/// Where the activities' buttons arrive in the app. The plugin installs the
/// handler; a press that comes before it (the button launched the app) waits
/// until it is installed.
public enum AwnLiveActivityButtons {

    /// (activityId, buttonKey), on the main thread.
    public typealias Handler = (String, String) -> Void

    private static var pending: [(String, String)] = []
    private static var current: Handler?

    /// The plugin's handler. Installing it delivers the presses that waited.
    public static var handler: Handler? {
        get { onMain { current } }
        set {
            onMain {
                current = newValue
                guard let handler = newValue else { return }
                let waiting = pending
                pending.removeAll()
                for (activityId, key) in waiting { handler(activityId, key) }
            }
        }
    }

    /// A button of [activityId] was pressed.
    public static func press(activityId: String, buttonKey: String) {
        onMain {
            if let handler = current {
                handler(activityId, buttonKey)
            } else {
                pending.append((activityId, buttonKey))
            }
        }
    }

    // MARK: - Keeping the app awake until it answers

    private static var waiters: [String: [(id: Int, resume: () -> Void)]] = [:]
    private static var nextWaiter = 0

    /// The app changed [activityId] (ActivityKit applied it): the presses
    /// waiting for it finish.
    public static func activityChanged(_ activityId: String) {
        onMain {
            let waiting = waiters.removeValue(forKey: activityId) ?? []
            for waiter in waiting { waiter.resume() }
        }
    }

    /// Waits until the app changes [activityId], at most [timeout] seconds. A
    /// button's intent waits so iOS keeps the app running while the app (in
    /// Dart) answers the press with an update.
    public static func waitForChange(_ activityId: String, timeout: TimeInterval) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            onMain {
                nextWaiter += 1
                let id = nextWaiter
                var resumed = false
                let resume = {
                    guard !resumed else { return }
                    resumed = true
                    continuation.resume()
                }
                waiters[activityId, default: []].append((id, resume))
                DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                    waiters[activityId]?.removeAll { $0.id == id }
                    resume()
                }
            }
        }
    }

    private static func onMain<T>(_ work: () -> T) -> T {
        Thread.isMainThread ? work() : DispatchQueue.main.sync(execute: work)
    }
}

#if os(iOS) && canImport(AppIntents)
/// A button of an awesome live activity (iOS 17+). Runs in the app's process,
/// in the background, and emits the core's action event as the notification's
/// button would.
@available(iOS 17.0, *)
public struct AwnLiveActivityButtonIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Live activity button"
    public static var isDiscoverable: Bool = false

    @Parameter(title: "Activity")
    public var activityId: String

    @Parameter(title: "Button")
    public var buttonKey: String

    public init() {}

    public init(activityId: String, buttonKey: String) {
        self.activityId = activityId
        self.buttonKey = buttonKey
    }

    public func perform() async throws -> some IntentResult {
        AwnLiveActivityButtons.press(activityId: activityId, buttonKey: buttonKey)
        // The app runs while it answers (its update), then iOS may suspend it.
        await AwnLiveActivityButtons.waitForChange(activityId, timeout: 8)
        return .result()
    }
}

/// A button of an awesome live activity that opens the app (action type
/// `Default`), iOS 17+.
@available(iOS 17.0, *)
public struct AwnLiveActivityOpenAppIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Live activity button (opens the app)"
    public static var isDiscoverable: Bool = false
    public static var openAppWhenRun: Bool = true

    @Parameter(title: "Activity")
    public var activityId: String

    @Parameter(title: "Button")
    public var buttonKey: String

    public init() {}

    public init(activityId: String, buttonKey: String) {
        self.activityId = activityId
        self.buttonKey = buttonKey
    }

    public func perform() async throws -> some IntentResult {
        AwnLiveActivityButtons.press(activityId: activityId, buttonKey: buttonKey)
        // The app runs while it answers (its update), then iOS may suspend it.
        await AwnLiveActivityButtons.waitForChange(activityId, timeout: 8)
        return .result()
    }
}
#endif
