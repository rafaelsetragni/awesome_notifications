
import 'dart:io';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/services.dart';

import 'background_callback_dispatcher.dart';

typedef BackgroundMessageHandler = Function(ReceivedAction action);

class AwesomeNotificationsBackgroundActionHandler  {

  static AwesomeNotifications get instance => AwesomeNotifications();
  static BackgroundMessageHandler? _onBackgroundMessageHandler;

  static bool _bgHandlerInitialized = false;

  static set onBackgroundMessage(BackgroundMessageHandler? handler) {
    _onBackgroundMessageHandler = handler;
  }

  static BackgroundMessageHandler? get onBackgroundMessage {
    return _onBackgroundMessageHandler;
  }

  AwesomeNotificationsBackgroundActionHandler(MethodChannel channel,BackgroundMessageHandler? handler){
    onBackgroundMessage = handler;

    if(!Platform.isAndroid) return;

    if(handler!= null)
      _registerHandler(channel, _onBackgroundMessageHandler!);
  }


  _registerHandler(MethodChannel channel,BackgroundMessageHandler handler) async {
    if (!_bgHandlerInitialized) {
      _bgHandlerInitialized = true;
      final bgHandle = PluginUtilities.getCallbackHandle(callbackDispatcher)!;
      final userHandle = PluginUtilities.getCallbackHandle(handler)!;
      await channel.invokeMapMethod(CHANNEL_METHOD_START_BACKGROUND, {
        'pluginCallbackHandle': bgHandle.toRawHandle(),
        'userCallbackHandle': userHandle.toRawHandle(),
      });
    }
  }
}