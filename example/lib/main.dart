// FIREBASE_MESSAGING will be discontinued
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:awesome_notifications_example/notifications/firebase_controller.dart';

import 'package:flutter/material.dart';

import 'package:awesome_notifications_example/routes/routes.dart';
import 'package:awesome_notifications_example/themes/themes_controller.dart';
import 'package:awesome_notifications_example/notifications/notifications_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationsController.initializeLocalNotifications();
  runApp(App());
}

class App extends StatefulWidget {
  App();

  static String name = 'Awesome Notifications - Example App';
  static Color mainColor = Color(0xFF9D50DD);

  // The navigator key is necessary to navigate using static methods
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();

    // Only after at least the action method is set, the notification events are delivered
    NotificationsController.initializeNotificationsEventListeners();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: App.name,
      color: App.mainColor,
      navigatorKey: App.navigatorKey,
      initialRoute: PAGE_HOME,
      routes: materialRoutes,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
      theme: ThemesController.currentTheme,
    );
  }
}
