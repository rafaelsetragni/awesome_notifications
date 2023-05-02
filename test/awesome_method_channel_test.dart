import 'dart:async';
import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications_method_channel.dart';
import 'package:awesome_notifications/src/isolates/isolate_main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import 'package:flutter/services.dart';
import 'package:mocktail/mocktail.dart';

import 'src/isolates/isolate_main_test.dart';

class MockMethodChannel extends MethodChannel {
  MockMethodChannel(String name) : super(name);

  Map<String, dynamic> _responses = {};

  // Use this method to set up the response for the method call
  void setMockMethodCallHandler(String methodName, dynamic response) {
    _responses[methodName] = response;
  }

  @override
  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) async {
    var response;
    if (_responses[method] is Function) {
      dynamic handler = _responses[method];
      if (handler is T Function(T)) {
        response = handler(arguments);
      } else if (handler is Future<T> Function(T)) {
        response = await handler(arguments);
      } else if (handler is T Function(Map<String, dynamic>)) {
        response = handler(arguments);
      } else if (handler is Future<T> Function(Map<String, dynamic>)) {
        response = await handler(arguments);
      } else if (handler is Future<T> Function()) {
        response = await handler();
      } else if (handler is FutureOr<T> Function()) {
        response = await handler();
      } else if (handler is FutureOr<T> Function(dynamic)) {
        response = await handler(arguments);
      } else {
        throw Exception("Unsupported function signature for method $method");
      }
    } else {
      response = _responses[method];
    }
    return Future.value(response);
  }
}

void main() {
  group('MethodChannelAwesomeNotifications', () {
    late MockMethodChannel mockMethodChannel;
    late MethodChannelAwesomeNotifications awesomeNotifications;

    setUpAll(() {
      mockMethodChannel = MockMethodChannel('awesome_notifications');
      awesomeNotifications = MethodChannelAwesomeNotifications()
        ..methodChannel = mockMethodChannel;
    });

    test('validateId', () async {
      expect(() => awesomeNotifications.validateId(0), returnsNormally);
      expect(() => awesomeNotifications.validateId(1), returnsNormally);
      expect(() => awesomeNotifications.validateId(-1), returnsNormally);
      expect(
          () => awesomeNotifications.validateId(0x7FFFFFFF), returnsNormally);
      expect(
          () => awesomeNotifications.validateId(-0x80000000), returnsNormally);

      expect(() => awesomeNotifications.validateId(-0x80000000 - 1),
          throwsA(isA<ArgumentError>()));

      expect(() => awesomeNotifications.validateId(0x7FFFFFFF + 1),
          throwsA(isA<ArgumentError>()));
    });

    test('cancel', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_CANCEL_NOTIFICATION, null);
      await awesomeNotifications.cancel(1);
    });

    test('cancelAll', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_CANCEL_ALL_NOTIFICATIONS, null);
      await awesomeNotifications.cancelAll();
    });

    test('cancelAllSchedules', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_CANCEL_ALL_SCHEDULES, null);
      await awesomeNotifications.cancelAllSchedules();
    });

    // Another example:
    test('createNotification', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_CREATE_NOTIFICATION, true);

      final bool result = await awesomeNotifications.createNotification(
        content: NotificationContent(
            id: 1,
            channelKey: 'test_channel',
            title: 'Test title',
            body: 'Test body'),
      );

      expect(result, true);
    });

    test('cancelNotificationsByChannelKey', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_CANCEL_NOTIFICATIONS_BY_CHANNEL_KEY, null);
      await awesomeNotifications
          .cancelNotificationsByChannelKey('test_channel');
    });

    test('cancelNotificationsByGroupKey', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_CANCEL_NOTIFICATIONS_BY_GROUP_KEY, null);
      await awesomeNotifications.cancelNotificationsByGroupKey('test_group');
    });

    test('cancelSchedule', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_CANCEL_SCHEDULE, null);
      await awesomeNotifications.cancelSchedule(1);
    });

    test('cancelSchedulesByChannelKey', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_CANCEL_SCHEDULES_BY_CHANNEL_KEY, null);
      await awesomeNotifications.cancelSchedulesByChannelKey('test_channel');
    });

    test('cancelSchedulesByGroupKey', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_CANCEL_SCHEDULES_BY_GROUP_KEY, null);
      await awesomeNotifications.cancelSchedulesByGroupKey('test_group');
    });

    test('checkPermissionList', () async {
      List<NotificationPermission> permissions = [
        NotificationPermission.Badge,
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Vibration,
        NotificationPermission.Light
      ];
      List<Object?> permissionList = permissions.map((e) => e.name).toList();

      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_CHECK_PERMISSIONS, permissionList);

      List<NotificationPermission> result =
          await awesomeNotifications.checkPermissionList(
        channelKey: 'test_channel',
        permissions: permissions,
      );

      expect(result, permissions);
    });

    test('createNotificationFromJsonData with valid data', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_CREATE_NOTIFICATION, true);

      Map<String, dynamic> validMapData = {
        NOTIFICATION_CONTENT: json.encode({
          'id': 1,
          'channelKey': 'test_channel',
          'title': 'Test title',
          'body': 'Test body',
        }),
      };

      bool result = await awesomeNotifications
          .createNotificationFromJsonData(validMapData);

      expect(result, true);
    });

    test('createNotificationFromJsonData with invalid data', () async {
      Map<String, dynamic> invalidMapData = {
        NOTIFICATION_CONTENT: json.encode({
          'id': 1,
          // Missing 'channelKey' field
          'title': 'Test title',
          'body': 'Test body',
        }),
      };

      bool result = await awesomeNotifications
          .createNotificationFromJsonData(invalidMapData);

      expect(result, false);
    });

    test('createNotificationFromJsonData with different data types', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_CREATE_NOTIFICATION, true);

      Map<String, dynamic> mapDataWithDifferentTypes = {
        NOTIFICATION_CONTENT: json.encode({
          'id': 1,
          'channelKey': 'test_channel',
          'title': 'Test title',
          'body': 'Test body',
        }),
        NOTIFICATION_SCHEDULE: json.encode({
          'interval': 10,
          'repeat': true,
          'timeZone': 'UTC',
          'scheduledDate': '2023-01-01T00:00:00.000Z',
        }),
        NOTIFICATION_BUTTONS: json.encode([
          {
            'key': 'action_key',
            'label': 'Action label',
          },
        ]),
        NOTIFICATION_LOCALIZATIONS: json.encode({
          'en_US': {
            'title': 'Localized title',
            'body': 'Localized body',
          },
        }),
      };

      bool result = await awesomeNotifications
          .createNotificationFromJsonData(mapDataWithDifferentTypes);

      expect(result, true);
    });

    // Add these test cases inside the group('MethodChannelAwesomeNotifications', () { ... }) block

    test('decrementGlobalBadgeCounter', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_DECREMENT_BADGE_COUNT, 5);

      int badgeCount = await awesomeNotifications.decrementGlobalBadgeCounter();

      expect(badgeCount, 5);
    });

    test('dismiss', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_DISMISS_NOTIFICATION, null);

      await awesomeNotifications.dismiss(1);
    });

    test('dismissAllNotifications', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_DISMISS_ALL_NOTIFICATIONS, null);

      await awesomeNotifications.dismissAllNotifications();
    });

    test('dismissNotificationsByChannelKey', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_DISMISS_NOTIFICATIONS_BY_CHANNEL_KEY, null);

      await awesomeNotifications
          .dismissNotificationsByChannelKey('test_channel');
    });

    test('dismissNotificationsByGroupKey', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_DISMISS_NOTIFICATIONS_BY_GROUP_KEY, null);

      await awesomeNotifications.dismissNotificationsByGroupKey('test_group');
    });

    // Add these test cases inside the group('MethodChannelAwesomeNotifications', () { ... }) block

    test('getAppLifeCycle', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_GET_APP_LIFE_CYCLE,
          NotificationLifeCycle.Terminated.name);

      NotificationLifeCycle lifeCycle =
          await awesomeNotifications.getAppLifeCycle();

      expect(lifeCycle, NotificationLifeCycle.Terminated);
    });

    test('getDrawableData', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_GET_DRAWABLE_DATA,
          Uint8List.fromList([1, 2, 3, 4, 5]));

      Uint8List? drawableData =
          await awesomeNotifications.getDrawableData('test_drawable_path');

      expect(drawableData, isNotNull);
      expect(drawableData, isA<Uint8List>());
      expect(drawableData, equals(Uint8List.fromList([1, 2, 3, 4, 5])));
    });

    test('getInitialNotificationAction', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_GET_INITIAL_ACTION,
          ReceivedAction().fromMap(
              {'id': 1, 'buttonKeyPressed': 'test_button_key'}).toMap());

      ReceivedAction? initialAction =
          await awesomeNotifications.getInitialNotificationAction();

      expect(initialAction, isNotNull);
      expect(initialAction, isA<ReceivedAction>());
      expect(initialAction!.id, 1);
      expect(initialAction!.buttonKeyPressed, 'test_button_key');
    });

    test('getGlobalBadgeCounter', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_GET_BADGE_COUNT, 7);

      int badgeCount = await awesomeNotifications.getGlobalBadgeCounter();

      expect(badgeCount, 7);
    });

    // Add these test cases inside the group('MethodChannelAwesomeNotifications', () { ... }) block

    test('getLocalTimeZoneIdentifier', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_GET_LOCAL_TIMEZONE_IDENTIFIER, 'America/New_York');

      String localTimeZoneIdentifier =
          await awesomeNotifications.getLocalTimeZoneIdentifier();

      expect(localTimeZoneIdentifier, 'America/New_York');
    });

    test('getNextDate', () async {
      DateTime fixedDate = DateTime(2023, 5, 3);
      DateTime expectedNextDate = fixedDate.add(Duration(days: 1));

      mockMethodChannel.setMockMethodCallHandler(CHANNEL_METHOD_GET_NEXT_DATE,
          AwesomeDateUtils.parseDateToString(expectedNextDate));

      DateTime? nextDate = await awesomeNotifications
          .getNextDate(NotificationInterval(interval: 1), fixedDate: fixedDate);

      expect(nextDate, isNotNull);
      expect(nextDate, expectedNextDate);
    });

    test('getUtcTimeZoneIdentifier', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_GET_UTC_TIMEZONE_IDENTIFIER, 'UTC');

      String utcTimeZoneIdentifier =
          await awesomeNotifications.getUtcTimeZoneIdentifier();

      expect(utcTimeZoneIdentifier, 'UTC');
    });

    test('incrementGlobalBadgeCounter', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_INCREMENT_BADGE_COUNT, 9);

      int badgeCount = await awesomeNotifications.incrementGlobalBadgeCounter();

      expect(badgeCount, 9);
    });

    test('initialize', () async {
      // Set up the mocked method channel handlers
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_INITIALIZE, true);

      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_GET_LOCAL_TIMEZONE_IDENTIFIER, 'Local');
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_GET_UTC_TIMEZONE_IDENTIFIER, 'UTC');

      try {
        await awesomeNotifications.initialize(
          'test_icon',
          [
            NotificationChannel(
                channelKey: 'test_channel',
                channelName: 'Test Channel',
                channelDescription: 'Test Channel Description',
                defaultColor: const Color(0xFF9D50DD),
                ledColor: Colors.yellow)
          ],
          channelGroups: [
            NotificationChannelGroup(
                channelGroupKey: 'test_group',
                channelGroupName: 'Test Group Name')
          ],
          languageCode: 'pt-br',
          debug: true,
        );
        fail("exception not thrown");
      } catch (e) {
        expect(e, isA<AssertionError>());
      }

      try {
        bool result = await awesomeNotifications.initialize(
          'resource://test_icon',
          [
            NotificationChannel(
                channelKey: 'test_channel',
                channelName: 'Test Channel',
                channelDescription: 'Test Channel Description',
                defaultColor: const Color(0xFF9D50DD),
                ledColor: Colors.yellow)
          ],
          channelGroups: [
            NotificationChannelGroup(
                channelGroupKey: 'test_group',
                channelGroupName: 'Test Group Name')
          ],
          languageCode: 'pt-br',
          debug: true,
        );
        expect(result, true);
      } catch (e) {
        fail("exception thrown: $e");
      }

      // Assert that the local and UTC time zone identifiers have been set
      expect(AwesomeNotifications.localTimeZoneIdentifier, 'Local');
      expect(AwesomeNotifications.utcTimeZoneIdentifier, 'UTC');
    });

    test('isNotificationAllowed', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_IS_NOTIFICATION_ALLOWED, () async {
        return true;
      });

      bool isAllowed = await awesomeNotifications.isNotificationAllowed();
      expect(isAllowed, true);
    });

    test('listScheduledNotifications', () async {
      mockMethodChannel
          .setMockMethodCallHandler(CHANNEL_METHOD_LIST_ALL_SCHEDULES, [
        {
          NOTIFICATION_CONTENT: {
            NOTIFICATION_CHANNEL_KEY: 'test_channel',
            NOTIFICATION_ID: 1,
            NOTIFICATION_TITLE: 'Test Title',
            NOTIFICATION_BODY: 'Test Body',
          },
          NOTIFICATION_SCHEDULE: {
            NOTIFICATION_SCHEDULE_INTERVAL: 1,
          }
        }
      ]);

      List<NotificationModel> scheduledNotifications =
          await awesomeNotifications.listScheduledNotifications();
      expect(scheduledNotifications.length, 1);
      expect(scheduledNotifications[0].content!.title, 'Test Title');
    });

    test('removeChannel', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_REMOVE_NOTIFICATION_CHANNEL, true);

      bool wasRemoved =
          await awesomeNotifications.removeChannel('test_channel');
      expect(wasRemoved, true);
    });

    test('requestPermissionToSendNotifications', () async {
      mockMethodChannel
          .setMockMethodCallHandler(CHANNEL_METHOD_REQUEST_NOTIFICATIONS, []);

      bool isAllowed = await awesomeNotifications
          .requestPermissionToSendNotifications(permissions: [
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Badge,
        NotificationPermission.Vibration,
        NotificationPermission.Light
      ]);
      expect(isAllowed, true);

      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_REQUEST_NOTIFICATIONS, [NotificationPermission.Alert]);

      isAllowed = await awesomeNotifications
          .requestPermissionToSendNotifications(permissions: [
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Badge,
        NotificationPermission.Vibration,
        NotificationPermission.Light
      ]);
      expect(isAllowed, false);

      mockMethodChannel
          .setMockMethodCallHandler(CHANNEL_METHOD_REQUEST_NOTIFICATIONS, [
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Badge,
        NotificationPermission.Vibration,
        NotificationPermission.Light
      ]);

      isAllowed = await awesomeNotifications
          .requestPermissionToSendNotifications(permissions: [
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Badge,
        NotificationPermission.Vibration,
        NotificationPermission.Light
      ]);
      expect(isAllowed, false);

      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_REQUEST_NOTIFICATIONS, null);

      isAllowed = await awesomeNotifications
          .requestPermissionToSendNotifications(permissions: [
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Badge,
        NotificationPermission.Vibration,
        NotificationPermission.Light
      ]);
      expect(isAllowed, false);
    });

    test('resetGlobalBadge', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_RESET_BADGE, true);
      await awesomeNotifications.resetGlobalBadge();
    });

    test('setChannel', () async {
      mockMethodChannel
          .setMockMethodCallHandler(CHANNEL_METHOD_SET_NOTIFICATION_CHANNEL,
              (Map<String, dynamic> parameters) async {
        expect(parameters[NOTIFICATION_CHANNEL_KEY], 'test_channel');
        expect(parameters[NOTIFICATION_CHANNEL_NAME], 'Test Channel');
        expect(parameters[CHANNEL_FORCE_UPDATE], false);
      });

      await awesomeNotifications.setChannel(NotificationChannel(
          channelKey: 'test_channel',
          channelName: 'Test Channel',
          channelDescription: 'Test Channel Description'));
    });

    test('setGlobalBadgeCounter', () async {
      await awesomeNotifications.setGlobalBadgeCounter(10);
    });

    test('setListeners', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_SET_EVENT_HANDLES, true);
      // (Map<String, dynamic> arguments) async {
      //   expect(arguments[CREATED_HANDLE], isNotNull);
      //   expect(arguments[DISPLAYED_HANDLE], isNotNull);
      //   expect(arguments[ACTION_HANDLE], isNotNull);
      //   expect(arguments[DISMISSED_HANDLE], isNotNull);
      //   setEventHandlesCalled = true;
      //   return true;
      // });

      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_SET_EVENT_HANDLES, false);

      bool result = await awesomeNotifications.setListeners(
        onActionReceivedMethod: onGlobalActionReceivedMethod,
        onNotificationCreatedMethod: onGlobalNotificationCreatedMethod,
        onNotificationDisplayedMethod: onGlobalNotificationDisplayedMethod,
        onDismissActionReceivedMethod: onGlobalDismissActionReceivedMethod,
      );

      expect(result, false);

      Future<void> onActionReceivedMethod(
          ReceivedAction receivedAction) async {}
      Future<void> onNotificationCreatedMethod(
          ReceivedNotification receivedNotification) async {}
      Future<void> onNotificationDisplayedMethod(
          ReceivedNotification receivedNotification) async {}
      Future<void> onDismissActionReceivedMethod(
          ReceivedAction receivedAction) async {}

      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_SET_EVENT_HANDLES, false);

      result = await awesomeNotifications.setListeners(
        onActionReceivedMethod: onActionReceivedMethod,
        onNotificationCreatedMethod: onNotificationCreatedMethod,
        onNotificationDisplayedMethod: onNotificationDisplayedMethod,
        onDismissActionReceivedMethod: onDismissActionReceivedMethod,
      );

      expect(result, false);
    });

    test('shouldShowRationaleToRequest', () async {
      mockMethodChannel
          .setMockMethodCallHandler(CHANNEL_METHOD_SHOULD_SHOW_RATIONALE,
              (Map<String, dynamic> arguments) {
        expect(arguments[NOTIFICATION_CHANNEL_KEY], null);
        expect(arguments[NOTIFICATION_PERMISSIONS], isNotNull);
        return [];
      });

      List<NotificationPermission> permissions =
          await awesomeNotifications.shouldShowRationaleToRequest();
      expect(permissions, isEmpty);
    });

    test('showAlarmPage', () async {
      bool showAlarmPageCalled = false;
      mockMethodChannel.setMockMethodCallHandler(CHANNEL_METHOD_SHOW_ALARM_PAGE,
          () async {
        showAlarmPageCalled = true;
      });

      await awesomeNotifications.showAlarmPage();
      expect(showAlarmPageCalled, true);
    });

    test('showGlobalDndOverridePage', () async {
      bool showGlobalDndOverridePageCalled = false;
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_SHOW_GLOBAL_DND_PAGE, () async {
        showGlobalDndOverridePageCalled = true;
      });

      await awesomeNotifications.showGlobalDndOverridePage();
      expect(showGlobalDndOverridePageCalled, true);
    });

    test('showNotificationConfigPage', () async {
      bool showNotificationConfigPageCalled = false;
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_SHOW_NOTIFICATION_PAGE, (dynamic arguments) async {
        expect(arguments, null);
        showNotificationConfigPageCalled = true;
      });

      await awesomeNotifications.showNotificationConfigPage();
      expect(showNotificationConfigPageCalled, true);
    });

    test('getLocalization', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_GET_LOCALIZATION, 'en_US');

      String localization = await awesomeNotifications.getLocalization();
      expect(localization, 'en_US');
    });

    test('setLocalization', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_SET_LOCALIZATION, (dynamic arguments) async {
        expect(arguments, 'en_US');
        return true;
      });

      bool success =
          await awesomeNotifications.setLocalization(languageCode: 'en_US');
      expect(success, true);
    });

    test('isNotificationActiveOnStatusBar', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_IS_NOTIFICATION_ACTIVE, (dynamic arguments) async {
        expect(arguments, 1);
        return true;
      });

      bool isActive =
          await awesomeNotifications.isNotificationActiveOnStatusBar(id: 1);
      expect(isActive, true);
    });

    test('getAllActiveNotificationIdsOnStatusBar', () async {
      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_GET_ALL_ACTIVE_NOTIFICATION_IDS, () async {
        return [1, 2, 3];
      });

      List<int>? ids =
          await awesomeNotifications.getAllActiveNotificationIdsOnStatusBar();
      expect(ids, [1, 2, 3]);

      mockMethodChannel.setMockMethodCallHandler(
          CHANNEL_METHOD_GET_ALL_ACTIVE_NOTIFICATION_IDS, () async {
        return null;
      });

      ids = await awesomeNotifications.getAllActiveNotificationIdsOnStatusBar();
      expect(ids, []);
    });

    test('_handleMethod: EVENT_NOTIFICATION_CREATED', () async {
      Map<String, dynamic> notificationData = {}; // Fill with actual data

      bool createdHandlerCalled = false;
      awesomeNotifications.createdHandler =
          (ReceivedNotification receivedNotification) async {
        createdHandlerCalled = true;
      };

      await awesomeNotifications.handleMethod(
          MethodCall(EVENT_NOTIFICATION_CREATED, notificationData));

      expect(createdHandlerCalled, true);
    });

    test('_handleMethod: EVENT_NOTIFICATION_DISPLAYED', () async {
      Map<String, dynamic> notificationData = {}; // Fill with actual data

      bool displayedHandlerCalled = false;
      awesomeNotifications.displayedHandler =
          (ReceivedNotification receivedNotification) async {
        displayedHandlerCalled = true;
      };

      await awesomeNotifications.handleMethod(
          MethodCall(EVENT_NOTIFICATION_DISPLAYED, notificationData));

      expect(displayedHandlerCalled, true);
    });

    test('_handleMethod: EVENT_NOTIFICATION_DISMISSED', () async {
      Map<String, dynamic> actionData = {}; // Fill with actual data

      bool dismissedHandlerCalled = false;
      awesomeNotifications.dismissedHandler =
          (ReceivedAction receivedAction) async {
        dismissedHandlerCalled = true;
      };

      await awesomeNotifications
          .handleMethod(MethodCall(EVENT_NOTIFICATION_DISMISSED, actionData));

      expect(dismissedHandlerCalled, true);
    });

    test('_handleMethod: EVENT_DEFAULT_ACTION', () async {
      Map<String, dynamic> actionData = {}; // Fill with actual data

      bool actionHandlerCalled = false;
      awesomeNotifications.actionHandler =
          (ReceivedAction receivedAction) async {
        actionHandlerCalled = true;
      };

      await awesomeNotifications
          .handleMethod(MethodCall(EVENT_DEFAULT_ACTION, actionData));

      expect(actionHandlerCalled, true);
    });

    test('_handleMethod: EVENT_SILENT_ACTION', () async {
      Map<String, dynamic> actionData = ReceivedAction().toMap();

      MockIsolateController isolateController = MockIsolateController();
      IsolateController.singleton = isolateController;

      when(() => isolateController.receiveSilentAction(any()))
          .thenAnswer((invocation) => Future.value(true));

      await awesomeNotifications
          .handleMethod(MethodCall(EVENT_SILENT_ACTION, actionData));

      verify(() => isolateController.receiveSilentAction(any())).called(1);

      actionData['actionType'] = ActionType.SilentBackgroundAction.name;
      await awesomeNotifications
          .handleMethod(MethodCall(EVENT_SILENT_ACTION, actionData));
    });

    test('_handleMethod: UnsupportedError', () {
      expect(
          () async => await awesomeNotifications
              .handleMethod(const MethodCall('unsupported_method', {})),
          throwsA(isA<UnsupportedError>()));
    });

    test('dispose', () async {
      await awesomeNotifications.dispose();
    });
  });
}

Future<void> onGlobalActionReceivedMethod(
    ReceivedAction receivedAction) async {}
Future<void> onGlobalNotificationCreatedMethod(
    ReceivedNotification receivedNotification) async {}
Future<void> onGlobalNotificationDisplayedMethod(
    ReceivedNotification receivedNotification) async {}
Future<void> onGlobalDismissActionReceivedMethod(
    ReceivedAction receivedAction) async {}
