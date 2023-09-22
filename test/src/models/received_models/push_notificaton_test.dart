import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PushNotification', () {
    test(
        'constructor creates a PushNotification with given content, schedule, and actionButtons',
        () {
      NotificationContent content = NotificationContent(
        id: 1,
        channelKey: 'test_channel',
        title: 'Test Title',
        body: 'Test Body',
      );

      NotificationSchedule schedule = NotificationInterval(interval: 60);

      List<NotificationActionButton> actionButtons = [
        NotificationActionButton(
          label: 'Accept',
          key: 'accept',
        ),
        NotificationActionButton(
          label: 'Decline',
          key: 'decline',
        ),
      ];

      // ignore: deprecated_member_use_from_same_package
      PushNotification pushNotification = PushNotification(
        content: content,
        schedule: schedule,
        actionButtons: actionButtons,
      );

      expect(pushNotification.content, content);
      expect(pushNotification.schedule, schedule);
      expect(pushNotification.actionButtons, actionButtons);
    });
  });
}
