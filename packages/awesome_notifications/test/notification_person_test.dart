import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ana = NotificationPerson(
      key: 'u-2',
      name: 'Ana',
      avatar: 'https://x/ana.jpg',
      uri: 'tel:+5511999',
      isImportant: true);

  test('round-trips through toMap/fromMap with the shared keys', () {
    final map = ana.toMap();
    expect(map, {
      'key': 'u-2',
      'name': 'Ana',
      'avatar': 'https://x/ana.jpg',
      'uri': 'tel:+5511999',
      'isBot': false,
      'isImportant': true,
    });
    expect(NotificationPerson.fromMap(map), ana);
    expect(NotificationPerson.fromMap(map).hashCode, ana.hashCode);
  });

  test('fromMap is null without a key or a name', () {
    expect(NotificationPerson.fromMap(null), isNull);
    expect(NotificationPerson.fromMap({'name': 'Ana'}), isNull);
    expect(NotificationPerson.fromMap({'key': 'k'}), isNull);
  });

  test('validate refuses an empty key or name', () {
    expect(() => const NotificationPerson(key: ' ', name: 'A').validate('caller'),
        throwsA(isA<AwesomeNotificationsException>()));
    expect(() => const NotificationPerson(key: 'k', name: '').validate('caller'),
        throwsA(isA<AwesomeNotificationsException>()));
    ana.validate('caller');
  });
}
