import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

/// Single-file demo of awesome_notifications_fcm.
///
/// Prerequisites (Firebase is required for push):
///  * Android: add `android/app/google-services.json` and apply the
///    `com.google.gms.google-services` Gradle plugin.
///  * iOS: add `GoogleService-Info.plist`, enable Push Notifications +
///    Background Modes (Remote notifications) capabilities.
///
/// The FCM handlers MUST be top-level / static functions so the background
/// isolate can resolve them while the app is terminated.

/// Receives the Firebase Cloud Messaging token (and its refreshes).
Future<void> onFcmTokenReceived(String token) async {
  debugPrint('FCM token: $token');
}

/// Receives the raw native (APNs) token — iOS only.
Future<void> onNativeTokenReceived(String token) async {
  debugPrint('Native token: $token');
}

/// Handles silent (data-only) pushes, even while the app is terminated.
@pragma('vm:entry-point')
Future<void> onSilentDataReceived(FcmSilentData silentData) async {
  debugPrint('Silent data: ${silentData.data} (source: ${silentData.createdSource})');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'push',
        channelName: 'Push notifications',
        channelDescription: 'Notifications delivered through Firebase',
        importance: NotificationImportance.High,
      ),
    ],
  );

  await AwesomeNotificationsFcm().initialize(
    onFcmTokenHandle: onFcmTokenReceived,
    onNativeTokenHandle: onNativeTokenReceived,
    onFcmSilentDataHandle: onSilentDataReceived,
    debug: true,
  );

  runApp(const FcmExampleApp());
}

class FcmExampleApp extends StatefulWidget {
  const FcmExampleApp({super.key});

  @override
  State<FcmExampleApp> createState() => _FcmExampleAppState();
}

class _FcmExampleAppState extends State<FcmExampleApp> {
  String _token = '(press "Get token")';
  final _topicController = TextEditingController(text: 'news');

  Future<void> _getToken() async {
    final available = await AwesomeNotificationsFcm().isFirebaseAvailable;
    final token = available
        ? await AwesomeNotificationsFcm().requestFirebaseAppToken()
        : 'Firebase not configured';
    setState(() => _token = token);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Awesome Notifications FCM')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('FCM registration token:'),
              const SizedBox(height: 8),
              SelectableText(_token),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _getToken,
                child: const Text('Get token'),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _topicController,
                decoration: const InputDecoration(labelText: 'Topic'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => AwesomeNotificationsFcm()
                          .subscribeToTopic(_topicController.text),
                      child: const Text('Subscribe'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => AwesomeNotificationsFcm()
                          .unsubscribeToTopic(_topicController.text),
                      child: const Text('Unsubscribe'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
