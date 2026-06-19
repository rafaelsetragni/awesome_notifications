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

    // Channel fields
    const val CHANNEL_KEY = "channelKey"
    const val CHANNEL_NAME = "channelName"
    const val CHANNEL_DESCRIPTION = "channelDescription"
    const val IMPORTANCE = "importance"

    // Initialize payload
    const val INITIALIZE_CHANNELS = "initializeChannels"
    const val INITIALIZE_DEFAULT_ICON = "defaultIcon"
    const val INITIALIZE_DEBUG_MODE = "debug"
}
