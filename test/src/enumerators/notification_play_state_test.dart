import 'package:awesome_notifications/src/enumerators/notification_play_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationPlayState Tests', () {
    test('toMap method should return correct integer values', () {
      expect(NotificationPlayState.unknown.toMap(), -1);
      expect(NotificationPlayState.none.toMap(), 0);
      expect(NotificationPlayState.stopped.toMap(), 1);
      expect(NotificationPlayState.skippingToQueueItem.toMap(), 11);
      // ... continue for all enum values
    });

    test('fromMap method should reconstruct enum from integer values', () {
      expect(NotificationPlayState.fromMap(-1), NotificationPlayState.unknown);
      expect(NotificationPlayState.fromMap(0), NotificationPlayState.none);
      expect(NotificationPlayState.fromMap(1), NotificationPlayState.stopped);
      expect(NotificationPlayState.fromMap(11), NotificationPlayState.skippingToQueueItem);
      // ... continue for all enum values
    });

    test('fromMap method should reconstruct enum from string values', () {
      expect(NotificationPlayState.fromMap('unknown'), NotificationPlayState.unknown);
      expect(NotificationPlayState.fromMap('none'), NotificationPlayState.none);
      expect(NotificationPlayState.fromMap('stopped'), NotificationPlayState.stopped);
      expect(NotificationPlayState.fromMap('skippingToQueueItem'), NotificationPlayState.skippingToQueueItem);
      // ... continue for all enum values
    });

    test('fromMap method should return null for invalid values', () {
      expect(NotificationPlayState.fromMap(null), isNull);
      expect(NotificationPlayState.fromMap(''), isNull);
      expect(NotificationPlayState.fromMap('invalid_value'), isNull);
      expect(NotificationPlayState.fromMap(12), isNull); // Assuming 100 is not a valid index
      expect(NotificationPlayState.fromMap(-2), isNull); // Assuming 100 is not a valid index
    });
  });
}