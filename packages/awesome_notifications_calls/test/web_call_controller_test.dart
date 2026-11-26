import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_calls/awesome_notifications_calls.dart';
import 'package:awesome_notifications_calls/src/web/web_call_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The web layer's logic, against fake browser notifications and timers.
class Shown {
  final String title, body;
  final String? icon;
  final bool requireInteraction;
  final List<WebCallButton> buttons;
  final void Function(CallAction?) onClick;
  Shown(this.title, this.body, this.icon, this.requireInteraction, this.buttons, this.onClick);
}

class FakeNotifications implements CallNotificationApi {
  @override
  bool available = true;
  final shown = <String, Shown>{};
  final log = <String>[];
  int focused = 0;

  @override
  void show(String tag,
      {required String title,
      required String body,
      String? icon,
      required bool requireInteraction,
      required List<WebCallButton> buttons,
      required void Function(CallAction?) onClick}) {
    log.add('show $tag');
    shown[tag] = Shown(title, body, icon, requireInteraction, buttons, onClick);
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

const ana = NotificationPerson(key: 'u-2', name: 'Ana', avatar: 'asset://assets/ana.png');

void main() {
  late FakeNotifications api;
  late WebCallController controller;
  late List<Dispatched> dispatched;
  late List<Map<String, dynamic>> created;
  late List<FakeTimer> timers;
  late List<Object?> events;
  late StreamSubscription<Object?> sub;
  final now = DateTime.utc(2026, 11, 26, 12);

  setUp(() {
    api = FakeNotifications();
    dispatched = [];
    created = [];
    timers = [];
    events = [];
    controller = WebCallController(
      api,
      dispatchAction: (model, {required buttonKey, input, button}) async =>
          dispatched.add(Dispatched(model, buttonKey, button)),
      // As the core does: through the builders.
      createNotification: (model) async {
        created.add(model);
        return await controller.build(model) ?? false;
      },
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

  Map<String, dynamic> model(NotificationCall call, {int id = 300, String? title, String? body}) => {
        ...NotificationModel(
          content: NotificationContent(
              id: id, channelKey: 'calls', title: title, body: body, payload: {'keep': 'me'}),
        ).toMap(),
        ...call.toMap(),
      };

  NotificationCall call(CallState state,
          {String callId = 'c1',
          CallCommandTarget target = CallCommandTarget.actionEvent,
          bool video = false,
          bool missed = true,
          String? groupName,
          Set<CallControl>? controls,
          DateTime? startedAt}) =>
      NotificationCall(
        callId: callId,
        caller: ana,
        state: state,
        video: video,
        groupName: groupName,
        startedAt: startedAt,
        ringTimeout: const Duration(seconds: 30),
        missedNotification: missed,
        commandTarget: target,
        controls: controls ??
            const {CallControl.accept, CallControl.decline, CallControl.hangUp, CallControl.mute},
        texts: const CallTexts(accept: 'Atender', decline: 'Recusar', hangUp: 'Desligar'),
      );

  Matcher rejected(String detail) => throwsA(isA<PlatformException>()
      .having((e) => e.code, 'code', 'INVALID_ARGUMENTS')
      .having((e) => e.details, 'details', detail));

  group('web helpers', () {
    test('the missed notification id is Java\'s String.hashCode of "missed:"+callId, positive', () {
      // "missed:a".hashCode() in Java.
      var expected = 0;
      for (final c in 'missed:a'.codeUnits) {
        expected = (31 * expected + c).toSigned(32);
      }
      expect(missedNotificationIdOf('a'), expected & 0x7FFFFFFF);
      expect(missedNotificationIdOf('a'), missedNotificationIdOf('a'));
      expect(missedNotificationIdOf('a'), isNot(missedNotificationIdOf('b')));
      expect(missedNotificationIdOf('a' * 200), greaterThanOrEqualTo(0));
    });

    test('image urls', () {
      String asset(String k) => '/assets/$k';
      expect(webImageUrlOf('https://x/a.jpg', asset), 'https://x/a.jpg');
      expect(webImageUrlOf('asset://assets/a.png', asset), '/assets/assets/a.png');
      expect(webImageUrlOf('file:///a.png', asset), isNull);
      expect(webImageUrlOf(null, asset), isNull);
    });

    test('parseWebCall fills the defaults of a minimal block', () {
      final call = parseWebCall({
        'callId': 'x',
        'caller': {'key': 'k', 'name': 'N'},
        'state': 'incoming',
      });
      expect(call['ringTimeout'], 60000);
      expect(call['missedNotification'], true);
      expect(call['controls'], ['accept', 'decline', 'hangUp', 'mute', 'hold']);
      expect(call['commandTarget'], 'actionEvent');
      expect(call['video'], false);
      expect((call['texts'] as Map)['accept'], 'Accept');
    });

    test('parseWebCall refuses what NotificationCall.validate refuses, and malformed maps', () {
      Map<String, dynamic> valid() => {
            'callId': 'x',
            'caller': {'key': 'k', 'name': 'N'},
            'state': 'incoming',
          };
      final invalid = <Map<String, dynamic>>[
        valid()..['callId'] = ' ',
        valid()..remove('callId'),
        valid()..remove('caller'),
        valid()..['caller'] = {'key': '', 'name': 'N'},
        valid()..['caller'] = {'key': 'k', 'name': ' '},
        valid()..['handle'] = '',
        valid()..['groupName'] = ' ',
        valid()..['ringTimeout'] = 0,
        valid()..['state'] = 'ringing',
        valid()..['controls'] = ['hangUp'],
        valid()..['controls'] = ['speaker'],
        valid()..['commandTarget'] = 'push',
        valid()..['video'] = 'yes',
        valid()..['texts'] = 'x',
      ];
      for (final map in invalid) {
        expect(() => parseWebCall(map), rejected('arguments.invalid.notificationCall'), reason: '$map');
      }
      expect(() => parseWebCall('x'), rejected('arguments.invalid.notificationCall'));
    });
  });

  group('WebCallController', () {
    test('leaves other models to the next builder', () async {
      final m = NotificationModel(
              content: NotificationContent(id: 1, channelKey: 'calls', category: NotificationCategory.Call))
          .toMap();
      expect(await controller.build(m), isNull);
      expect(api.shown, isEmpty);
    });

    test('refuses a scheduled call (before validating it), allows a push one', () async {
      await expectLater(controller.build(model(call(CallState.incoming))..['schedule'] = {'interval': 60}),
          rejected('arguments.invalid.notificationCall.schedule'));
      await expectLater(controller.build({...model(call(CallState.incoming)), 'call': {}, 'schedule': {}}),
          rejected('arguments.invalid.notificationCall.schedule'));
      await expectLater(controller.build({...model(call(CallState.incoming)), 'call': {'callId': ''}}),
          rejected('arguments.invalid.notificationCall'));
      expect(api.shown, isEmpty);
      expect(timers, isEmpty);

      final push = model(call(CallState.incoming));
      (push['content'] as Map)['createdSource'] = 'Firebase';
      expect(await controller.build(push), isTrue);
    });

    test('incoming: a requireInteraction notification with Accept / Decline, the ring timer', () async {
      final m = model(call(CallState.incoming));
      expect(await controller.build(m), isTrue);
      final shown = api.shown['awn.call.c1']!;
      expect(shown.title, 'Ana');
      expect(shown.body, 'Incoming call');
      expect(shown.icon, 'assets/assets/ana.png');
      expect(shown.requireInteraction, isTrue);
      expect(shown.buttons, const [
        WebCallButton(CallAction.accept, 'Atender'),
        WebCallButton(CallAction.decline, 'Recusar'),
      ]);
      expect(timers.single.duration, const Duration(seconds: 30));

      // The created / displayed events report the content with the callId.
      final content = m['content'] as Map;
      expect(content['title'], 'Ana');
      expect(content['body'], 'Incoming call');
      expect(content['payload'], {'keep': 'me', 'callId': 'c1'});

      expect(await controller.invokeMethod('callActiveCalls'), [
        {'callId': 'c1', 'state': 'incoming'}
      ]);
    });

    test('the app\'s title / body, group name and video texts', () async {
      await controller.build(model(call(CallState.incoming, video: true, groupName: 'Family')));
      expect(api.shown['awn.call.c1']!.title, 'Family');
      expect(api.shown['awn.call.c1']!.body, 'Incoming video call');
      await controller.build(model(call(CallState.incoming), title: 'T', body: 'B'));
      expect(api.shown['awn.call.c1']!.title, 'T');
      expect(api.shown['awn.call.c1']!.body, 'B');
    });

    test('an update of a ringing call keeps its timer', () async {
      await controller.build(model(call(CallState.incoming)));
      await controller.build(model(call(CallState.incoming, video: true)));
      expect(timers, hasLength(1));
      expect(timers.single.cancelled, isFalse);
      expect(api.shown['awn.call.c1']!.body, 'Incoming video call');
    });

    test('outgoing, ongoing and held: Hang up, no ring timer', () async {
      await controller.build(model(call(CallState.outgoing)));
      expect(api.shown['awn.call.c1']!.body, 'Calling…');
      expect(api.shown['awn.call.c1']!.buttons, const [WebCallButton(CallAction.hangUp, 'Desligar')]);
      expect(api.shown['awn.call.c1']!.requireInteraction, isTrue);
      expect(timers, isEmpty);

      await controller.build(model(call(CallState.incoming)));
      await controller.build(model(call(CallState.ongoing)));
      expect(timers.single.cancelled, isTrue);
      expect(api.shown['awn.call.c1']!.body, 'Ongoing call');
      await controller.build(model(call(CallState.held)));
      expect(await controller.invokeMethod('callActiveCalls'), [
        {'callId': 'c1', 'state': 'held'}
      ]);

      // Without the hangUp control: no button.
      await controller.build(model(call(CallState.ongoing, controls: {CallControl.accept})));
      expect(api.shown['awn.call.c1']!.buttons, isEmpty);
    });

    test('accept: ongoing first (startedAt now, timer cancelled), then the action event', () async {
      await controller.build(model(call(CallState.incoming)));
      api.log.clear();
      api.shown['awn.call.c1']!.onClick(CallAction.accept);
      await settle();
      expect(timers.single.cancelled, isTrue);
      expect(api.shown['awn.call.c1']!.body, 'Ongoing call');
      expect(api.shown['awn.call.c1']!.buttons, const [WebCallButton(CallAction.hangUp, 'Desligar')]);
      expect(await controller.invokeMethod('callActiveCalls'), [
        {'callId': 'c1', 'state': 'ongoing'}
      ]);
      final d = dispatched.single;
      expect(d.buttonKey, 'awn.call.accept');
      expect(d.button!['actionType'], 'Default');
      expect((d.model['content'] as Map)['payload'], {'keep': 'me', 'callId': 'c1'});
      expect(events, isEmpty);

      // The app sends ongoing without startedAt: the accepted one is kept.
      final m = model(call(CallState.ongoing));
      await controller.build(m);
      expect((m['call'] as Map)['startedAt'], now.millisecondsSinceEpoch);
    });

    test('decline / hangUp: the call ends, then the command (stream / both)', () async {
      await controller.build(model(call(CallState.incoming, target: CallCommandTarget.stream)));
      api.shown['awn.call.c1']!.onClick(CallAction.decline);
      await settle();
      expect(api.shown, isEmpty);
      expect(timers.single.cancelled, isTrue);
      expect(dispatched, isEmpty);
      expect(events, [
        {'kind': 'command', 'action': 'decline', 'callId': 'c1'}
      ]);
      expect(await controller.invokeMethod('callActiveCalls'), isEmpty);

      await controller.build(model(call(CallState.ongoing, target: CallCommandTarget.both)));
      api.shown['awn.call.c1']!.onClick(CallAction.hangUp);
      await settle();
      expect(api.shown, isEmpty);
      expect(events.last, {'kind': 'command', 'action': 'hangUp', 'callId': 'c1'});
      expect(dispatched.single.buttonKey, 'awn.call.hangUp');
      expect(dispatched.single.button!['actionType'], 'SilentAction');
    });

    test('a click on the body focuses the page and emits a plain action event', () async {
      await controller.build(model(call(CallState.incoming, target: CallCommandTarget.stream)));
      api.shown['awn.call.c1']!.onClick(null);
      await settle();
      expect(api.focused, 1);
      // Not a command: the call keeps ringing.
      expect(api.shown, contains('awn.call.c1'));
      expect(events, isEmpty);
      final d = dispatched.single;
      expect(d.buttonKey, '');
      expect(AwesomeNotificationsCalls.commandOf(ReceivedAction().fromMap({
        ...(d.model['content'] as Map).cast<String, dynamic>(),
        'buttonKeyPressed': d.buttonKey,
      })), isNull);
    });

    test('the ring timeout: call ended, missed notification through the core, timeout command', () async {
      await controller.build(model(call(CallState.incoming, video: true, target: CallCommandTarget.both)));
      timers.single.fire();
      await settle();
      expect(api.shown.keys, ['awn.call.missed.${missedNotificationIdOf('c1')}']);
      final missed = api.shown.values.single;
      expect(missed.title, 'Ana');
      expect(missed.body, 'Missed video call');
      expect(missed.buttons, isEmpty);
      expect(missed.requireInteraction, isFalse);
      final content = created.single['content'] as Map;
      expect(content['id'], missedNotificationIdOf('c1'));
      expect(content['channelKey'], 'calls');
      expect(content['payload'], {'callId': 'c1'});
      expect(content['largeIcon'], 'asset://assets/ana.png');
      expect(events, [
        {'kind': 'command', 'action': 'timeout', 'callId': 'c1'}
      ]);
      expect(dispatched.single.buttonKey, 'awn.call.timeout');
      expect(await controller.invokeMethod('callActiveCalls'), isEmpty);

      // A click on the missed notification opens the app and closes it.
      missed.onClick(null);
      await settle();
      expect(api.shown, isEmpty);
      expect(dispatched.last.buttonKey, '');
      expect((dispatched.last.model['content'] as Map)['id'], missedNotificationIdOf('c1'));
    });

    test('the timeout without a missed notification, and after an answer', () async {
      await controller.build(model(call(CallState.incoming, missed: false)));
      timers.single.fire();
      await settle();
      expect(api.shown, isEmpty);
      expect(created, isEmpty);
      expect(dispatched.single.buttonKey, 'awn.call.timeout');

      await controller.build(model(call(CallState.incoming)));
      api.shown['awn.call.c1']!.onClick(CallAction.accept);
      await settle();
      timers.last.fire();
      await settle();
      expect(dispatched.map((d) => d.buttonKey), ['awn.call.timeout', 'awn.call.accept']);
    });

    test('ended and missed states: no command, missed shows the notification', () async {
      await controller.build(model(call(CallState.incoming)));
      expect(await controller.build(model(call(CallState.ended))), isTrue);
      expect(api.shown, isEmpty);
      expect(timers.single.cancelled, isTrue);

      await controller.build(model(call(CallState.incoming)));
      await controller.build(model(call(CallState.missed)));
      expect(api.shown.keys, ['awn.call.missed.${missedNotificationIdOf('c1')}']);
      expect(api.shown.values.single.body, 'Missed call');

      await controller.build(model(call(CallState.missed, callId: 'c2', missed: false)));
      expect(created, hasLength(1));
      expect(dispatched, isEmpty);
      expect(events, isEmpty);
    });

    test('callEnd: ends silently; unanswered shows the missed notification', () async {
      await controller.build(model(call(CallState.incoming)));
      await controller.invokeMethod('callEnd', {'callId': 'c1', 'reason': 'remoteEnded'});
      expect(api.shown, isEmpty);
      expect(created, isEmpty);
      expect(timers.single.cancelled, isTrue);

      await controller.build(model(call(CallState.incoming)));
      await controller.invokeMethod('callEnd', {'callId': 'c1', 'reason': 'unanswered'});
      expect(api.shown.keys, ['awn.call.missed.${missedNotificationIdOf('c1')}']);

      await controller.build(model(call(CallState.incoming, callId: 'c2', missed: false)));
      await controller.invokeMethod('callEnd', {'callId': 'c2', 'reason': 'unanswered'});
      expect(created, hasLength(1));
      // An unknown call is ignored.
      expect(await controller.invokeMethod('callEnd', {'callId': 'x', 'reason': 'unanswered'}), isNull);
      expect(dispatched, isEmpty);
      expect(events, isEmpty);
    });

    test('a cancel / dismiss of the notification ends the call, without a command', () async {
      await controller.build(model(call(CallState.incoming)));
      await controller.build(model(call(CallState.ongoing, callId: 'c2'), id: 301));
      controller.onRemoved((m) => (m['content'] as Map)['id'] == 300);
      expect(api.shown.keys, ['awn.call.c2']);
      expect(timers.single.cancelled, isTrue);
      expect(await controller.invokeMethod('callActiveCalls'), [
        {'callId': 'c2', 'state': 'ongoing'}
      ]);

      // A missed notification is removed as any other.
      await controller.invokeMethod('callEnd', {'callId': 'c2', 'reason': 'unanswered'});
      controller.onRemoved((m) => (m['content'] as Map)['channelKey'] == 'calls');
      expect(api.shown, isEmpty);
      expect(dispatched, isEmpty);
      expect(events, isEmpty);
    });

    test('without permission: the call is tracked, createNotification answers false', () async {
      api.available = false;
      expect(await controller.build(model(call(CallState.incoming))), isFalse);
      expect(api.shown, isEmpty);
      expect(timers, hasLength(1));
      expect(await controller.invokeMethod('callActiveCalls'), hasLength(1));
    });

    test('the other methods answer as the contract says for the web', () async {
      expect(await controller.invokeMethod('callVoipToken'), isNull);
      expect(await controller.invokeMethod('callCanUseFullScreenIntent'), isTrue);
      expect(await controller.invokeMethod('callRequestFullScreenIntent'), isTrue);
      expect(await controller.invokeMethod('callCapabilities'),
          {'systemCallUI': false, 'lockScreen': false, 'muteAndHold': false, 'push': false});
      expect(() => controller.invokeMethod('callUnknown'), throwsA(isA<MissingPluginException>()));
    });

    test('AwesomeNotificationsCalls goes through the bridge', () async {
      AwesomeNotificationsCalls.bridge = controller;
      addTearDown(() => AwesomeNotificationsCalls.bridge = null);
      final calls = AwesomeNotificationsCalls.private(
          const MethodChannel('unused'), const EventChannel('unused/events'));
      await controller.build(model(call(CallState.incoming, target: CallCommandTarget.stream)));
      expect(await calls.activeCalls(), const [ActiveCall(callId: 'c1', state: CallState.incoming)]);
      expect(await calls.voipToken(), isNull);
      expect(await calls.canUseFullScreenIntent(), isTrue);
      final caps = await calls.capabilities();
      expect([caps.systemCallUI, caps.lockScreen, caps.muteAndHold, caps.push], [false, false, false, false]);

      final commands = <CallCommand>[];
      final s = calls.commands.listen(commands.add);
      api.shown['awn.call.c1']!.onClick(CallAction.accept);
      await settle();
      await s.cancel();
      expect(commands, const [CallCommand(action: CallAction.accept, callId: 'c1')]);

      await calls.endCall('c1');
      expect(api.shown, isEmpty);
      expect(await calls.activeCalls(), isEmpty);
    });
  });
}
