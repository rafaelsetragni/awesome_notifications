@TestOn('browser')
library;

import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_live_activities/awesome_notifications_live_activities.dart';
import 'package:awesome_notifications_live_activities/awesome_notifications_live_activities_web.dart';
import 'package:awesome_notifications_live_activities/src/web/js_live_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The browser's `Notification`, replaced by a recording one (a test can't
/// grant the permission, click or close a real notification).
const _fakeNotification = '''
window.__awnShown = [];
window.__awnFocused = 0;
window.__awnAsked = 0;
window.focus = function () { window.__awnFocused++; };
window.Notification = class {
  constructor(title, options) {
    if (options && options.actions) throw new TypeError('actions need a service worker');
    if (options && options.renotify && !options.tag) throw new TypeError('renotify needs a tag');
    this.title = title;
    this.options = options;
    this.closed = false;
    window.__awnShown.push(this);
  }
  close() { this.closed = true; if (this.onclose) this.onclose({}); }
};
window.Notification.permission = 'granted';
window.Notification.requestPermission = function () {
  window.__awnAsked++;
  return Promise.resolve(window.Notification.permission);
};
''';

JSArray<JSObject> get _shownArray => globalContext.getProperty<JSArray<JSObject>>('__awnShown'.toJS);
List<JSObject> get _shown => _shownArray.toDart;
JSObject get _notificationClass => globalContext.getProperty<JSObject>('Notification'.toJS);

Map<String, Object?> _optionsOf(JSObject n) =>
    (n.getProperty<JSObject>('options'.toJS).dartify() as Map).cast<String, Object?>();

/// The notifications on screen (the last of each tag), as maps.
Map<String, Map<String, Object?>> get _onScreen {
  final byTag = <String, Map<String, Object?>>{};
  for (final n in _shown) {
    final options = _optionsOf(n);
    final tag = options['tag'] as String;
    if (n.getProperty<JSBoolean>('closed'.toJS).toDart) {
      byTag.remove(tag);
    } else {
      byTag[tag] = {'title': n.getProperty<JSString>('title'.toJS).toDart, ...options};
    }
  }
  return byTag;
}

JSObject _last(String tag) => _shown.lastWhere((n) => _optionsOf(n)['tag'] == tag);

void _click(String tag) {
  final event = {'preventDefault': (() {}).toJS}.jsify();
  _last(tag).getProperty<JSFunction>('onclick'.toJS).callAsFunction(_last(tag), event);
}

/// The user closes it: the browser closes it and fires `close`.
void _userClose(String tag) => _last(tag).callMethod('close'.toJS);

class _Schedule implements NotificationExtension {
  @override
  Map<String, dynamic> toMap() => {
        'schedule': {'interval': 60, 'repeats': false}
      };
}

void main() {
  test('the real Notification: available only with the permission', () {
    final permission = globalContext.has('Notification')
        ? _notificationClass.getProperty<JSString>('permission'.toJS).toDart
        : null;
    expect(JsLiveNotifications().available, permission == 'granted');
  });

  group('through the core\'s web createNotification', () {
    final actions = <ReceivedAction>[];
    final created = <ReceivedNotification>[];
    final displayed = <ReceivedNotification>[];
    final live = AwesomeNotificationsLiveActivities();

    setUpAll(() async {
      globalContext.callMethod('eval'.toJS, _fakeNotification.toJS);
      AwesomeNotificationsLiveActivitiesWeb.registerWith();
      await AwesomeNotifications().setListeners(
        onActionReceivedMethod: (a) async => actions.add(a),
        onNotificationCreatedMethod: (n) async => created.add(n),
        onNotificationDisplayedMethod: (n) async => displayed.add(n),
      );
    });

    setUp(() {
      actions.clear();
      created.clear();
      displayed.clear();
      _notificationClass.setProperty('permission'.toJS, 'granted'.toJS);
      _shownArray.callMethod('splice'.toJS, 0.toJS, _shown.length.toJS);
    });

    tearDown(() => AwesomeNotifications().cancelAll());

    Future<bool> show(NotificationLiveActivity activity, {int id = 1, String body = 'On the way', double? progress}) =>
        AwesomeNotifications().createNotification(
            content: NotificationContent(id: id, channelKey: 'live', title: 'Order', body: body, progress: progress),
            extensions: [activity]);

    test('the first post: requireInteraction, created and displayed events with the activityId', () async {
      expect(await show(const NotificationLiveActivity(activityId: 'o7', shortText: '12 min'), progress: 30), isTrue);
      expect(_onScreen, {
        'awn.live.o7': {
          'title': 'Order',
          'body': 'On the way\n▰▰▰▱▱▱▱▱▱▱ 30% · 12 min',
          'tag': 'awn.live.o7',
          'renotify': false,
          'requireInteraction': true,
        }
      });
      expect(created.single.payload, {'activityId': 'o7'});
      expect(displayed.single.id, 1);
      expect(await live.activities(),
          const [ActiveLiveActivity(activityId: 'o7', status: LiveActivityStatus.active)]);
    });

    test('updates replace it silently; alert renotifies', () async {
      await show(const NotificationLiveActivity(), progress: 10);
      await show(const NotificationLiveActivity(), progress: 50);
      expect(_shown.length, 2);
      expect(_optionsOf(_shown.last)['renotify'], false);
      expect(_onScreen.keys, ['awn.live.1']);
      await show(const NotificationLiveActivity(alert: true), progress: 80);
      expect(_optionsOf(_shown.last)['renotify'], true);
      expect(created.length, 3);
    });

    test('the user closes it: the dismissed state event', () async {
      final states = <ActiveLiveActivity>[];
      final sub = live.onStatusChanged.listen(states.add);
      await show(const NotificationLiveActivity(activityId: 'o7'));
      _userClose('awn.live.o7');
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(states, const [ActiveLiveActivity(activityId: 'o7', status: LiveActivityStatus.dismissed)]);
      expect(await live.activities(), isEmpty);
    });

    test('a click focuses the page and reaches onActionReceivedMethod', () async {
      await show(const NotificationLiveActivity(activityId: 'o7'));
      final focused = globalContext.getProperty<JSNumber>('__awnFocused'.toJS).toDartInt;
      _click('awn.live.o7');
      await Future<void>.delayed(Duration.zero);
      expect(globalContext.getProperty<JSNumber>('__awnFocused'.toJS).toDartInt, focused + 1);
      expect(actions.single.buttonKeyPressed, '');
      expect(AwesomeNotificationsLiveActivities.activityIdOf(actions.single), 'o7');
    });

    test('end: final content, then the dismissal; cancel closes it', () async {
      await show(const NotificationLiveActivity(activityId: 'o7'));
      await live.end('o7');
      expect(_onScreen['awn.live.o7']!['requireInteraction'], false);
      expect(await live.activities(),
          const [ActiveLiveActivity(activityId: 'o7', status: LiveActivityStatus.ended)]);
      await live.end('o7', dismissal: LiveActivityDismissal.immediate);
      expect(_onScreen, isEmpty);

      await show(const NotificationLiveActivity(), id: 2);
      await AwesomeNotifications().dismiss(2);
      expect(_onScreen, isEmpty);
      expect(await live.activities(), isEmpty);
      expect(actions, isEmpty);
    });

    test('a dismissal time closes it then; staleAt too', () async {
      await show(NotificationLiveActivity(
          state: LiveActivityState.ended,
          dismissal: LiveActivityDismissal.at(DateTime.now().add(const Duration(milliseconds: 20)))));
      await show(NotificationLiveActivity(staleAt: DateTime.now().add(const Duration(milliseconds: 20))), id: 2);
      expect(_onScreen.length, 2);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(_onScreen, isEmpty);
    });

    test('a schedule is refused; JSON data goes through the builder', () async {
      await expectLater(
          AwesomeNotifications().createNotification(
              content: NotificationContent(id: 3, channelKey: 'live'),
              extensions: [const NotificationLiveActivity(), _Schedule()]),
          throwsA(isA<PlatformException>()
              .having((e) => e.code, 'code', 'INVALID_ARGUMENTS')
              .having((e) => e.details, 'details', 'arguments.invalid.notificationLiveActivity.schedule')));
      expect(_onScreen, isEmpty);

      expect(
          await AwesomeNotifications().createNotificationFromJsonData({
            'content': jsonEncode({'id': 4, 'channelKey': 'live', 'title': 'T', 'progress': 40}),
            'liveActivity': jsonEncode(const NotificationLiveActivity().toMap()['liveActivity']),
          }),
          isTrue);
      expect(_onScreen['awn.live.4']!['body'], '▰▰▰▰▱▱▱▱▱▱ 40%');
    });

    test('methods: capabilities, permission, tokens', () async {
      final caps = await live.capabilities();
      expect([caps.systemSurface, caps.progressSegments, caps.metrics, caps.buttons, caps.push],
          [false, false, false, false, false]);
      expect(await live.pushToStartToken(), isNull);
      expect(await live.pushToken('o7'), isNull);
      expect(await live.areEnabled(), isTrue);
      final asked = globalContext.getProperty<JSNumber>('__awnAsked'.toJS).toDartInt;
      expect(await live.requestPermission(), isTrue);
      // Already granted: the browser isn't asked.
      expect(globalContext.getProperty<JSNumber>('__awnAsked'.toJS).toDartInt, asked);

      _notificationClass.setProperty('permission'.toJS, 'denied'.toJS);
      expect(await live.areEnabled(), isFalse);
      expect(await live.requestPermission(), isFalse);
      expect(globalContext.getProperty<JSNumber>('__awnAsked'.toJS).toDartInt, asked + 1);
      expect(await show(const NotificationLiveActivity(), id: 5), isFalse);
      expect(_onScreen, isEmpty);
    });

    test('a model without liveActivity is left to the core', () async {
      expect(await AwesomeNotifications().createNotification(content: NotificationContent(id: 6, channelKey: 'basic')),
          isFalse);
      expect(_onScreen, isEmpty);
    });
  });
}
