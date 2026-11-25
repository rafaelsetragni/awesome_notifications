import 'dart:ui_web' as ui_web;

import 'package:awesome_notifications/awesome_notifications_web.dart';

import 'awesome_notifications_media.dart';
import 'src/web/js_media_session.dart';
import 'src/web/web_media_controller.dart';

/// The web implementation: the page's media session
/// (`navigator.mediaSession`).
class AwesomeNotificationsMediaWeb {
  /// Called by the generated plugin registrant (the registrar isn't needed:
  /// everything runs in Dart, without channels).
  static void registerWith([Object? registrar]) {
    final controller = WebMediaController(
      JsMediaSession(),
      dispatchAction: AwesomeNotificationsWeb.dispatchAction,
      assetUrl: ui_web.assetManager.getAssetUrl,
    );
    AwesomeNotificationsWeb.registerNotificationBuilder(controller.build);
    AwesomeNotificationsMedia.bridge = controller;
  }
}
