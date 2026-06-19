import 'dart:async';

import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

/// Main page with the test options + a live event log. Mirrors the original
/// example's home page (simplified to the core's current capabilities).
class HomePage extends StatefulWidget {
  final String channelKey;
  final Stream<String> events;

  const HomePage({super.key, required this.channelKey, required this.events});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _bigPicture = 'https://picsum.photos/id/1062/600/400';
  static const String _largeIcon = 'https://picsum.photos/id/64/200/200';

  bool _allowed = false;
  final List<String> _log = [];
  StreamSubscription<String>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.events.listen((line) {
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

  Future<void> _basic() => AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 1,
          channelKey: widget.channelKey,
          title: 'Basic notification',
          body: 'A simple title + body notification.',
        ),
      );

  Future<void> _withImageAndPayload() =>
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 2,
          channelKey: widget.channelKey,
          title: 'Notification with image',
          body: 'Tap me to open the details page with the picture and payload.',
          notificationLayout: NotificationLayout.BigPicture,
          bigPicture: _bigPicture,
          largeIcon: _largeIcon,
          payload: {'page': 'details', 'itemId': '1062', 'from': 'home'},
        ),
      );

  Future<void> _payloadOnly() => AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 3,
          channelKey: widget.channelKey,
          title: 'Notification with payload',
          body: 'No image; tap to inspect the payload.',
          payload: {'secret': '42', 'origin': 'payload-only'},
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Awesome Notifications core')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Notifications allowed: $_allowed'),
                const SizedBox(height: 8),
                if (!_allowed)
                  FilledButton.tonal(
                    onPressed: _requestPermission,
                    child: const Text('Request permission'),
                  ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: _basic,
                      child: const Text('Basic'),
                    ),
                    FilledButton(
                      onPressed: _withImageAndPayload,
                      child: const Text('Image + payload'),
                    ),
                    FilledButton(
                      onPressed: _payloadOnly,
                      child: const Text('Payload only'),
                    ),
                    OutlinedButton(
                      onPressed: () =>
                          AwesomeNotifications().dismissAllNotifications(),
                      child: const Text('Dismiss all'),
                    ),
                    OutlinedButton(
                      onPressed: () => AwesomeNotifications().cancelAll(),
                      child: const Text('Cancel all'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Events:'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _log.length,
              itemBuilder: (context, i) =>
                  ListTile(dense: true, title: Text(_log[i])),
            ),
          ),
        ],
      ),
    );
  }
}
