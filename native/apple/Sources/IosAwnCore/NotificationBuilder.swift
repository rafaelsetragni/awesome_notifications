import Foundation
import UserNotifications

/// Builds notifications from a serialized `NotificationModel`, injects the full
/// model into the delivered notification so it can be recovered later, and
/// stamps the lifecycle events (created/displayed/pressed/dismissed).
///
/// Created via a factory (an instance with injected helpers — not static utility
/// methods), mirroring the original IosAwnCore `NotificationBuilder`.
/// The deliverable produced by the builder chain: the built content plus an
/// optional delivery trigger contributed by a scheduling decorator.
public struct BuiltNotification {
    public let id: Int
    public let content: UNMutableNotificationContent
    public let trigger: UNNotificationTrigger?
    /// The (possibly decorator-transformed) model, so the caller stamps events
    /// from the same content that was built.
    public let model: [String: Any]
    public init(
        id: Int,
        content: UNMutableNotificationContent,
        trigger: UNNotificationTrigger? = nil,
        model: [String: Any]
    ) {
        self.id = id
        self.content = content
        self.trigger = trigger
        self.model = model
    }
}

open class NotificationBuilder {

    public static func newInstance() -> NotificationBuilder {
        return NotificationBuilder()
    }

    /// The wrapped inner builder — the next in the decorator chain; nil for the
    /// base builder.
    private let inner: NotificationBuilder?
    public init(inner: NotificationBuilder? = nil) {
        self.inner = inner
    }

    private let stringUtils = StringUtils.shared
    private let mapUtils = MapUtils.shared
    private let jsonUtils = JsonUtils.shared

    // MARK: - Decorator chain

    /// Produces the deliverable for a model. The base builds the content (no
    /// trigger); a decorator overrides this, does its work, and calls [next] to
    /// delegate to the wrapped builder. The registry composes the chain in
    /// priority order so the build order is predictable.
    open func build(model: [String: Any]) -> BuiltNotification? {
        // Stamp the created lifecycle into the content BEFORE building, so it is
        // stored in the delivered notification's userInfo and round-trips to the
        // displayed/action events (otherwise a tapped notification reports a null
        // createdDate). Mirrors the original core's registerCreateEvent.
        let stampedModel = stampCreatedLifecycle(into: model)
        guard let (id, content) = createNotificationContent(fromModel: stampedModel) else {
            return nil
        }
        return BuiltNotification(id: id, content: content, trigger: nil, model: stampedModel)
    }

    /// Delegates to the wrapped inner builder (called by decorators).
    public func next(_ model: [String: Any]) -> BuiltNotification? {
        return inner?.build(model: model)
    }

    // MARK: - Lifecycle stamping (persisted into the stored content)

    /// Returns a copy of [model] with the created lifecycle (date/source/lifeCycle)
    /// merged into its `content` sub-map, unless already present. Persisting it in
    /// the content is what lets a later displayed/action event carry the
    /// createdDate — the original core stamped it the same way.
    public func stampCreatedLifecycle(
        into model: [String: Any],
        lifeCycle: NotificationLifeCycle = .foreground,
        source: NotificationSource = .local
    ) -> [String: Any] {
        var result = model
        var content = contentMap(fromModel: model)
        if content[Definitions.NOTIFICATION_CREATED_DATE] == nil {
            content[Definitions.NOTIFICATION_CREATED_DATE] = now()
            content[Definitions.NOTIFICATION_CREATED_LIFECYCLE] = lifeCycle.rawValue
            content[Definitions.NOTIFICATION_CREATED_SOURCE] = source.rawValue
        }
        result[Definitions.NOTIFICATION_CONTENT] = content
        return result
    }

    /// Returns a copy of [model] with the displayed lifecycle merged into its
    /// `content` sub-map. For an immediate notification the caller passes the
    /// created date/lifecycle; for a scheduled one, the (predicted) fire date and
    /// the `AppKilled` lifecycle (it may be shown while the app is not foreground).
    public func stampDisplayedLifecycle(
        into model: [String: Any],
        displayedDate: String,
        lifeCycle: NotificationLifeCycle
    ) -> [String: Any] {
        var result = model
        var content = contentMap(fromModel: model)
        content[Definitions.NOTIFICATION_DISPLAYED_DATE] = displayedDate
        content[Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE] = lifeCycle.rawValue
        result[Definitions.NOTIFICATION_CONTENT] = content
        return result
    }

    /// Bakes the (predicted) displayed lifecycle into a built notification's stored
    /// userInfo, returning the updated deliverable. Immediate → displayed == created
    /// (foreground); scheduled → the trigger's next fire date, lifecycle terminated
    /// (it may be shown while the app is not running).
    public func stampDisplayed(on built: BuiltNotification) -> BuiltNotification {
        let displayedDate: String
        let lifeCycle: NotificationLifeCycle
        if let fireDate = nextTriggerDate(built.trigger) {
            displayedDate = fireDate
            lifeCycle = .terminated
        } else {
            let content = contentMap(fromModel: built.model)
            displayedDate =
                (content[Definitions.NOTIFICATION_CREATED_DATE] as? String) ?? now()
            lifeCycle = .foreground
        }
        let updatedModel = stampDisplayedLifecycle(
            into: built.model, displayedDate: displayedDate, lifeCycle: lifeCycle)
        // Rewrite the stored payload so the delivered notification carries it.
        if let json = jsonUtils.toJson(updatedModel) {
            built.content.userInfo[Definitions.NOTIFICATION_JSON] = json
        }
        return BuiltNotification(
            id: built.id, content: built.content,
            trigger: built.trigger, model: updatedModel)
    }

    /// The next fire date of a delivery trigger (interval or calendar), formatted
    /// like the other lifecycle dates, or nil for an immediate (nil) trigger.
    private func nextTriggerDate(_ trigger: UNNotificationTrigger?) -> String? {
        if let calendar = trigger as? UNCalendarNotificationTrigger,
           let date = calendar.nextTriggerDate() {
            return format(date)
        }
        if let interval = trigger as? UNTimeIntervalNotificationTrigger,
           let date = interval.nextTriggerDate() {
            return format(date)
        }
        return nil
    }

    // MARK: - Build

    /// Builds the content for a notification from a serialized model, injecting
    /// the full model JSON so it can be recovered on display/tap/dismiss.
    /// Returns the notification id and the built content, or nil if invalid.
    public func createNotificationContent(
        fromModel model: [String: Any]
    ) -> (id: Int, content: UNMutableNotificationContent)? {
        let content = contentMap(fromModel: model)
        guard let id = mapUtils.getInt(content[Definitions.NOTIFICATION_ID]) else {
            return nil
        }

        let unContent = UNMutableNotificationContent()
        let title = mapUtils.getString(content[Definitions.NOTIFICATION_TITLE])
        if !stringUtils.isNullOrEmpty(title) { unContent.title = title! }
        let body = mapUtils.getString(content[Definitions.NOTIFICATION_BODY])
        if !stringUtils.isNullOrEmpty(body) { unContent.body = body! }
        unContent.sound = .default
        unContent.categoryIdentifier = categoryIdentifier(forModel: model)

        applyImages(content, to: unContent)
        setUserInfoContent(model: model, content: unContent)
        return (id, unContent)
    }

    // MARK: - Action buttons

    /// The serialized action buttons of a model (the `actionButtons` list).
    public func actionButtons(fromModel model: [String: Any]) -> [[String: Any]] {
        return (model[Definitions.NOTIFICATION_BUTTONS] as? [[String: Any]]) ?? []
    }

    /// The category identifier a notification should use: `DEFAULT` when it has
    /// no buttons, otherwise a deterministic id derived from the button keys so
    /// the same set of buttons reuses the same registered category.
    public func categoryIdentifier(forModel model: [String: Any]) -> String {
        let keys = actionButtons(fromModel: model)
            .compactMap { mapUtils.getString($0[Definitions.NOTIFICATION_BUTTON_KEY]) }
            .filter { !$0.isEmpty }
        return keys.isEmpty ? Definitions.DEFAULT_CATEGORY_IDENTIFIER : keys.joined(separator: ",")
    }

    /// Builds the `UNNotificationCategory` (with its actions) for a model's
    /// buttons, or nil when there are none. The caller registers it.
    public func actionCategory(forModel model: [String: Any]) -> UNNotificationCategory? {
        let buttons = actionButtons(fromModel: model)
        var actions: [UNNotificationAction] = []
        for button in buttons {
            guard let key = mapUtils.getString(button[Definitions.NOTIFICATION_BUTTON_KEY]),
                  !key.isEmpty else { continue }
            let label = mapUtils.getString(button[Definitions.NOTIFICATION_BUTTON_LABEL]) ?? key
            let actionType =
                ActionType.from(mapUtils.getString(button[Definitions.NOTIFICATION_ACTION_TYPE]))

            var options: UNNotificationActionOptions = []
            if actionType == .default { options.insert(.foreground) }
            if mapUtils.getBool(button[Definitions.NOTIFICATION_IS_DANGEROUS_OPTION]) == true {
                options.insert(.destructive)
            }
            if mapUtils.getBool(button[Definitions.NOTIFICATION_AUTHENTICATION_REQUIRED]) == true {
                options.insert(.authenticationRequired)
            }

            if mapUtils.getBool(button[Definitions.NOTIFICATION_REQUIRE_INPUT_TEXT]) == true {
                actions.append(UNTextInputNotificationAction(
                    identifier: key, title: label, options: options))
            } else {
                actions.append(UNNotificationAction(
                    identifier: key, title: label, options: options))
            }
        }
        if actions.isEmpty { return nil }
        return UNNotificationCategory(
            identifier: categoryIdentifier(forModel: model),
            actions: actions,
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
    }

    /// Finds a button map by its key (nil for the content tap / unknown key).
    public func findButton(inModel model: [String: Any], key: String) -> [String: Any]? {
        if key.isEmpty { return nil }
        return actionButtons(fromModel: model).first {
            (mapUtils.getString($0[Definitions.NOTIFICATION_BUTTON_KEY]) ?? "") == key
        }
    }

    /// Attaches the notification image. iOS shows a single attachment, so prefer
    /// the big picture and fall back to the large icon.
    private func applyImages(_ content: [String: Any], to unContent: UNMutableNotificationContent) {
        let bigPicture = mapUtils.getString(content[Definitions.NOTIFICATION_BIG_PICTURE])
        let largeIcon = mapUtils.getString(content[Definitions.NOTIFICATION_LARGE_ICON])
        let source = !(bigPicture?.isEmpty ?? true) ? bigPicture : largeIcon
        if let attachment = bitmapAttachment(from: source) {
            unContent.attachments = [attachment]
        }
    }

    private func bitmapAttachment(from source: String?) -> UNNotificationAttachment? {
        #if canImport(UIKit)
        guard let source = source, !source.isEmpty,
              let image = BitmapUtils.shared.getBitmapFromSource(source),
              let data = image.pngData()
        else { return nil }

        // Each call writes into its own unique temp subfolder (like the original
        // core's `globallyUniqueString` subfolder), so concurrent builds never
        // share a path. The attachment identifier is unique too.
        let uniqueName = UUID().uuidString
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(uniqueName, isDirectory: true)
        do {
            try FileManager.default.createDirectory(
                at: directory, withIntermediateDirectories: true)
            let fileURL = directory.appendingPathComponent(uniqueName + ".png")
            try data.write(to: fileURL)
            return try UNNotificationAttachment(
                identifier: uniqueName + ".png", url: fileURL, options: nil)
        } catch {
            return nil
        }
        #else
        return nil
        #endif
    }

    /// Stores the full serialized model into userInfo for later recovery.
    private func setUserInfoContent(
        model: [String: Any],
        content: UNMutableNotificationContent
    ) {
        if let json = jsonUtils.toJson(model) {
            content.userInfo[Definitions.NOTIFICATION_JSON] = json
        }
    }

    // MARK: - Recover

    /// Rebuilds the model map from a delivered notification's userInfo.
    public func notificationModel(fromUserInfo userInfo: [AnyHashable: Any]) -> [String: Any]? {
        guard let json = userInfo[Definitions.NOTIFICATION_JSON] as? String else {
            return nil
        }
        return jsonUtils.fromJson(json)
    }

    /// The content sub-map of a serialized model.
    public func contentMap(fromModel model: [String: Any]) -> [String: Any] {
        return (model[Definitions.NOTIFICATION_CONTENT] as? [String: Any]) ?? [:]
    }

    // MARK: - Event registration (stamps date + lifecycle on the content)

    public func registerCreatedEvent(
        _ content: [String: Any],
        lifeCycle: NotificationLifeCycle
    ) -> [String: Any] {
        var map = content
        // Preserve values already stamped into the content (e.g. a scheduling
        // decorator sets the source to Schedule); only fill what's missing.
        map[Definitions.NOTIFICATION_CREATED_DATE] =
            content[Definitions.NOTIFICATION_CREATED_DATE] ?? now()
        map[Definitions.NOTIFICATION_CREATED_LIFECYCLE] =
            content[Definitions.NOTIFICATION_CREATED_LIFECYCLE] ?? lifeCycle.rawValue
        map[Definitions.NOTIFICATION_CREATED_SOURCE] =
            content[Definitions.NOTIFICATION_CREATED_SOURCE] ?? NotificationSource.local.rawValue
        return map
    }

    public func registerDisplayedEvent(
        _ content: [String: Any],
        lifeCycle: NotificationLifeCycle
    ) -> [String: Any] {
        var map = content
        map[Definitions.NOTIFICATION_DISPLAYED_DATE] = now()
        map[Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE] = lifeCycle.rawValue
        return map
    }

    public func registerActionEvent(
        _ content: [String: Any],
        lifeCycle: NotificationLifeCycle,
        actionType: ActionType = .default
    ) -> [String: Any] {
        var map = content
        map[Definitions.NOTIFICATION_ACTION_DATE] = now()
        map[Definitions.NOTIFICATION_ACTION_LIFECYCLE] = lifeCycle.rawValue
        map[Definitions.NOTIFICATION_ACTION_TYPE] = actionType.rawValue
        return map
    }

    public func registerDismissedEvent(
        _ content: [String: Any],
        lifeCycle: NotificationLifeCycle
    ) -> [String: Any] {
        var map = content
        map[Definitions.NOTIFICATION_DISMISSED_DATE] = now()
        map[Definitions.NOTIFICATION_ACTION_LIFECYCLE] = lifeCycle.rawValue
        return map
    }

    // MARK: - Dismiss concepts

    func readId(_ content: [String: Any]) -> Int? {
        return mapUtils.getInt(content[Definitions.NOTIFICATION_ID])
    }

    /// A `DismissAction` notification/button behaves like a user dismissal: it
    /// dismisses the notification and fires the dismiss event (ignoring
    /// autoDismissible).
    func isDismissAction(_ content: [String: Any]) -> Bool {
        return ActionType.from(
            mapUtils.getString(content[Definitions.NOTIFICATION_ACTION_TYPE])) == .dismissAction
    }

    /// The actionType of a pressed button (`.default` when the content itself was
    /// tapped / the button is unknown).
    func buttonActionType(_ button: [String: Any]?) -> ActionType {
        return ActionType.from(mapUtils.getString(button?[Definitions.NOTIFICATION_ACTION_TYPE]))
    }

    /// Whether a pressed button should auto-dismiss its notification.
    /// `DismissAction` always dismisses; `KeepOnTop` never; otherwise honor the
    /// button's `autoDismissible` flag (default true).
    func shouldButtonAutoDismiss(_ button: [String: Any]?) -> Bool {
        switch buttonActionType(button) {
        case .dismissAction: return true
        case .keepOnTop: return false
        default:
            return mapUtils.getBool(button?[Definitions.NOTIFICATION_AUTO_DISMISSIBLE] ?? "")
                ?? true
        }
    }

    private func now() -> String {
        return format(Date())
    }

    /// Formats a date the way all lifecycle dates are serialized (UTC), so Dart's
    /// `AwesomeDateUtils` parses it back consistently.
    private func format(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: Definitions.UTC_TIMEZONE)
        return formatter.string(from: date)
    }
}
