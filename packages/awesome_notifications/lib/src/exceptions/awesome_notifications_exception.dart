class AwesomeNotificationsException implements Exception {
  final String message;
  const AwesomeNotificationsException({required this.message});

  @override
  String toString() {
    return 'AwesomeNotificationsException{msg: $message}';
  }
}
