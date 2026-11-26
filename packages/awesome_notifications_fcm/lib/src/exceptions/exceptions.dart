import 'dart:core';

/// Thrown when the background isolate cannot resolve the registered silent
/// data callback (e.g. the tear-off was not a valid global/static function).
class DartCallbackException implements Exception {
  final String msg;
  DartCallbackException(this.msg);

  @override
  String toString() => 'DartCallbackException: $msg';
}

/// Generic failure raised while handling a Firebase message.
class AwesomeNotificationsFcmException implements Exception {
  final String msg;
  AwesomeNotificationsFcmException(this.msg);

  @override
  String toString() => 'AwesomeNotificationsFcmException: $msg';
}
