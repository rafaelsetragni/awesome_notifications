import 'package:awesome_notifications/src/enumerators/notification_life_cycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationLifeCycle tests', () {
    test('AppKilled returns same value as Terminated', () {
      expect(NotificationLifeCycle.AppKilled, NotificationLifeCycle.Terminated);
    });
  });
}
