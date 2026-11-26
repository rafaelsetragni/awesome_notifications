@TestOn('browser')
library;

import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_calls/awesome_notifications_calls.dart';
import 'package:awesome_notifications_calls/awesome_notifications_calls_web.dart';
import 'package:awesome_notifications_calls/src/web/js_call_notifications.dart';
import 'package:awesome_notifications_calls/src/web/web_call_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The browser's `Notification`, replaced by a recording one (a test can't
/// grant the permission nor click a real notification).
const _fakeNotification = '''
window.__awnShown = [];
window.__awnFocused = 0;
window.focus = function () { window.__awnFocused++; };
window.Notification = class {
  constructor(title, options) {
    if (options && options.actions) throw new TypeError('actions need a service worker');
    this.title = title;
    this.options = options;
    this.closed = false;
    window.__awnShown.push(this);
  }
  close() { this.closed = true; }
};
window.Notification.permission = 'granted';
''';

JSArray<JSObject> get _shownArray => globalContext.getProperty<JSArray<JSObject>>('__awnShown'.toJS);
List<JSObject> get _shown => _shownArray.toDart;

/// The notifications on screen (the last of each tag), as maps.
Map<String, Map<String, Object?>> get _onScreen {
  final byTag = <String, Map<String, Object?>>{};
  for (final n in _shown) {
    final options = (n.getProperty<JSObject>('options'.toJS).dartify() as Map).cast<String, Object?>();
    final tag = options['tag'] as String;
    if (n.getProperty<JSBoolean>('closed'.toJS).toDart) {
      byTag.remove(tag);
    } else {
      byTag[tag] = {'title': n.getProperty<JSString>('title'.toJS).toDart, ...options};
    }
  }
  return byTag;
}

void _click(String tag) {
  final n = _shown.lastWhere(
      (n) => (n.getProperty<JSObject>('options'.toJS).dartify() as Map)['tag'] == tag);
  final event = {'preventDefault': (() {}).toJS}.jsify();
  n.getProperty<JSFunction>('onclick'.toJS).callAsFunction(n, event);
}

class _Schedule implements NotificationExtension {
  @override
  Map<String, dynamic> toMap() => {
        'schedule': {'interval': 60, 'repeats': false}
      };
}

void main() {
  test('the real Notification: available only with the permission', () {
    final permission = globalContext.has('Notification')
        ? globalContext.getProperty<JSObject>('Notification'.toJS).getProperty<JSString>('permission'.toJS).toDart
        : null;
    expect(JsCallNotifications().available, permission == 'granted');
  });

  group('through the core\'s web createNotification', () {
    final actions = <ReceivedAction>[];
    final created = <ReceivedNotification>[];

    setUpAll(() async {
      globalContext.callMethod('eval'.toJS, _fakeNotification.toJS);
      AwesomeNotificationsCallsWeb.registerWith();
      await AwesomeNotifications().setListeners(
        onActionReceivedMethod: (a) async => actions.add(a),
        onNotificationCreatedMethod: (n) async => created.add(n),
      );
    });

    setUp(() {
      actions.clear();
      created.clear();
      _shownArray.callMethod('splice'.toJS, 0.toJS, _shown.length.toJS);
    });

    tearDown(() => AwesomeNotifications().cancelAll());

    NotificationCall call(CallState state,
            {CallCommandTarget target = CallCommandTarget.actionEvent, Duration ring = const Duration(seconds: 60)}) =>
        NotificationCall(
          callId: 'w1',
          caller: const NotificationPerson(key: 'u', name: 'Ana', avatar: 'https://x/ana.png'),
          state: state,
          ringTimeout: ring,
          commandTarget: target,
        );

    Future<bool> show(NotificationCall c, {int id = 1}) => AwesomeNotifications().createNotification(
        content: NotificationContent(id: id, channelKey: 'calls'), extensions: [c]);

    test('incoming: a requireInteraction notification, no actions (no service worker)', () async {
      expect(await show(call(CallState.incoming)), isTrue);
      expect(_onScreen, {
        'awn.call.w1': {
          'title': 'Ana',
          'body': 'Incoming call',
          'tag': 'awn.call.w1',
          'requireInteraction': true,
          'icon': 'https://x/ana.png',
        }
      });
      expect(created.single.payload, {'callId': 'w1'});
      expect(created.single.title, 'Ana');
      expect(await AwesomeNotificationsCalls().activeCalls(),
          const [ActiveCall(callId: 'w1', state: CallState.incoming)]);
    });

    test('a click on the body focuses the page and reaches onActionReceivedMethod', () async {
      await show(call(CallState.incoming));
      final focused = globalContext.getProperty<JSNumber>('__awnFocused'.toJS).toDartInt;
      _click('awn.call.w1');
      await Future<void>.delayed(Duration.zero);
      expect(globalContext.getProperty<JSNumber>('__awnFocused'.toJS).toDartInt, focused + 1);
      final action = actions.single;
      expect(action.id, 1);
      expect(action.buttonKeyPressed, '');
      expect(AwesomeNotificationsCalls.callIdOf(action), 'w1');
      expect(AwesomeNotificationsCalls.commandOf(action), isNull);
    });

    test('the ring timeout: the missed notification (created event) and the timeout command', () async {
      final commands = <CallCommand>[];
      final sub = AwesomeNotificationsCalls().commands.listen(commands.add);
      await show(call(CallState.incoming,
          target: CallCommandTarget.both, ring: const Duration(milliseconds: 20)));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await sub.cancel();

      final missedId = missedNotificationIdOf('w1');
      expect(_onScreen.keys, ['awn.call.missed.$missedId']);
      expect(_onScreen.values.single['body'], 'Missed call');
      expect(_onScreen.values.single['requireInteraction'], false);
      expect(created.map((n) => n.id), [1, missedId]);
      expect(created.last.payload, {'callId': 'w1'});
      expect(commands, const [CallCommand(action: CallAction.timeout, callId: 'w1')]);
      expect(AwesomeNotificationsCalls.commandOf(actions.single),
          const CallCommand(action: CallAction.timeout, callId: 'w1'));

      await AwesomeNotifications().cancel(missedId);
      expect(_onScreen, isEmpty);
    });

    test('ongoing replaces the notification in place; cancel ends the call', () async {
      await show(call(CallState.incoming));
      await show(call(CallState.ongoing));
      expect(_onScreen.keys, ['awn.call.w1']);
      expect(_onScreen['awn.call.w1']!['body'], 'Ongoing call');
      await AwesomeNotifications().cancel(1);
      expect(_onScreen, isEmpty);
      expect(await AwesomeNotificationsCalls().activeCalls(), isEmpty);
      expect(actions, isEmpty);
    });

    test('endCall unanswered shows the missed notification', () async {
      await show(call(CallState.incoming));
      await AwesomeNotificationsCalls().endCall('w1', reason: CallEndReason.unanswered);
      expect(_onScreen.keys, ['awn.call.missed.${missedNotificationIdOf('w1')}']);
      final caps = await AwesomeNotificationsCalls().capabilities();
      expect([caps.systemCallUI, caps.lockScreen, caps.muteAndHold, caps.push], [false, false, false, false]);
      expect(await AwesomeNotificationsCalls().voipToken(), isNull);
      expect(await AwesomeNotificationsCalls().requestFullScreenIntent(), isTrue);
    });

    test('a scheduled call is refused; JSON data goes through the builder', () async {
      await expectLater(
          AwesomeNotifications().createNotification(
              content: NotificationContent(id: 2, channelKey: 'calls'),
              extensions: [call(CallState.incoming), _Schedule()]),
          throwsA(isA<PlatformException>()
              .having((e) => e.code, 'code', 'INVALID_ARGUMENTS')
              .having((e) => e.details, 'details', 'arguments.invalid.notificationCall.schedule')));
      expect(_onScreen, isEmpty);

      expect(
          await AwesomeNotifications().createNotificationFromJsonData({
            'content': jsonEncode({'id': 3, 'channelKey': 'calls'}),
            'call': jsonEncode(call(CallState.outgoing).toMap()['call']),
          }),
          isTrue);
      expect(_onScreen['awn.call.w1']!['body'], 'Calling…');
    });

    test('a model without a call is left to the core', () async {
      expect(
          await AwesomeNotifications().createNotification(
              content: NotificationContent(id: 4, channelKey: 'basic', category: NotificationCategory.Call)),
          isFalse);
      expect(_onScreen, isEmpty);
    });
  });
}
