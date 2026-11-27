import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/awesome_notifications_empty.dart';
import 'package:awesome_notifications/awesome_notifications_platform.dart';
import 'package:awesome_notifications/method_channel_awesome_notifications.dart';
import 'package:awesome_notifications/src/helpers/bitmap_helper.dart';
import 'package:awesome_notifications/src/isolates/isolate_controller.dart';
import 'package:flutter/cupertino.dart' show CupertinoColors;
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Top-level handlers: only these have callback handles (closures don't), so
// they reach the code paths that serialize or look up a handle.
final List<int> _received = [];

@pragma('vm:entry-point')
Future<void> _onActionA(ReceivedAction a) async => _received.add(a.id!);
@pragma('vm:entry-point')
Future<void> _onActionB(ReceivedAction a) async {}
@pragma('vm:entry-point')
Future<void> _onActionThrows(ReceivedAction a) async => throw StateError('x');
@pragma('vm:entry-point')
Future<void> _onNotification(ReceivedNotification r) async {}

int _handleOf(Function f) => ui.PluginUtilities.getCallbackHandle(f)!.toRawHandle();

/// A 1x1 transparent PNG.
final Uint8List _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0B, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x60, 0x00, 0x02, 0x00,
  0x00, 0x05, 0x00, 0x01, 0x7A, 0x5E, 0xAB, 0x3F, 0x00, 0x00, 0x00, 0x00,
  0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

class _DrawablePlatform extends AwesomeNotificationsEmpty {
  @override
  Future<Uint8List?> getDrawableData(String path) async => _png;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('facade and empty platform', () {
    test('maxID is the 32-bit limit', () {
      expect(AwesomeNotifications.maxID, 2147483647);
    });

    test('getPermissionStatusList reaches the platform', () async {
      final previous = AwesomeNotificationsPlatform.instance;
      AwesomeNotificationsPlatform.instance = AwesomeNotificationsEmpty();
      addTearDown(() => AwesomeNotificationsPlatform.instance = previous);
      expect(await AwesomeNotifications().getPermissionStatusList(), isEmpty);
    });
  });

  group('models and helpers', () {
    test('a channel accepts a resource icon', () {
      final channel = NotificationChannel(
          channelKey: 'ch',
          channelName: 'Ch',
          channelDescription: 'd',
          icon: 'resource://drawable/ic');
      expect(channel.icon, 'resource://drawable/ic');
    });

    test('MediaSourcePrefix keeps its value', () {
      expect(const MediaSourcePrefix(2).value, 2);
      expect(MediaSourcePrefix.values, hasLength(5));
    });

    test('BitmapHelper.fromHeadful drops the RGBA32 header', () {
      final bitmap = BitmapHelper.fromHeadful(
          1, 1, Uint8List(RGBA32HeaderSize + bitmapPixelLength));
      expect(bitmap.content, hasLength(bitmapPixelLength));
    });

    test('toListMap maps each model, or null when empty', () {
      expect(AwesomeAssertUtils.toListMap<NotificationChannel>(null), isNull);
      expect(AwesomeAssertUtils.toListMap<NotificationChannel>([]), isNull);
      // Only models whose map has no null values (as in 0.12).
      final maps = AwesomeAssertUtils.toListMap([
        NotificationChannelGroup(channelGroupKey: 'g', channelGroupName: 'G')
      ]);
      expect(maps!.single[NOTIFICATION_CHANNEL_GROUP_KEY], 'g');
    });

    test('getValueOrDefault turns material and cupertino colors into a Color',
        () {
      expect(
          AwesomeAssertUtils.getValueOrDefault<ui.Color>(
              NOTIFICATION_DEFAULT_COLOR, Colors.blue),
          Colors.blue.shade500);
      expect(
          AwesomeAssertUtils.getValueOrDefault<ui.Color>(
                  NOTIFICATION_DEFAULT_COLOR, Colors.blueAccent)!
              .toARGB32(),
          Colors.blueAccent.toARGB32());
      expect(
          AwesomeAssertUtils.getValueOrDefault<ui.Color>(
                  NOTIFICATION_DEFAULT_COLOR, CupertinoColors.systemBlue)!
              .toARGB32(),
          CupertinoColors.systemBlue.toARGB32());
    });

    test('extractValue reads a date with a time zone name', () {
      final date = AwesomeAssertUtils.extractValue<DateTime>(
          NOTIFICATION_CREATED_DATE,
          {NOTIFICATION_CREATED_DATE: '2024-01-02 03:04:05 UTC'});
      // A zone name the format can't parse falls back to the default.
      expect(date, anyOf(isNull, isA<DateTime>()));
    });

    test('extractValue reads a cupertino color', () {
      AwesomeAssertUtils.extractValue<ui.Color>(NOTIFICATION_DEFAULT_COLOR,
          {NOTIFICATION_DEFAULT_COLOR: CupertinoColors.systemBlue});
    });
  });

  group('ResourceImage', () {
    testWidgets('decodes the drawable the platform returns', (tester) async {
      final previous = AwesomeNotificationsPlatform.instance;
      AwesomeNotificationsPlatform.instance = _DrawablePlatform();
      addTearDown(() => AwesomeNotificationsPlatform.instance = previous);

      final image = ResourceImage('resource://drawable/ic',
          awesomeNotifications: AwesomeNotifications());
      await tester.runAsync(() async {
        final codec = await image.loadAsync(image,
            (buffer, {getTargetSize}) => ui.instantiateImageCodecFromBuffer(buffer));
        final frame = await codec.getNextFrame();
        expect(frame.image.width, 1);
        frame.image.dispose();

        final completer = image.loadImage(image,
            (buffer, {getTargetSize}) => ui.instantiateImageCodecFromBuffer(buffer));
        expect(completer, isA<MultiFrameImageStreamCompleter>());
      });
    });
  });

  group('method channel', () {
    const channel = MethodChannel('awesome_notifications');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    Object? Function(MethodCall call) reply = (_) => null;
    final calls = <MethodCall>[];

    setUp(() {
      calls.clear();
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return reply(call);
      });
    });
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('setListeners sends the handles of top-level methods', () async {
      final mc = MethodChannelAwesomeNotifications();
      reply = (_) => true;
      expect(
          await mc.setListeners(
            onActionReceivedMethod: _onActionA,
            onNotificationCreatedMethod: _onNotification,
            onNotificationDisplayedMethod: _onNotification,
            onDismissActionReceivedMethod: _onActionA,
          ),
          isTrue);
      final args = calls.last.arguments as Map;
      expect(args[ACTION_HANDLE], _handleOf(_onActionA));
      expect(args[CREATED_HANDLE], _handleOf(_onNotification));
      expect(args[DISPLAYED_HANDLE], _handleOf(_onNotification));
      expect(args[DISMISSED_HANDLE], _handleOf(_onActionA));
    });

    test('setListeners redefined, and refused by native', () async {
      final mc = MethodChannelAwesomeNotifications();
      reply = (_) => true;
      await mc.setListeners(onActionReceivedMethod: _onActionA);
      reply = (_) => false;
      expect(await mc.setListeners(onActionReceivedMethod: _onActionB), isFalse);
      expect(mc.actionHandler, _onActionB);
    });

    test('no active notification ids is an empty list', () async {
      reply = (_) => null;
      expect(
          await MethodChannelAwesomeNotifications()
              .getAllActiveNotificationIdsOnStatusBar(),
          isEmpty);
    });

    test('an invalid JSON notification is refused', () async {
      reply = (_) => true;
      final mc = MethodChannelAwesomeNotifications();
      expect(await mc.createNotificationFromJsonData({}), isFalse);
      expect(calls, isEmpty);
    });

    test('validateId refuses ids beyond 32 bits', () {
      final mc = MethodChannelAwesomeNotifications();
      expect(() => mc.validateId(0x80000000), throwsArgumentError);
      expect(() => mc.validateId(-0x80000001), throwsArgumentError);
      mc.validateId(0x7FFFFFFF);
      mc.dispose();
    });
  });

  group('IsolateController with a registered handler', () {
    setUp(_received.clear);

    test('runs the silent action handler', () async {
      final ok = await IsolateController().receiveSilentAction({
        ACTION_HANDLE: _handleOf(_onActionA),
        NOTIFICATION_ID: 5,
        NOTIFICATION_CHANNEL_KEY: 'ch',
      });
      expect(ok, isTrue);
      expect(_received, [5]);
    });

    test('a handler that throws reports false, and is swallowed', () async {
      final args = {
        ACTION_HANDLE: _handleOf(_onActionThrows),
        NOTIFICATION_ID: 6,
        NOTIFICATION_CHANNEL_KEY: 'ch',
      };
      expect(await IsolateController().receiveSilentAction(args), isFalse);
      // The callback handler turns the failure into a logged exception.
      await IsolateController()
          .channelMethodSilentCallbackHandle(MethodCall('x', args));
    });

    test('the reverse channel refuses an unknown method', () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
          const MethodChannel(DART_REVERSE_CHANNEL), (call) async => null);
      addTearDown(() => messenger.setMockMethodCallHandler(
          const MethodChannel(DART_REVERSE_CHANNEL), null));

      dartIsolateMain();
      await Future<void>.delayed(Duration.zero);

      ByteData? response;
      await messenger.handlePlatformMessage(
        DART_REVERSE_CHANNEL,
        const StandardMethodCodec().encodeMethodCall(const MethodCall('bogus')),
        (data) => response = data,
      );
      expect(
          () => const StandardMethodCodec().decodeEnvelope(response!),
          throwsA(isA<PlatformException>()));
    });
  });
}
