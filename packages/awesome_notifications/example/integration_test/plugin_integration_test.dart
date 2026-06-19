// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:awesome_notifications/awesome_notifications.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('initialize and query notification permission',
      (WidgetTester tester) async {
    final plugin = AwesomeNotifications();

    await plugin.initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for integration tests',
        ),
      ],
    );

    // The host platform answers whether notifications are allowed; we only
    // assert the round-trip through the method channel returns a bool.
    final allowed = await plugin.isNotificationAllowed();
    expect(allowed, isA<bool>());
  });
}
