package me.carda.android_awn_core

/**
 * Map keys shared with the Dart side (mirrors `lib/src/definitions.dart`).
 *
 * These are the serialization keys used by `NotificationModel.toMap()` and the
 * channel/content models. Keep them in sync with the Dart constants.
 */
object Definitions {
    // Notification model sections
    const val CONTENT = "content"
    const val ACTION_BUTTONS = "actionButtons"

    // Content fields
    const val ID = "id"
    const val TITLE = "title"
    const val BODY = "body"
    const val PAYLOAD = "payload"

    // Permissions
    const val PERMISSIONS = "permissions"

    // Channel fields
    const val CHANNEL_KEY = "channelKey"
    const val CHANNEL_NAME = "channelName"
    const val CHANNEL_DESCRIPTION = "channelDescription"
    const val IMPORTANCE = "importance"

    // Initialize payload
    const val INITIALIZE_CHANNELS = "initializeChannels"
    const val INITIALIZE_DEFAULT_ICON = "defaultIcon"
    const val INITIALIZE_DEBUG_MODE = "debug"

    // Lifecycle / action metadata (native -> Dart)
    const val CREATED_SOURCE = "createdSource"
    const val CREATED_LIFECYCLE = "createdLifeCycle"
    const val DISPLAYED_LIFECYCLE = "displayedLifeCycle"
    const val ACTION_TYPE = "actionType"
    const val ACTION_LIFECYCLE = "actionLifeCycle"

    // Event method names sent back to Dart (mirror the Dart EVENT_* constants).
    const val EVENT_NOTIFICATION_CREATED = "notificationCreated"
    const val EVENT_NOTIFICATION_DISPLAYED = "notificationDisplayed"
    const val EVENT_NOTIFICATION_DISMISSED = "notificationDismissed"
    const val EVENT_DEFAULT_ACTION = "defaultAction"

    // Intent actions + extra used to carry the notification through the
    // tap (contentIntent) and dismiss (deleteIntent) PendingIntents.
    const val ACTION_SELECT_NOTIFICATION =
        "me.carda.awesome_notifications.SELECT_NOTIFICATION"
    const val ACTION_DISMISSED_NOTIFICATION =
        "me.carda.awesome_notifications.DISMISSED_NOTIFICATION"
    const val NOTIFICATION_JSON = "notificationJson"
}
