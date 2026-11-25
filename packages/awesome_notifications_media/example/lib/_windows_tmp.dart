// TEMPORARY Windows check entry point (the lead decides whether it stays).
//   flutter run -d windows -t lib/_windows_tmp.dart
// Every result is printed with the AWN_TMP prefix and listed on screen.
import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_media/awesome_notifications_media.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final _log = ValueNotifier<List<String>>([]);

void _print(String line) {
  debugPrint('AWN_TMP $line');
  _log.value = [line, ..._log.value].take(60).toList();
}

@pragma('vm:entry-point')
Future<void> onAction(ReceivedAction action) async {
  _print('ACTION key=${action.buttonKeyPressed} input=${action.buttonKeyInput} '
      'type=${action.actionType?.name} payload=${action.payload} '
      'command=${AwesomeNotificationsMedia.commandOf(action)}');
}

@pragma('vm:entry-point')
Future<void> onCreated(ReceivedNotification n) async => _print('CREATED id=${n.id}');

@pragma('vm:entry-point')
Future<void> onDisplayed(ReceivedNotification n) async => _print('DISPLAYED id=${n.id}');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AwesomeNotifications().initialize(null, [
    NotificationChannel(channelKey: 'media', channelName: 'Media', channelDescription: 'Media'),
  ]);
  await AwesomeNotifications().setListeners(
    onActionReceivedMethod: onAction,
    onNotificationCreatedMethod: onCreated,
    onNotificationDisplayedMethod: onDisplayed,
  );
  AwesomeNotificationsMedia().commands.listen((command) => _print('STREAM $command'));
  runApp(const MaterialApp(home: _Page()));
}

class _Page extends StatefulWidget {
  const _Page();

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  MediaCommandTarget target = MediaCommandTarget.both;
  String artwork = 'https://picsum.photos/id/1025/400/400.jpg';
  bool skips = false;
  final positions = StreamController<Duration>.broadcast();

  NotificationMedia media(NotificationPlayState state,
          {String session = 'main', String title = 'Champagne Supernova', bool live = false}) =>
      NotificationMedia(
        sessionId: session,
        title: title,
        artist: 'Bright Sharp',
        album: 'Album X',
        artwork: artwork.isEmpty ? null : artwork,
        duration: live ? null : const Duration(minutes: 3, seconds: 20),
        position: const Duration(seconds: 10),
        state: state,
        controls: {
          MediaControl.skipPrevious,
          MediaControl.play,
          MediaControl.pause,
          MediaControl.stop,
          MediaControl.skipNext,
          MediaControl.seekTo,
          if (skips) ...{MediaControl.skipForward, MediaControl.skipBackward},
        },
        commandTarget: target,
      );

  Future<void> post(NotificationMedia model, {int id = 100}) async {
    try {
      final ok = await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id, channelKey: 'media', notificationLayout: NotificationLayout.MediaPlayer),
        extensions: [model],
      );
      _print('created ${model.sessionId} ${model.state.name}: $ok');
    } catch (e) {
      _print('create failed $e');
    }
  }

  Future<void> invalid() async {
    for (final attempt in [
      () => AwesomeNotifications().createNotification(
          content: NotificationContent(
              id: 1, channelKey: 'media', notificationLayout: NotificationLayout.MediaPlayer)),
      () => AwesomeNotifications().createNotification(
          content: NotificationContent(id: 2, channelKey: 'media', title: 'x'),
          extensions: [media(NotificationPlayState.playing)]),
    ]) {
      try {
        _print('invalid answered ${await attempt()}');
      } catch (e) {
        _print('invalid rejected $e');
      }
    }
  }

  /// A schedule / a push source are rejected natively (sent raw: the public
  /// API can't stamp a push source).
  Future<void> rejected(String kind) async {
    final model = <String, dynamic>{
      'content': {'id': 102, 'channelKey': 'media', 'notificationLayout': 'MediaPlayer'},
      ...media(NotificationPlayState.playing, session: kind).toMap(),
    };
    if (kind == 'schedule') model['schedule'] = {'interval': 60, 'repeats': false};
    if (kind == 'push') (model['content'] as Map)['createdSource'] = 'Firebase';
    try {
      final ok = await const MethodChannel('awesome_notifications')
          .invokeMethod('createNewNotification', model);
      _print('$kind answered $ok');
    } on PlatformException catch (e) {
      _print('$kind rejected ${e.code} ${e.details}');
    }
  }

  Future<void> remove(String label, Future<void> Function() call) async {
    await call();
    _print('$label done');
  }

  @override
  Widget build(BuildContext context) {
    final actions = <String, VoidCallback>{
      'Playing': () => post(media(NotificationPlayState.playing)),
      'Paused': () => post(media(NotificationPlayState.paused)),
      'Buffering': () => post(media(NotificationPlayState.buffering)),
      'Live stream': () => post(media(NotificationPlayState.playing, live: true)),
      'Second session': () =>
          post(media(NotificationPlayState.playing, session: 'second', title: 'Second'), id: 101),
      'Position 1:30': () {
        AwesomeNotificationsMedia().bindPosition('main', positions.stream);
        positions.add(const Duration(seconds: 90));
      },
      'Stop main': () async {
        await AwesomeNotificationsMedia().stop('main');
        _print('stopped main');
      },
      'Stop second': () async {
        await AwesomeNotificationsMedia().stop('second');
        _print('stopped second');
      },
      'Capabilities': () async {
        final c = await AwesomeNotificationsMedia().capabilities();
        _print('capabilities seekBar=${c.seekBar} artwork=${c.artwork} '
            'customButtons=${c.customButtons} lockScreen=${c.lockScreen}');
      },
      'Invalid models': invalid,
      'Scheduled (rejected)': () => rejected('schedule'),
      'Push (rejected)': () => rejected('push'),
      'Cancel 100': () => remove('cancel 100', () => AwesomeNotifications().cancel(100)),
      'Dismiss 100': () => remove('dismiss 100', () => AwesomeNotifications().dismiss(100)),
      'Cancel all': () => remove('cancelAll', AwesomeNotifications().cancelAll),
      'Dismiss all':
          () => remove('dismissAll', AwesomeNotifications().dismissAllNotifications),
      'Cancel channel': () => remove('cancel channel',
          () => AwesomeNotifications().cancelNotificationsByChannelKey('media')),
    };
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final entry in actions.entries)
                FilledButton(onPressed: entry.value, child: Text(entry.key)),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              DropdownButton<MediaCommandTarget>(
                value: target,
                items: [
                  for (final t in MediaCommandTarget.values)
                    DropdownMenuItem(value: t, child: Text('target: ${t.name}')),
                ],
                onChanged: (t) => setState(() => target = t!),
              ),
              const SizedBox(width: 16),
              const Text('skipForward/Backward'),
              Switch(value: skips, onChanged: (v) => setState(() => skips = v)),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: artwork,
                  decoration: const InputDecoration(labelText: 'artwork'),
                  onChanged: (v) => artwork = v.trim(),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            Expanded(
              child: ValueListenableBuilder<List<String>>(
                valueListenable: _log,
                builder: (_, lines, _) => ListView(
                  children: [for (final line in lines) SelectableText(line)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
