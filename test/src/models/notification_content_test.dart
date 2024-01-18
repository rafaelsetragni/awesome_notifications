import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/src/enumerators/notification_play_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationContent Tests', () {
    group('Constructor Tests', () {
      test('Default values are properly set', () {
        final notificationContent = NotificationContent(
          id: 1,
          channelKey: 'test_channel',
        );

        expect(notificationContent.id, 1);
        expect(notificationContent.channelKey, 'test_channel');
        // Check default values for optional parameters
        expect(notificationContent.showWhen, true);
        expect(notificationContent.wakeUpScreen, false);
        expect(notificationContent.fullScreenIntent, false);
        expect(notificationContent.criticalAlert, false);
        expect(notificationContent.roundedLargeIcon, false);
        expect(notificationContent.roundedBigPicture, false);
        expect(notificationContent.autoDismissible, true);
        expect(notificationContent.actionType, ActionType.Default);
        expect(
            notificationContent.notificationLayout, NotificationLayout.Default);
        expect(notificationContent.displayOnForeground, true);
        expect(notificationContent.displayOnBackground, true);
      });
    });

    group('fromMap Tests', () {
      test('Valid data is properly deserialized', () {
        final Map<String, dynamic> mapData = {
          'id': 1,
          'channelKey': 'test_channel',
          'hideLargeIconOnExpand': true,
          'progress': "50",
          'badge': 2,
          'ticker': 'ticker_text',
          'locked': true,
          'notificationLayout': 'BigText',
          'displayOnForeground': false,
          'displayOnBackground': false,
        };

        final notificationContent = NotificationContent(
          id: 1,
          channelKey: 'test_channel',
        ).fromMap(mapData);

        expect(notificationContent, isNotNull);
        expect(notificationContent!.id, 1);
        expect(notificationContent.channelKey, 'test_channel');
        expect(notificationContent.hideLargeIconOnExpand, true);
        expect(notificationContent.progress, 50.0);
        expect(notificationContent.badge, 2);
        expect(notificationContent.ticker, 'ticker_text');
        expect(notificationContent.locked, true);
        expect(
            notificationContent.notificationLayout, NotificationLayout.BigText);
        expect(notificationContent.displayOnForeground, false);
        expect(notificationContent.displayOnBackground, false);
      });

      test('Invalid data returns null', () {
        final Map<String, dynamic> invalidMapData = {
          // Missing required fields
        };

        final notificationContent = NotificationContent(
          id: 1,
          channelKey: 'test_channel',
        ).fromMap(invalidMapData);

        expect(notificationContent, isNull);
      });
    });

    group('fromMap media player Tests', () {
      test('Valid data with integer play state', () {
        final Map<String, dynamic> mapData = {
          'id': 1,
          'channelKey': 'test_channel',
          'duration': 50,
          'playState': 5,
          'playbackSpeed': 2,
        };

        final notificationContent = NotificationContent(
          id: 1,
          channelKey: 'test_channel',
        ).fromMap(mapData);

        expect(notificationContent?.duration, const Duration(seconds: 50));
        expect(notificationContent?.playState, NotificationPlayState.rewinding);
        expect(notificationContent?.playbackSpeed, 2);
      });

      test('Valid data with string play state', () {
        final Map<String, dynamic> mapData = {
          'id': 1,
          'channelKey': 'test_channel',
          'duration': 50,
          'playState': 'rewinding',
          'playbackSpeed': 2,
        };

        final notificationContent = NotificationContent(
          id: 1,
          channelKey: 'test_channel',
        ).fromMap(mapData);

        expect(notificationContent?.duration, const Duration(seconds: 50));
        expect(notificationContent?.playState, NotificationPlayState.rewinding);
        expect(notificationContent?.playbackSpeed, 2);
      });
    });

    group('toMap Tests', () {
      test('Object is properly serialized', () {
        final notificationContent = NotificationContent(
          id: 1,
          channelKey: 'test_channel',
          hideLargeIconOnExpand: true,
          progress: 50,
          badge: 2,
          ticker: 'ticker_text',
          locked: true,
          notificationLayout: NotificationLayout.BigText,
          displayOnForeground: false,
          displayOnBackground: false,
        );

        final mapData = notificationContent.toMap();

        expect(mapData, isNotNull);
        expect(mapData['id'], 1);
        expect(mapData['channelKey'], 'test_channel');
        expect(mapData['hideLargeIconOnExpand'], true);
        expect(mapData['progress'], 50);
        expect(mapData['badge'], 2);
        expect(mapData['ticker'], 'ticker_text');
        expect(mapData['locked'], true);
        expect(mapData['notificationLayout'], 'BigText');
        expect(mapData['displayOnForeground'], false);
        expect(mapData['displayOnBackground'], false);
      });
    });
    group('toString Tests', () {
      test('Object is properly converted to String', () {
        final notificationContent = NotificationContent(
          id: 1,
          channelKey: 'test_channel',
          hideLargeIconOnExpand: true,
          progress: 50,
          badge: 2,
          ticker: 'ticker_text',
          locked: true,
          notificationLayout: NotificationLayout.BigText,
          displayOnForeground: false,
          displayOnBackground: false,
        );

        final stringRepresentation = notificationContent.toString();

        expect(stringRepresentation, isNotNull);
        expect(stringRepresentation.contains('id: 1'), true);
        expect(stringRepresentation.contains('channelKey: test_channel'), true);
        expect(
            stringRepresentation.contains('hideLargeIconOnExpand: true'), true);
        expect(stringRepresentation.contains('progress: 50'), true);
        expect(stringRepresentation.contains('badge: 2'), true);
        expect(stringRepresentation.contains('ticker: ticker_text'), true);
        expect(stringRepresentation.contains('locked: true'), true);
        expect(
            stringRepresentation.contains('notificationLayout: BigText'), true);
        expect(
            stringRepresentation.contains('displayOnForeground: false'), true);
        expect(
            stringRepresentation.contains('displayOnBackground: false'), true);
      });
    });
  });
}
