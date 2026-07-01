import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/awesome_notifications_platform.dart';
import 'package:awesome_notifications/method_channel_awesome_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationContent', () {
    test('serializes core fields through toMap/fromMap', () {
      final original = NotificationContent(
        id: 42,
        channelKey: 'basic_channel',
        title: 'Title',
        body: 'Body',
      );

      final restored = NotificationContent(id: 0, channelKey: '')
          .fromMap(original.toMap());

      expect(restored, isNotNull);
      expect(restored!.id, 42);
      expect(restored.channelKey, 'basic_channel');
      expect(restored.title, 'Title');
      expect(restored.body, 'Body');
    });
  });

  group('NotificationModel', () {
    test('requires content to be valid', () {
      expect(
        () => NotificationModel().validate(),
        throwsA(isA<AwesomeNotificationsException>()),
      );
    });

    test('round-trips content and action buttons', () {
      final model = NotificationModel(
        content: NotificationContent(
          id: 1,
          channelKey: 'basic_channel',
          title: 'Hello',
        ),
        actionButtons: [
          NotificationActionButton(key: 'ACCEPT', label: 'Accept'),
        ],
      );

      final restored = NotificationModel().fromMap(model.toMap());

      expect(restored, isNotNull);
      expect(restored!.content?.id, 1);
      expect(restored.actionButtons?.single.key, 'ACCEPT');
    });
  });

  // The core is localization-agnostic, but a push/JSON payload (old format) may
  // carry a top-level `localizations` key. createNotificationFromJsonData must
  // forward it untouched so the localizations add-on can translate natively.
  group('createNotificationFromJsonData preserves the push/JSON payload', () {
    const channel = MethodChannel('awesome_notifications');
    Map? captured;

    setUp(() {
      // On a non-mobile test host the default platform is the no-op stub; force
      // the method-channel implementation so the channel is actually exercised.
      AwesomeNotificationsPlatform.instance = MethodChannelAwesomeNotifications();
      captured = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'createNewNotification') {
          captured = call.arguments as Map;
          return true;
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('forwards a top-level localizations map to native', () async {
      final ok = await AwesomeNotifications().createNotificationFromJsonData({
        'content': {'id': 1, 'channelKey': 'basic_channel', 'title': 'Hi'},
        'localizations': {
          'pt-br': {'title': 'Olá'}
        },
      });

      expect(ok, isTrue);
      expect(captured, isNotNull);
      expect(captured!['localizations'], isA<Map>());
      expect((captured!['localizations'] as Map)['pt-br'], isA<Map>());
    });

    test('decodes a JSON-string localizations (FCM data style)', () async {
      await AwesomeNotifications().createNotificationFromJsonData({
        'content': '{"id":2,"channelKey":"basic_channel","title":"Hi"}',
        'localizations': '{"pt-br":{"title":"Olá"}}',
      });

      expect(captured, isNotNull);
      expect(captured!['localizations'], isA<Map>());
      expect((captured!['localizations'] as Map)['pt-br'], isA<Map>());
    });
  });
}
