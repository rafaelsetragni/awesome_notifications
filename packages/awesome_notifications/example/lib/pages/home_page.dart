import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import '../common_widgets/led_light.dart';
import '../common_widgets/simple_button.dart';
import '../common_widgets/text_divisor.dart';

/// Main page with the test options, following the original example's style
/// (ListView of TextDivisor sections + full-width SimpleButtons). Notification
/// events are surfaced as snackbars (see main.dart).
class HomePage extends StatefulWidget {
  final String channelKey;

  const HomePage({super.key, required this.channelKey});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _bigPicture = 'https://picsum.photos/id/1062/600/400';
  static const String _largeIcon = 'https://picsum.photos/id/64/200/200';

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
      appBar: AppBar(title: const Text('Awesome Notifications')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          TextDivisor(title: 'Global Permission to send Notifications'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LedLight(_allowed),
                const SizedBox(height: 4),
                Text(
                  'Notifications are ${_allowed ? 'allowed' : 'not allowed'}.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
