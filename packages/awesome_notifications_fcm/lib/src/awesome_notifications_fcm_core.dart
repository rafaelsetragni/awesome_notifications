import 'dart:async';
import 'dart:ui';

import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:awesome_notifications_fcm/src/fcm_definitions.dart';
import 'package:awesome_notifications_fcm/src/isolates/silent_push_isolate_main.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Firebase Cloud Messaging decorator for awesome_notifications.
///
/// This class is a thin, Flutter-side facade over the native FCM engine. It does
/// not build or display notifications itself: incoming push messages are turned
/// into a core payload natively and handed to the awesome_notifications engine,
/// which fires the usual `onNotificationCreated` / `onActionReceived` events.
///
/// Use it for:
///  * receiving the FCM (and native APNs) registration token,
///  * handling silent (data-only) messages in the background/terminated app,
///  * subscribing to topics and managing the token.
class AwesomeNotificationsFcm {
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  PushTokenHandler? _tokenFcmHandler;
  PushTokenHandler? _tokenNativeHandler;

  final MethodChannel _channel;

  factory AwesomeNotificationsFcm() => _instance;

  @visibleForTesting
  AwesomeNotificationsFcm.private(MethodChannel channel) : _channel = channel;

  static final AwesomeNotificationsFcm _instance =
      AwesomeNotificationsFcm.private(
          const MethodChannel(CHANNEL_FLUTTER_PLUGIN));

  /// Initializes the plugin. Call this once, early in `main`.
  ///
  /// [onFcmTokenHandle] receives the Firebase token (and its refreshes).
  /// [onFcmSilentDataHandle] handles silent (data-only) pushes — it must be a
  /// top-level or static function so it can be resolved from a background isolate.
  /// [onNativeTokenHandle] optionally receives the raw native (APNs) token.
  /// [debug] enables verbose native logging.
  Future<bool> initialize({
    required PushTokenHandler onFcmTokenHandle,
    required FcmSilentDataHandler onFcmSilentDataHandle,
    PushTokenHandler? onNativeTokenHandle,
    bool debug = false,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();

    _tokenFcmHandler = onFcmTokenHandle;
    _tokenNativeHandler = onNativeTokenHandle;

    final CallbackHandle? dartCallbackReference =
        PluginUtilities.getCallbackHandle(silentPushBackgroundMain);
    final CallbackHandle? tokenCallbackReference =
        PluginUtilities.getCallbackHandle(onFcmTokenHandle);
    final CallbackHandle? silentCallbackReference =
        PluginUtilities.getCallbackHandle(onFcmSilentDataHandle);

    _channel.setMethodCallHandler(_handleMethod);

    _isInitialized = await _channel.invokeMethod<bool>(
          CHANNEL_METHOD_FCM_INITIALIZE,
          {
            DEBUG_MODE: debug,
            DART_BG_HANDLE: dartCallbackReference?.toRawHandle(),
            TOKEN_HANDLE: tokenCallbackReference?.toRawHandle(),
            SILENT_HANDLE: silentCallbackReference?.toRawHandle(),
          },
        ) ??
        false;

    if (tokenCallbackReference == null) {
      debugPrint('Callback onFcmTokenHandle is not defined or is invalid.\n'
          'Please ensure it is a valid global/static method.');
    }
    if (silentCallbackReference == null) {
      debugPrint('Callback onFcmSilentDataHandle is not defined or is invalid.\n'
          'Please ensure it is a valid global/static method.');
    }

    return _isInitialized;
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case CHANNEL_METHOD_NEW_NATIVE_TOKEN:
        final String? token = call.arguments as String?;
        if (_tokenNativeHandler != null) await _tokenNativeHandler!(token ?? '');
        return;

      case CHANNEL_METHOD_NEW_FCM_TOKEN:
        final String? token = call.arguments as String?;
        if (_tokenFcmHandler != null) await _tokenFcmHandler!(token ?? '');
        return;

      // Silent data delivered while the app engine is alive (foreground handoff).
      case CHANNEL_METHOD_SILENT_CALLBACK:
        try {
          if (!await receiveSilentData(
              (call.arguments as Map).cast<String, dynamic>())) {
            throw AwesomeNotificationsFcmException(
                'Silent data could not be recovered');
          }
        } on DartCallbackException {
          debugPrint('Fatal: could not find silent callback');
        } catch (e) {
          debugPrint('Awesome Notifications FCM: an error occurred in your '
              'silent data handler:');
          debugPrint(e.toString());
        }
        return;

      default:
        throw UnsupportedError('Unrecognized method ${call.method}');
    }
  }

  /// Whether Firebase is fully available (configured) on the device.
  Future<bool> get isFirebaseAvailable async =>
      await _channel.invokeMethod<bool>(CHANNEL_METHOD_IS_FCM_AVAILABLE) ??
      false;

  /// Requests the current Firebase Cloud Messaging registration token.
  Future<String> requestFirebaseAppToken() async =>
      await _channel.invokeMethod<String>(CHANNEL_METHOD_GET_FCM_TOKEN) ?? '';

  /// Subscribes the device to an FCM [topic].
  Future<bool> subscribeToTopic(String topic) async =>
      await _channel.invokeMethod<bool>(
          CHANNEL_METHOD_SUBSCRIBE_TOPIC, {NOTIFICATION_TOPIC: topic}) ??
      false;

  /// Unsubscribes the device from an FCM [topic].
  Future<bool> unsubscribeToTopic(String topic) async =>
      await _channel.invokeMethod<bool>(
          CHANNEL_METHOD_UNSUBSCRIBE_TOPIC, {NOTIFICATION_TOPIC: topic}) ??
      false;

  /// Deletes the current registration token, forcing a new one to be issued.
  Future<bool> deleteToken() async =>
      await _channel.invokeMethod<bool>(CHANNEL_METHOD_DELETE_TOKEN) ?? false;
}
