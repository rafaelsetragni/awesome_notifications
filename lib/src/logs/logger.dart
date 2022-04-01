import 'package:flutter/foundation.dart';

class Logger {
  Logger._internal();

  static void d(String msg) {
    debugPrint('[Awesome Notifications - DEBUG]: $msg');
  }

  static void e(String msg) {
    print('\x1B[31m[Awesome Notifications - ERROR]: $msg\x1B[0m');
  }

  static void i(String msg) {
    print('\x1B[34m[Awesome Notifications - INFO]: $msg\x1B[0m');
  }

  static void w(String msg) {
    print('\x1B[33m[Awesome Notifications - WARNING]: $msg\x1B[0m');
  }
}
