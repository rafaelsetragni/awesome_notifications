import Foundation
import UserNotifications

/// Builds notifications from a serialized `NotificationModel`, injects the full
/// model into the delivered notification so it can be recovered later, and
/// stamps the lifecycle events (created/displayed/pressed/dismissed).
///
/// Created via a factory (an instance with injected helpers — not static utility
/// methods), mirroring the original IosAwnCore `NotificationBuilder`.
public final class NotificationBuilder {

    public static func newInstance() -> NotificationBuilder {
        return NotificationBuilder()
    }
    private init() {}

    private let stringUtils = StringUtils.shared
    private let mapUtils = MapUtils.shared
    private let jsonUtils = JsonUtils.shared

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
                mapUtils.getString(button[Definitions.NOTIFICATION_ACTION_TYPE]) ?? "Default"

            var options: UNNotificationActionOptions = []
            if actionType.hasSuffix("Default") { options.insert(.foreground) }
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

    public func registerCreatedEvent(_ content: [String: Any], lifeCycle: String) -> [String: Any] {
        var map = content
        map[Definitions.NOTIFICATION_CREATED_DATE] = now()
        map[Definitions.NOTIFICATION_CREATED_LIFECYCLE] = lifeCycle
        map[Definitions.NOTIFICATION_CREATED_SOURCE] = "Local"
        return map
    }

    public func registerDisplayedEvent(_ content: [String: Any], lifeCycle: String) -> [String: Any] {
        var map = content
        map[Definitions.NOTIFICATION_DISPLAYED_DATE] = now()
        map[Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE] = lifeCycle
        return map
    }

    public func registerActionEvent(
        _ content: [String: Any],
        lifeCycle: String,
        actionType: String = "Default"
    ) -> [String: Any] {
        var map = content
        map[Definitions.NOTIFICATION_ACTION_DATE] = now()
        map[Definitions.NOTIFICATION_ACTION_LIFECYCLE] = lifeCycle
        map[Definitions.NOTIFICATION_ACTION_TYPE] = actionType
        return map
    }

    public func registerDismissedEvent(_ content: [String: Any], lifeCycle: String) -> [String: Any] {
        var map = content
        map[Definitions.NOTIFICATION_DISMISSED_DATE] = now()
        map[Definitions.NOTIFICATION_ACTION_LIFECYCLE] = lifeCycle
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
        let actionType =
            mapUtils.getString(content[Definitions.NOTIFICATION_ACTION_TYPE]) ?? ""
        return actionType.hasSuffix("DismissAction")
    }

    /// The actionType of a pressed button (or "Default" when the content itself
    /// was tapped / the button is unknown).
    func buttonActionType(_ button: [String: Any]?) -> String {
        return mapUtils.getString(button?[Definitions.NOTIFICATION_ACTION_TYPE] ?? "")
            ?? "Default"
    }

    /// Whether a pressed button should auto-dismiss its notification.
    /// `DismissAction` always dismisses; `KeepOnTop` never; otherwise honor the
    /// button's `autoDismissible` flag (default true).
    func shouldButtonAutoDismiss(_ button: [String: Any]?) -> Bool {
        let actionType = buttonActionType(button)
        if actionType.hasSuffix("DismissAction") { return true }
        if actionType.hasSuffix("KeepOnTop") { return false }
        return mapUtils.getBool(button?[Definitions.NOTIFICATION_AUTO_DISMISSIBLE] ?? "")
            ?? true
    }

    private func now() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: Date())
    }
}
