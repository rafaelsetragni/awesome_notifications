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
  static const String _bigPicture =
      'https://media.wired.com/photos/598e35994ab8482c0d6946e0/master/w_2560%2Cc_limit/phonepicutres-TA.jpg';
  static const String _largeIcon =
      'https://image.freepik.com/vetores-gratis/modelo-de-logotipo-de-restaurante-retro_23-2148451519.jpg';

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

  // Auto-dismiss concept: stays in the tray after a tap (Android).
  Future<void> _keepOnTap() => AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 4,
          channelKey: widget.channelKey,
          title: 'Stays after tap',
          body: 'autoDismissible: false — tapping keeps it on the tray (Android).',
          autoDismissible: false,
          payload: {'origin': 'keep-on-tap'},
        ),
      );

  // DismissAction concept: a tap dismisses it and fires onDismissActionReceived.
  Future<void> _dismissOnTap() => AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 5,
          channelKey: widget.channelKey,
          title: 'Dismiss on tap',
          body: 'actionType DismissAction — tapping dismisses it and fires '
              'onDismissActionReceived.',
          actionType: ActionType.DismissAction,
          payload: {'origin': 'dismiss-action'},
        ),
      );

  // Localizations decorator: translated at build time based on the set language.
  Future<void> _localized() => AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 6,
          channelKey: widget.channelKey,
          title: 'Hello',
          body: 'This is the default (en) text.',
          payload: {'origin': 'localized'},
        ),
        localizations: {
          'pt': NotificationLocalization(
            title: 'Olá',
            body: 'Este é o texto em português.',
          ),
          'es': NotificationLocalization(
            title: 'Hola',
            body: 'Este es el texto en español.',
          ),
        },
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
          TextDivisor(title: 'Dismiss vs Cancel'),
          Text(
            'Dismiss only removes the notification from the status bar. '
            'Cancel does the same AND cancels its schedule.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          SimpleButton('Dismiss the basic notification (#1)',
              onPressed: () => AwesomeNotifications().dismiss(1)),
          SimpleButton('Cancel the basic notification (#1)',
              onPressed: () => AwesomeNotifications().cancel(1)),
          SimpleButton('Dismiss all notifications',
              onPressed: () =>
                  AwesomeNotifications().dismissAllNotifications()),
          SimpleButton('Cancel all notifications',
              onPressed: () => AwesomeNotifications().cancelAll()),
          TextDivisor(title: 'Dismiss concepts'),
          SimpleButton('Keep on tray after tap (autoDismissible: false)',
              onPressed: _keepOnTap),
          SimpleButton('Dismiss on tap (DismissAction)',
              onPressed: _dismissOnTap),
          TextDivisor(title: 'Localizations (decorator)'),
          SimpleButton('Set language: Portuguese (pt)',
              onPressed: () =>
                  AwesomeNotifications().setLocalization(languageCode: 'pt')),
          SimpleButton('Set language: Spanish (es)',
              onPressed: () =>
                  AwesomeNotifications().setLocalization(languageCode: 'es')),
          SimpleButton('Set language: English (en)',
              onPressed: () =>
                  AwesomeNotifications().setLocalization(languageCode: 'en')),
          SimpleButton('Show localized notification', onPressed: _localized),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
