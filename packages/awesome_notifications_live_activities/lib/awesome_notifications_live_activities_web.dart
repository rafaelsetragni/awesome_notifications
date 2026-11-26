import 'dart:ui_web' as ui_web;

import 'package:awesome_notifications/awesome_notifications_web.dart';

import 'awesome_notifications_live_activities.dart';
import 'src/web/js_live_notifications.dart';
import 'src/web/web_live_activity_controller.dart';

/// The web implementation: a page notification per activity, replaced in
/// place without alerting again (no system surface on the web). See
/// [JsLiveNotifications] for what a page can and can't do without a service
/// worker.
class AwesomeNotificationsLiveActivitiesWeb {
  /// Called by the generated plugin registrant (the registrar isn't needed:
  /// everything runs in Dart, without channels).
  static void registerWith([Object? registrar]) {
    final controller = WebLiveActivityController(
      JsLiveNotifications(),
      dispatchAction: AwesomeNotificationsWeb.dispatchAction,
      assetUrl: ui_web.assetManager.getAssetUrl,
    );
    AwesomeNotificationsWeb.registerNotificationBuilder(controller.build);
    AwesomeNotificationsWeb.registerRemovalListener(
        (removal) async => controller.onRemoved(removal.matches));
    AwesomeNotificationsLiveActivities.bridge = controller;
  }
}
