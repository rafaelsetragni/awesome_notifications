import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_live_activities/awesome_notifications_live_activities.dart';
import 'package:awesome_notifications_live_activities/src/live_activity_keys.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _Bridge implements LiveActivitiesPlatformBridge {
  final calls = <MethodCall>[];
  final controller = StreamController<Object?>.broadcast();
  Object? Function(String method)? answer;

  @override
  Future<Object?> invokeMethod(String method, [Object? arguments]) async {
    calls.add(MethodCall(method, arguments));
    return answer?.call(method);
  }

  @override
  Stream<Object?> get events => controller.stream;
}

Map<String, dynamic> _block(NotificationLiveActivity activity) =>
    (activity.toMap()['liveActivity'] as Map).cast<String, dynamic>();

Matcher _throwsInvalid(String text) => throwsA(isA<AwesomeNotificationsException>()
    .having((e) => e.message, 'message', contains(text)));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationLiveActivity', () {
    test('serializes only the defaults when nothing is set', () {
      expect(_block(const NotificationLiveActivity()), {
        'state': 'active',
        'metrics': <Object>[],
        'alert': false,
        'dismissal': 'default',
      });
    });

    test('serializes every field under the liveActivity key', () {
      final start = DateTime.utc(2026, 11, 26, 12);
      final end = DateTime.utc(2026, 11, 26, 12, 30);
      final block = _block(NotificationLiveActivity(
        activityId: 'order-7',
        state: LiveActivityState.ended,
        progress: const LiveActivityProgress(
          segments: [
            LiveActivitySegment(30, color: Color(0xFF00AA00)),
            LiveActivitySegment(70),
          ],
          points: [LiveActivityPoint(30, color: Color(0xFFFF0000))],
          trackerIcon: 'resource://drawable/res_car',
          startIcon: 'asset://assets/store.png',
          endIcon: 'https://x/home.png',
        ),
        timer: LiveActivityTimer.countDown(start: start, end: end),
        metrics: const [LiveActivityMetric(label: 'Speed', value: '42', unit: 'km/h')],
        shortText: '12 min',
        accentColor: const Color(0xFF7B0AC4),
        staleAt: end,
        relevance: 0.8,
        alert: true,
        dismissal: LiveActivityDismissal.at(end),
        pushChannel: 'match-1',
      ));
      expect(block, {
        'activityId': 'order-7',
        'state': 'ended',
        'progress': {
          'segments': [
            {'length': 30, 'color': 0xFF00AA00},
            {'length': 70},
          ],
          'points': [
            {'position': 30, 'color': 0xFFFF0000},
          ],
          'trackerIcon': 'resource://drawable/res_car',
          'startIcon': 'asset://assets/store.png',
          'endIcon': 'https://x/home.png',
        },
        'timer': {
          'start': start.millisecondsSinceEpoch,
          'end': end.millisecondsSinceEpoch,
          'countDown': true,
        },
        'metrics': [
          {'label': 'Speed', 'value': '42', 'unit': 'km/h'},
        ],
        'shortText': '12 min',
        'accentColor': 0xFF7B0AC4,
        'staleAt': end.millisecondsSinceEpoch,
        'relevance': 0.8,
        'alert': true,
        'dismissal': end.millisecondsSinceEpoch,
        'pushChannel': 'match-1',
      });
    });

    test('an elapsed timer counts up from its start, in UTC', () {
      final start = DateTime(2026, 11, 26, 9);
      expect(_block(NotificationLiveActivity(timer: LiveActivityTimer.elapsed(start: start)))['timer'],
          {'start': start.toUtc().millisecondsSinceEpoch, 'countDown': false});
    });

    test('dismissal immediate', () {
      expect(
          _block(const NotificationLiveActivity(
              state: LiveActivityState.ended,
              dismissal: LiveActivityDismissal.immediate))['dismissal'],
          'immediate');
    });

    test('refuses an invalid model before reaching the platform', () {
      expect(() => const NotificationLiveActivity(activityId: ' ').toMap(),
          _throwsInvalid('activityId'));
      expect(
          () => const NotificationLiveActivity(metrics: [
                LiveActivityMetric(label: 'a', value: '1'),
                LiveActivityMetric(label: 'b', value: '2'),
                LiveActivityMetric(label: 'c', value: '3'),
                LiveActivityMetric(label: 'd', value: '4'),
              ]).toMap(),
          _throwsInvalid('at most 3 metrics'));
      expect(
          () => const NotificationLiveActivity(metrics: [LiveActivityMetric(label: '', value: '1')])
              .toMap(),
          _throwsInvalid('label'));
      expect(() => const NotificationLiveActivity(shortText: '').toMap(),
          _throwsInvalid('shortText'));
      expect(() => const NotificationLiveActivity(pushChannel: ' ').toMap(),
          _throwsInvalid('pushChannel'));
      expect(
          () => const NotificationLiveActivity(
                  progress: LiveActivityProgress(segments: [LiveActivitySegment(0)])).toMap(),
          _throwsInvalid('positive length'));
      expect(
          () => const NotificationLiveActivity(
                  progress: LiveActivityProgress(
                      segments: [LiveActivitySegment(10)], points: [LiveActivityPoint(11)]))
              .toMap(),
          _throwsInvalid('0 to 10'));
      expect(
          () => const NotificationLiveActivity(
              progress: LiveActivityProgress(points: [LiveActivityPoint(101)])).toMap(),
          _throwsInvalid('0 to 100'));
      final at = DateTime.utc(2026);
      expect(() => NotificationLiveActivity(timer: LiveActivityTimer.countDown(start: at, end: at))
          .toMap(), _throwsInvalid('end after it starts'));
    });

    test('createNotification merges the block next to content', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('awesome_notifications'), (call) async {
        calls.add(call);
        return true;
      });
      await AwesomeNotifications().createNotification(
        content: NotificationContent(id: 400, channelKey: 'live', progress: 60),
        extensions: [const NotificationLiveActivity(shortText: '12 min')],
      );
      final args = (calls.last.arguments as Map).cast<String, dynamic>();
      expect((args['content'] as Map)['progress'], 60);
      expect((args['liveActivity'] as Map)['shortText'], '12 min');
    }, testOn: 'vm');
  });

  group('AwesomeNotificationsLiveActivities', () {
    late _Bridge bridge;
    late AwesomeNotificationsLiveActivities live;

    setUp(() {
      bridge = _Bridge();
      AwesomeNotificationsLiveActivities.bridge = bridge;
      live = AwesomeNotificationsLiveActivities.private(
          const MethodChannel('unused'), const EventChannel('unused'));
    });
    tearDown(() => AwesomeNotificationsLiveActivities.bridge = null);

    test('end sends the activity and its dismissal', () async {
      await live.end('order-7');
      await live.end('order-8', dismissal: LiveActivityDismissal.immediate);
      expect(bridge.calls.map((c) => [c.method, c.arguments]), [
        ['liveActivityEnd', {'activityId': 'order-7', 'dismissal': 'default'}],
        ['liveActivityEnd', {'activityId': 'order-8', 'dismissal': 'immediate'}],
      ]);
    });

    test('activities skips malformed entries', () async {
      bridge.answer = (_) => [
            {'activityId': 'a', 'state': 'active'},
            {'activityId': 'b', 'state': 'stale'},
            {'activityId': 'c', 'state': 'bogus'},
            {'state': 'ended'},
            'junk',
          ];
      expect(await live.activities(), const [
        ActiveLiveActivity(activityId: 'a', status: LiveActivityStatus.active),
        ActiveLiveActivity(activityId: 'b', status: LiveActivityStatus.stale),
      ]);
      bridge.answer = (_) => null;
      expect(await live.activities(), isEmpty);
    });

    test('areEnabled and requestPermission read a true answer only', () async {
      bridge.answer = (_) => true;
      expect(await live.areEnabled(), isTrue);
      expect(await live.requestPermission(), isTrue);
      bridge.answer = (_) => 'yes';
      expect(await live.areEnabled(), isFalse);
      expect(bridge.calls.map((c) => c.method),
          ['liveActivityAreEnabled', 'liveActivityRequestPermission', 'liveActivityAreEnabled']);
    });

    test('tokens: empty or missing reads as null', () async {
      bridge.answer = (_) => 'abc';
      expect(await live.pushToStartToken(), 'abc');
      expect(await live.pushToken('order-7'), 'abc');
      expect(bridge.calls.last.arguments, {'activityId': 'order-7'});
      bridge.answer = (_) => '';
      expect(await live.pushToStartToken(), isNull);
      expect(await live.pushToken('order-7'), isNull);
    });

    test('capabilities', () async {
      bridge.answer = (_) => {
            'systemSurface': true,
            'progressSegments': true,
            'metrics': false,
            'buttons': true,
            'push': true,
          };
      final caps = await live.capabilities();
      expect([caps.systemSurface, caps.progressSegments, caps.metrics, caps.buttons, caps.push],
          [true, true, false, true, true]);
      bridge.answer = (_) => null;
      expect((await live.capabilities()).systemSurface, isFalse);
    });

    test('events: tokens and status changes, malformed ones dropped', () async {
      final startTokens = <String>[];
      final tokens = <LiveActivityPushToken>[];
      final statuses = <ActiveLiveActivity>[];
      final subs = [
        live.onPushToStartToken.listen(startTokens.add),
        live.onPushToken.listen(tokens.add),
        live.onStatusChanged.listen(statuses.add),
      ];
      for (final event in [
        {'kind': 'pushToStartToken', 'token': 's1'},
        {'kind': 'pushToStartToken', 'token': ''},
        {'kind': 'pushToken', 'activityId': 'a', 'token': 't1'},
        {'kind': 'pushToken', 'token': 't2'},
        {'kind': 'state', 'activityId': 'a', 'state': 'dismissed'},
        {'kind': 'state', 'activityId': 'a', 'state': 'bogus'},
        'junk',
      ]) {
        bridge.controller.add(event);
      }
      await Future<void>.delayed(Duration.zero);
      for (final sub in subs) {
        await sub.cancel();
      }
      expect(startTokens, ['s1']);
      expect(tokens, const [LiveActivityPushToken(activityId: 'a', token: 't1')]);
      expect(statuses,
          const [ActiveLiveActivity(activityId: 'a', status: LiveActivityStatus.dismissed)]);
    });

    test('activityIdOf reads the payload', () {
      expect(
          AwesomeNotificationsLiveActivities.activityIdOf(
              ReceivedNotification().fromMap({'id': 1, 'payload': {LiveActivityKeys.payloadActivityId: 'x'}})),
          'x');
    });
  });
}
