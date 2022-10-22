// ignore_for_file: constant_identifier_names
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_example/pages/phone_call_page.dart';
import 'package:flutter/material.dart';

import 'package:awesome_notifications_example/pages/media_details_page.dart';
import 'package:awesome_notifications_example/pages/notification_details_page.dart';
import 'package:awesome_notifications_example/pages/home_page.dart';

import '../main.dart';
import '../notifications/notifications_controller.dart';

const String PAGE_HOME = '/';
const String PAGE_MEDIA_DETAILS = '/media-details';
const String PAGE_NOTIFICATION_DETAILS = '/notification-details';
const String PAGE_FIREBASE_TESTS = '/firebase-tests';
const String PAGE_PHONE_CALL = '/phone-call';

Map<String, WidgetBuilder> materialRoutes = {
  PAGE_HOME: (context) => const HomePage(),
  PAGE_MEDIA_DETAILS: (context) => MediaDetailsPage(),
  PAGE_NOTIFICATION_DETAILS: (context) => NotificationDetailsPage(
        ModalRoute.of(context)!.settings.arguments as ReceivedNotification,
      ),
  PAGE_PHONE_CALL: (context) {
    ReceivedAction? receivedAction =
        ModalRoute.of(context)!.settings.arguments == null
            ? NotificationsController.initialCallAction
            : ModalRoute.of(context)!.settings.arguments as ReceivedAction;

    return PhoneCallPage(receivedAction: receivedAction!);
  }
};
