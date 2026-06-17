import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReceivedNotification', () {
    test('fromMap and toMap', () {
      Map<String, dynamic> dataMap = {
        // Add data for the BaseNotificationContent superclass
        // ...
        'createdSource': NotificationSource.Firebase.name,
        'createdLifeCycle': NotificationLifeCycle.Foreground.name,
        'displayedLifeCycle': NotificationLifeCycle.Background.name,
        'createdDate': '2023-05-01 12:34:56',
        'displayedDate': '2023-05-01 12:35:56',
      };

      ReceivedNotification receivedNotification =
          ReceivedNotification().fromMap(dataMap);
      expect(receivedNotification.createdSource, NotificationSource.Firebase);
      expect(receivedNotification.createdLifeCycle,
          NotificationLifeCycle.Foreground);
      expect(receivedNotification.displayedLifeCycle,
          NotificationLifeCycle.Background);
      expect(
          receivedNotification.createdDate, DateTime(2023, 5, 1, 12, 34, 56));
      expect(
          receivedNotification.displayedDate, DateTime(2023, 5, 1, 12, 35, 56));

      Map<String, dynamic> newDataMap = receivedNotification.toMap();
      expect(newDataMap['createdSource'], NotificationSource.Firebase.name);
      expect(newDataMap['createdLifeCycle'],
          NotificationLifeCycle.Foreground.name);
      expect(newDataMap['displayedLifeCycle'],
          NotificationLifeCycle.Background.name);
      expect(newDataMap['createdDate'], '2023-05-01 12:34:56');
      expect(newDataMap['displayedDate'], '2023-05-01 12:35:56');
    });
  });
}
