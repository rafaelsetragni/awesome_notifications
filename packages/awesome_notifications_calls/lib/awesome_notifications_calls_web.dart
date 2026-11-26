import 'dart:ui_web' as ui_web;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/awesome_notifications_web.dart';

import 'awesome_notifications_calls.dart';
import 'src/web/js_call_notifications.dart';
import 'src/web/web_call_controller.dart';

/// The web implementation: a page notification per call (no system call UI
/// on the web). See [JsCallNotifications] for what a page can and can't do
/// without a service worker.
class AwesomeNotificationsCallsWeb {
  /// Called by the generated plugin registrant (the registrar isn't needed:
  /// everything runs in Dart, without channels).
  static void registerWith([Object? registrar]) {
    final controller = WebCallController(
      JsCallNotifications(),
      dispatchAction: AwesomeNotificationsWeb.dispatchAction,
      createNotification: AwesomeNotifications().createNotificationFromJsonData,
      assetUrl: ui_web.assetManager.getAssetUrl,
    );
    AwesomeNotificationsWeb.registerNotificationBuilder(controller.build);
    AwesomeNotificationsWeb.registerRemovalListener(
        (removal) async => controller.onRemoved(removal.matches));
    AwesomeNotificationsCalls.bridge = controller;
  }
}
