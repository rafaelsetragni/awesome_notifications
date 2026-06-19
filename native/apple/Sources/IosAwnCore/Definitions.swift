import Foundation

/// Map keys and constants shared with the Dart side. The names mirror the
/// original IosAwnCore `Definitions` (which in turn mirror `definitions.dart`),
/// to keep the migration consistent.
public enum Definitions {
    // Notification model sections
    public static let NOTIFICATION_CONTENT = "content"
    public static let NOTIFICATION_BUTTONS = "actionButtons"

    // Content fields
    public static let NOTIFICATION_ID = "id"
    public static let NOTIFICATION_TITLE = "title"
    public static let NOTIFICATION_BODY = "body"
    public static let NOTIFICATION_PAYLOAD = "payload"

    // Permissions
    public static let NOTIFICATION_PERMISSIONS = "permissions"

    // Channel fields
    public static let NOTIFICATION_CHANNEL_KEY = "channelKey"
    public static let NOTIFICATION_CHANNEL_NAME = "channelName"
    public static let NOTIFICATION_IMPORTANCE = "importance"

    // Initialize payload
    public static let INITIALIZE_CHANNELS = "initializeChannels"
    public static let INITIALIZE_DEFAULT_ICON = "defaultIcon"
    public static let INITIALIZE_DEBUG_MODE = "debug"

    // Lifecycle / action metadata (native -> Dart)
    public static let NOTIFICATION_CREATED_SOURCE = "createdSource"
    public static let NOTIFICATION_CREATED_LIFECYCLE = "createdLifeCycle"
    public static let NOTIFICATION_DISPLAYED_LIFECYCLE = "displayedLifeCycle"
    public static let NOTIFICATION_ACTION_TYPE = "actionType"
    public static let NOTIFICATION_ACTION_LIFECYCLE = "actionLifeCycle"
    public static let NOTIFICATION_CREATED_DATE = "createdDate"
    public static let NOTIFICATION_DISPLAYED_DATE = "displayedDate"
    public static let NOTIFICATION_ACTION_DATE = "actionDate"
    public static let NOTIFICATION_DISMISSED_DATE = "dismissedDate"

    // The full serialized NotificationModel, injected into the delivered
    // notification (userInfo) so it can be recovered on display/tap/dismiss.
    public static let NOTIFICATION_JSON = "notificationJson"

    // Event method names sent back to Dart.
    public static let EVENT_NOTIFICATION_CREATED = "notificationCreated"
    public static let EVENT_NOTIFICATION_DISPLAYED = "notificationDisplayed"
    public static let EVENT_NOTIFICATION_DISMISSED = "notificationDismissed"
    public static let EVENT_DEFAULT_ACTION = "defaultAction"

    // iOS category whose `.customDismissAction` lets us capture dismiss events.
    public static let DEFAULT_CATEGORY_IDENTIFIER = "DEFAULT"
}
