import 'dart:core';

class IsolateCallbackException implements Exception {
  String msg;
  IsolateCallbackException(this.msg);
}
