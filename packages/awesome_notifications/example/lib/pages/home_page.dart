import 'dart:async';

import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import '../common_widgets/simple_button.dart';
import '../common_widgets/text_divisor.dart';

/// Main page with the test options + a live event log, following the original
/// example's style (ListView of TextDivisor sections + full-width SimpleButtons).
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Awesome Notifications core')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          TextDivisor(title: 'Global Permission to send Notifications'),
          Text(
            'Notifications are ${_allowed ? 'allowed' : 'not allowed'}.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          SimpleButton(
            'Request permission to send notifications',
            enabled: !_allowed,
            backgroundColor: Colors.deepPurple,
            labelColor: Colors.white,
            onPressed: _requestPermission,
          ),
          TextDivisor(title: 'Basic Notifications'),
          SimpleButton('Show the most basic notification', onPressed: _basic),
          SimpleButton('Show notification with image and payload',
              onPressed: _withImageAndPayload),
          SimpleButton('Show notification with payload',
              onPressed: _payloadOnly),
          SimpleButton('Dismiss all notifications',
              onPressed: () =>
                  AwesomeNotifications().dismissAllNotifications()),
          SimpleButton('Cancel all notifications',
              onPressed: () => AwesomeNotifications().cancelAll()),
          TextDivisor(title: 'Events'),
          if (_log.isEmpty)
            Text('No events yet.',
                textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
          for (final line in _log)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(line, style: theme.textTheme.bodyMedium),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
