import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_chat/awesome_notifications_chat.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const me = NotificationPerson(key: 'u-1', name: 'Rafael');
  const ana = NotificationPerson(
      key: 'u-2', name: 'Ana', avatar: 'https://x/ana.jpg', uri: 'tel:+5511999', isImportant: true);

  NotificationConversation conversation({
    String id = 'family',
    NotificationPerson sender = ana,
    String text = 'On my way',
    List<NotificationPerson> participants = const [ana],
  }) =>
      NotificationConversation(
        id: id,
        title: 'Family',
        me: me,
        participants: participants,
        message: NotificationMessage(
            sender: sender, text: text, timestamp: DateTime.utc(2026, 11, 25, 10, 30)),
      );

  group('NotificationPerson', () {
    test('round-trips through its map', () {
      expect(NotificationPerson.fromMap(ana.toMap()), ana);
      expect(NotificationPerson.fromMap({'key': 'k'}), isNull);
    });
  });

  group('NotificationConversation', () {
    test('serializes under the conversation key', () {
      final map = conversation().toMap()['conversation'] as Map<String, dynamic>;
      expect(map['id'], 'family');
      expect(map['title'], 'Family');
      expect((map['me'] as Map)['key'], 'u-1');
      expect((map['participants'] as List).single, ana.toMap());
      final message = map['message'] as Map<String, dynamic>;
      expect(message['text'], 'On my way');
      expect(message['timestamp'], '2026-11-25 10:30:00');
      expect((message['sender'] as Map)['name'], 'Ana');
      expect(map['history'], 'append');
      expect(map['shortcut'], true);
    });

    test('is validated before it reaches the platform', () {
      expect(() => conversation(id: ' ').toMap(), throwsA(isA<AwesomeNotificationsException>()));
      expect(() => conversation(text: '').toMap(), throwsA(isA<AwesomeNotificationsException>()));
      expect(() => conversation(sender: const NotificationPerson(key: '', name: 'X')).toMap(),
          throwsA(isA<AwesomeNotificationsException>()));
      expect(() => conversation(participants: [ana, ana]).toMap(),
          throwsA(isA<AwesomeNotificationsException>()));
      expect(() => conversation(participants: [me]).toMap(),
          throwsA(isA<AwesomeNotificationsException>()));
    });
  });

  group('AwesomeNotificationsChat', () {
    const channel = MethodChannel('awesome_notifications');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final calls = <MethodCall>[];
    final chat = AwesomeNotificationsChat();

    setUp(() {
      calls.clear();
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        switch (call.method) {
          case 'chatListActiveConversations':
            return ['family'];
          case 'chatCapabilities':
            return {'history': true, 'reply': true, 'avatar': true, 'systemConversation': true};
        }
        return null;
      });
    });
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('routes the conversation operations to the shared channel', () async {
      await chat.addReply('family', const NotificationMessage(sender: me, text: 'Ok'));
      await chat.markAsRead('family');
      await chat.removeConversation('family');
      expect(await chat.listActiveConversations(), ['family']);
      expect((await chat.capabilities()).systemConversation, isTrue);
      expect(calls.map((c) => c.method), [
        'chatAddReply',
        'chatMarkAsRead',
        'chatRemoveConversation',
        'chatListActiveConversations',
        'chatCapabilities'
      ]);
      expect((calls.first.arguments as Map)['id'], 'family');
    });

    test('answers "unavailable" where the core does not run', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      expect(AwesomeNotificationsChat.isPlatformSupported, isFalse);
      await chat.markAsRead('family');
      expect(await chat.listActiveConversations(), isEmpty);
      expect((await chat.capabilities()).history, isFalse);
      expect(calls, isEmpty);
    });
  });
}
