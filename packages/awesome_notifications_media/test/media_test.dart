import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_media/awesome_notifications_media.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  NotificationMedia media({
    String sessionId = 'main-player',
    String title = 'Champagne Supernova',
    Duration? duration = const Duration(minutes: 4, seconds: 21),
    Duration position = const Duration(seconds: 37),
    double? playbackSpeed,
    NotificationPlayState state = NotificationPlayState.playing,
    Set<MediaControl> controls = const {MediaControl.pause, MediaControl.skipNext},
    Duration skipInterval = const Duration(seconds: 15),
  }) =>
      NotificationMedia(
        sessionId: sessionId,
        title: title,
        artist: 'Bright Sharp',
        album: 'Rock Disc',
        artwork: 'https://x/rock-disc.jpg',
        duration: duration,
        position: position,
        playbackSpeed: playbackSpeed,
        state: state,
        controls: controls,
        skipInterval: skipInterval,
      );

  group('NotificationMedia', () {
    test('serializes under the media key', () {
      expect(media().toMap(), {
        'media': {
          'sessionId': 'main-player',
          'title': 'Champagne Supernova',
          'artist': 'Bright Sharp',
          'album': 'Rock Disc',
          'artwork': 'https://x/rock-disc.jpg',
          'duration': 261000,
          'position': 37000,
          'playbackSpeed': 1.0,
          'state': 'playing',
          'controls': ['pause', 'skipNext'],
          'skipInterval': 15000,
          'commandTarget': 'actionEvent',
        }
      });
    });

    test('the speed defaults to 1 while playing and 0 otherwise', () {
      expect((media().toMap()['media'] as Map)['playbackSpeed'], 1.0);
      expect((media(state: NotificationPlayState.paused).toMap()['media'] as Map)['playbackSpeed'],
          0.0);
      expect((media(playbackSpeed: 1.5).toMap()['media'] as Map)['playbackSpeed'], 1.5);
    });

    test('a live stream has no duration', () {
      expect((media(duration: null).toMap()['media'] as Map).containsKey('duration'), isFalse);
    });

    test('controls keep a stable order', () {
      final map = media(controls: {MediaControl.seekTo, MediaControl.play, MediaControl.skipPrevious})
          .toMap()['media'] as Map;
      expect(map['controls'], ['play', 'skipPrevious', 'seekTo']);
    });

    for (final entry in <String, NotificationMedia Function()>{
      'an empty sessionId': () => media(sessionId: ' '),
      'an empty title': () => media(title: ''),
      'a negative position': () => media(position: const Duration(seconds: -1)),
      'a zero duration': () => media(duration: Duration.zero),
      'a position past the duration': () => media(position: const Duration(minutes: 5)),
      'a negative speed': () => media(playbackSpeed: -1),
      'a zero skip interval': () => media(skipInterval: Duration.zero),
    }.entries) {
      test('rejects ${entry.key}', () {
        expect(() => entry.value().toMap(), throwsA(isA<AwesomeNotificationsException>()));
      });
    }

    test('goes through createNotification\'s extensions', () async {
      MethodCall? sent;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('awesome_notifications'), (call) async {
        if (call.method == 'createNewNotification') sent = call;
        return true;
      });
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 100, channelKey: 'media_player', notificationLayout: NotificationLayout.MediaPlayer),
        extensions: [media()],
      );
      expect(((sent!.arguments as Map)['media'] as Map)['sessionId'], 'main-player');
      // The web core has no channel: web_media_session_test covers it there.
    }, testOn: 'vm');
  });

  group('MediaCommand', () {
    test('every control has its key', () {
      expect(MediaControl.pause.key, 'awn.media.pause');
      expect(MediaControl.values.map((c) => MediaCommand.parse(key: c.key)!.control),
          MediaControl.values);
    });

    test('reads a seek with its position', () {
      final command =
          MediaCommand.parse(key: 'awn.media.seekTo', input: '37000', sessionId: 'main-player')!;
      expect([command.control, command.position, command.sessionId],
          [MediaControl.seekTo, const Duration(seconds: 37), 'main-player']);
    });

    test('other actions are not commands', () {
      expect(MediaCommand.parse(key: 'MEDIA_PLAY'), isNull);
      expect(MediaCommand.parse(key: 'awn.media.dance'), isNull);
      expect(MediaCommand.parse(key: null), isNull);
    });

    test('commandOf reads a received action', () {
      final action = ReceivedAction().fromMap({
        'id': 100,
        'channelKey': 'media_player',
        'buttonKeyPressed': 'awn.media.seekTo',
        'buttonKeyInput': '5000',
        'payload': {'mediaSessionId': 'main-player'},
      });
      final command = AwesomeNotificationsMedia.commandOf(action)!;
      expect([command.control, command.position, command.sessionId],
          [MediaControl.seekTo, const Duration(seconds: 5), 'main-player']);
    });
  });

  group('AwesomeNotificationsMedia', () {
    const channel = MethodChannel('test/media');
    const events = EventChannel('test/media/commands');
    final calls = <MethodCall>[];
    late AwesomeNotificationsMedia api;

    setUp(() {
      calls.clear();
      api = AwesomeNotificationsMedia.private(channel, events);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'mediaCapabilities') {
          return {'seekBar': true, 'artwork': true, 'customButtons': false, 'lockScreen': true};
        }
        return null;
      });
    });

    test('stop releases the session', () async {
      await api.stop('main-player');
      expect(calls.single.method, 'mediaStop');
      expect(calls.single.arguments, 'main-player');
    });

    test('capabilities', () async {
      final caps = await api.capabilities();
      expect([caps.seekBar, caps.artwork, caps.customButtons, caps.lockScreen],
          [true, true, false, true]);
    });

    test('bindPosition sends at most once a second, and a jump at once', () async {
      var clock = DateTime(2026, 11, 25, 12);
      api.now = () => clock;
      final positions = StreamController<Duration>();
      api.bindPosition('main-player', positions.stream);

      Future<void> emit(int seconds, {int advance = 0}) async {
        clock = clock.add(Duration(milliseconds: advance));
        positions.add(Duration(seconds: seconds));
        await Future<void>.delayed(Duration.zero);
      }

      await emit(10); // first: sent
      await emit(10, advance: 200); // too soon: skipped
      await emit(11, advance: 900); // 1.1 s later: sent
      await emit(60, advance: 100); // a seek: sent at once
      api.unbindPosition('main-player');
      await emit(61, advance: 2000); // unbound: nothing

      expect(calls.map((c) => (c.arguments as Map)['position']), [10000, 11000, 60000]);
      expect(calls.every((c) => c.method == 'mediaUpdatePosition'), isTrue);
      await positions.close();
    });

    test('the commands stream reads the native events', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(events, MockStreamHandler.inline(onListen: (args, sink) {
        sink.success({'control': 'skipNext', 'sessionId': 'main-player'});
        sink.success({'control': 'seekTo', 'sessionId': 'main-player', 'position': 9000});
        sink.success({'control': 'unknown'});
        sink.endOfStream();
      }));
      final received = await api.commands.toList();
      expect(received.map((c) => '${c.control.name} ${c.position}'),
          ['skipNext null', 'seekTo 0:00:09.000000']);
    });
  });
}
