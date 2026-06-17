import 'package:awesome_notifications/src/enumerators/notification_life_cycle.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore_for_file: deprecated_member_use_from_same_package

void main() {
  group('NotificationLifeCycle tests', () {
    test('AppKilled returns same value as Terminated', () {
      expect(NotificationLifeCycle.AppKilled, NotificationLifeCycle.Terminated);
    });
  });
}
