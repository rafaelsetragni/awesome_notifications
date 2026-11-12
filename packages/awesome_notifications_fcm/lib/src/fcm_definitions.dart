/// Wire constants shared between the Dart side and the native FCM decorator.
/// These MUST stay in sync with the native `FcmDefinitions` (Kotlin / Swift).

/// Method channel the plugin talks over (app-side isolate).
const String CHANNEL_FLUTTER_PLUGIN = 'awesome_notifications_fcm';

/// Reverse channel used by the headless background isolate that handles silent
/// data while the app is terminated.
const String DART_FCM_REVERSE_CHANNEL = 'AWFcmReverse';

// Initialization payload keys.
const String DEBUG_MODE = 'debug';
const String DART_BG_HANDLE = 'fcmDartBGHandle';
const String TOKEN_HANDLE = 'tokenHandle';
const String SILENT_HANDLE = 'fcmSilentHandle';

// Topic / data keys.
const String NOTIFICATION_TOPIC = 'topic';
const String NOTIFICATION_SILENT_DATA = 'notificationSilentData';

// Channel methods invoked from Dart -> native.
const String CHANNEL_METHOD_FCM_INITIALIZE = 'initialize';
const String CHANNEL_METHOD_IS_FCM_AVAILABLE = 'isFirebaseAvailable';
const String CHANNEL_METHOD_GET_FCM_TOKEN = 'getFirebaseToken';
const String CHANNEL_METHOD_SUBSCRIBE_TOPIC = 'subscribeTopic';
const String CHANNEL_METHOD_UNSUBSCRIBE_TOPIC = 'unsubscribeTopic';
const String CHANNEL_METHOD_DELETE_TOKEN = 'deleteToken';
const String CHANNEL_METHOD_PUSH_NEXT_DATA = 'pushNext';

// Channel methods invoked from native -> Dart.
const String CHANNEL_METHOD_NEW_NATIVE_TOKEN = 'newNativeToken';
const String CHANNEL_METHOD_NEW_FCM_TOKEN = 'newFcmToken';
const String CHANNEL_METHOD_SILENT_CALLBACK = 'silentCallbackReference';
