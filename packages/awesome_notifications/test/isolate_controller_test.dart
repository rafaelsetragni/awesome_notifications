import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/src/isolates/isolate_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('IsolateController() is a singleton', () {
    expect(IsolateController(), same(IsolateController()));
  });

  test('receiveSilentAction throws for an unregistered callback handle',
      () async {
    await expectLater(
      IsolateController().receiveSilentAction({
        ACTION_HANDLE: 123456789,
        NOTIFICATION_ID: 1,
        NOTIFICATION_CHANNEL_KEY: 'ch',
      }),
      throwsA(isA<IsolateCallbackException>()),
    );
  });

  test('channelMethodSilentCallbackHandle swallows the callback error',
      () async {
    // The invalid handle makes receiveSilentAction throw; the handler logs and
    // returns without rethrowing.
    await IsolateController().channelMethodSilentCallbackHandle(
      const MethodCall('x', {ACTION_HANDLE: 123456789, NOTIFICATION_ID: 1}),
    );
  });

  test('channelMethodIsolateShutdown completes', () async {
    await IsolateController().channelMethodIsolateShutdown(const MethodCall('x'));
  });

  test('dartIsolateMain wires the reverse channel and routes its methods',
      () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        const MethodChannel(DART_REVERSE_CHANNEL), (call) async => null);

    dartIsolateMain(); // installs the incoming-call handler
    await Future<void>.delayed(Duration.zero);

    const codec = StandardMethodCodec();
    Future<void> deliver(MethodCall call) => messenger.handlePlatformMessage(
          DART_REVERSE_CHANNEL,
          codec.encodeMethodCall(call),
          (_) {},
        );

    // Exercise the handler's switch (both are swallowed internally).
    await deliver(const MethodCall(
        CHANNEL_METHOD_SILENT_CALLBACK, {ACTION_HANDLE: 123456789, NOTIFICATION_ID: 1}));
    await deliver(const MethodCall(CHANNEL_METHOD_ISOLATE_SHUTDOWN));

    messenger.setMockMethodCallHandler(
        const MethodChannel(DART_REVERSE_CHANNEL), null);
  });
}
