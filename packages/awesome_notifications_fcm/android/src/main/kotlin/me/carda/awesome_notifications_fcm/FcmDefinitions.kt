package me.carda.awesome_notifications_fcm

/**
 * Wire constants for the FCM decorator. These MUST stay in sync with the Dart
 * `fcm_definitions.dart` and the iOS `FcmDefinitions.swift`.
 */
object FcmDefinitions {
    const val CHANNEL_FLUTTER_PLUGIN = "awesome_notifications_fcm"
    const val DART_FCM_REVERSE_CHANNEL = "AWFcmReverse"

    const val FIREBASE_MESSAGING_EVENT = "com.google.firebase.MESSAGING_EVENT"

    // Shared-prefs store for the registered background callback handles + flags.
    const val SHARED_FCM_DEFAULTS = "awn_fcm_defaults"

    // Initialization payload keys (Dart -> native).
    const val DEBUG_MODE = "debug"
    const val DART_BG_HANDLE = "fcmDartBGHandle"
    const val TOKEN_HANDLE = "tokenHandle"
    const val SILENT_HANDLE = "fcmSilentHandle"

    const val NOTIFICATION_TOPIC = "topic"
    const val NOTIFICATION_SILENT_DATA = "notificationSilentData"

    // Channel methods invoked Dart -> native.
    const val CHANNEL_METHOD_INITIALIZE = "initialize"
    const val CHANNEL_METHOD_IS_FCM_AVAILABLE = "isFirebaseAvailable"
    const val CHANNEL_METHOD_GET_FCM_TOKEN = "getFirebaseToken"
    const val CHANNEL_METHOD_SUBSCRIBE_TOPIC = "subscribeTopic"
    const val CHANNEL_METHOD_UNSUBSCRIBE_TOPIC = "unsubscribeTopic"
    const val CHANNEL_METHOD_DELETE_TOKEN = "deleteToken"
    const val CHANNEL_METHOD_PUSH_NEXT_DATA = "pushNext"

    // Channel methods invoked native -> Dart.
    const val CHANNEL_METHOD_NEW_FCM_TOKEN = "newFcmToken"
    const val CHANNEL_METHOD_NEW_NATIVE_TOKEN = "newNativeToken"
    const val CHANNEL_METHOD_SILENT_CALLBACK = "silentCallbackReference"

    // Top-level notification payload sections the server may embed in an FCM data
    // message. Each is either a JSON string (structured) or dot-flattened.
    const val MODEL_CONTENT = "content"
    const val MODEL_BUTTONS = "actionButtons"
    const val MODEL_SCHEDULE = "schedule"
    const val MODEL_LOCALIZATIONS = "localizations"
    const val MODEL_ANDROID = "Android"
    const val MODEL_IOS = "iOS"

    // Marks a data-only message that must be treated as silent even if it happens
    // to carry displayable-looking keys.
    const val FLAG_IS_SILENT_DATA = "isSilentData"
}
