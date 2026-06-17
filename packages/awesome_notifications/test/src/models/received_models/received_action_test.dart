import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReceivedAction', () {
    test('fromMap and toMap', () {
      Map<String, dynamic> dataMap = {
        // Add data for the ReceivedNotification superclass
        // ...
        'actionLifeCycle': NotificationLifeCycle.Foreground.name,
        'dismissedLifeCycle': NotificationLifeCycle.Terminated.name,
        'actionDate': '2023-05-01 12:34:56',
        'dismissedDate': '2023-05-01 12:35:56',
        'buttonKeyPressed': 'testButton',
        'buttonKeyInput': 'testInput'
      };

      ReceivedAction receivedAction = ReceivedAction().fromMap(dataMap);
      expect(receivedAction.actionLifeCycle, NotificationLifeCycle.Foreground);
      expect(
          receivedAction.dismissedLifeCycle, NotificationLifeCycle.Terminated);
      expect(receivedAction.actionDate, DateTime(2023, 5, 1, 12, 34, 56));
      expect(receivedAction.dismissedDate, DateTime(2023, 5, 1, 12, 35, 56));
      expect(receivedAction.buttonKeyPressed, 'testButton');
      expect(receivedAction.buttonKeyInput, 'testInput');

      Map<String, dynamic> newDataMap = receivedAction.toMap();
      expect(
          newDataMap['actionLifeCycle'], NotificationLifeCycle.Foreground.name);
      expect(newDataMap['dismissedLifeCycle'],
          NotificationLifeCycle.Terminated.name);
      expect(newDataMap['actionDate'], '2023-05-01 12:34:56');
      expect(newDataMap['dismissedDate'], '2023-05-01 12:35:56');
      expect(newDataMap['buttonKeyPressed'], 'testButton');
      expect(newDataMap['buttonKeyInput'], 'testInput');
    });
  });
}
