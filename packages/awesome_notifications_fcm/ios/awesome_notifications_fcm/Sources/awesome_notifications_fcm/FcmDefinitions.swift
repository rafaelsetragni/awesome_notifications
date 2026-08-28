import Foundation

/// Wire constants for the FCM decorator. Keep in sync with the Dart
/// `fcm_definitions.dart` and the Android `FcmDefinitions.kt`.
enum FcmDefinitions {
    static let CHANNEL_FLUTTER_PLUGIN = "awesome_notifications_fcm"
    static let DART_FCM_REVERSE_CHANNEL = "AWFcmReverse"

    // UserDefaults store for the registered background callback handles + flags.
    static let SHARED_FCM_DEFAULTS = "awn_fcm_defaults"

    // Initialization payload keys (Dart -> native).
    static let DEBUG_MODE = "debug"
    static let DART_BG_HANDLE = "fcmDartBGHandle"
    static let TOKEN_HANDLE = "tokenHandle"
    static let SILENT_HANDLE = "fcmSilentHandle"

    static let NOTIFICATION_TOPIC = "topic"

    // Channel methods invoked Dart -> native.
    static let CHANNEL_METHOD_INITIALIZE = "initialize"
    static let CHANNEL_METHOD_IS_FCM_AVAILABLE = "isFirebaseAvailable"
    static let CHANNEL_METHOD_GET_FCM_TOKEN = "getFirebaseToken"
    static let CHANNEL_METHOD_SUBSCRIBE_TOPIC = "subscribeTopic"
    static let CHANNEL_METHOD_UNSUBSCRIBE_TOPIC = "unsubscribeTopic"
    static let CHANNEL_METHOD_DELETE_TOKEN = "deleteToken"
    static let CHANNEL_METHOD_PUSH_NEXT_DATA = "pushNext"

    // Channel methods invoked native -> Dart.
    static let CHANNEL_METHOD_NEW_FCM_TOKEN = "newFcmToken"
    static let CHANNEL_METHOD_NEW_NATIVE_TOKEN = "newNativeToken"
    static let CHANNEL_METHOD_SILENT_CALLBACK = "silentCallbackReference"

    // Top-level notification payload sections embedded in the push userInfo.
    static let MODEL_CONTENT = "content"
    static let MODEL_BUTTONS = "actionButtons"
    static let MODEL_SCHEDULE = "schedule"
    static let MODEL_LOCALIZATIONS = "localizations"
    static let MODEL_ANDROID = "Android"
    static let MODEL_IOS = "iOS"

    static let FLAG_IS_SILENT_DATA = "isSilentData"

    // Apple push envelope keys.
    static let APS = "aps"
    static let APS_ALERT = "alert"
    static let APS_TITLE = "title"
    static let APS_BODY = "body"
    static let APS_CONTENT_AVAILABLE = "content-available"
    static let APS_MUTABLE_CONTENT = "mutable-content"
}
