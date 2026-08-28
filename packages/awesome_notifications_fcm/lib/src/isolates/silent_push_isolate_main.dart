import 'dart:ui';

import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:awesome_notifications_fcm/src/fcm_definitions.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Entry point executed by the native side inside a dedicated background Flutter
/// engine when a silent (data-only) push arrives while the app is terminated.
///
/// It opens the reverse channel, waits for the native side to push queued silent
/// messages, and forwards each to the user's [FcmSilentDataHandler].
@pragma('vm:entry-point')
Future<void> silentPushBackgroundMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(DART_FCM_REVERSE_CHANNEL);

  channel.setMethodCallHandler((MethodCall call) async {
    switch (call.method) {
      case CHANNEL_METHOD_SILENT_CALLBACK:
        await channelMethodSilentCallbackHandle(call);
        break;

      default:
        throw UnimplementedError('${call.method} has not been implemented');
    }
  });

  // Tell the native side the isolate is ready to receive the next queued item.
  await channel.invokeMethod<void>(CHANNEL_METHOD_PUSH_NEXT_DATA);
}

/// Handles a single silent callback dispatched over the reverse channel.
Future<void> channelMethodSilentCallbackHandle(MethodCall call) async {
  try {
    final bool success = await receiveSilentData(
        (call.arguments as Map).cast<String, dynamic>());

    if (!success) {
      throw AwesomeNotificationsFcmException(
          'Silent data could not be recovered');
    }
  } catch (e) {
    debugPrint('Awesome Notifications FCM: an error occurred in your '
        'background messaging handler:');
    debugPrint(e.toString());
  }
}

/// Resolves the registered silent-data tear-off from its raw handle and invokes
/// it with the decoded [FcmSilentData]. Returns true when handled.
Future<bool> receiveSilentData(Map<String, dynamic> arguments) async {
  final CallbackHandle silentCallbackHandle =
      CallbackHandle.fromRawHandle(arguments[SILENT_HANDLE]);

  // PluginUtilities.getCallbackFromHandle performs a lookup based on the callback
  // handle and returns a tear-off of the original callback.
  final FcmSilentDataHandler? onSilentDataHandle =
      PluginUtilities.getCallbackFromHandle(silentCallbackHandle)
          as FcmSilentDataHandler?;

  if (onSilentDataHandle == null) {
    throw DartCallbackException('could not find silent callback');
  }

  final FcmSilentData? silentData = FcmSilentData().fromMap(arguments);
  if (silentData != null) await onSilentDataHandle(silentData);

  return true;
}
