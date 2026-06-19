import 'dart:async';

import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

const String _channelKey = 'basic_channel';

/// Broadcast of human-readable event lines, fed by the static listeners below.
final StreamController<String> _events = StreamController<String>.broadcast();

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

// Notification lifecycle listeners. They must be static/top-level and annotated
// with @pragma('vm:entry-point') so they can also be invoked from background.

@pragma('vm:entry-point')
Future<void> _onCreated(ReceivedNotification received) async {
  _events.add('created • #${received.id} ${received.title ?? ''}');
}

@pragma('vm:entry-point')
Future<void> _onDisplayed(ReceivedNotification received) async {
  _events.add('displayed • #${received.id} ${received.title ?? ''}');
}

@pragma('vm:entry-point')
Future<void> _onAction(ReceivedAction action) async {
  _events.add('action • #${action.id} (${action.actionType})');
}

@pragma('vm:entry-point')
Future<void> _onDismiss(ReceivedAction action) async {
  _events.add('dismissed • #${action.id}');
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _allowed = false;
  final List<String> _log = [];
  StreamSubscription<String>? _sub;

  @override
  void initState() {
    super.initState();

    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onAction,
      onNotificationCreatedMethod: _onCreated,
      onNotificationDisplayedMethod: _onDisplayed,
      onDismissActionReceivedMethod: _onDismiss,
    );

    _sub = _events.stream.listen((line) {
      if (mounted) setState(() => _log.insert(0, line));
    });

    AwesomeNotifications().isNotificationAllowed().then((allowed) {
      if (mounted) setState(() => _allowed = allowed);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
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
        body: 'Tap or swipe me to see the action / dismiss events.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Awesome Notifications core')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Notifications allowed: $_allowed'),
                  const SizedBox(height: 12),
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
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Events:'),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _log.length,
                itemBuilder: (context, i) => ListTile(
                  dense: true,
                  title: Text(_log[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
