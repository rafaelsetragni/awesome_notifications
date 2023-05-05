import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/src/isolates/isolate_main.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

typedef ActionHandler = Future<void> Function(ReceivedAction receivedAction);

class MockPluginUtilities extends Mock implements PluginUtilities {}

class MockWidgetsFlutterBinding extends Mock implements WidgetsFlutterBinding {}

class MockMethodChannel extends Mock implements MethodChannel {}

class MockIsolateController extends Mock implements IsolateController {}

class MockMethodCall extends Fake implements MethodCall {}

void main() {
  channel = MockMethodChannel();

  setUpAll(() {
    registerFallbackValue(MockMethodCall());
  });

  test('dartIsolateMain', () async {
    // WidgetsFlutterBinding binding = MockWidgetsFlutterBinding();
    // Ensure binding is called once
    // verify(() => binding.ensureInitialized()).called(1);

    when(() => channel.invokeMethod<void>(any()))
        .thenAnswer((invocation) => Future.value());

    dartIsolateMain();

    // Ensure the CHANNEL_METHOD_PUSH_NEXT_DATA method is invoked
    verify(() => channel.invokeMethod<void>(CHANNEL_METHOD_PUSH_NEXT_DATA))
        .called(1);

    // MockIsolateController mockIsolateController = MockIsolateController();
    // IsolateController.singleton = mockIsolateController;

    // when(() => mockIsolateController.channelMethodSilentCallbackHandle(any()))
    //     .thenAnswer((invocation) => Future.value());

    // when(() => mockIsolateController.channelMethodIsolateShutdown(any()))
    //     .thenAnswer((invocation) => Future.value());

    // channel.invokeMethod<void>(CHANNEL_METHOD_SILENT_CALLBACK);

    // verify(() => mockIsolateController.channelMethodSilentCallbackHandle(any()))
    //     .called(1);

    // channel.invokeMethod<void>(CHANNEL_METHOD_ISOLATE_SHUTDOWN);

    // verify(() => mockIsolateController.channelMethodIsolateShutdown(any()))
    //     .called(1);
  });
}
