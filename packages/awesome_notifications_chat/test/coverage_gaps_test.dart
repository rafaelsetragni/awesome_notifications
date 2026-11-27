import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_chat/awesome_notifications_chat.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('conversationIdOf reads the conversation from the payload', () {
    final received = ReceivedNotification().fromMap({
      NOTIFICATION_ID: 1,
      NOTIFICATION_CHANNEL_KEY: 'chat',
      NOTIFICATION_PAYLOAD: {'conversationId': 'room-1'},
    });
    expect(AwesomeNotificationsChat.conversationIdOf(received), 'room-1');
    expect(AwesomeNotificationsChat.conversationIdOf(ReceivedNotification()), isNull);
  });
}
