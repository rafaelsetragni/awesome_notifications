import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart' show NOTIFICATION_ID;
import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:awesome_notifications_fcm/src/fcm_definitions.dart';
import 'package:awesome_notifications_fcm/src/isolates/silent_push_isolate_main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Top-level so PluginUtilities can resolve it from a raw callback handle,
/// exactly like the real background isolate does.
FcmSilentData? capturedSilent;
@pragma('vm:entry-point')
Future<void> topLevelSilentHandler(FcmSilentData silentData) async {
  capturedSilent = silentData;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => capturedSilent = null);

  group('receiveSilentData', () {
    test('resolves the registered handler and delivers the data', () async {
      final handle =
          PluginUtilities.getCallbackHandle(topLevelSilentHandler)!.toRawHandle();

      final handled = await receiveSilentData({
        SILENT_HANDLE: handle,
        NOTIFICATION_ID: 3,
        'payload': 'x',
      });

      expect(handled, isTrue);
      expect(capturedSilent, isNotNull);
      expect(capturedSilent!.id, 3);
      expect(capturedSilent!.data, {'payload': 'x'});
    });

    test('throws DartCallbackException for an unresolvable handle', () async {
      expect(
        () => receiveSilentData({SILENT_HANDLE: 1}),
        throwsA(isA<DartCallbackException>()),
      );
    });
  });

  group('channelMethodSilentCallbackHandle', () {
    test('swallows a bad-handle error instead of rethrowing', () async {
      // Must complete without throwing (errors are logged, not propagated).
      await channelMethodSilentCallbackHandle(
        const MethodCall(CHANNEL_METHOD_SILENT_CALLBACK, {SILENT_HANDLE: 1}),
      );
    });

    test('delivers the data for a valid handle', () async {
      final handle =
          PluginUtilities.getCallbackHandle(topLevelSilentHandler)!.toRawHandle();
      await channelMethodSilentCallbackHandle(
        MethodCall(CHANNEL_METHOD_SILENT_CALLBACK, {
          SILENT_HANDLE: handle,
          NOTIFICATION_ID: 9,
        }),
      );
      expect(capturedSilent!.id, 9);
    });
  });

  group('silentPushBackgroundMain', () {
    test('opens the reverse channel, asks for the next item, and routes calls',
        () async {
      final reverse = const MethodChannel(DART_FCM_REVERSE_CHANNEL);
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final outgoing = <String>[];
      messenger.setMockMethodCallHandler(reverse, (call) async {
        outgoing.add(call.method);
        return null;
      });

      await silentPushBackgroundMain();
      // It requests the first queued item on startup.
      expect(outgoing, contains(CHANNEL_METHOD_PUSH_NEXT_DATA));

      // A silent callback dispatched over the reverse channel is handled.
      final handle =
          PluginUtilities.getCallbackHandle(topLevelSilentHandler)!.toRawHandle();
      await messenger.handlePlatformMessage(
        reverse.name,
        reverse.codec.encodeMethodCall(
          MethodCall(CHANNEL_METHOD_SILENT_CALLBACK, {SILENT_HANDLE: handle}),
        ),
        (_) {},
      );
      expect(capturedSilent, isNotNull);

      // An unknown reverse-channel method is rejected (error contained by the
      // platform-message layer), leaving the isolate healthy.
      await messenger.handlePlatformMessage(
        reverse.name,
        reverse.codec.encodeMethodCall(const MethodCall('unknownReverse')),
        (_) {},
      );

      messenger.setMockMethodCallHandler(reverse, null);
    });
  });

  group('exceptions', () {
    test('carry a message in toString', () {
      expect(DartCallbackException('a').toString(), contains('a'));
      expect(AwesomeNotificationsFcmException('b').toString(), contains('b'));
    });
  });
}
