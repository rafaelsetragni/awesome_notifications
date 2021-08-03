import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

void callbackDispatcher() {

  // 1. Initialize MethodChannel used to communicate with the platform portion of the plugin.
  const MethodChannel _backgroundChannel = MethodChannel(CHANNEL_FLUTTER_BACKGROUND_PLUGIN);

  // 2. Setup internal state needed for MethodChannels.
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Listen for background events from the platform portion of the plugin.
  _backgroundChannel.setMethodCallHandler((MethodCall call) async {
    if(call.method == CHANNEL_METHOD_ACTION_RECEIVED_BACKGROUND){
      final handleRaw = call.arguments["userCallbackHandle"];
      final CallbackHandle handle = CallbackHandle.fromRawHandle(handleRaw);

      // 3.1. Retrieve closure instance for handle.
      final closure = PluginUtilities.getCallbackFromHandle(handle)! as Function(ReceivedAction);
      try{
        final messgae = call.arguments["message"];
        Map<String, dynamic> arguments = Map<String, dynamic>.from(messgae[ARGUMENT_BACKGROUND_ACTION_RECEIVED]);
        final action = ReceivedAction().fromMap(arguments) as ReceivedAction;
        closure(action);
      }catch(e){
        print('AwesomeNotifications Messaging: An error occurred in your background messaging handler:');
        print(e);
      }
    }else{
      throw UnimplementedError('${call.method} has not been implemented');
    }
  });
  // Once we've finished initializing, let the native portion of the plugin
  // know that it can start scheduling alarms.
  _backgroundChannel.invokeMethod<void>(CHANNEL_METHOD_INIT_BACKGROUND);
}