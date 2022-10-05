import 'package:flutter/foundation.dart';

// ignore_for_file: avoid_print
class Logger {
  Logger._internal();

  static RegExp stackTraceRegex = RegExp(r'#2\s+.*:(\d+):\d+\)');
  static String _getLastLine() {
    String stack = StackTrace.current.toString();
    return stackTraceRegex.firstMatch(stack)?.group(1) ?? '?';
  }

  static void d(String className, String msg) {
    debugPrint(
        '[Awesome Notifications - DEBUG]: $msg ($className:${_getLastLine()})');
  }

  static void e(String className, String msg) {
    print(
        '\x1B[31m[Awesome Notifications - ERROR]: $msg ($className:${_getLastLine()})\x1B[0m');
  }

  static void i(String className, String msg) {
    print('\x1B[34m[Awesome Notifications - INFO]: $msg ($className)\x1B[0m');
  }

  static void w(String className, String msg) {
    print(
        '\x1B[33m[Awesome Notifications - WARNING]: $msg ($className:${_getLastLine()})\x1B[0m');
  }
}
