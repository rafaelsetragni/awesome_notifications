import 'package:awesome_notifications/awesome_notifications.dart';
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
}
