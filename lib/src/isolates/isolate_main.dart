import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../awesome_notifications.dart';
import '../logs/logger.dart';

@pragma("vm:entry-point")
void dartIsolateMain() {
  // Initialize state necessary for MethodChannels.

  // Current in tests
  // DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  // We establish a new flutter native channel to be able to receive data in
  // inverse direction
  const MethodChannel channel = MethodChannel(DART_REVERSE_CHANNEL);

  // This is where we handle background silent events
  channel.setMethodCallHandler((MethodCall call) async {
    switch (call.method) {
      case CHANNEL_METHOD_SILENT_CALLBACK:
        await channelMethodSilentCallbackHandle(call);
        break;

      case CHANNEL_METHOD_ISOLATE_SHUTDOWN:
        await channelMethodIsolateShutdown(call);
        break;

      default:
        throw UnimplementedError("${call.method} has not been implemented");
    }
  });

  // for last, the native channel is initialize to allow to call CHANNEL_METHOD_SILENCED_CALLBACK
  channel.invokeMethod<void>(CHANNEL_METHOD_PUSH_NEXT_DATA);
}

/// This method handle the silent callback as a flutter plugin
@pragma("vm:entry-point")
Future<void> channelMethodIsolateShutdown(MethodCall call) async {
  try {} catch (error, stacktrace) {
    Logger.e("channelMethodIsolateShutdown",
        "An error occurred in your background messaging handler: $error");
    Logger.e("receiveSilentAction", stacktrace.toString());
  }
}

/// This method handle the silent callback as a flutter plugin
Future<void> channelMethodSilentCallbackHandle(MethodCall call) async {
  try {
    bool success = await receiveSilentAction(
        (call.arguments as Map).cast<String, dynamic>());

    if (!success) {
      throw const AwesomeNotificationsException(
          message: 'Silent data could not be recovered');
    }
  } on Exception catch (error, stacktrace) {
    Logger.e("channelMethodSilentCallbackHandle",
        "An error occurred in your background messaging handler: $error");
    Logger.e("receiveSilentAction", stacktrace.toString());
  }
}

/// Calls the silent data method, if is a valid static one
Future<bool> receiveSilentAction(Map<String, dynamic> arguments) async {
  final CallbackHandle actionCallbackHandle =
      CallbackHandle.fromRawHandle(arguments[ACTION_HANDLE]);

  // PluginUtilities.getCallbackFromHandle performs a lookup based on the
  // callback handle and returns a tear-off of the original callback.
  final ActionHandler? onActionDataHandle =
      PluginUtilities.getCallbackFromHandle(actionCallbackHandle)
          as ActionHandler?;

  if (onActionDataHandle == null) {
    throw IsolateCallbackException(
        'Could not find a valid action callback. Certifies that your action method is global and static.');
  }

  Map<String, dynamic> actionMap = Map<String, dynamic>.from(arguments);
  final ReceivedAction receivedAction = ReceivedAction().fromMap(actionMap);

  try {
    await onActionDataHandle(receivedAction);
  } catch (error, stacktrace) {
    Logger.e("receiveSilentAction",
        "Got an unknown Silent Action callback error: $error");
    Logger.e("receiveSilentAction", stacktrace.toString());
    return false;
  }

  return true;
}
