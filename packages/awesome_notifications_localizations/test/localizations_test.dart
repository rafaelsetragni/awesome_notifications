import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/method_channel_awesome_notifications.dart';
import 'package:awesome_notifications_localizations/awesome_notifications_localizations.dart';
import 'package:flutter/foundation.dart';
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

    test('toMap serializes every field', () {
      final map = NotificationLocalization(
        title: 'T',
        body: 'B',
        summary: 'S',
        largeIcon: 'asset://l.png',
        bigPicture: 'https://x/b.png',
        buttonLabels: {'YES': 'Sim'},
      ).toMap();
      expect(map, {
        NOTIFICATION_TITLE: 'T',
        NOTIFICATION_BODY: 'B',
        NOTIFICATION_SUMMARY: 'S',
        NOTIFICATION_LARGE_ICON: 'asset://l.png',
        NOTIFICATION_BIG_PICTURE: 'https://x/b.png',
        NOTIFICATION_BUTTON_LABELS: {'YES': 'Sim'},
      });
    });

    test('an empty localization serializes to an empty map', () {
      expect(NotificationLocalization().toMap(), isEmpty);
      expect(NotificationLocalization(buttonLabels: {}).toMap(), isEmpty);
    });

    test('toMap → fromMap round-trips', () {
      final original = NotificationLocalization(
          title: 'Olá', summary: 'Resumo', buttonLabels: {'NO': 'Não'});
      final copy = NotificationLocalization().fromMap(original.toMap())!;
      expect(copy.toMap(), original.toMap());
      expect(copy.body, isNull);
    });

    test('fromMap stringifies button labels and ignores a non-map', () {
      final loc = NotificationLocalization().fromMap({
        NOTIFICATION_TITLE: 'x',
        NOTIFICATION_BUTTON_LABELS: {'COUNT': 3, 1: true},
      });
      expect(loc?.buttonLabels, {'COUNT': '3', '1': 'true'});
      final noLabels = NotificationLocalization()
          .fromMap({NOTIFICATION_TITLE: 'x', NOTIFICATION_BUTTON_LABELS: 'bad'});
      expect(noLabels?.buttonLabels, isNull);
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

    test('an empty set still contributes an (empty) block', () {
      expect(const NotificationLocalizations({}).toMap(), {'localizations': {}});
    });

    test('the block is JSON-encodable (push/schedule persistence)', () {
      final encoded = jsonEncode(NotificationLocalizations({
        'pt-br': NotificationLocalization(title: 'Olá', buttonLabels: {'YES': 'Sim'}),
      }).toMap());
      expect(jsonDecode(encoded), {
        'localizations': {
          'pt-br': {
            NOTIFICATION_TITLE: 'Olá',
            NOTIFICATION_BUTTON_LABELS: {'YES': 'Sim'},
          },
        },
      });
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

    test('setLocalization(null) asks for the system language', () async {
      expect(await localizations.setLocalization(languageCode: null), isTrue);
      expect(calls.single.arguments, isNull);
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

  group('native replies without a value', () {
    const channel = MethodChannel('awesome_notifications');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    setUp(() => messenger.setMockMethodCallHandler(channel, (_) async => null));
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('setLocalization is false and getLocalization is empty', () async {
      final localizations = AwesomeNotificationsLocalizations();
      expect(await localizations.setLocalization(languageCode: 'en'), isFalse);
      expect(await localizations.getLocalization(), '');
    });
  });

  group('createNotification payload', () {
    const channel = MethodChannel('awesome_notifications');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    late Map<String, dynamic> sent;

    setUp(() {
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == CHANNEL_METHOD_CREATE_NOTIFICATION) {
          sent = Map<String, dynamic>.from(call.arguments as Map);
        }
        return true;
      });
    });
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('carries the localizations block next to content and buttons', () async {
      final created = await MethodChannelAwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 7, channelKey: 'basic', title: 'Hello', body: 'World'),
        actionButtons: [NotificationActionButton(key: 'YES', label: 'Yes')],
        extensions: [
          NotificationLocalizations({
            'pt-br': NotificationLocalization(
                title: 'Olá', buttonLabels: {'YES': 'Sim'}),
            'es': NotificationLocalization(body: 'Mundo'),
          }),
        ],
      );
      expect(created, isTrue);
      final content = Map<String, dynamic>.from(sent[NOTIFICATION_CONTENT] as Map);
      expect(content[NOTIFICATION_TITLE], 'Hello');  // translated natively
      expect(sent[NOTIFICATION_BUTTONS], isA<List>());
      final block = Map<String, dynamic>.from(sent['localizations'] as Map);
      expect(block.keys, unorderedEquals(['pt-br', 'es']));
      expect(block['pt-br'], {
        NOTIFICATION_TITLE: 'Olá',
        NOTIFICATION_BUTTON_LABELS: {'YES': 'Sim'},
      });
      expect(block['es'], {NOTIFICATION_BODY: 'Mundo'});
    });

    test('carries loc keys and their arguments in the content', () async {
      await MethodChannelAwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 8,
          channelKey: 'basic',
          title: 'Fallback',
          titleLocKey: 'greeting',
          titleLocArgs: ['Ana'],
          bodyLocKey: 'news',
          bodyLocArgs: ['Ana', '3'],
        ),
      );
      final content = Map<String, dynamic>.from(sent[NOTIFICATION_CONTENT] as Map);
      expect(content['titleLocKey'], 'greeting');
      expect(content['titleLocArgs'], ['Ana']);
      expect(content['bodyLocKey'], 'news');
      expect(content['bodyLocArgs'], ['Ana', '3']);
      expect(sent.containsKey('localizations'), isFalse);
    });

    group('where translation is not available', () {
      setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia);
      tearDown(() => debugDefaultTargetPlatformOverride = null);

      test('answers "unavailable" without reaching native', () async {
        const channel = MethodChannel('awesome_notifications');
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        final calls = <MethodCall>[];
        messenger.setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
        addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
        final localizations = AwesomeNotificationsLocalizations();

        expect(AwesomeNotificationsLocalizations.isPlatformSupported, isFalse);
        expect(await localizations.setLocalization(languageCode: 'pt-br'), isFalse);
        expect(await localizations.getLocalization(), '');
        expect(calls, isEmpty);
      });
    });
  });
}
