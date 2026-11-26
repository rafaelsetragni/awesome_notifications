import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IsolateCallbackException tests', () {
    test('Exception message is stored and returned correctly', () {
      const errorMessage = 'Test error message';
      final exception = IsolateCallbackException(errorMessage);
      expect(exception.msg, errorMessage);
      expect(exception.toString(), 'IsolateCallbackException: $errorMessage');
    });
  });
}
