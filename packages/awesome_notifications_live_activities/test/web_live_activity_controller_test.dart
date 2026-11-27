import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_live_activities/awesome_notifications_live_activities.dart';
import 'package:awesome_notifications_live_activities/src/live_activity_keys.dart';
import 'package:awesome_notifications_live_activities/src/web/web_live_activity_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The web layer's logic, against fake browser notifications and timers.
class Shown {
  final String title, body;
  final String? icon;
  final bool requireInteraction, renotify;
  final void Function() onClick, onClose;
  Shown(this.title, this.body, this.icon, this.requireInteraction, this.renotify, this.onClick, this.onClose);
}

class FakeNotifications implements LiveNotificationApi {
  @override
  bool available = true;
  bool grantOnRequest = true;
  final shown = <String, Shown>{};
  final log = <String>[];
  int focused = 0;

  @override
  Future<bool> requestPermission() async => available = available || grantOnRequest;

  @override
  void show(String tag,
      {required String title,
      required String body,
      String? icon,
      required bool requireInteraction,
      required bool renotify,
      required void Function() onClick,
      required void Function() onClose}) {
    log.add('show $tag${renotify ? ' renotify' : ''}');
    shown[tag] = Shown(title, body, icon, requireInteraction, renotify, onClick, onClose);
  }

  @override
  void close(String tag) {
    log.add('close $tag');
    shown.remove(tag);
  }

  @override
  void focusPage() => focused++;
}

class FakeTimer implements Timer {
  FakeTimer(this.duration, this.callback);
  final Duration duration;
  final void Function() callback;
  bool cancelled = false;
  @override
  void cancel() => cancelled = true;
  @override
  bool get isActive => !cancelled;
  @override
  int get tick => 0;
  void fire() {
    if (!cancelled) callback();
  }
}

class Dispatched {
  final Map<String, dynamic> model;
  final String buttonKey;
  final Map<String, dynamic>? button;
  Dispatched(this.model, this.buttonKey, this.button);
}

Matcher _refused(String detail) => throwsA(isA<PlatformException>()
    .having((e) => e.code, 'code', 'INVALID_ARGUMENTS')
    .having((e) => e.details, 'details', detail));

void main() {
  late FakeNotifications api;
  late WebLiveActivityController controller;
  late List<Dispatched> dispatched;
  late List<FakeTimer> timers;
  late List<Object?> events;
  late StreamSubscription<Object?> sub;
  final now = DateTime.utc(2026, 11, 26, 12);

  setUp(() {
    api = FakeNotifications();
    dispatched = [];
    timers = [];
    events = [];
    controller = WebLiveActivityController(
      api,
      dispatchAction: (model, {required buttonKey, input, button}) async =>
          dispatched.add(Dispatched(model, buttonKey, button)),
      assetUrl: (key) => 'assets/$key',
      timer: (duration, callback) {
        final timer = FakeTimer(duration, callback);
        timers.add(timer);
        return timer;
      },
      now: () => now,
    );
    sub = controller.events.listen(events.add);
  });

  tearDown(() => sub.cancel());

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Map<String, dynamic> model(NotificationLiveActivity activity,
          {int id = 400, String? title = 'Order', String? body = 'On the way', double? progress, String? largeIcon}) =>
      {
        ...NotificationModel(
          content: NotificationContent(
              id: id,
              channelKey: 'live',
              title: title,
              body: body,
              progress: progress,
              largeIcon: largeIcon,
              payload: {'keep': 'me'}),
        ).toMap(),
        ...activity.toMap(),
      };

  Map<String, Object?> stateEvent(String id, String state) =>
      {'kind': 'state', 'activityId': id, 'state': state};

  group('build', () {
    test('a model without liveActivity is left to the others', () async {
      expect(await controller.build(NotificationModel(content: NotificationContent(id: 1, channelKey: 'b')).toMap()),
          isNull);
      expect(api.log, isEmpty);
    });

    test('the first post: requireInteraction, the activityId payload, the notification id as activityId', () async {
      final m = model(const NotificationLiveActivity(), largeIcon: 'asset://assets/car.png');
      expect(await controller.build(m), isTrue);
      final shown = api.shown['awn.live.400']!;
      expect(shown.title, 'Order');
      expect(shown.body, 'On the way');
      expect(shown.icon, 'assets/assets/car.png');
      expect(shown.requireInteraction, isTrue);
      expect(shown.renotify, isFalse);
      expect((m['content'] as Map)['payload'], {'keep': 'me', 'activityId': '400'});
      expect((m['liveActivity'] as Map)['activityId'], '400');
      expect(await controller.invokeMethod(LiveActivityKeys.methodList), [
        {'activityId': '400', 'state': 'active'}
      ]);
    });

    test('updates replace the same tag silently; alert renotifies', () async {
      await controller.build(model(const NotificationLiveActivity(activityId: 'o7'), progress: 10));
      await controller.build(model(const NotificationLiveActivity(activityId: 'o7'), progress: 50));
      await controller.build(model(const NotificationLiveActivity(activityId: 'o7', alert: true), progress: 90));
      expect(api.log, ['show awn.live.o7', 'show awn.live.o7', 'show awn.live.o7 renotify']);
      expect(api.shown.keys, ['awn.live.o7']);
      expect(api.shown['awn.live.o7']!.body, 'On the way\n▰▰▰▰▰▰▰▰▰▱ 90%');
    });

    test('alert on the first post does not renotify (a new notification alerts anyway)', () async {
      await controller.build(model(const NotificationLiveActivity(alert: true)));
      expect(api.log, ['show awn.live.400']);
    });

    test('progress, short text, timer and metrics are folded into the body', () async {
      final end = DateTime.utc(2026, 11, 26, 12, 30);
      await controller.build(model(
          NotificationLiveActivity(
            shortText: '12 min',
            timer: LiveActivityTimer.countDown(end: end),
            metrics: const [
              LiveActivityMetric(label: 'Speed', value: '42', unit: 'km/h'),
              LiveActivityMetric(label: 'Stops', value: '2'),
            ],
          ),
          progress: 60));
      expect(api.shown['awn.live.400']!.body,
          'On the way\n▰▰▰▰▰▰▱▱▱▱ 60% · 12 min\nEnds at ${webTimeOf(end.millisecondsSinceEpoch)}\nSpeed 42 km/h · Stops 2');

      final start = DateTime.utc(2026, 11, 26, 11, 45);
      await controller.build(model(NotificationLiveActivity(timer: LiveActivityTimer.elapsed(start: start)), body: null));
      expect(api.shown['awn.live.400']!.body, 'Started at ${webTimeOf(start.millisecondsSinceEpoch)}');
    });

    test('a schedule is refused', () async {
      final m = model(const NotificationLiveActivity())..['schedule'] = {'interval': 60};
      await expectLater(controller.build(m), _refused('arguments.invalid.notificationLiveActivity.schedule'));
      expect(api.log, isEmpty);
    });

    test('an invalid block is refused', () async {
      Map<String, dynamic> raw(Map<String, dynamic> block) =>
          {...NotificationModel(content: NotificationContent(id: 1, channelKey: 'l')).toMap(), 'liveActivity': block};
      for (final block in <Map<String, dynamic>>[
        {'state': 'paused'},
        {'activityId': ' '},
        {'metrics': List.filled(4, {'label': 'a', 'value': '1'})},
        {'metrics': [{'label': '', 'value': '1'}]},
        {'shortText': ''},
        {'progress': {'segments': [{'length': 0}]}},
        {'progress': {'points': [{'position': 101}]}},
        {'timer': {'start': 10, 'end': 5, 'countDown': true}},
        {'timer': {'countDown': false}},
        {'alert': 'yes'},
        {'dismissal': 'later'},
        {'staleAt': 'soon'},
      ]) {
        await expectLater(controller.build(raw(block)), _refused('arguments.invalid.notificationLiveActivity'),
            reason: '$block');
      }
      await expectLater(controller.build({...raw({}), 'liveActivity': 'x'}),
          _refused('arguments.invalid.notificationLiveActivity'));
      expect(api.log, isEmpty);
    });

    test('without the permission nothing is shown nor kept', () async {
      api.available = false;
      expect(await controller.build(model(const NotificationLiveActivity())), isFalse);
      expect(api.log, isEmpty);
      expect(await controller.invokeMethod(LiveActivityKeys.methodList), isEmpty);
    });

    test('a new activityId on the same notification replaces the old activity', () async {
      await controller.build(model(const NotificationLiveActivity(activityId: 'a')));
      await controller.build(model(const NotificationLiveActivity(activityId: 'b')));
      expect(api.shown.keys, ['awn.live.b']);
      await settle();
      expect(events, [stateEvent('a', 'dismissed')]);
    });
  });

  group('end', () {
    test('state ended with the default dismissal: final content stays, no requireInteraction', () async {
      await controller.build(model(const NotificationLiveActivity()));
      await controller.build(model(const NotificationLiveActivity(state: LiveActivityState.ended), body: 'Delivered'));
      final shown = api.shown['awn.live.400']!;
      expect(shown.body, 'Delivered');
      expect(shown.requireInteraction, isFalse);
      expect(shown.renotify, isFalse);
      expect(timers, isEmpty);
      await settle();
      expect(events, [stateEvent('400', 'ended')]);
      expect(await controller.invokeMethod(LiveActivityKeys.methodList), [
        {'activityId': '400', 'state': 'ended'}
      ]);
      // The user closes it.
      shown.onClose();
      await settle();
      expect(events.last, stateEvent('400', 'dismissed'));
      expect(await controller.invokeMethod(LiveActivityKeys.methodList), isEmpty);
    });

    test('immediate dismissal closes it now', () async {
      await controller.build(model(const NotificationLiveActivity()));
      await controller.build(model(const NotificationLiveActivity(
          state: LiveActivityState.ended, dismissal: LiveActivityDismissal.immediate)));
      expect(api.log.last, 'close awn.live.400');
      expect(api.shown, isEmpty);
      await settle();
      expect(events, [stateEvent('400', 'ended'), stateEvent('400', 'dismissed')]);
    });

    test('a dismissal time closes it then', () async {
      await controller.build(model(const NotificationLiveActivity()));
      await controller.build(model(NotificationLiveActivity(
          state: LiveActivityState.ended,
          dismissal: LiveActivityDismissal.at(now.add(const Duration(minutes: 5))))));
      expect(timers.single.duration, const Duration(minutes: 5));
      expect(api.shown.keys, ['awn.live.400']);
      timers.single.fire();
      expect(api.shown, isEmpty);
      expect(await controller.invokeMethod(LiveActivityKeys.methodList), isEmpty);
    });

    test('liveActivityEnd: final content silently, then its dismissal', () async {
      await controller.build(model(const NotificationLiveActivity(activityId: 'o7')));
      await controller.invokeMethod(LiveActivityKeys.methodEnd, {'activityId': 'o7', 'dismissal': 'default'});
      expect(api.log, ['show awn.live.o7', 'show awn.live.o7']);
      expect(api.shown['awn.live.o7']!.requireInteraction, isFalse);
      await settle();
      expect(events, [stateEvent('o7', 'ended')]);
      await controller.invokeMethod(LiveActivityKeys.methodEnd, {'activityId': 'o7', 'dismissal': 'immediate'});
      expect(api.shown, isEmpty);
      await settle();
      expect(events.last, stateEvent('o7', 'dismissed'));
      // Unknown activity: nothing.
      await controller.invokeMethod(LiveActivityKeys.methodEnd, {'activityId': 'x', 'dismissal': 'immediate'});
      expect(api.log.length, 3);
    });

    test('a new post after the end starts a new activity (not an update)', () async {
      await controller.build(model(const NotificationLiveActivity(state: LiveActivityState.ended)));
      await controller.build(model(const NotificationLiveActivity(alert: true)));
      expect(api.log, ['show awn.live.400', 'show awn.live.400']);
      expect(api.shown['awn.live.400']!.requireInteraction, isTrue);
    });

    test('the core\'s cancel / dismiss ends it right away', () async {
      await controller.build(model(const NotificationLiveActivity(activityId: 'a'), id: 1));
      await controller.build(model(const NotificationLiveActivity(activityId: 'b'), id: 2));
      controller.onRemoved((m) => (m['content'] as Map)['id'] == 1);
      expect(api.shown.keys, ['awn.live.b']);
      controller.onRemoved((_) => true);
      expect(api.shown, isEmpty);
      await settle();
      expect(events, [stateEvent('a', 'dismissed'), stateEvent('b', 'dismissed')]);
    });

    test('staleAt closes it at that time; an update reschedules it', () async {
      await controller.build(model(NotificationLiveActivity(staleAt: now.add(const Duration(hours: 1)))));
      await controller.build(model(NotificationLiveActivity(staleAt: now.add(const Duration(hours: 2)))));
      expect(timers.map((t) => (t.duration, t.cancelled)),
          [(const Duration(hours: 1), true), (const Duration(hours: 2), false)]);
      timers.last.fire();
      expect(api.shown, isEmpty);
      await settle();
      expect(events, [stateEvent('400', 'dismissed')]);
    });

    test('a closed notification from an earlier post is ignored', () async {
      await controller.build(model(const NotificationLiveActivity()));
      final old = api.shown['awn.live.400']!;
      await controller.build(model(const NotificationLiveActivity()));
      old.onClose();
      await settle();
      expect(events, isEmpty);
      expect(api.shown.keys, ['awn.live.400']);
    });
  });

  test('a click focuses the page and emits the action event with the activityId', () async {
    await controller.build(model(const NotificationLiveActivity(activityId: 'o7')));
    api.shown['awn.live.o7']!.onClick();
    await settle();
    expect(api.focused, 1);
    final action = dispatched.single;
    expect(action.buttonKey, '');
    expect(action.button, {'actionType': 'Default'});
    expect((action.model['content'] as Map)['payload'], {'keep': 'me', 'activityId': 'o7'});
  });

  test('methods: capabilities, permission, tokens', () async {
    expect(await controller.invokeMethod(LiveActivityKeys.methodCapabilities), {
      'systemSurface': false,
      'progressSegments': false,
      'metrics': false,
      'buttons': false,
      'push': false,
    });
    api.available = false;
    expect(await controller.invokeMethod(LiveActivityKeys.methodAreEnabled), isFalse);
    expect(await controller.invokeMethod(LiveActivityKeys.methodRequestPermission), isTrue);
    expect(await controller.invokeMethod(LiveActivityKeys.methodAreEnabled), isTrue);
    expect(await controller.invokeMethod(LiveActivityKeys.methodPushToStartToken), isNull);
    expect(await controller.invokeMethod(LiveActivityKeys.methodPushToken, {'activityId': 'a'}), isNull);
    await expectLater(controller.invokeMethod('nope'), throwsA(isA<MissingPluginException>()));
  });

  test('through the public API', () async {
    AwesomeNotificationsLiveActivities.bridge = controller;
    addTearDown(() => AwesomeNotificationsLiveActivities.bridge = null);
    final live = AwesomeNotificationsLiveActivities();
    await controller.build(model(const NotificationLiveActivity(activityId: 'o7')));
    expect(await live.activities(),
        const [ActiveLiveActivity(activityId: 'o7', status: LiveActivityStatus.active)]);
    expect((await live.capabilities()).systemSurface, isFalse);
    expect(await live.areEnabled(), isTrue);
    await live.end('o7', dismissal: LiveActivityDismissal.immediate);
    expect(await live.activities(), isEmpty);
  });
}
