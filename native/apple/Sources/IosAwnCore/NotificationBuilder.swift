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
        unContent.categoryIdentifier = Definitions.DEFAULT_CATEGORY_IDENTIFIER

        setUserInfoContent(model: model, content: unContent)
        return (id, unContent)
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

    public func registerActionEvent(_ content: [String: Any], lifeCycle: String) -> [String: Any] {
        var map = content
        map[Definitions.NOTIFICATION_ACTION_DATE] = now()
        map[Definitions.NOTIFICATION_ACTION_LIFECYCLE] = lifeCycle
        map[Definitions.NOTIFICATION_ACTION_TYPE] = "Default"
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

    private func now() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: Date())
    }
}
