import 'dart:async';

import 'package:awesome_notifications/src/logs/logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Logger prints expected log messages', () {
    // Capture logs during the test
    List<String> logMessages = [];
    String className = 'TestClass';

    runZoned(() {
      // Call the Logger methods
      Logger.d(className, 'Debug message');
      Logger.e(className, 'Error message');
      Logger.i(className, 'Info message');
      Logger.w(className, 'Warning message');
    }, zoneSpecification: ZoneSpecification(
        print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
      logMessages.add(line);
    }));

    // Verify that the log messages were printed
    expect(logMessages[0],
        startsWith('[Awesome Notifications - DEBUG]: Debug message'));
    expect(logMessages[1],
        startsWith('\x1B[31m[Awesome Notifications - ERROR]: Error message'));
    expect(logMessages[2],
        startsWith('\x1B[34m[Awesome Notifications - INFO]: Info message'));
    expect(
        logMessages[3],
        startsWith(
            '\x1B[33m[Awesome Notifications - WARNING]: Warning message'));
  });
}
