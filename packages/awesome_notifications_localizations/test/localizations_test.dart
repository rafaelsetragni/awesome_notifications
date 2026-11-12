import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_localizations/awesome_notifications_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationLocalization', () {
    test('toMap omits null/empty fields', () {
      final map = NotificationLocalization(
        title: 'Olá',
        body: '',
        buttonLabels: {'YES': 'Sim'},
      ).toMap();
      expect(map[NOTIFICATION_TITLE], 'Olá');
      expect(map.containsKey(NOTIFICATION_BODY), isFalse); // empty omitted
      expect(map[NOTIFICATION_BUTTON_LABELS], {'YES': 'Sim'});
    });

    test('fromMap parses fields and button labels', () {
      final loc = NotificationLocalization().fromMap({
        NOTIFICATION_TITLE: 'Olá',
        NOTIFICATION_BODY: 'Corpo',
        NOTIFICATION_SUMMARY: 'Resumo',
        NOTIFICATION_LARGE_ICON: 'asset://l.png',
        NOTIFICATION_BIG_PICTURE: 'https://x/b.png',
        NOTIFICATION_BUTTON_LABELS: {'YES': 'Sim', 'NO': 'Não'},
      });
      expect(loc?.title, 'Olá');
      expect(loc?.summary, 'Resumo');
      expect(loc?.buttonLabels, {'YES': 'Sim', 'NO': 'Não'});
    });

    test('fromMap returns null for an empty map', () {
      expect(NotificationLocalization().fromMap({}), isNull);
    });
  });

  group('NotificationLocalizations extension', () {
    test('contributes a top-level localizations block', () {
      final extension = NotificationLocalizations({
        'pt-br': NotificationLocalization(title: 'Olá'),
        'en': NotificationLocalization(title: 'Hello'),
      });
      // NotificationExtension contract.
      expect(extension, isA<NotificationExtension>());
      final map = extension.toMap();
      final localizations = map['localizations'] as Map<String, dynamic>;
      expect((localizations['pt-br'] as Map)[NOTIFICATION_TITLE], 'Olá');
      expect((localizations['en'] as Map)[NOTIFICATION_TITLE], 'Hello');
    });
  });

  group('AwesomeNotificationsLocalizations', () {
    const channel = MethodChannel('awesome_notifications');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final localizations = AwesomeNotificationsLocalizations();
    final calls = <MethodCall>[];

    setUp(() {
      calls.clear();
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        switch (call.method) {
          case 'setLocalization':
            return true;
          case 'getLocalization':
            return 'pt-br';
          default:
            return null;
        }
      });
    });

    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('setLocalization forwards the language code', () async {
      expect(await localizations.setLocalization(languageCode: 'pt-br'), isTrue);
      expect(calls.single.method, 'setLocalization');
      expect(calls.single.arguments, 'pt-br');
    });

    test('getLocalization returns the current language', () async {
      expect(await localizations.getLocalization(), 'pt-br');
      expect(calls.single.method, 'getLocalization');
    });

    test('is a singleton', () {
      expect(AwesomeNotificationsLocalizations(),
          same(AwesomeNotificationsLocalizations()));
    });
  });
}
