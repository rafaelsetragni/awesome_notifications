import 'dart:typed_data';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/awesome_notifications_empty.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AwesomeNotificationsEmpty', () {
    late AwesomeNotificationsEmpty notifications;

    setUp(() {
      notifications = AwesomeNotificationsEmpty();
    });

    test('cancel method', () async {
      await notifications.cancel(1);
    });

    test('cancelAll method', () async {
      await notifications.cancelAll();
    });

    test('cancelAllSchedules method', () async {
      await notifications.cancelAllSchedules();
    });

    test('cancelNotificationsByChannelKey method', () async {
      await notifications.cancelNotificationsByChannelKey('channelKey');
    });

    test('cancelNotificationsByGroupKey method', () async {
      await notifications.cancelNotificationsByGroupKey('groupKey');
    });

    test('cancelSchedule method', () async {
      await notifications.cancelSchedule(1);
    });

    test('cancelSchedulesByChannelKey method', () async {
      await notifications.cancelSchedulesByChannelKey('channelKey');
    });

    test('cancelSchedulesByGroupKey method', () async {
      await notifications.cancelSchedulesByGroupKey('groupKey');
    });

    test('checkPermissionList method', () async {
      List<NotificationPermission> result =
          await notifications.checkPermissionList();
      expect(result, [
        NotificationPermission.Badge,
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Vibration,
        NotificationPermission.Light
      ]);
    });

    test('createNotification method', () async {
      bool result = await notifications.createNotification(
        content: NotificationContent(id: 1, channelKey: 'test'),
      );
      expect(result, false);
    });

    test('createNotificationFromJsonData method', () async {
      bool result = await notifications.createNotificationFromJsonData({
        'id': 1,
        'channelKey': 'test',
      });
      expect(result, false);
    });

    test('decrementGlobalBadgeCounter method', () async {
      int result = await notifications.decrementGlobalBadgeCounter();
      expect(result, 0);
    });

    test('dismiss method', () async {
      await notifications.dismiss(1);
    });

    test('dismissAllNotifications method', () async {
      await notifications.dismissAllNotifications();
    });

    test('dismissNotificationsByChannelKey method', () async {
      await notifications.dismissNotificationsByChannelKey('channelKey');
    });

    test('dismissNotificationsByGroupKey method', () async {
      await notifications.dismissNotificationsByGroupKey('groupKey');
    });

    test('getAppLifeCycle method', () async {
      NotificationLifeCycle result = await notifications.getAppLifeCycle();
      expect(result, NotificationLifeCycle.Terminated);
    });

    test('getDrawableData method', () async {
      Uint8List? result = await notifications.getDrawableData('drawablePath');
      expect(result, null);
    });

    test('getInitialNotificationAction method', () async {
      ReceivedAction? result =
          await notifications.getInitialNotificationAction();
      expect(result, null);
    });

    test('getGlobalBadgeCounter method', () async {
      int result = await notifications.getGlobalBadgeCounter();
      expect(result, 0);
    });

    test('getLocalTimeZoneIdentifier method', () async {
      String result = await notifications.getLocalTimeZoneIdentifier();
      expect(result, AwesomeNotifications.localTimeZoneIdentifier);
    });

    test('getNextDate method', () async {
      DateTime? result = await notifications.getNextDate(
        NotificationInterval(interval: 10),
      );
      expect(result, null);
    });

    test('getUtcTimeZoneIdentifier method', () async {
      String result = await notifications.getUtcTimeZoneIdentifier();
      expect(result, AwesomeNotifications.utcTimeZoneIdentifier);
    });

    test('incrementGlobalBadgeCounter method', () async {
      int result = await notifications.incrementGlobalBadgeCounter();
      expect(result, 0);
    });

    test('initialize method', () async {
      bool result = await notifications.initialize(
        'defaultIcon',
        [],
      );
      expect(result, true);
    });

    test('isNotificationAllowed method', () async {
      bool result = await notifications.isNotificationAllowed();
      expect(result, false);
    });

    test('listScheduledNotifications method', () async {
      List<NotificationModel> result =
          await notifications.listScheduledNotifications();
      expect(result, []);
    });

    test('removeChannel method', () async {
      bool result = await notifications.removeChannel('channelKey');
      expect(result, false);
    });

    test('requestPermissionToSendNotifications method', () async {
      bool result = await notifications.requestPermissionToSendNotifications();
      expect(result, false);
    });

    test('resetGlobalBadge method', () async {
      await notifications.resetGlobalBadge();
    });

    test('setChannel method', () async {
      await notifications.setChannel(
        NotificationChannel(
          channelKey: 'test',
          channelName: 'Test Channel',
          channelDescription: 'Test Channel Description',
        ),
      );
    });

    test('setGlobalBadgeCounter method', () async {
      await notifications.setGlobalBadgeCounter(0);
    });

    test('setListeners method', () async {
      bool result = await notifications.setListeners(
        onActionReceivedMethod: (ReceivedAction action) async {},
      );
      expect(result, true);
    });

    test('shouldShowRationaleToRequest method', () async {
      List<NotificationPermission> result =
          await notifications.shouldShowRationaleToRequest();
      expect(result, []);
    });

    test('showAlarmPage method', () async {
      await notifications.showAlarmPage();
    });

    test('showGlobalDndOverridePage method', () async {
      await notifications.showGlobalDndOverridePage();
    });

    test('showNotificationConfigPage method', () async {
      await notifications.showNotificationConfigPage();
    });

    test('getLocalization method', () async {
      String result = await notifications.getLocalization();
      expect(result, '');
    });

    test('setLocalization method', () async {
      bool result = await notifications.setLocalization(
        languageCode: 'en',
      );
      expect(result, false);
    });

    test('isNotificationActiveOnStatusBar method', () async {
      bool result = await notifications.isNotificationActiveOnStatusBar(id: 1);
      expect(result, false);
    });

    test('getAllActiveNotificationIdsOnStatusBar method', () async {
      List<int> result =
          await notifications.getAllActiveNotificationIdsOnStatusBar();
      expect(result, []);
    });

    test('dispose method', () {
      notifications.dispose();
    });
  });
}
