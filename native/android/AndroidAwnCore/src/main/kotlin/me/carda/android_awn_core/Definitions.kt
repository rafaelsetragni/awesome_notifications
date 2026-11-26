package me.carda.android_awn_core

/**
 * Map keys and constants shared with the Dart side. The names mirror the
 * original AndroidAwnCore `Definitions` (which in turn mirror `definitions.dart`),
 * to keep the migration consistent.
 */
object Definitions {
    // Notification model sections
    const val NOTIFICATION_CONTENT = "content"
    const val NOTIFICATION_BUTTONS = "actionButtons"

    // Content fields
    const val NOTIFICATION_ID = "id"
    const val NOTIFICATION_TITLE = "title"
    const val NOTIFICATION_BODY = "body"
    const val NOTIFICATION_PAYLOAD = "payload"
    const val NOTIFICATION_AUTO_DISMISSIBLE = "autoDismissible"
    const val NOTIFICATION_LAYOUT = "notificationLayout"
    const val NOTIFICATION_LARGE_ICON = "largeIcon"
    const val NOTIFICATION_BIG_PICTURE = "bigPicture"
    const val NOTIFICATION_CATEGORY = "category"
    const val NOTIFICATION_LOCKED = "locked"
    const val NOTIFICATION_WAKE_UP_SCREEN = "wakeUpScreen"
    const val NOTIFICATION_FULL_SCREEN_INTENT = "fullScreenIntent"
    const val NOTIFICATION_CUSTOM_SOUND = "customSound"

    // Action button fields
    const val NOTIFICATION_BUTTON_KEY = "key"
    const val NOTIFICATION_BUTTON_LABEL = "label"
    const val NOTIFICATION_BUTTON_ICON = "icon"
    const val NOTIFICATION_BUTTON_ENABLED = "enabled"
    const val NOTIFICATION_REQUIRE_INPUT_TEXT = "requireInputText"
    const val NOTIFICATION_BUTTON_KEY_PRESSED = "buttonKeyPressed"
    const val NOTIFICATION_BUTTON_KEY_INPUT = "buttonKeyInput"

    // Permissions
    const val NOTIFICATION_PERMISSIONS = "permissions"

    // Channel fields
    const val NOTIFICATION_CHANNEL_KEY = "channelKey"
    const val NOTIFICATION_GROUP_KEY = "groupKey"
    const val NOTIFICATION_CHANNEL_NAME = "channelName"
    const val NOTIFICATION_CHANNEL_DESCRIPTION = "channelDescription"
    const val NOTIFICATION_IMPORTANCE = "importance"
    const val NOTIFICATION_PLAY_SOUND = "playSound"
    const val NOTIFICATION_ENABLE_VIBRATION = "enableVibration"
    const val NOTIFICATION_VIBRATION_PATTERN = "vibrationPattern"
    const val NOTIFICATION_ENABLE_LIGHTS = "enableLights"
    const val NOTIFICATION_LED_COLOR = "ledColor"
    const val NOTIFICATION_CHANNEL_SHOW_BADGE = "channelShowBadge"
    const val NOTIFICATION_SOUND_SOURCE = "soundSource"
    const val NOTIFICATION_DEFAULT_RINGTONE_TYPE = "defaultRingtoneType"
    const val NOTIFICATION_CHANNEL_CRITICAL_ALERTS = "criticalAlerts"

    // Initialize payload
    const val INITIALIZE_CHANNELS = "initializeChannels"
    const val INITIALIZE_DEFAULT_ICON = "defaultIcon"
    const val NOTIFICATION_ICON = "icon"
    const val INITIALIZE_DEBUG_MODE = "debug"

    // Lifecycle / action metadata (native -> Dart)
    const val NOTIFICATION_CREATED_SOURCE = "createdSource"
    const val NOTIFICATION_CREATED_LIFECYCLE = "createdLifeCycle"
    const val NOTIFICATION_DISPLAYED_LIFECYCLE = "displayedLifeCycle"
    const val NOTIFICATION_ACTION_TYPE = "actionType"
    const val NOTIFICATION_ACTION_LIFECYCLE = "actionLifeCycle"
    const val NOTIFICATION_CREATED_DATE = "createdDate"
    const val NOTIFICATION_DISPLAYED_DATE = "displayedDate"
    const val NOTIFICATION_ACTION_DATE = "actionDate"
    const val NOTIFICATION_DISMISSED_DATE = "dismissedDate"

    // Event method names sent back to Dart.
    const val EVENT_NOTIFICATION_CREATED = "notificationCreated"
    const val EVENT_NOTIFICATION_DISPLAYED = "notificationDisplayed"
    const val EVENT_NOTIFICATION_DISMISSED = "notificationDismissed"
    const val EVENT_DEFAULT_ACTION = "defaultAction"

    // Intent actions + extra used to carry the notification through the
    // tap (contentIntent), dismiss (deleteIntent) and action-button PendingIntents.
    const val SELECT_NOTIFICATION = "SELECT_NOTIFICATION"
    const val DISMISSED_NOTIFICATION = "DISMISSED_NOTIFICATION"
    const val NOTIFICATION_BUTTON_ACTION_PREFIX = "ACTION_NOTIFICATION"
    const val NOTIFICATION_JSON = "notificationJson"

    // 0.12 exception codes / detailed codes (the PlatformException code + details).
    const val CODE_MISSING_ARGUMENTS = "MISSING_ARGUMENTS"
    const val CODE_INVALID_ARGUMENTS = "INVALID_ARGUMENTS"
    const val CODE_UNKNOWN_EXCEPTION = "UNKNOWN_EXCEPTION"
    const val CODE_NOTIFICATION_THREAD_EXCEPTION = "NOTIFICATION_THREAD_EXCEPTION"
    const val DETAILED_REQUIRED_ARGUMENTS = "arguments.required"
    const val DETAILED_INVALID_ARGUMENTS = "arguments.invalid"
    const val DETAILED_UNEXPECTED_ERROR = "unexpectedError"

    // The reference time zone all lifecycle dates are serialized in.
    const val UTC_TIMEZONE = "UTC"
}
