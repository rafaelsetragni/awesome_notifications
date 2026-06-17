import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AwesomeNotificationsException tests', () {
    test('Exception message is stored and returned correctly', () {
      const errorMessage = 'Test error message';
      const exception = AwesomeNotificationsException(message: errorMessage);
      expect(exception.message, errorMessage);
      expect(exception.toString(),
          'AwesomeNotificationsException{msg: $errorMessage}');
    });
  });
}
