import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/method_channel_awesome_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A stand-in add-on extension (like scheduling) that contributes extra top-level
/// entries to the serialized notification map.
class _FakeExtension implements NotificationExtension {
  @override
  Map<String, dynamic> toMap() => {
        'fake': 'data',
        'schedule': {'interval': 60},
      };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('awesome_notifications');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final mc = MethodChannelAwesomeNotifications();
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case CHANNEL_METHOD_INITIALIZE:
        case CHANNEL_METHOD_CREATE_NOTIFICATION:
        case CHANNEL_METHOD_IS_NOTIFICATION_ALLOWED:
        case CHANNEL_METHOD_IS_NOTIFICATION_ACTIVE:
        case CHANNEL_METHOD_SET_EVENT_HANDLES:
        case CHANNEL_METHOD_REMOVE_NOTIFICATION_CHANNEL:
          return true;
        case CHANNEL_METHOD_CHECK_PERMISSIONS:
        case CHANNEL_METHOD_SHOULD_SHOW_RATIONALE:
          return <Object?>['Alert', 'Sound'];
        case CHANNEL_METHOD_REQUEST_NOTIFICATIONS:
          return <Object?>[]; // nothing missing → granted
        case CHANNEL_METHOD_GET_BADGE_COUNT:
        case CHANNEL_METHOD_INCREMENT_BADGE_COUNT:
        case CHANNEL_METHOD_DECREMENT_BADGE_COUNT:
          return 5;
        case CHANNEL_METHOD_GET_LOCAL_TIMEZONE_IDENTIFIER:
        case CHANNEL_METHOD_GET_UTC_TIMEZONE_IDENTIFIER:
          return 'UTC';
        case CHANNEL_METHOD_GET_APP_LIFE_CYCLE:
          return 'Foreground';
        case CHANNEL_METHOD_GET_DRAWABLE_DATA:
          return Uint8List.fromList([1, 2, 3]);
        case CHANNEL_METHOD_GET_ALL_ACTIVE_NOTIFICATION_IDS:
          return <int>[1, 2];
        case CHANNEL_METHOD_GET_INITIAL_ACTION:
          return {NOTIFICATION_ID: 7, NOTIFICATION_CHANNEL_KEY: 'ch'};
        default:
          return null;
      }
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  Map<String, dynamic> lastArgs() =>
      Map<String, dynamic>.from(calls.last.arguments as Map);

  // --- create ---

  test('createNotification invokes the channel with the content map', () async {
    final ok = await mc.createNotification(
      content: NotificationContent(id: 1, channelKey: 'ch', title: 'T'),
    );
    expect(ok, isTrue);
    expect(calls.single.method, CHANNEL_METHOD_CREATE_NOTIFICATION);
    expect((lastArgs()[NOTIFICATION_CONTENT] as Map)[NOTIFICATION_ID], 1);
  });

  test('createNotification serializes action buttons', () async {
    await mc.createNotification(
      content: NotificationContent(id: 1, channelKey: 'ch'),
      actionButtons: [NotificationActionButton(key: 'A', label: 'a')],
    );
    final data = lastArgs();
    expect(data[NOTIFICATION_BUTTONS], isA<List>());
    expect((data[NOTIFICATION_BUTTONS] as List).first[NOTIFICATION_KEY], 'A');
  });

  test('a silent background action is dispatched through compute', () async {
    final bgType =
        AwesomeAssertUtils.toSimpleEnumString(ActionType.SilentBackgroundAction);
    await expectLater(
      mc.handleMethod(MethodCall(EVENT_SILENT_ACTION, {
        NOTIFICATION_ACTION_TYPE: bgType,
        ACTION_HANDLE: 123456789,
        NOTIFICATION_ID: 1,
      })),
      throwsA(anything),
    );
  });

  test('createNotification merges extension entries as siblings', () async {
    await mc.createNotification(
      content: NotificationContent(id: 1, channelKey: 'ch'),
      extensions: [_FakeExtension()],
    );
    final data = lastArgs();
    expect(data['fake'], 'data');
    expect((data['schedule'] as Map)['interval'], 60);
  });

  // --- dismiss / cancel ---

  test('cancel / dismiss route to the right channel methods', () async {
    await mc.cancel(3);
    await mc.dismiss(4);
    await mc.cancelAll();
    await mc.dismissAllNotifications();
    await mc.cancelNotificationsByChannelKey('ch');
    await mc.dismissNotificationsByChannelKey('ch');
    await mc.cancelNotificationsByGroupKey('grp');
    await mc.dismissNotificationsByGroupKey('grp');

    expect(calls.map((c) => c.method).toList(), [
      CHANNEL_METHOD_CANCEL_NOTIFICATION,
      CHANNEL_METHOD_DISMISS_NOTIFICATION,
      CHANNEL_METHOD_CANCEL_ALL_NOTIFICATIONS,
      CHANNEL_METHOD_DISMISS_ALL_NOTIFICATIONS,
      CHANNEL_METHOD_CANCEL_NOTIFICATIONS_BY_CHANNEL_KEY,
      CHANNEL_METHOD_DISMISS_NOTIFICATIONS_BY_CHANNEL_KEY,
      CHANNEL_METHOD_CANCEL_NOTIFICATIONS_BY_GROUP_KEY,
      CHANNEL_METHOD_DISMISS_NOTIFICATIONS_BY_GROUP_KEY,
    ]);
    expect(calls.first.arguments, 3);
  });

  // --- permissions ---

  test('permission queries parse the native lists', () async {
    expect(await mc.isNotificationAllowed(), isTrue);
    expect(await mc.requestPermissionToSendNotifications(), isTrue);
    final checked = await mc.checkPermissionList();
    expect(checked, contains(NotificationPermission.Alert));
    expect(checked, contains(NotificationPermission.Sound));
    final rationale = await mc.shouldShowRationaleToRequest();
    expect(rationale, contains(NotificationPermission.Alert));
  });

  // --- badge ---

  test('badge counters round-trip', () async {
    expect(await mc.getGlobalBadgeCounter(), 5);
    await mc.setGlobalBadgeCounter(9);
    expect(calls.last.method, CHANNEL_METHOD_SET_BADGE_COUNT);
    expect(calls.last.arguments, 9);
    expect(await mc.incrementGlobalBadgeCounter(), 5);
    expect(await mc.decrementGlobalBadgeCounter(), 5);
    await mc.resetGlobalBadge();
    expect(calls.last.method, CHANNEL_METHOD_RESET_BADGE);
  });

  // --- misc getters ---

  test('time zones, lifecycle, drawable and active notifications', () async {
    expect(await mc.getLocalTimeZoneIdentifier(), 'UTC');
    expect(await mc.getUtcTimeZoneIdentifier(), 'UTC');
    expect(await mc.getAppLifeCycle(), NotificationLifeCycle.Foreground);
    expect(await mc.getDrawableData('res'), isA<Uint8List>());
    expect(await mc.isNotificationActiveOnStatusBar(id: 1), isTrue);
    expect(await mc.getAllActiveNotificationIdsOnStatusBar(), [1, 2]);
  });

  test('getInitialNotificationAction parses the launch action', () async {
    final action = await mc.getInitialNotificationAction();
    expect(action, isNotNull);
    expect(action!.id, 7);
  });

  test('getInitialNotificationAction returns null when there is none', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => null);
    expect(await mc.getInitialNotificationAction(), isNull);
  });

  // --- channels + pages ---

  test('channels and system pages invoke their methods', () async {
    await mc.setChannel(NotificationChannel(
      channelKey: 'ch',
      channelName: 'Ch',
      channelDescription: 'desc',
    ));
    expect(calls.last.method, CHANNEL_METHOD_SET_NOTIFICATION_CHANNEL);
    expect(await mc.removeChannel('ch'), isTrue);
    await mc.showAlarmPage();
    await mc.showGlobalDndOverridePage();
    await mc.showNotificationConfigPage(channelKey: 'ch');
    expect(
        calls.map((c) => c.method),
        containsAll([
          CHANNEL_METHOD_SHOW_ALARM_PAGE,
          CHANNEL_METHOD_SHOW_GLOBAL_DND_PAGE,
          CHANNEL_METHOD_SHOW_NOTIFICATION_PAGE,
        ]));
  });

  // --- inbound event dispatch ---

  test('incoming lifecycle events reach the registered handlers', () async {
    ReceivedNotification? created;
    ReceivedNotification? displayed;
    ReceivedAction? dismissed;
    ReceivedAction? action;

    await mc.setListeners(
      onActionReceivedMethod: (a) async => action = a,
      onNotificationCreatedMethod: (r) async => created = r,
      onNotificationDisplayedMethod: (r) async => displayed = r,
      onDismissActionReceivedMethod: (a) async => dismissed = a,
    );

    await mc.handleMethod(MethodCall(EVENT_NOTIFICATION_CREATED,
        {NOTIFICATION_ID: 9, NOTIFICATION_CHANNEL_KEY: 'ch'}));
    await mc.handleMethod(MethodCall(EVENT_NOTIFICATION_DISPLAYED,
        {NOTIFICATION_ID: 10, NOTIFICATION_CHANNEL_KEY: 'ch'}));
    await mc.handleMethod(MethodCall(EVENT_NOTIFICATION_DISMISSED,
        {NOTIFICATION_ID: 11, NOTIFICATION_CHANNEL_KEY: 'ch'}));
    await mc.handleMethod(MethodCall(EVENT_DEFAULT_ACTION,
        {NOTIFICATION_ID: 12, NOTIFICATION_CHANNEL_KEY: 'ch'}));

    expect(created!.id, 9);
    expect(displayed!.id, 10);
    expect(dismissed!.id, 11);
    expect(action!.id, 12);
  });

  test('getInitialNotificationAction can remove itself from action events',
      () async {
    final action =
        await mc.getInitialNotificationAction(removeFromActionEvents: true);
    expect(action!.id, 7);
    expect(calls.last.arguments, true);
  });

  test('an unrecognized inbound method throws', () async {
    expect(() => mc.handleMethod(const MethodCall('bogus', <String, dynamic>{})),
        throwsA(isA<UnsupportedError>()));
  });

  test('a silent action is routed to the isolate controller', () async {
    // No registered callback for the handle → the controller rejects it.
    expect(
        () => mc.handleMethod(const MethodCall(EVENT_SILENT_ACTION,
            {ACTION_HANDLE: 123456789, NOTIFICATION_ID: 1})),
        throwsA(isA<IsolateCallbackException>()));
  });

  test('initialize registers channels/groups and caches the time zones',
      () async {
    final ok = await mc.initialize(
      'resource://drawable/ic',
      [
        NotificationChannel(
            channelKey: 'ch', channelName: 'Ch', channelDescription: 'd')
      ],
      channelGroups: [
        NotificationChannelGroup(channelGroupKey: 'g', channelGroupName: 'G')
      ],
      debug: true,
    );
    expect(ok, isTrue);
    expect(calls.first.method, CHANNEL_METHOD_INITIALIZE);
    expect(AwesomeNotifications.utcTimeZoneIdentifier, 'UTC');
  });

  test('createNotificationFromJsonData forwards preserved keys to native',
      () async {
    await mc.createNotificationFromJsonData({
      NOTIFICATION_CONTENT: {NOTIFICATION_ID: 1, NOTIFICATION_CHANNEL_KEY: 'ch'},
      'localizations': '{"pt-br":{"title":"Olá"}}',
    });
    final data = lastArgs();
    expect(calls.last.method, CHANNEL_METHOD_CREATE_NOTIFICATION);
    // The JSON-string localizations was decoded and preserved.
    expect((data['localizations'] as Map)['pt-br'], isA<Map>());
  });
}
