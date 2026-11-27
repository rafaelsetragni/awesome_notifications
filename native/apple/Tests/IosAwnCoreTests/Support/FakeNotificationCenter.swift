import Foundation
import ObjectiveC
import UserNotifications

/// Test double of `UNUserNotificationCenter`.
///
/// A `swift test` process has no app bundle, so the real
/// `UNUserNotificationCenter.current()` raises ("bundleProxyForCurrentProcess is
/// nil"). `install()` swaps the implementation of `+currentNotificationCenter`
/// (test process only) for one returning this object, which answers the same
/// Objective-C selectors the engine sends and records what it was asked.
/// Production code is unchanged: it still calls `UNUserNotificationCenter.current()`.
///
/// Shared by several test targets (symlinked), so it only depends on Apple SDKs.
final class FakeNotificationCenter: NSObject {

    static let shared = FakeNotificationCenter()

    private static var installed = false
    private static let installLock = NSLock()

    /// Routes `UNUserNotificationCenter.current()` to `shared` and resets it.
    static func install() {
        installLock.lock()
        if !installed {
            installed = true
            let method = class_getClassMethod(
                UNUserNotificationCenter.self, NSSelectorFromString("currentNotificationCenter"))!
            let block: @convention(block) (AnyObject) -> AnyObject = { _ in FakeNotificationCenter.shared }
            method_setImplementation(method, imp_implementationWithBlock(block))
        }
        installLock.unlock()
        shared.reset()
    }

    private let lock = NSLock()

    // MARK: - State (configure before, inspect after)

    @objc weak var delegate: AnyObject?
    var categories: Set<UNNotificationCategory> = []
    var setCategoriesCalls = 0
    var added: [UNNotificationRequest] = []
    var addError: Error?
    var delivered: [UNNotification] = []
    var pending: [UNNotificationRequest] = []
    var removedDelivered: [[String]] = []
    var removedPending: [[String]] = []
    var removedAllDelivered = 0
    var removedAllPending = 0
    var settings: UNNotificationSettings = FakeNotificationCenter.makeSettings()
    var settingsReads = 0
    /// While true, settings reads are parked until `releaseSettings()`.
    var holdSettings = false
    private var heldSettingsHandlers: [(UNNotificationSettings) -> Void] = []
    var authorizationGranted = true
    var authorizationError: Error?
    var requestedOptions: UNAuthorizationOptions?

    func reset() {
        lock.lock(); defer { lock.unlock() }
        delegate = nil
        categories = []
        setCategoriesCalls = 0
        added = []
        addError = nil
        delivered = []
        pending = []
        removedDelivered = []
        removedPending = []
        removedAllDelivered = 0
        removedAllPending = 0
        settings = Self.makeSettings()
        settingsReads = 0
        holdSettings = false
        heldSettingsHandlers = []
        authorizationGranted = true
        authorizationError = nil
        requestedOptions = nil
    }

    /// Reads state under the lock (callbacks may run on other threads).
    func read<T>(_ body: (FakeNotificationCenter) -> T) -> T {
        lock.lock(); defer { lock.unlock() }
        return body(self)
    }

    // MARK: - UNUserNotificationCenter selectors

    @objc(getNotificationCategoriesWithCompletionHandler:)
    func getNotificationCategories(_ handler: @escaping (Set<UNNotificationCategory>) -> Void) {
        let current = read { $0.categories }
        handler(current)
    }

    @objc(setNotificationCategories:)
    func setNotificationCategories(_ categories: Set<UNNotificationCategory>) {
        lock.lock(); defer { lock.unlock() }
        self.categories = categories
        setCategoriesCalls += 1
    }

    @objc(requestAuthorizationWithOptions:completionHandler:)
    func requestAuthorization(
        options: UNAuthorizationOptions, completionHandler: @escaping (Bool, Error?) -> Void
    ) {
        lock.lock()
        requestedOptions = options
        let granted = authorizationGranted, error = authorizationError
        lock.unlock()
        DispatchQueue.global().async { completionHandler(granted, error) }
    }

    @objc(getNotificationSettingsWithCompletionHandler:)
    func getNotificationSettings(_ handler: @escaping (UNNotificationSettings) -> Void) {
        lock.lock()
        settingsReads += 1
        let current = settings
        if holdSettings {
            heldSettingsHandlers.append(handler)
            lock.unlock()
            return
        }
        lock.unlock()
        DispatchQueue.global().async { handler(current) }
    }

    /// Answers the settings reads parked while `holdSettings` was on.
    func releaseSettings() {
        lock.lock()
        holdSettings = false
        let handlers = heldSettingsHandlers, current = settings
        heldSettingsHandlers = []
        lock.unlock()
        for handler in handlers { handler(current) }
    }

    @objc(addNotificationRequest:withCompletionHandler:)
    func add(_ request: UNNotificationRequest, withCompletionHandler handler: ((Error?) -> Void)?) {
        lock.lock()
        let error = addError
        if error == nil { added.append(request) }
        lock.unlock()
        DispatchQueue.global().async { handler?(error) }
    }

    @objc(removeDeliveredNotificationsWithIdentifiers:)
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        lock.lock(); defer { lock.unlock() }
        removedDelivered.append(identifiers)
    }

    @objc(removePendingNotificationRequestsWithIdentifiers:)
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        lock.lock(); defer { lock.unlock() }
        removedPending.append(identifiers)
    }

    @objc func removeAllDeliveredNotifications() {
        lock.lock(); defer { lock.unlock() }
        removedAllDelivered += 1
    }

    @objc func removeAllPendingNotificationRequests() {
        lock.lock(); defer { lock.unlock() }
        removedAllPending += 1
    }

    @objc(getDeliveredNotificationsWithCompletionHandler:)
    func getDeliveredNotifications(_ handler: @escaping ([UNNotification]) -> Void) {
        let current = read { $0.delivered }
        DispatchQueue.global().async { handler(current) }
    }

    @objc(getPendingNotificationRequestsWithCompletionHandler:)
    func getPendingNotificationRequests(_ handler: @escaping ([UNNotificationRequest]) -> Void) {
        let current = read { $0.pending }
        DispatchQueue.global().async { handler(current) }
    }

    // MARK: - Factories of the system types without public initializers

    /// `UNNotificationSettings` with the given values (the rest `.notSupported`).
    static func makeSettings(
        authorizationStatus: UNAuthorizationStatus = .authorized,
        alert: UNNotificationSetting = .enabled,
        sound: UNNotificationSetting = .enabled,
        badge: UNNotificationSetting = .enabled,
        criticalAlert: UNNotificationSetting = .notSupported
    ) -> UNNotificationSettings {
        let empty = UNNotificationSettings.perform(NSSelectorFromString("emptySettings"))!
            .takeUnretainedValue() as! NSObject
        let settings = empty.mutableCopy() as! NSObject
        settings.setValue(NSNumber(value: authorizationStatus.rawValue), forKey: "authorizationStatus")
        settings.setValue(NSNumber(value: alert.rawValue), forKey: "alertSetting")
        settings.setValue(NSNumber(value: sound.rawValue), forKey: "soundSetting")
        settings.setValue(NSNumber(value: badge.rawValue), forKey: "badgeSetting")
        settings.setValue(NSNumber(value: criticalAlert.rawValue), forKey: "criticalAlertSetting")
        return settings as! UNNotificationSettings
    }

    /// The trigger of a remote (push) notification.
    static func pushTrigger() -> UNNotificationTrigger {
        typealias Factory = @convention(c) (AnyObject, Selector, Bool, Bool) -> AnyObject
        let selector = NSSelectorFromString("triggerWithContentAvailable:mutableContent:")
        let method = class_getClassMethod(UNPushNotificationTrigger.self, selector)!
        let factory = unsafeBitCast(method_getImplementation(method), to: Factory.self)
        return factory(UNPushNotificationTrigger.self, selector, false, true) as! UNNotificationTrigger
    }

    /// A delivered `UNNotification` for [request].
    static func notification(_ request: UNNotificationRequest, date: Date = Date()) -> UNNotification {
        return UNNotification.perform(
            NSSelectorFromString("notificationWithRequest:date:"), with: request, with: date)!
            .takeUnretainedValue() as! UNNotification
    }

    /// The user's response [actionIdentifier] to [notification].
    static func response(_ notification: UNNotification, action: String) -> UNNotificationResponse {
        return UNNotificationResponse.perform(
            NSSelectorFromString("responseWithNotification:actionIdentifier:"),
            with: notification, with: action)!
            .takeUnretainedValue() as! UNNotificationResponse
    }

    /// A text-input response carrying [text].
    static func textResponse(
        _ notification: UNNotification, action: String, text: String
    ) -> UNTextInputNotificationResponse {
        typealias Factory = @convention(c) (AnyObject, Selector, AnyObject, AnyObject, AnyObject) -> AnyObject
        let selector = NSSelectorFromString("responseWithNotification:actionIdentifier:userText:")
        let method = class_getClassMethod(UNTextInputNotificationResponse.self, selector)!
        let factory = unsafeBitCast(method_getImplementation(method), to: Factory.self)
        return factory(UNTextInputNotificationResponse.self, selector,
                       notification, action as NSString, text as NSString)
            as! UNTextInputNotificationResponse
    }
}
