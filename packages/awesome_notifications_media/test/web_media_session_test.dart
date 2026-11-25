@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:awesome_notifications/awesome_notifications.dart';
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
}
