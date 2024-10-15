import 'dart:typed_data';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/awesome_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock the AwesomeNotifications class
class MockAwesomeNotificationsPlatform extends AwesomeNotificationsPlatform
    with Mock {}

void main() {
  group('AwesomeNotifications', () {
    late MockAwesomeNotificationsPlatform mockNotifications;

    setUp(() {
      mockNotifications = MockAwesomeNotificationsPlatform();
      AwesomeNotificationsPlatform.instance = mockNotifications;
    });

    tearDown(() {
      reset(mockNotifications);
    });

    test('cancel method is called once', () async {
      when(() => mockNotifications.cancel(any()))
          .thenAnswer((_) => Future.value());
      await AwesomeNotifications().cancel(1);
      verify(() => mockNotifications.cancel(1)).called(1);
    });

    test('cancelAll method is called once', () async {
      when(() => mockNotifications.cancelAll())
          .thenAnswer((_) => Future.value());
      await AwesomeNotifications().cancelAll();
      verify(() => mockNotifications.cancelAll()).called(1);
    });

    test('cancelAllSchedules method is called once', () async {
      when(() => mockNotifications.cancelAllSchedules())
          .thenAnswer((_) => Future.value());
      await AwesomeNotifications().cancelAllSchedules();
      verify(() => mockNotifications.cancelAllSchedules()).called(1);
    });

    test('cancelNotificationsByChannelKey method is called once', () async {
      when(() => mockNotifications.cancelNotificationsByChannelKey(any()))
          .thenAnswer((_) => Future.value());
      await AwesomeNotifications()
          .cancelNotificationsByChannelKey('channel_key');
      verify(() =>
              mockNotifications.cancelNotificationsByChannelKey('channel_key'))
          .called(1);
    });

    test('cancelNotificationsByGroupKey method is called once', () async {
      when(() => mockNotifications.cancelNotificationsByGroupKey(any()))
          .thenAnswer((_) => Future.value());
      await AwesomeNotifications().cancelNotificationsByGroupKey('group_key');
      verify(() => mockNotifications.cancelNotificationsByGroupKey('group_key'))
          .called(1);
    });

    test('cancelSchedule method is called once', () async {
      when(() => mockNotifications.cancelSchedule(any()))
          .thenAnswer((_) => Future.value());
      await AwesomeNotifications().cancelSchedule(1);
      verify(() => mockNotifications.cancelSchedule(1)).called(1);
    });

    test('cancelSchedulesByChannelKey method is called once', () async {
      when(() => mockNotifications.cancelSchedulesByChannelKey(any()))
          .thenAnswer((_) => Future.value());
      await AwesomeNotifications().cancelSchedulesByChannelKey('channel_key');
      verify(() => mockNotifications.cancelSchedulesByChannelKey('channel_key'))
          .called(1);
    });

    test('cancelSchedulesByGroupKey method is called once', () async {
      when(() => mockNotifications.cancelSchedulesByGroupKey(any()))
          .thenAnswer((_) => Future.value());
      await AwesomeNotifications().cancelSchedulesByGroupKey('group_key');
      verify(() => mockNotifications.cancelSchedulesByGroupKey('group_key'))
          .called(1);
    });

    test('checkPermissionList method is called once', () async {
      when(() => mockNotifications.checkPermissionList())
          .thenAnswer((_) async => <NotificationPermission>[]);
      await AwesomeNotifications().checkPermissionList();
      verify(() => mockNotifications.checkPermissionList()).called(1);
    });

    test('createNotification method is called once', () async {
      NotificationContent content = NotificationContent(
          id: 1, channelKey: 'channel_key', title: 'title', body: 'body');
      when(() => mockNotifications.createNotification(content: content))
          .thenAnswer((_) async => true);

      await AwesomeNotifications().createNotification(content: content);
      verify(() => mockNotifications.createNotification(content: content))
          .called(1);
    });

    test('createNotificationFromJsonData method is called once', () async {
      Map<String, dynamic> jsonData = {
        'id': 1,
        'channelKey': 'channel_key',
        'title': 'title',
        'body': 'body'
      };
      when(() => mockNotifications.createNotificationFromJsonData(jsonData))
          .thenAnswer((_) async => true);

      await AwesomeNotifications().createNotificationFromJsonData(jsonData);
      verify(() => mockNotifications.createNotificationFromJsonData(jsonData))
          .called(1);
    });

    test('decrementGlobalBadgeCounter method is called once', () async {
      when(() => mockNotifications.decrementGlobalBadgeCounter())
          .thenAnswer((_) async => 1);
      await AwesomeNotifications().decrementGlobalBadgeCounter();
      verify(() => mockNotifications.decrementGlobalBadgeCounter()).called(1);
    });

    test('dismiss method is called once', () async {
      when(() => mockNotifications.dismiss(any()))
          .thenAnswer((_) => Future.value());
      await AwesomeNotifications().dismiss(1);
      verify(() => mockNotifications.dismiss(1)).called(1);
    });

    test('dismissAllNotifications method is called once', () async {
      when(() => mockNotifications.dismissAllNotifications())
          .thenAnswer((_) => Future.value());
      await AwesomeNotifications().dismissAllNotifications();
      verify(() => mockNotifications.dismissAllNotifications()).called(1);
    });

    test('dismissNotificationsByChannelKey method is called once', () async {
      when(() => mockNotifications.dismissNotificationsByChannelKey(any()))
          .thenAnswer((_) => Future.value());
      await AwesomeNotifications()
          .dismissNotificationsByChannelKey('channel_key');
      verify(() =>
              mockNotifications.dismissNotificationsByChannelKey('channel_key'))
          .called(1);
    });

    test('dismissNotificationsByGroupKey method is called once', () async {
      when(() => mockNotifications.dismissNotificationsByGroupKey(any()))
          .thenAnswer((_) => Future.value());
      await AwesomeNotifications().dismissNotificationsByGroupKey('group_key');
      verify(() =>
              mockNotifications.dismissNotificationsByGroupKey('group_key'))
          .called(1);
    });

    test('dispose method is called once', () async {
      when(() => mockNotifications.dispose()).thenReturn(true);
      await AwesomeNotifications().dispose();
      verify(() => mockNotifications.dispose()).called(1);
    });

    test('getAppLifeCycle method is called once', () async {
      when(() => mockNotifications.getAppLifeCycle())
          .thenAnswer((_) async => NotificationLifeCycle.Foreground);
      await AwesomeNotifications().getAppLifeCycle();
      verify(() => mockNotifications.getAppLifeCycle()).called(1);
    });

    test('getDrawableData method is called once', () async {
      when(() => mockNotifications.getDrawableData('drawable_path'))
          .thenAnswer((_) async => null);
      await AwesomeNotifications().getDrawableData('drawable_path');
      verify(() => mockNotifications.getDrawableData('drawable_path'))
          .called(1);
    });

    test('getInitialNotificationAction method is called once', () async {
      when(() => mockNotifications.getInitialNotificationAction())
          .thenAnswer((_) async => null);
      await AwesomeNotifications().getInitialNotificationAction();
      verify(() => mockNotifications.getInitialNotificationAction()).called(1);
    });

    test('getGlobalBadgeCounter method is called once', () async {
      when(() => mockNotifications.getGlobalBadgeCounter())
          .thenAnswer((_) async => 0);
      await AwesomeNotifications().getGlobalBadgeCounter();
      verify(() => mockNotifications.getGlobalBadgeCounter()).called(1);
    });

    test('getLocalTimeZoneIdentifier method is called once', () async {
      when(() => mockNotifications.getLocalTimeZoneIdentifier())
          .thenAnswer((_) async => 'UTC');
      await AwesomeNotifications().getLocalTimeZoneIdentifier();
      verify(() => mockNotifications.getLocalTimeZoneIdentifier()).called(1);
    });

    test('getNextDate method is called once', () async {
      NotificationSchedule schedule =
          NotificationInterval(interval: Duration(minutes: 1));
      when(() => mockNotifications.getNextDate(schedule))
          .thenAnswer((_) async => DateTime.now());
      await AwesomeNotifications().getNextDate(schedule);
      verify(() => mockNotifications.getNextDate(schedule)).called(1);
    });

    test('getUtcTimeZoneIdentifier method is called once', () async {
      when(() => mockNotifications.getUtcTimeZoneIdentifier())
          .thenAnswer((_) async => 'UTC');
      await AwesomeNotifications().getUtcTimeZoneIdentifier();
      verify(() => mockNotifications.getUtcTimeZoneIdentifier()).called(1);
    });

    test('incrementGlobalBadgeCounter method is called once', () async {
      when(() => mockNotifications.incrementGlobalBadgeCounter())
          .thenAnswer((_) async => 1);
      await AwesomeNotifications().incrementGlobalBadgeCounter();
      verify(() => mockNotifications.incrementGlobalBadgeCounter()).called(1);
    });

    test('initialize method is called once', () async {
      List<NotificationChannel> channels = [
        NotificationChannel(
          channelKey: 'channel_key',
          channelName: 'channel_name',
          channelDescription: 'channel_description',
        ),
      ];
      when(() => mockNotifications.initialize(null, channels))
          .thenAnswer((_) async => true);
      await AwesomeNotifications().initialize(null, channels);
      verify(() => mockNotifications.initialize(null, channels)).called(1);
    });

    test('isNotificationAllowed method is called once', () async {
      when(() => mockNotifications.isNotificationAllowed())
          .thenAnswer((_) async => true);
      await AwesomeNotifications().isNotificationAllowed();
      verify(() => mockNotifications.isNotificationAllowed()).called(1);
    });

    test('listScheduledNotifications method is called once', () async {
      when(() => mockNotifications.listScheduledNotifications())
          .thenAnswer((_) async => <NotificationModel>[]);
      await AwesomeNotifications().listScheduledNotifications();
      verify(() => mockNotifications.listScheduledNotifications()).called(1);
    });

    test('removeChannel method is called once', () async {
      when(() => mockNotifications.removeChannel(any()))
          .thenAnswer((_) async => true);
      await AwesomeNotifications().removeChannel('channel_key');
      verify(() => mockNotifications.removeChannel('channel_key')).called(1);
    });

    test('requestPermissionToSendNotifications method is called once',
        () async {
      when(() => mockNotifications.requestPermissionToSendNotifications())
          .thenAnswer((_) async => true);
      await AwesomeNotifications().requestPermissionToSendNotifications();
      verify(() => mockNotifications.requestPermissionToSendNotifications())
          .called(1);
    });

    test('resetGlobalBadge method is called once', () async {
      when(() => mockNotifications.resetGlobalBadge())
          .thenAnswer((_) async => true);
      await AwesomeNotifications().resetGlobalBadge();
      verify(() => mockNotifications.resetGlobalBadge()).called(1);
    });

    test('setChannel method is called once', () async {
      NotificationChannel notificationChannel = NotificationChannel(
        channelKey: 'channel_key',
        channelName: 'channel_name',
        channelDescription: 'channel_description',
      );
      when(() => mockNotifications.setChannel(notificationChannel))
          .thenAnswer((_) async => true);
      await AwesomeNotifications().setChannel(notificationChannel);
      verify(() => mockNotifications.setChannel(notificationChannel)).called(1);
    });

    test('setGlobalBadgeCounter method is called once', () async {
      when(() => mockNotifications.setGlobalBadgeCounter(any()))
          .thenAnswer((_) async => true);
      await AwesomeNotifications().setGlobalBadgeCounter(1);
      verify(() => mockNotifications.setGlobalBadgeCounter(1)).called(1);
    });

    test('setListeners method is called once', () async {
      actionMethod(_) async {}

      when(() => mockNotifications.setListeners(
          onActionReceivedMethod: actionMethod)).thenAnswer((_) async => true);

      await AwesomeNotifications()
          .setListeners(onActionReceivedMethod: actionMethod);

      verify(() => mockNotifications.setListeners(
          onActionReceivedMethod: actionMethod)).called(1);
    });

    test('shouldShowRationaleToRequest method is called once', () async {
      when(() => mockNotifications.shouldShowRationaleToRequest())
          .thenAnswer((_) async => <NotificationPermission>[]);
      await AwesomeNotifications().shouldShowRationaleToRequest();
      verify(() => mockNotifications.shouldShowRationaleToRequest()).called(1);
    });

    test('showAlarmPage method is called once', () async {
      when(() => mockNotifications.showAlarmPage())
          .thenAnswer((_) => Future.value());
      await AwesomeNotifications().showAlarmPage();
      verify(() => mockNotifications.showAlarmPage()).called(1);
    });

    test('showGlobalDndOverridePage method is called once', () async {
      when(() => mockNotifications.showGlobalDndOverridePage())
          .thenAnswer((_) => Future.value());
      await AwesomeNotifications().showGlobalDndOverridePage();
      verify(() => mockNotifications.showGlobalDndOverridePage()).called(1);
    });

    test('showNotificationConfigPage method is called once', () async {
      when(() => mockNotifications.showNotificationConfigPage())
          .thenAnswer((_) => Future.value());
      await AwesomeNotifications().showNotificationConfigPage();
      verify(() => mockNotifications.showNotificationConfigPage()).called(1);
    });

    test('getLocalization method is called once', () async {
      when(() => mockNotifications.getLocalization())
          .thenAnswer((_) async => 'en_US');
      await AwesomeNotifications().getLocalization();
      verify(() => mockNotifications.getLocalization()).called(1);
    });

    test('setLocalization method is called once', () async {
      when(() => mockNotifications.setLocalization(languageCode: 'en_US'))
          .thenAnswer((_) async => true);
      await AwesomeNotifications().setLocalization(languageCode: 'en_US');
      verify(() => mockNotifications.setLocalization(languageCode: 'en_US'))
          .called(1);
    });

    test('isNotificationActiveOnStatusBar method is called once', () async {
      when(() => mockNotifications.isNotificationActiveOnStatusBar(id: 1))
          .thenAnswer((_) async => true);
      await AwesomeNotifications().isNotificationActiveOnStatusBar(id: 1);
      verify(() => mockNotifications.isNotificationActiveOnStatusBar(id: 1))
          .called(1);
    });

    test('getAllActiveNotificationIdsOnStatusBar method is called once',
        () async {
      when(() => mockNotifications.getAllActiveNotificationIdsOnStatusBar())
          .thenAnswer((_) async => <int>[]);
      await AwesomeNotifications().getAllActiveNotificationIdsOnStatusBar();
      verify(() => mockNotifications.getAllActiveNotificationIdsOnStatusBar())
          .called(1);
    });
  });

  group('default values', () {
    test('limits', () async {
      expect(AwesomeNotifications.maxID, 2147483647);
    });

    test('vibration standards', () async {
      expect(lowVibrationPattern, Int64List.fromList([0, 200, 200, 200]));
      expect(mediumVibrationPattern,
          Int64List.fromList([0, 500, 200, 200, 200, 200]));
      expect(highVibrationPattern,
          Int64List.fromList([0, 1000, 200, 200, 200, 200, 200, 200]));
    });
  });
}
