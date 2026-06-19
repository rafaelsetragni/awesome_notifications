import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

const String _channelKey = 'basic_channel';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: _channelKey,
        channelName: 'Basic notifications',
        channelDescription: 'Notification channel for basic tests',
        importance: NotificationImportance.High,
      ),
    ],
    debug: true,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _allowed = false;

  @override
  void initState() {
    super.initState();
    AwesomeNotifications().isNotificationAllowed().then((allowed) {
      if (mounted) setState(() => _allowed = allowed);
    });
  }

  Future<void> _requestPermission() async {
    final allowed =
        await AwesomeNotifications().requestPermissionToSendNotifications();
    if (mounted) setState(() => _allowed = allowed);
  }

  Future<void> _createNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: _channelKey,
        title: 'Hello from the monorepo core',
        body: 'This local notification was created by the new core plugin.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Awesome Notifications core')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Notifications allowed: $_allowed'),
              const SizedBox(height: 16),
              if (!_allowed)
                ElevatedButton(
                  onPressed: _requestPermission,
                  child: const Text('Request permission'),
                ),
              ElevatedButton(
                onPressed: _createNotification,
                child: const Text('Create notification'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
