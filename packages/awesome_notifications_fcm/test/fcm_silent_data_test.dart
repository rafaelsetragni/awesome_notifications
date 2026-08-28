import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FcmSilentData.fromMap', () {
    test('extracts the envelope and keeps custom data', () {
      final silent = FcmSilentData().fromMap({
        NOTIFICATION_ID: 42,
        NOTIFICATION_CREATED_DATE: '2025-01-02 03:04:05',
        NOTIFICATION_CREATED_SOURCE: 'Firebase',
        NOTIFICATION_CREATED_LIFECYCLE: 'Terminated',
        'orderId': '999',
        'action': 'refresh',
      })!;

      expect(silent.id, 42);
      expect(silent.createdSource, NotificationSource.Firebase);
      expect(silent.createdLifeCycle, NotificationLifeCycle.Terminated);
      expect(silent.createdDate, isNotNull);
      expect(silent.data, {'orderId': '999', 'action': 'refresh'});
    });

    test('parses a string id and tolerates missing envelope fields', () {
      final silent = FcmSilentData().fromMap({
        NOTIFICATION_ID: '7',
        'foo': 'bar',
      })!;

      expect(silent.id, 7);
      expect(silent.createdSource, isNull);
      expect(silent.createdLifeCycle, isNull);
      expect(silent.data, {'foo': 'bar'});
    });

    test('does not surface internal routing keys as data', () {
      final silent = FcmSilentData().fromMap({
        NOTIFICATION_ID: 1,
        'fcmSilentHandle': 12345,
        'payloadKey': 'value',
      })!;

      expect(silent.data!.containsKey('fcmSilentHandle'), isFalse);
      expect(silent.data, {'payloadKey': 'value'});
    });
  });

  group('FcmSilentData.toMap', () {
    test('round-trips the envelope + data', () {
      final silent = FcmSilentData().fromMap({
        NOTIFICATION_ID: 5,
        NOTIFICATION_CREATED_SOURCE: 'Firebase',
        NOTIFICATION_CREATED_LIFECYCLE: 'Background',
        'k': 'v',
      })!;

      final map = silent.toMap();
      expect(map[NOTIFICATION_ID], '5');
      expect(map[NOTIFICATION_CREATED_SOURCE], 'Firebase');
      expect(map[NOTIFICATION_CREATED_LIFECYCLE], 'Background');
      expect(map['k'], 'v');
    });
  });
}
