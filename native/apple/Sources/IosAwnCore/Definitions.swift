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

    // Channel fields
    public static let channelKey = "channelKey"
    public static let channelName = "channelName"
    public static let importance = "importance"

    // Initialize payload
    public static let initializeChannels = "initializeChannels"
    public static let initializeDefaultIcon = "defaultIcon"
    public static let initializeDebugMode = "debug"
}
