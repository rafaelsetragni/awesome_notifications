@TestOn('browser')
library;

import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/awesome_notifications_web.dart';
import 'package:flutter/services.dart';
import 'package:awesome_notifications_media/awesome_notifications_media.dart';
import 'package:awesome_notifications_media/awesome_notifications_media_web.dart';
import 'package:flutter_test/flutter_test.dart';

@JS('navigator.mediaSession')
external JSObject get _mediaSession;

/// The real `navigator.mediaSession`, through the core's web createNotification.
void main() {
  final handlers = <String, JSFunction>{};

  setUpAll(() {
    // Records the handlers (the browser has no way to fire them from a test).
    final original = _mediaSession.getProperty<JSFunction>('setActionHandler'.toJS);
    _mediaSession.setProperty(
        'setActionHandler'.toJS,
        ((String action, JSFunction? handler) {
          handler == null ? handlers.remove(action) : handlers[action] = handler;
          original.callAsFunction(_mediaSession, action.toJS, handler);
        }).toJS);
    // The core's default platform instance on the web is AwesomeNotificationsWeb.
    AwesomeNotificationsMediaWeb.registerWith();
  });

  String? metadataField(String name) => _mediaSession
      .getProperty<JSObject?>('metadata'.toJS)
      ?.getProperty<JSString?>(name.toJS)
      ?.toDart;

  test('createNotification sets the media session, a control reaches onActionReceivedMethod', () async {
    final actions = <ReceivedAction>[];
    await AwesomeNotifications().setListeners(onActionReceivedMethod: (a) async => actions.add(a));

    final created = await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: 1, channelKey: 'media', notificationLayout: NotificationLayout.MediaPlayer),
      extensions: [
        const NotificationMedia(
          sessionId: 'web',
          title: 'Song',
          artist: 'Band',
          album: 'Disc',
          artwork: 'https://example.com/cover.png',
          duration: Duration(seconds: 100),
          position: Duration(seconds: 10),
          state: NotificationPlayState.playing,
          controls: {MediaControl.pause, MediaControl.skipNext, MediaControl.seekTo},
        ),
      ],
    );
    expect(created, isTrue);
    expect(metadataField('title'), 'Song');
    expect(metadataField('artist'), 'Band');
    expect(metadataField('album'), 'Disc');
    final artwork = _mediaSession
        .getProperty<JSObject>('metadata'.toJS)
        .getProperty<JSArray<JSObject>>('artwork'.toJS)
        .toDart;
    expect(artwork.single.getProperty<JSString>('src'.toJS).toDart, 'https://example.com/cover.png');
    expect(_mediaSession.getProperty<JSString>('playbackState'.toJS).toDart, 'playing');
    expect(handlers.keys.toSet(), {'pause', 'nexttrack', 'seekto'});

    handlers['seekto']!.callAsFunction(null, {'action': 'seekto', 'seekTime': 12.5}.jsify());
    await Future<void>.delayed(Duration.zero);
    final action = actions.single;
    expect(action.buttonKeyPressed, 'awn.media.seekTo');
    expect(action.buttonKeyInput, '12500');
    expect(action.id, 1);
    final command = AwesomeNotificationsMedia.commandOf(action)!;
    expect(command.control, MediaControl.seekTo);
    expect(command.sessionId, 'web');
    expect(command.position, const Duration(milliseconds: 12500));

    final caps = await AwesomeNotificationsMedia().capabilities();
    expect(caps.seekBar, isTrue);
    expect(caps.customButtons, isFalse);

    await AwesomeNotificationsMedia().stop('web');
    expect(_mediaSession.getProperty<JSAny?>('metadata'.toJS), isNull);
    expect(_mediaSession.getProperty<JSString>('playbackState'.toJS).toDart, 'none');
    expect(handlers, isEmpty);
  });

  test('a model without media is left to the core', () async {
    final created = await AwesomeNotifications().createNotification(
        content: NotificationContent(id: 2, channelKey: 'basic'));
    expect(created, isFalse);
  });

  NotificationMedia media(String sessionId) => NotificationMedia(
        sessionId: sessionId,
        title: 'Song $sessionId',
        artist: 'Band',
        duration: const Duration(seconds: 100),
        state: NotificationPlayState.playing,
        controls: const {MediaControl.pause, MediaControl.seekTo},
      );

  bool sessionCleared() =>
      _mediaSession.getProperty<JSAny?>('metadata'.toJS) == null &&
      _mediaSession.getProperty<JSString>('playbackState'.toJS).toDart == 'none' &&
      handlers.isEmpty;

  Future<void> show(int id, String sessionId, {String channelKey = 'media', String? groupKey}) async {
    final created = await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: channelKey,
          groupKey: groupKey,
          notificationLayout: NotificationLayout.MediaPlayer),
      extensions: [media(sessionId)],
    );
    expect(created, isTrue);
    expect(metadataField('title'), 'Song $sessionId');
    expect(sessionCleared(), isFalse);
  }

  test('created and displayed fire for a handled media model', () async {
    final created = <ReceivedNotification>[], displayed = <ReceivedNotification>[];
    await AwesomeNotifications().setListeners(
      onActionReceivedMethod: (_) async {},
      onNotificationCreatedMethod: (n) async => created.add(n),
      onNotificationDisplayedMethod: (n) async => displayed.add(n),
    );
    addTearDown(() => AwesomeNotifications().setListeners(onActionReceivedMethod: (_) async {}));

    await show(10, 'events');
    for (final n in [created.single, displayed.single]) {
      expect(n.id, 10);
      expect(n.title, 'Song events');
      expect(n.body, 'Band');
      expect(n.payload, {'mediaSessionId': 'events'});
      expect(n.createdSource, NotificationSource.Local);
      expect(n.createdLifeCycle, NotificationLifeCycle.Foreground);
      expect(n.displayedLifeCycle, NotificationLifeCycle.Foreground);
      expect(n.createdDate, isNotNull);
      expect(n.displayedDate, isNotNull);
    }

    // A model no builder took fires nothing.
    await AwesomeNotifications().createNotification(content: NotificationContent(id: 11, channelKey: 'basic'));
    expect(created, hasLength(1));
    await AwesomeNotifications().cancelAll();
  });

  test('cancel / dismiss (by id, channel, group, all) end the media session', () async {
    final removals = <Future<void> Function()>[
      () => AwesomeNotifications().cancel(20),
      () => AwesomeNotifications().dismiss(20),
      () => AwesomeNotifications().cancelNotificationsByChannelKey('media'),
      () => AwesomeNotifications().dismissNotificationsByChannelKey('media'),
      () => AwesomeNotifications().cancelNotificationsByGroupKey('g'),
      () => AwesomeNotifications().dismissNotificationsByGroupKey('g'),
      () => AwesomeNotifications().cancelAll(),
      () => AwesomeNotifications().dismissAllNotifications(),
    ];
    for (final remove in removals) {
      await show(20, 'r', groupKey: 'g');
      await remove();
      expect(sessionCleared(), isTrue);
    }

    // Removing another notification keeps the session.
    await show(20, 'r', groupKey: 'g');
    await AwesomeNotifications().cancel(21);
    await AwesomeNotifications().dismissNotificationsByChannelKey('basic');
    await AwesomeNotifications().cancelNotificationsByGroupKey('other');
    expect(sessionCleared(), isFalse);
    await AwesomeNotifications().cancelAll();
    expect(sessionCleared(), isTrue);
  });

  test('push and scheduled media models are rejected', () async {
    final push = NotificationContent(
        id: 30, channelKey: 'media', notificationLayout: NotificationLayout.MediaPlayer)
      ..createdSource = NotificationSource.Firebase;
    await expectLater(
        AwesomeNotifications().createNotification(content: push, extensions: [media('p')]),
        throwsA(isA<PlatformException>()
            .having((e) => e.code, 'code', 'INVALID_ARGUMENTS')
            .having((e) => e.details, 'details', 'arguments.invalid.notificationMedia.push')));
    await expectLater(
        AwesomeNotifications().createNotification(
            content: NotificationContent(
                id: 31, channelKey: 'media', notificationLayout: NotificationLayout.MediaPlayer),
            extensions: [media('s'), _Schedule()]),
        throwsA(isA<PlatformException>()
            .having((e) => e.code, 'code', 'INVALID_ARGUMENTS')
            .having((e) => e.details, 'details', 'arguments.invalid.notificationMedia.schedule')));
    expect(sessionCleared(), isTrue);
  });

  test('createNotificationFromJsonData goes through the builders', () async {
    final content = {
      'id': 40,
      'channelKey': 'media',
      'notificationLayout': 'MediaPlayer',
    };
    expect(
        await AwesomeNotifications().createNotificationFromJsonData({
          'content': jsonEncode(content),
          'media': jsonEncode(media('json').toMap()['media']),
        }),
        isTrue);
    expect(metadataField('title'), 'Song json');
    await AwesomeNotifications().cancel(40);
    expect(sessionCleared(), isTrue);

    // A rejected model answers false, as the method channel does on a failure.
    expect(
        await AwesomeNotifications().createNotificationFromJsonData({
          'content': jsonEncode(content),
          'schedule': jsonEncode({'interval': 60}),
          'media': jsonEncode(media('json').toMap()['media']),
        }),
        isFalse);
    expect(sessionCleared(), isTrue);
  });

  test('WebNotificationRemoval.matches', () {
    final model = {
      'content': {'id': 1, 'channelKey': 'c', 'groupKey': 'g'}
    };
    expect(const WebNotificationRemoval(id: 1).matches(model), isTrue);
    expect(const WebNotificationRemoval(id: 2).matches(model), isFalse);
    expect(const WebNotificationRemoval(channelKey: 'c').matches(model), isTrue);
    expect(const WebNotificationRemoval(channelKey: 'x').matches(model), isFalse);
    expect(const WebNotificationRemoval(groupKey: 'g').matches(model), isTrue);
    expect(const WebNotificationRemoval(groupKey: 'x').matches(model), isFalse);
    expect(const WebNotificationRemoval().matches(model), isTrue);
    expect(const WebNotificationRemoval().matches(const {}), isFalse);
  });
}

class _Schedule implements NotificationExtension {
  @override
  Map<String, dynamic> toMap() => {
        'schedule': {'interval': 60, 'repeats': false}
      };
}
