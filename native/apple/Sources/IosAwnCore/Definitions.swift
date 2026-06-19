import Foundation

/// Map keys shared with the Dart side (mirrors `lib/src/definitions.dart`).
///
/// These are the serialization keys used by `NotificationModel.toMap()` and the
/// channel/content models. Keep them in sync with the Dart constants.
public enum Definitions {
    // Notification model sections
    public static let content = "content"
    public static let actionButtons = "actionButtons"

    // Content fields
    public static let id = "id"
    public static let title = "title"
    public static let body = "body"
    public static let payload = "payload"

    // Permissions
    public static let permissions = "permissions"

    // Channel fields
    public static let channelKey = "channelKey"
    public static let channelName = "channelName"
    public static let importance = "importance"

    // Initialize payload
    public static let initializeChannels = "initializeChannels"
    public static let initializeDefaultIcon = "defaultIcon"
    public static let initializeDebugMode = "debug"

    // Lifecycle / action metadata (native -> Dart)
    public static let createdSource = "createdSource"
    public static let createdLifeCycle = "createdLifeCycle"
    public static let displayedLifeCycle = "displayedLifeCycle"
    public static let actionType = "actionType"
    public static let actionLifeCycle = "actionLifeCycle"

    // Event method names sent back to Dart (mirror the Dart EVENT_* constants).
    public static let eventNotificationCreated = "notificationCreated"
    public static let eventNotificationDisplayed = "notificationDisplayed"
    public static let eventNotificationDismissed = "notificationDismissed"
    public static let eventDefaultAction = "defaultAction"

    // iOS category whose `.customDismissAction` lets us capture dismiss events.
    public static let defaultCategoryIdentifier = "AWESOME_DEFAULT"
}
