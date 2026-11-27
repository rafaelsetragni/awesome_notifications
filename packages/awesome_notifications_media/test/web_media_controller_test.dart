import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_media/awesome_notifications_media.dart';
import 'package:awesome_notifications_media/src/web/web_media_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The web layer's logic, against a fake `navigator.mediaSession`.
class FakeSession implements MediaSessionApi {
  @override
  bool available = true;
  Map<String, Object?>? metadata;
  String playbackState = 'none';
  Map<String, double>? positionState;
  final handlers = <String, void Function(double?)>{};

  @override
  void setMetadata({required String title, String? artist, String? album, String? artworkUrl}) =>
      metadata = {'title': title, 'artist': artist, 'album': album, 'artwork': artworkUrl};
  @override
  void clearMetadata() => metadata = null;
  @override
  void setPlaybackState(String state) => playbackState = state;
  @override
  void setPositionState({required double duration, required double playbackRate, required double position}) =>
      positionState = {'duration': duration, 'playbackRate': playbackRate, 'position': position};
  @override
  void clearPositionState() => positionState = null;
  @override
  void setActionHandler(String action, void Function(double?)? handler) =>
      handler == null ? handlers.remove(action) : handlers[action] = handler;
}

class Dispatched {
  final Map<String, dynamic> model;
  final String buttonKey;
  final String? input;
  final Map<String, dynamic>? button;
  Dispatched(this.model, this.buttonKey, this.input, this.button);
}

void main() {
  late FakeSession session;
  late WebMediaController controller;
  late List<Dispatched> dispatched;

  setUp(() {
    session = FakeSession();
    dispatched = [];
    controller = WebMediaController(
      session,
      dispatchAction: (model, {required buttonKey, input, button}) async =>
          dispatched.add(Dispatched(model, buttonKey, input, button)),
      assetUrl: (key) => 'assets/$key',
    );
  });

  Map<String, dynamic> model({
    NotificationLayout layout = NotificationLayout.MediaPlayer,
    NotificationMedia? media,
    String? title,
    bool withMedia = true,
  }) =>
      {
        ...NotificationModel(
          content: NotificationContent(
            id: 7,
            channelKey: 'media',
            title: title,
            notificationLayout: layout,
            payload: {'keep': 'me'},
          ),
        ).toMap(),
        if (withMedia)
          ...(media ??
                  NotificationMedia(
                    sessionId: 's1',
                    title: 'Song',
                    artist: 'Band',
                    album: 'Disc',
                    artwork: 'asset://assets/cover.png',
                    duration: const Duration(seconds: 200),
                    position: const Duration(seconds: 20),
                    state: NotificationPlayState.playing,
                    controls: const {
                      MediaControl.play,
                      MediaControl.pause,
                      MediaControl.skipNext,
                      MediaControl.skipForward,
                      MediaControl.fastForward,
                      MediaControl.rewind,
                      MediaControl.seekTo,
                    },
                    commandTarget: MediaCommandTarget.both,
                  ))
              .toMap(),
      };

  group('web mapping', () {
    test('fastForward / rewind take the seek actions only without the skip controls', () {
      expect(webActionsOf({MediaControl.skipForward, MediaControl.fastForward, MediaControl.rewind}), {
        'seekforward': MediaControl.skipForward,
        'seekbackward': MediaControl.rewind,
      });
      expect(webActionsOf({MediaControl.play, MediaControl.skipPrevious, MediaControl.stop}), {
        'play': MediaControl.play,
        'previoustrack': MediaControl.skipPrevious,
        'stop': MediaControl.stop,
      });
    });

    test('play states', () {
      expect(webPlaybackStateOf('playing'), 'playing');
      expect(webPlaybackStateOf('buffering'), 'playing');
      expect(webPlaybackStateOf('paused'), 'paused');
      expect(webPlaybackStateOf('stopped'), 'none');
      expect(webPlaybackStateOf('error'), 'none');
    });

    test('artwork urls', () {
      String asset(String k) => '/assets/$k';
      expect(webArtworkUrlOf('https://x/a.jpg', asset), 'https://x/a.jpg');
      expect(webArtworkUrlOf('asset://assets/a.png', asset), '/assets/assets/a.png');
      expect(webArtworkUrlOf('file:///a.png', asset), isNull);
      expect(webArtworkUrlOf('resource://drawable/a', asset), isNull);
    });
  });

  group('WebMediaController', () {
    test('leaves other models to the next builder', () async {
      expect(await controller.build(model(layout: NotificationLayout.Default, withMedia: false)), isNull);
      expect(session.metadata, isNull);
    });

    test('rejects MediaPlayer without media and media with another layout', () async {
      await expectLater(
          controller.build(model(withMedia: false)),
          throwsA(isA<PlatformException>()
              .having((e) => e.code, 'code', 'INVALID_ARGUMENTS')
              .having((e) => e.details, 'details', 'arguments.invalid.notificationMedia')));
      await expectLater(
          controller.build(model(layout: NotificationLayout.Default)),
          throwsA(isA<PlatformException>()
              .having((e) => e.details, 'details', 'arguments.invalid.notificationMedia.layout')));
    });

    Matcher rejected(String detail) => throwsA(isA<PlatformException>()
        .having((e) => e.code, 'code', 'INVALID_ARGUMENTS')
        .having((e) => e.details, 'details', detail));

    test('rejects a push model (createdSource Firebase, any case)', () async {
      for (final source in ['Firebase', 'FIREBASE', 'firebase']) {
        final m = model();
        (m['content'] as Map)['createdSource'] = source;
        await expectLater(controller.build(m), rejected('arguments.invalid.notificationMedia.push'));
      }
      // A push is rejected before the other rules.
      final m = model(withMedia: false)..['schedule'] = {'interval': 60};
      (m['content'] as Map)['createdSource'] = 'Firebase';
      await expectLater(controller.build(m), rejected('arguments.invalid.notificationMedia.push'));
      expect(session.metadata, isNull);
    });

    test('rejects a scheduled model, before the layout rules', () async {
      await expectLater(controller.build(model()..['schedule'] = {'interval': 60}),
          rejected('arguments.invalid.notificationMedia.schedule'));
      await expectLater(
          controller.build(model(layout: NotificationLayout.Default)..['schedule'] = {'interval': 60}),
          rejected('arguments.invalid.notificationMedia.schedule'));
      await expectLater(controller.build(model(withMedia: false)..['schedule'] = {'interval': 60}),
          rejected('arguments.invalid.notificationMedia.schedule'));
      // A null schedule entry is no schedule.
      expect(await controller.build(model()..['schedule'] = null), isTrue);
    });

    test('pushes and schedules of other models are left to the next builder', () async {
      final m = model(layout: NotificationLayout.Default, withMedia: false)..['schedule'] = {'interval': 60};
      (m['content'] as Map)['createdSource'] = 'Firebase';
      expect(await controller.build(m), isNull);
    });

    test('a cancel / dismiss of the notification ends its session, even playing', () async {
      Future<void> expectEnds(Map<String, Object?> removal, bool ends) async {
        await controller.build(model());
        expect(session.playbackState, 'playing');
        // As the core's WebNotificationRemoval.matches does.
        controller.onRemoved((m) {
          final c = m['content'] as Map;
          return removal.entries.every((e) => c[e.key] == e.value);
        });
        expect(session.metadata == null, ends, reason: '$removal');
        if (ends) {
          expect(session.playbackState, 'none');
          expect(session.handlers, isEmpty);
          // The session is gone: a later command / position update is ignored.
          await controller.invokeMethod('mediaUpdatePosition', {'sessionId': 's1', 'position': 1});
          expect(session.positionState, isNull);
        }
      }

      await expectEnds({'id': 7}, true);
      await expectEnds({'id': 8}, false);
      await expectEnds({'channelKey': 'media'}, true);
      await expectEnds({'channelKey': 'other'}, false);
      await expectEnds({}, true);
    });

    test('a removal ends only the sessions it matches', () async {
      await controller.build(model());
      final other = model(media: const NotificationMedia(sessionId: 's2', title: 'B', state: NotificationPlayState.playing));
      (other['content'] as Map)['id'] = 9;
      await controller.build(other);
      controller.onRemoved((m) => (m['content'] as Map)['id'] == 7);
      // s2 is still active on the page.
      expect(session.metadata?['title'], 'B');
      controller.onRemoved((m) => (m['content'] as Map)['id'] == 9);
      expect(session.metadata, isNull);
    });

    test('builds the media session', () async {
      expect(await controller.build(model()), isTrue);
      expect(session.metadata,
          {'title': 'Song', 'artist': 'Band', 'album': 'Disc', 'artwork': 'assets/assets/cover.png'});
      expect(session.playbackState, 'playing');
      expect(session.positionState, {'duration': 200.0, 'playbackRate': 1.0, 'position': 20.0});
      expect(session.handlers.keys.toSet(),
          {'play', 'pause', 'nexttrack', 'seekforward', 'seekbackward', 'seekto'});
    });

    test('a paused session keeps a valid rate, a live stream has no position', () async {
      await controller.build(model(
          media: const NotificationMedia(
              sessionId: 's1', title: 'Radio', state: NotificationPlayState.paused)));
      expect(session.playbackState, 'paused');
      expect(session.positionState, isNull);
      await controller.build(model(
          media: const NotificationMedia(
              sessionId: 's1',
              title: 'Song',
              duration: Duration(seconds: 10),
              state: NotificationPlayState.paused)));
      expect(session.positionState!['playbackRate'], 1.0);
    });

    test('a command reaches the action event and the stream', () async {
      final events = <Object?>[];
      final sub = controller.commandEvents.listen(events.add);
      await controller.build(model());
      session.handlers['seekto']!(42.5);
      session.handlers['pause']!(null);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(events, [
        {'control': 'seekTo', 'sessionId': 's1', 'position': 42500},
        {'control': 'pause', 'sessionId': 's1'},
      ]);
      expect(dispatched.map((d) => [d.buttonKey, d.input]), [
        ['awn.media.seekTo', '42500'],
        ['awn.media.pause', null],
      ]);
      final first = dispatched.first;
      expect(first.button, {'key': 'awn.media.seekTo', 'actionType': 'SilentAction', 'autoDismissible': false});
      final content = first.model['content'] as Map;
      expect(content['title'], 'Song');
      expect(content['body'], 'Band');
      expect(content['payload'], {'keep': 'me', 'mediaSessionId': 's1'});
    });

    test('commandTarget stream does not emit the action event', () async {
      await controller.build(model(
          media: const NotificationMedia(
              sessionId: 's1',
              title: 'Song',
              state: NotificationPlayState.playing,
              controls: {MediaControl.pause},
              commandTarget: MediaCommandTarget.stream)));
      session.handlers['pause']!(null);
      await Future<void>.delayed(Duration.zero);
      expect(dispatched, isEmpty);
    });

    test('rejects media without a sessionId or a title', () async {
      for (final media in [
        {'sessionId': '', 'title': 'T'},
        {'sessionId': 's1'},
      ]) {
        final m = model()..['media'] = media;
        await expectLater(controller.build(m), rejected('arguments.invalid.notificationMedia'),
            reason: '$media');
      }
    });

    test('an unknown method is not implemented on the web', () async {
      await expectLater(controller.invokeMethod('bogus'), throwsA(isA<MissingPluginException>()));
    });

    test('mediaUpdatePosition, mediaStop and mediaCapabilities', () async {
      await controller.build(model());
      await controller.invokeMethod('mediaUpdatePosition', {'sessionId': 's1', 'position': 90000});
      expect(session.positionState, {'duration': 200.0, 'playbackRate': 1.0, 'position': 90.0});

      expect(await controller.invokeMethod('mediaCapabilities'),
          {'seekBar': true, 'artwork': true, 'customButtons': false, 'lockScreen': false});

      await controller.invokeMethod('mediaStop', 's1');
      expect(session.metadata, isNull);
      expect(session.playbackState, 'none');
      expect(session.positionState, isNull);
      expect(session.handlers, isEmpty);
    });

    test('AwesomeNotificationsMedia goes through the bridge', () async {
      AwesomeNotificationsMedia.bridge = controller;
      addTearDown(() => AwesomeNotificationsMedia.bridge = null);
      final media = AwesomeNotificationsMedia.private(
          const MethodChannel('unused'), const EventChannel('unused/events'));
      await controller.build(model());
      final caps = await media.capabilities();
      expect(caps.seekBar, isTrue);
      expect(caps.lockScreen, isFalse);

      final commands = <MediaCommand>[];
      final sub = media.commands.listen(commands.add);
      session.handlers['seekto']!(3);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(commands.single.control, MediaControl.seekTo);
      expect(commands.single.position, const Duration(seconds: 3));
      expect(commands.single.sessionId, 's1');

      await media.stop('s1');
      expect(session.metadata, isNull);
    });
  });
}
