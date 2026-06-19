import 'dart:async';

import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import 'pages/home_page.dart';
import 'pages/notification_details_page.dart';

const String channelKey = 'basic_channel';

/// Used by the action listener to open the details page from anywhere.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Broadcast of human-readable event lines, fed by the static listeners below.
final StreamController<String> events = StreamController<String>.broadcast();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: channelKey,
        channelName: 'Basic notifications',
        channelDescription: 'Notification channel for basic tests',
        importance: NotificationImportance.High,
      ),
    ],
    debug: true,
  );
  runApp(const MyApp());
}

// Notification lifecycle listeners. They must be static/top-level and annotated
// with @pragma('vm:entry-point') so they can also be invoked from background.

@pragma('vm:entry-point')
Future<void> onCreated(ReceivedNotification received) async {
  events.add('created • #${received.id} ${received.title ?? ''}');
}

@pragma('vm:entry-point')
Future<void> onDisplayed(ReceivedNotification received) async {
  events.add('displayed • #${received.id} ${received.title ?? ''}');
}

@pragma('vm:entry-point')
Future<void> onDismiss(ReceivedAction action) async {
  events.add('dismissed • #${action.id}');
}

@pragma('vm:entry-point')
Future<void> onAction(ReceivedAction action) async {
  events.add('pressed • #${action.id} (${action.actionType})');
  // "Open" the notification fullscreen.
  navigatorKey.currentState?.push(
    MaterialPageRoute(builder: (_) => NotificationDetailsPage(action)),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onAction,
      onNotificationCreatedMethod: onCreated,
      onNotificationDisplayedMethod: onDisplayed,
      onDismissActionReceivedMethod: onDismiss,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Awesome Notifications',
      navigatorKey: navigatorKey,
      theme: ThemeData(useMaterial3: true),
      home: HomePage(channelKey: channelKey, events: events.stream),
    );
  }
}
