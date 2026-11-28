import Foundation
import UserNotifications

/// Flutter-free notification engine for Apple platforms (iOS & macOS).
///
/// This type is intentionally free of any Flutter dependency: it is shared by the
/// Flutter plugin (app side) and, later, by the Notification Service Extension
/// (push side), which links this core *without* the Flutter engine.
///
/// Delegates building/payload-injection/event-stamping to `NotificationBuilder`
/// and broadcasts lifecycle events through `AwesomeEventsReceiver`.
public final class AwesomeNotifications: NSObject, UNUserNotificationCenterDelegate {

    public static let shared = AwesomeNotifications()
    private override init() { super.init() }

    private var center: UNUserNotificationCenter { .current() }
    private let builder = NotificationBuilder.newInstance()
    /// Real displayed lifecycle of notifications shown with the app open.
    private let displayedTracker = DisplayedLifecycleTracker()

    /// iOS/macOS have no notification channels; the channel config (sound,
    /// importance, critical alerts, …) is kept in `ChannelManager` and honored
    /// per channelKey by the builder.
    private var channels: ChannelManager { .shared }

    // Initial-action (launch) state. Until the launch phase settles, an action
    // arriving through `didReceive` is the one that launched the app.
    private var didFinishLaunch = false
    private var initialAction: [String: Any]?
    private var removeInitialActionFromEvents = false
    /// A `getInitialAction` request that arrived before the launch settled.
    private var pendingInitialActionCompletion: (([String: Any]?) -> Void)?

    // MARK: - Initialization

    public func initialize(channels: [[String: Any]]) {
        // Receive willPresent / didReceive callbacks: foreground display, taps
        // and dismissals.
        center.delegate = self
        registerDefaultCategory()
        for channel in channels {
            registerChannel(channel)
        }
    }

    public func setChannel(_ channel: [String: Any]) {
        registerChannel(channel)
    }

    /// 0.12: a notification without a group key takes its channel's.
    private func withChannelGroupKey(_ model: [String: Any]) -> [String: Any] {
        var content = builder.contentMap(fromModel: model)
        if let groupKey = content[Definitions.NOTIFICATION_GROUP_KEY] as? String, !groupKey.isEmpty {
            return model
        }
        guard let channelKey = content[Definitions.NOTIFICATION_CHANNEL_KEY] as? String,
              let groupKey = channels.channel(forKey: channelKey)?[Definitions.NOTIFICATION_GROUP_KEY] as? String,
              !groupKey.isEmpty else { return model }
        content[Definitions.NOTIFICATION_GROUP_KEY] = groupKey
        var updated = model
        updated[Definitions.NOTIFICATION_CONTENT] = content
        return updated
    }

    private func registerChannel(_ channel: [String: Any]) {
        channels.setChannel(channel)
    }

    /// Registers a category with `.customDismissAction` so the system reports
    /// when the user swipes a notification away (otherwise dismiss is silent).
    private func registerDefaultCategory() {
        let category = UNNotificationCategory(
            identifier: Definitions.DEFAULT_CATEGORY_IDENTIFIER,
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        registerCategory(category)
    }

    /// Adds a category to the notification center, keeping the existing ones.
    private func registerCategory(_ category: UNNotificationCategory) {
        center.getNotificationCategories { existing in
            // Replace any same-identifier category, then add the new one.
            let kept = existing.filter { $0.identifier != category.identifier }
            self.center.setNotificationCategories(Set(kept).union([category]))
        }
    }

    // MARK: - Permissions

    public func requestPermission(_ completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            // 0.12.1: the answer may change the critical-alert availability.
            CriticalAlertUtils.clearCache()
            if let error = error {
                // e.g. UNErrorDomain 1 "Notifications are not allowed for this
                // application" — an unsigned/ad-hoc macOS build can't ask.
                NSLog("[AwesomeNotifications] requestAuthorization failed: %@", "\(error)")
            }
            DispatchQueue.main.async { completion(granted) }
        }
    }

    public func isNotificationAllowed(_ completion: @escaping (Bool) -> Void) {
        center.getNotificationSettings { settings in
            CriticalAlertUtils.updateCache(from: settings)
            let allowed = settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
            DispatchQueue.main.async { completion(allowed) }
        }
    }

    /// 0.12.1 `getPermissionStatuses`: each permission name → `granted`,
    /// `denied`, `notDetermined` or `notSupported` (answered on main).
    public func getPermissionStatuses(
        _ permissions: [String],
        filteringByChannelKey channelKey: String?,
        whenGotResults completion: @escaping ([String: String]) -> Void
    ) {
        PermissionManager.shared.getPermissionStatuses(
            permissions, filteringByChannelKey: channelKey
        ) { statuses in
            DispatchQueue.main.async { completion(statuses) }
        }
    }

    // MARK: - Launch / initial action

    /// Claims the notification-center delegate as early as the plugin registers.
    /// Apple requires the delegate to be assigned *before the app finishes
    /// launching*; otherwise a notification that launched a killed app is dropped
    /// by the system instead of being delivered via `didReceive` — which is
    /// exactly the getInitialAction path. Under UIScene the plugin registers
    /// during scene connection, so this must not be deferred to `initialize`.
    public func attachToNotificationCenter() {
        center.delegate = self
    }

    /// Marks the launch phase complete and resolves any pending
    /// `getInitialAction`. Idempotent — called both from the platform's "app
    /// became active" signal (via the plugin bridge, which owns UIKit) and from
    /// `didReceive` once the launch action is captured, whichever happens first.
    public func finishLaunching() {
        if didFinishLaunch { return }
        didFinishLaunch = true
        if let completion = pendingInitialActionCompletion {
            let action = initialAction
            if removeInitialActionFromEvents { initialAction = nil }
            completion(action)
            pendingInitialActionCompletion = nil
        }
    }

    /// Returns the action that launched the app, or nil. Reliable under both the
    /// classic and UIScene lifecycles: if the launch hasn't settled yet, the
    /// request is parked and answered by `finishLaunching()`.
    public func getInitialAction(
        removeFromEvents: Bool,
        completion: @escaping ([String: Any]?) -> Void
    ) {
        if didFinishLaunch {
            let action = initialAction
            if removeFromEvents { initialAction = nil }
            completion(action)
            return
        }
        removeInitialActionFromEvents = removeFromEvents
        pendingInitialActionCompletion = completion
    }

    // MARK: - Create / display

    /// Builds and delivers a notification from a serialized `NotificationModel`
    /// (the same map produced by the Dart `NotificationModel.toMap()`).
    public func createNotification(
        _ rawNotification: [String: Any],
        completion: @escaping (Bool) -> Void
    ) {
        createNotification(rawNotification, completion: completion) { _ in
            completion(false)
        }
    }

    /// Same as `createNotification(_:completion:)`, but a decorator's rejection
    /// (an `AwesomeNotificationsException` thrown while building) is reported to
    /// [failure] instead of as `false`.
    public func createNotification(
        _ rawNotification: [String: Any],
        completion: @escaping (Bool) -> Void,
        failure: @escaping (AwesomeNotificationsException) -> Void
    ) {
        // Build off the main thread (image loading does I/O), once the
        // critical-alert availability is resolved (async, never blocking), so
        // the builder's synchronous check reads the real value (0.12.1).
        CriticalAlertUtils.ensureAvailabilityResolved { [weak self] in
            DispatchQueue.global(qos: .userInitiated).async {
                self?.buildAndDeliver(rawNotification, completion: completion, failure: failure)
            }
        }
    }

    private func buildAndDeliver(
        _ rawNotification: [String: Any],
        completion: @escaping (Bool) -> Void,
        failure: @escaping (AwesomeNotificationsException) -> Void
    ) {
        // Build through the decorator chain (localization, scheduling, …),
        // composed in priority order by the registry. Each decorator may
        // transform the model and/or contribute a delivery trigger.
        let builder = NotificationBuilderRegistry.shared.makeBuilder()
        let chained: BuiltNotification?
        do {
            chained = try builder.build(model: self.withChannelGroupKey(rawNotification))
        } catch let exception as AwesomeNotificationsException {
            DispatchQueue.main.async { failure(exception) }
            return
        } catch {
            DispatchQueue.main.async { completion(false) }
            return
        }
        guard let chained = chained else {
            DispatchQueue.main.async { completion(false) }
            return
        }
        // A decorator took over delivery (as Android's BuildOutcome.Handled):
        // nothing to post, but it was created and shown like any other.
        if chained.isHandled {
            let model = builder.stampHandledLifecycle(into: chained.model)
            let content = builder.contentMap(fromModel: model)
            self.displayedTracker.forget(id: chained.id)
            self.emit(
                Definitions.EVENT_NOTIFICATION_CREATED,
                builder.registerCreatedEvent(content, lifeCycle: AppLifeCycle.current))
            self.emit(Definitions.EVENT_NOTIFICATION_DISPLAYED, content)
            DispatchQueue.main.async { completion(true) }
            return
        }

        // Bake the (predicted) displayed lifecycle into the stored payload now
        // that the trigger is known, so the createdDate + displayedDate both
        // round-trip to the displayed/action events (a tapped notification
        // otherwise reports them as null).
        let built = builder.stampDisplayed(on: chained)

        // Register the per-notification action-button category (if any) so
        // iOS shows the buttons and reports which one was pressed.
        if let category = builder.actionCategory(forModel: built.model) {
            self.registerCategory(category)
        }

        // A scheduling decorator contributes a trigger from the notification's
        // `schedule`; otherwise nil delivers it immediately.
        // A new notification reusing an id starts with no display record.
        self.displayedTracker.forget(id: built.id)
        let request = UNNotificationRequest(
            identifier: String(built.id),
            content: built.content,
            trigger: built.trigger
        )
        self.center.add(request) { error in
            let created = error == nil
            if created {
                let content = builder.contentMap(fromModel: built.model)
                self.emit(
                    Definitions.EVENT_NOTIFICATION_CREATED,
                    builder.registerCreatedEvent(content, lifeCycle: AppLifeCycle.current)
                )
            }
            DispatchQueue.main.async { completion(created) }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        #if os(macOS)
        // macOS hands every push to the running app, where the add-on (FCM)
        // builds it as an awesome notification: the system's raw copy of that
        // push would show it twice.
        if notification.request.trigger is UNPushNotificationTrigger,
           builder.notificationModel(fromUserInfo: notification.request.content.userInfo) == nil,
           RemoteModelProviderRegistry.shared.model(from: notification.request) != nil {
            completionHandler([])
            return
        }
        #endif
        if let model = builder.notificationModel(
            fromUserInfo: notification.request.content.userInfo
        ) {
            let content = builder.contentMap(fromModel: model)
            // As the original core: displayed in the app's current lifecycle.
            let lifeCycle = AppLifeCycle.current
            let displayed = builder.registerDisplayedEvent(content, lifeCycle: lifeCycle)
            if let id = builder.readId(content),
               let date = displayed[Definitions.NOTIFICATION_DISPLAYED_DATE] as? String {
                displayedTracker.recordDisplay(id: id, date: date, lifeCycle: lifeCycle)
            }
            emit(Definitions.EVENT_NOTIFICATION_DISPLAYED, displayed)
        }
        if #available(iOS 14.0, macOS 11.0, *) {
            completionHandler([.banner, .list, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let model = builder.notificationModel(
            fromUserInfo: response.notification.request.content.userInfo
        ) {
            // The stored content carries the displayed lifecycle predicted at
            // creation; correct it if the notification was shown in foreground.
            let stored = builder.contentMap(fromModel: model)
            var content = displayedTracker.resolve(stored, id: builder.readId(stored))
            let actionId = response.actionIdentifier
            let systemDismiss = actionId == UNNotificationDismissActionIdentifier
            let defaultTap = actionId == UNNotificationDefaultActionIdentifier
            // Anything else is one of our button keys.
            let buttonKey = (systemDismiss || defaultTap) ? "" : actionId
            let pressedButton = builder.findButton(inModel: model, key: buttonKey)
            // An add-on may act on its own buttons first, and keep the event.
            let emitEvent = buttonKey.isEmpty
                || NotificationActionInterceptorRegistry.shared.shouldEmit(model: model, buttonKey: buttonKey)

            // Carry the pressed button key + any typed text back to Dart.
            if !buttonKey.isEmpty {
                content[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED] = buttonKey
                if let textResponse = response as? UNTextInputNotificationResponse {
                    content[Definitions.NOTIFICATION_BUTTON_KEY_INPUT] = textResponse.userText
                }
            }

            // A swipe, a DismissAction notification, or a DismissAction button all
            // count as a dismissal.
            let isDismiss = systemDismiss
                || (buttonKey.isEmpty && builder.isDismissAction(content))
                || builder.buttonActionType(pressedButton) == .dismissAction

            if isDismiss {
                if !systemDismiss, let id = builder.readId(content) {
                    dismiss(id: id)
                }
                if emitEvent {
                    emit(
                        Definitions.EVENT_NOTIFICATION_DISMISSED,
                        builder.registerDismissedEvent(content, lifeCycle: .foreground)
                    )
                }
            } else {
                // Default tap, or a non-dismiss button. Auto-dismiss the button's
                // notification when requested (a plain tap is auto-dismissed by iOS).
                if !buttonKey.isEmpty,
                   builder.shouldButtonAutoDismiss(pressedButton),
                   let id = builder.readId(content) {
                    dismiss(id: id)
                }
                if !emitEvent {
                    completionHandler()
                    return
                }
                // If the launch phase hasn't settled yet, this notification is the
                // one that launched the app from a killed state: capture it as the
                // initial action and settle any pending getInitialAction with it.
                let launchAction = !didFinishLaunch
                let actionMap = builder.registerActionEvent(
                    content,
                    lifeCycle: launchAction ? .terminated : .foreground,
                    actionType: builder.buttonActionType(pressedButton)
                )
                if launchAction {
                    initialAction = actionMap
                    finishLaunching()
                }
                emit(Definitions.EVENT_DEFAULT_ACTION, actionMap)
            }
        }
        completionHandler()
    }

    // MARK: - Controls that are not buttons

    /// Emits the action (or dismiss) event of [model] for the control
    /// [buttonKey], with [input] as its typed value, as a pressed button does
    /// (see `NotificationBuilder.controlEvent`). For add-ons whose controls are
    /// not notification buttons: a media remote command, for instance.
    public func dispatchAction(
        model: [String: Any],
        buttonKey: String,
        input: String? = nil,
        button: [String: Any]? = nil
    ) {
        let event = builder.controlEvent(
            model: model, buttonKey: buttonKey, input: input, button: button,
            lifeCycle: AppLifeCycle.current)
        if let id = event.dismissId { dismiss(id: id) }
        emit(event.eventName, event.data)
    }

    // MARK: - Dismiss / cancel

    public func dismiss(id: Int) {
        NotificationRemovalRegistry.shared.notify(.id(id), cancel: false)
        displayedTracker.forget(id: id)
        center.removeDeliveredNotifications(withIdentifiers: [String(id)])
    }

    public func cancel(id: Int) {
        NotificationRemovalRegistry.shared.notify(.id(id), cancel: true)
        displayedTracker.forget(id: id)
        let identifiers = [String(id)]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    public func dismissAllNotifications() {
        NotificationRemovalRegistry.shared.notify(.all, cancel: false)
        displayedTracker.forgetAll()
        center.removeAllDeliveredNotifications()
    }

    public func cancelAll() {
        NotificationRemovalRegistry.shared.notify(.all, cancel: true)
        displayedTracker.forgetAll()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    // dismiss* removes the visible notification (keeps the schedule); cancel* also
    // removes the pending request (which will be the schedule once that exists).

    public func dismissByChannelKey(_ channelKey: String) {
        NotificationRemovalRegistry.shared.notify(.channelKey(channelKey), cancel: false)
        removeDelivered(matchingKey: Definitions.NOTIFICATION_CHANNEL_KEY, value: channelKey)
    }

    public func dismissByGroupKey(_ groupKey: String) {
        NotificationRemovalRegistry.shared.notify(.groupKey(groupKey), cancel: false)
        removeDelivered(matchingKey: Definitions.NOTIFICATION_GROUP_KEY, value: groupKey)
    }

    public func cancelByChannelKey(_ channelKey: String) {
        NotificationRemovalRegistry.shared.notify(.channelKey(channelKey), cancel: true)
        removeDelivered(matchingKey: Definitions.NOTIFICATION_CHANNEL_KEY, value: channelKey)
        removePending(matchingKey: Definitions.NOTIFICATION_CHANNEL_KEY, value: channelKey)
    }

    public func cancelByGroupKey(_ groupKey: String) {
        NotificationRemovalRegistry.shared.notify(.groupKey(groupKey), cancel: true)
        removeDelivered(matchingKey: Definitions.NOTIFICATION_GROUP_KEY, value: groupKey)
        removePending(matchingKey: Definitions.NOTIFICATION_GROUP_KEY, value: groupKey)
    }

    // MARK: - Helpers

    /// Content fields the 0.12 Apple events never carried (its content model
    /// never read `category` / `fullScreenIntent`, and its events came without
    /// `wakeUpScreen`): Dart reads them as null / false. They stay in the model,
    /// where the builder uses them (wakeUpScreen → interruption level).
    static let fieldsAbsentFromEvents = [
        Definitions.NOTIFICATION_CATEGORY,
        Definitions.NOTIFICATION_FULL_SCREEN_INTENT,
        Definitions.NOTIFICATION_WAKE_UP_SCREEN,
    ]

    private func emit(_ eventName: String, _ data: [String: Any]) {
        var data = data
        for key in Self.fieldsAbsentFromEvents { data.removeValue(forKey: key) }
        AwesomeEventsReceiver.shared.notifyAwesomeEvent(eventType: eventName, content: data)
    }

    /// Reads a stored content string (channelKey/groupKey) from a notification's
    /// injected payload.
    private func contentString(_ userInfo: [AnyHashable: Any], _ key: String) -> String? {
        guard let model = builder.notificationModel(fromUserInfo: userInfo) else {
            return nil
        }
        return builder.contentMap(fromModel: model)[key] as? String
    }

    private func removeDelivered(matchingKey key: String, value: String) {
        center.getDeliveredNotifications { [weak self] delivered in
            guard let self = self else { return }
            let ids = delivered
                .filter { self.contentString($0.request.content.userInfo, key) == value }
                .map { $0.request.identifier }
            if !ids.isEmpty {
                self.center.removeDeliveredNotifications(withIdentifiers: ids)
            }
        }
    }

    private func removePending(matchingKey key: String, value: String) {
        center.getPendingNotificationRequests { [weak self] pending in
            guard let self = self else { return }
            let ids = pending
                .filter { self.contentString($0.content.userInfo, key) == value }
                .map { $0.identifier }
            if !ids.isEmpty {
                self.center.removePendingNotificationRequests(withIdentifiers: ids)
            }
        }
    }
}
