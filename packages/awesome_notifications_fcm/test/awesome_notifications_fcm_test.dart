import 'dart:ui';

import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:awesome_notifications_fcm/src/fcm_definitions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

FcmSilentData? coreCapturedSilent;
@pragma('vm:entry-point')
Future<void> coreSilentHandler(FcmSilentData silentData) async {
  coreCapturedSilent = silentData;
}

@pragma('vm:entry-point')
Future<void> coreTokenHandler(String token) async {}

@pragma('vm:entry-point')
Future<void> coreThrowingSilentHandler(FcmSilentData silentData) async {
  throw StateError('handler blew up');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannel channel;
  late AwesomeNotificationsFcm fcm;
  late List<MethodCall> log;
  late TestDefaultBinaryMessenger messenger;

  /// Feeds a native -> Dart call into the channel's handler.
  Future<void> emitFromNative(MethodCall call) async {
    await messenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(call),
      (_) {},
    );
  }

  setUp(() {
    channel = const MethodChannel('awesome_notifications_fcm_test');
    fcm = AwesomeNotificationsFcm.private(channel);
    log = [];
    messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      log.add(call);
      switch (call.method) {
        case CHANNEL_METHOD_FCM_INITIALIZE:
        case CHANNEL_METHOD_IS_FCM_AVAILABLE:
        case CHANNEL_METHOD_SUBSCRIBE_TOPIC:
        case CHANNEL_METHOD_UNSUBSCRIBE_TOPIC:
        case CHANNEL_METHOD_DELETE_TOKEN:
          return true;
        case CHANNEL_METHOD_GET_FCM_TOKEN:
          return 'fcm-token-123';
        default:
          return null;
      }
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    coreCapturedSilent = null;
  });

  group('defaults when native returns null', () {
    setUp(() {
      messenger.setMockMethodCallHandler(channel, (_) async => null);
    });

    test('boolean + token getters fall back safely', () async {
      expect(await fcm.isFirebaseAvailable, isFalse);
      expect(await fcm.requestFirebaseAppToken(), '');
      expect(await fcm.subscribeToTopic('t'), isFalse);
      expect(await fcm.unsubscribeToTopic('t'), isFalse);
      expect(await fcm.deleteToken(), isFalse);
    });

    test('initialize returns false when native does not confirm', () async {
      final ok = await fcm.initialize(
        onFcmTokenHandle: (_) async {},
        onFcmSilentDataHandle: (_) async {},
      );
      expect(ok, isFalse);
    });
  });

  group('singleton', () {
    test('the default constructor returns the shared instance', () {
      expect(identical(AwesomeNotificationsFcm(), AwesomeNotificationsFcm()), isTrue);
      expect(AwesomeNotificationsFcm.isInitialized, isA<bool>());
    });
  });

  group('initialize with resolvable handles', () {
    test('forwards non-null token + silent callback handles', () async {
      final ok = await fcm.initialize(
        onFcmTokenHandle: coreTokenHandler,
        onFcmSilentDataHandle: coreSilentHandler,
      );
      expect(ok, isTrue);
      final call = log.firstWhere((c) => c.method == CHANNEL_METHOD_FCM_INITIALIZE);
      final args = call.arguments as Map;
      expect(args[TOKEN_HANDLE], isNotNull);
      expect(args[SILENT_HANDLE], isNotNull);
      expect(args[DART_BG_HANDLE], isNotNull);
    });
  });

  group('silent data over the main channel', () {
    test('a valid handle delivers the silent data', () async {
      final handle =
          PluginUtilities.getCallbackHandle(coreSilentHandler)!.toRawHandle();
      await fcm.initialize(
        onFcmTokenHandle: (_) async {},
        onFcmSilentDataHandle: (_) async {},
      );
      await emitFromNative(MethodCall(CHANNEL_METHOD_SILENT_CALLBACK, {
        SILENT_HANDLE: handle,
        'orderId': '77',
      }));
      expect(coreCapturedSilent, isNotNull);
      expect(coreCapturedSilent!.data, {'orderId': '77'});
    });

    test('a bad handle is swallowed, not rethrown', () async {
      await fcm.initialize(
        onFcmTokenHandle: (_) async {},
        onFcmSilentDataHandle: (_) async {},
      );
      // Completes normally even though the handle cannot be resolved.
      await emitFromNative(
        const MethodCall(CHANNEL_METHOD_SILENT_CALLBACK, {SILENT_HANDLE: 1}),
      );
    });

    test('an error thrown inside the handler is caught and logged', () async {
      final handle = PluginUtilities
          .getCallbackHandle(coreThrowingSilentHandler)!
          .toRawHandle();
      await fcm.initialize(
        onFcmTokenHandle: (_) async {},
        onFcmSilentDataHandle: (_) async {},
      );
      // The handler throws a StateError; _handleMethod must contain it.
      await emitFromNative(MethodCall(CHANNEL_METHOD_SILENT_CALLBACK, {
        SILENT_HANDLE: handle,
      }));
    });
  });

  group('delegation', () {
    test('isFirebaseAvailable invokes the channel', () async {
      expect(await fcm.isFirebaseAvailable, isTrue);
      expect(log.single.method, CHANNEL_METHOD_IS_FCM_AVAILABLE);
    });

    test('requestFirebaseAppToken returns the token', () async {
      expect(await fcm.requestFirebaseAppToken(), 'fcm-token-123');
      expect(log.single.method, CHANNEL_METHOD_GET_FCM_TOKEN);
    });

    test('subscribeToTopic passes the topic', () async {
      expect(await fcm.subscribeToTopic('news'), isTrue);
      expect(log.single.method, CHANNEL_METHOD_SUBSCRIBE_TOPIC);
      expect(log.single.arguments, {NOTIFICATION_TOPIC: 'news'});
    });

    test('unsubscribeToTopic passes the topic', () async {
      expect(await fcm.unsubscribeToTopic('news'), isTrue);
      expect(log.single.method, CHANNEL_METHOD_UNSUBSCRIBE_TOPIC);
      expect(log.single.arguments, {NOTIFICATION_TOPIC: 'news'});
    });

    test('deleteToken invokes the channel', () async {
      expect(await fcm.deleteToken(), isTrue);
      expect(log.single.method, CHANNEL_METHOD_DELETE_TOKEN);
    });
  });

  group('initialize', () {
    test('sends debug + the callback handles and returns success', () async {
      final ok = await fcm.initialize(
        onFcmTokenHandle: (_) async {},
        onFcmSilentDataHandle: (_) async {},
        debug: true,
      );
      expect(ok, isTrue);
      final call = log.firstWhere((c) => c.method == CHANNEL_METHOD_FCM_INITIALIZE);
      final args = call.arguments as Map;
      expect(args[DEBUG_MODE], isTrue);
      expect(args.containsKey(DART_BG_HANDLE), isTrue);
      expect(args.containsKey(TOKEN_HANDLE), isTrue);
      expect(args.containsKey(SILENT_HANDLE), isTrue);
    });
  });

  group('native -> Dart callbacks', () {
    test('newFcmToken reaches the fcm token handler', () async {
      String? received;
      await fcm.initialize(
        onFcmTokenHandle: (t) async => received = t,
        onFcmSilentDataHandle: (_) async {},
      );
      await emitFromNative(const MethodCall(CHANNEL_METHOD_NEW_FCM_TOKEN, 'tok'));
      expect(received, 'tok');
    });

    test('newNativeToken reaches the native token handler', () async {
      String? received;
      await fcm.initialize(
        onFcmTokenHandle: (_) async {},
        onFcmSilentDataHandle: (_) async {},
        onNativeTokenHandle: (t) async => received = t,
      );
      await emitFromNative(const MethodCall(CHANNEL_METHOD_NEW_NATIVE_TOKEN, 'apns'));
      expect(received, 'apns');
    });

    test('a null token is normalized to empty string', () async {
      String? received;
      await fcm.initialize(
        onFcmTokenHandle: (t) async => received = t,
        onFcmSilentDataHandle: (_) async {},
      );
      await emitFromNative(const MethodCall(CHANNEL_METHOD_NEW_FCM_TOKEN, null));
      expect(received, '');
    });

    test('an unknown native method does not break later valid callbacks', () async {
      String? received;
      await fcm.initialize(
        onFcmTokenHandle: (t) async => received = t,
        onFcmSilentDataHandle: (_) async {},
      );
      // An unrecognized method is rejected by the handler, but the channel stays
      // healthy for subsequent, valid native -> Dart calls.
      await emitFromNative(const MethodCall('bogusMethod'));
      await emitFromNative(const MethodCall(CHANNEL_METHOD_NEW_FCM_TOKEN, 'later'));
      expect(received, 'later');
    });
  });
}
