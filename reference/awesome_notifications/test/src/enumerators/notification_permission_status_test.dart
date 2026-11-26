import 'package:awesome_notifications/src/enumerators/notification_permission_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationPermissionStatus tests', () {
    test('values contains exactly the four expected statuses', () {
      expect(
        NotificationPermissionStatus.values,
        containsAll([
          NotificationPermissionStatus.granted,
          NotificationPermissionStatus.denied,
          NotificationPermissionStatus.notDetermined,
          NotificationPermissionStatus.notSupported,
        ]),
      );
      expect(NotificationPermissionStatus.values.length, 4);
    });

    test('each value has the expected name', () {
      expect(NotificationPermissionStatus.granted.name, 'granted');
      expect(NotificationPermissionStatus.denied.name, 'denied');
      expect(NotificationPermissionStatus.notDetermined.name, 'notDetermined');
      expect(NotificationPermissionStatus.notSupported.name, 'notSupported');
    });
  });
}
