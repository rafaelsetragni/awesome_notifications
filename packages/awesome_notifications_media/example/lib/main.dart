// awesome_notifications_media example: the media player screen of the 0.12
// example app, in one file. The player is simulated (a timer plays the track):
// the package never plays audio, it shows the system's media controls for the
// app's player and sends the user's commands back.
import 'dart:async';
import 'dart:math';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_media/awesome_notifications_media.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

/// The album covers of the 0.12 example, pinned to a commit so they never move.
const _covers =
    'https://raw.githubusercontent.com/rafaelsetragni/awesome_notifications/'
    '46032aae60fb47f3c372676c77bb59e470956339/example/assets/images';

const _channelKey = 'media_player';
const _notificationId = 100;
const _sessionId = 'example-player';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The status bar icon: a white glyph on transparent (Android draws only its
  // alpha). Without it, the full-color app icon shows as a square.
  await AwesomeNotifications().initialize('resource://drawable/res_notification_icon', [
    NotificationChannel(
      channelKey: _channelKey,
      channelName: 'Media player',
      channelDescription: 'Media player controls',
      importance: NotificationImportance.Low,
      playSound: false,
      enableVibration: false,
    ),
  ]);
  await AwesomeNotifications().setListeners(
    onActionReceivedMethod: onActionReceivedMethod,
  );
  runApp(const MediaExampleApp());
  // Never blocks the screen: the silent loop is only a helper (see SilentAudio).
  unawaited(
    SilentAudio.initialize().catchError((Object e) {
      debugPrint('Silent audio unavailable: $e');
    }),
  );
}

/// The system's media controls (and any other notification action) land here,
/// also with the app killed (Android).
@pragma('vm:entry-point')
Future<void> onActionReceivedMethod(ReceivedAction action) async {
  final command = AwesomeNotificationsMedia.commandOf(action);
  if (command != null) MediaPlayerCentral.handle(command);
}

///  *********************************************
///     SILENT AUDIO
///  *********************************************

/// The simulated player plays a silent loop only because iOS (and browsers)
/// show the system's media controls just while the app plays audio. A real
/// app plays its own audio instead. Windows and Linux need nothing.
class SilentAudio {
  static AudioPlayer? _player;

  static bool get _needed =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.android;

  static Future<void> initialize() async {
    if (!_needed) return;
    // The playback audio session iOS needs for Now Playing.
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    final player = AudioPlayer();
    final wav = _silentWav(const Duration(seconds: 2));
    if (kIsWeb) {
      await player.setAudioSource(
        AudioSource.uri(Uri.dataFromBytes(wav, mimeType: 'audio/wav')),
      );
    } else {
      final file = File(
        '${Directory.systemTemp.path}/awesome_notifications_silence.wav',
      );
      await file.writeAsBytes(wav, flush: true);
      await player.setAudioSource(AudioSource.file(file.path));
    }
    await player.setLoopMode(LoopMode.one);
    _player = player;
  }

  static Future<void> sync(bool playing) async {
    final player = _player;
    if (player == null) return;
    // play() completes only when playback stops: don't wait for it.
    playing
        ? unawaited(player.play().catchError((_) {}))
        : await player.pause();
  }

  /// A mono 8 kHz 16-bit WAV of silence, made in memory (no bundled file).
  static Uint8List _silentWav(Duration length) {
    const rate = 8000;
    final samples = rate * length.inMilliseconds ~/ 1000;
    final data = ByteData(44 + samples * 2);
    void text(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        data.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    text(0, 'RIFF');
    data.setUint32(4, 36 + samples * 2, Endian.little);
    text(8, 'WAVE');
    text(12, 'fmt ');
    data.setUint32(16, 16, Endian.little); // fmt chunk size
    data.setUint16(20, 1, Endian.little); // PCM
    data.setUint16(22, 1, Endian.little); // mono
    data.setUint32(24, rate, Endian.little);
    data.setUint32(28, rate * 2, Endian.little); // bytes per second
    data.setUint16(32, 2, Endian.little); // block align
    data.setUint16(34, 16, Endian.little); // bits per sample
    text(36, 'data');
    data.setUint32(40, samples * 2, Endian.little);
    return data.buffer.asUint8List();
  }
}

///  *********************************************
///     PLAYLIST
///  *********************************************

class MediaModel {
  final String band;
  final String track;
  final Duration length;
  final String cover;

  /// The screen's color for this album (the 0.12 example took it from the cover).
  final Color color;

  const MediaModel(this.band, this.track, this.length, this.cover, this.color);
}

class CloseCaption {
  final Duration start, end;
  final String subtitle;
  const CloseCaption(this.start, this.end, this.subtitle);
}

/// "la la la" every 15 s, as in the 0.12 example.
final List<CloseCaption> closeCaptions = [
  for (var s = 15; s <= 225; s += 15)
    CloseCaption(
      Duration(seconds: s),
      Duration(seconds: s + 5),
      'la la la la la la',
    ),
];

const playlist = [
  MediaModel(
    'Bright Sharp',
    'Champagne Supernova',
    Duration(minutes: 4, seconds: 21),
    '$_covers/rock-disc.jpg',
    Color(0xFF3E2723),
  ),
  MediaModel(
    'Best of Mozart',
    'Allegro',
    Duration(minutes: 7, seconds: 41),
    '$_covers/classic-disc.jpg',
    Color(0xFF4E342E),
  ),
  MediaModel(
    'Dj Allucard',
    '21st Century',
    Duration(minutes: 4, seconds: 59),
    '$_covers/remix-disc.jpg',
    Color(0xFF1A237E),
  ),
  MediaModel(
    'Dj Brainiak',
    'Speed of light',
    Duration(minutes: 4, seconds: 59),
    '$_covers/dj-disc.jpg',
    Color(0xFF311B92),
  ),
  MediaModel(
    'Back to the 80\'s',
    'Disco revenge',
    Duration(minutes: 4, seconds: 59),
    '$_covers/80s-disc.jpg',
    Color(0xFF880E4F),
  ),
  MediaModel(
    'PeacefulMind',
    'Never look at back',
    Duration(minutes: 4, seconds: 59),
    '$_covers/old-disc.jpg',
    Color(0xFF004D40),
  ),
];

///  *********************************************
///     SIMULATED PLAYER (0.12 MediaPlayerCentral)
///  *********************************************

enum MediaLifeCycle { stopped, paused, playing }

class MediaPlayerCentral {
  static final ValueNotifier<int> changes = ValueNotifier(0);

  /// Going back within this time restarts the track instead.
  static const replayTolerance = Duration(seconds: 4);

  static int _index = 0;
  static MediaLifeCycle lifeCycle = MediaLifeCycle.stopped;
  static Duration position = Duration.zero;
  static Timer? _clock;

  static MediaModel get current => playlist[_index];
  static bool get isPlaying => lifeCycle == MediaLifeCycle.playing;
  static bool get hasNext => _index < playlist.length - 1;
  static bool get hasPrevious => _index > 0;

  static void playPause() {
    lifeCycle = isPlaying ? MediaLifeCycle.paused : MediaLifeCycle.playing;
    isPlaying ? _start() : _clock?.cancel();
    _changed();
  }

  static void stop() {
    _clock?.cancel();
    lifeCycle = MediaLifeCycle.stopped;
    position = Duration.zero;
    _changed();
  }

  static void goTo(Duration moment) {
    position = moment > current.length ? current.length : moment;
    _changed();
  }

  static void next() {
    if (!hasNext) return stop();
    _index++;
    position = Duration.zero;
    _changed();
  }

  static void previous() {
    if (position < replayTolerance && hasPrevious) _index--;
    position = Duration.zero;
    _changed();
  }

  /// A command from the system's media controls.
  static void handle(MediaCommand command) {
    switch (command.control) {
      case MediaControl.play:
      case MediaControl.pause:
        playPause();
      case MediaControl.stop:
        stop();
      case MediaControl.skipNext:
        next();
      case MediaControl.skipPrevious:
        previous();
      case MediaControl.seekTo:
        goTo(command.position ?? position);
      case MediaControl.skipForward:
      case MediaControl.fastForward:
        goTo(position + const Duration(seconds: 15));
      case MediaControl.skipBackward:
      case MediaControl.rewind:
        goTo(
          position - const Duration(seconds: 15) < Duration.zero
              ? Duration.zero
              : position - const Duration(seconds: 15),
        );
    }
  }

  static void _start() {
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      position += const Duration(seconds: 1);
      if (position >= current.length) {
        hasNext ? next() : stop();
      } else {
        changes.value++; // the screen's progress; the system advances its own
      }
    });
  }

  static void _changed() {
    changes.value++;
    SilentAudio.sync(isPlaying);
    _updateMediaControls();
  }

  /// Sends the player's state to the system's media controls (only on real
  /// changes: the system advances the position by itself while playing).
  static Future<void> _updateMediaControls() async {
    if (lifeCycle == MediaLifeCycle.stopped) {
      await AwesomeNotificationsMedia().stop(_sessionId);
      return;
    }
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _notificationId,
        channelKey: _channelKey,
        notificationLayout: NotificationLayout.MediaPlayer,
        autoDismissible: false,
      ),
      extensions: [
        NotificationMedia(
          sessionId: _sessionId,
          title: current.track,
          artist: current.band,
          artwork: current.cover,
          duration: current.length,
          position: position,
          state: isPlaying
              ? NotificationPlayState.playing
              : NotificationPlayState.paused,
          controls: {
            MediaControl.skipPrevious,
            isPlaying ? MediaControl.pause : MediaControl.play,
            if (hasNext) MediaControl.skipNext,
            MediaControl.seekTo,
            MediaControl.stop,
          },
        ),
      ],
    );
  }
}

///  *********************************************
///     SCREEN (0.12 MediaDetailsPage)
///  *********************************************

class MediaExampleApp extends StatelessWidget {
  const MediaExampleApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
    title: 'Awesome Notifications Media',
    debugShowCheckedModeBanner: false,
    home: MediaPlayerPage(),
  );
}

class MediaPlayerPage extends StatefulWidget {
  const MediaPlayerPage({super.key});

  @override
  State<MediaPlayerPage> createState() => _MediaPlayerPageState();
}

class _MediaPlayerPageState extends State<MediaPlayerPage> {
  bool closeCaptionOn = false;
  bool isDragging = false;
  Duration dragged = Duration.zero;

  @override
  void initState() {
    super.initState();
    AwesomeNotifications().isNotificationAllowed().then((allowed) {
      if (!allowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: MediaPlayerCentral.changes,
      builder: (context, _, _) => _buildPlayer(context),
    );
  }

  Widget _buildPlayer(BuildContext context) {
    final media = MediaPlayerCentral.current;
    final contrast = media.color.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
    final size = MediaQuery.sizeOf(context);
    final maxSize = max(size.width, size.height);
    final position = isDragging ? dragged : MediaPlayerCentral.position;

    // White status bar text and icons over the album's dark color.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Theme(
        data: ThemeData(
          brightness: contrast == Colors.white
              ? Brightness.dark
              : Brightness.light,
          scaffoldBackgroundColor: media.color,
          iconTheme: IconThemeData(color: contrast),
          sliderTheme: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: contrast,
            inactiveTrackColor: contrast.withValues(alpha: 0.24),
            thumbColor: contrast,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 16),
          ),
        ),
        child: Builder(
          builder: (context) {
            return Scaffold(
              body: Stack(
                children: [
                  // The cover, blurred into the album color.
                  Positioned.fill(
                    child: Image.network(
                      media.cover,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                  Positioned.fill(
                    child: ColoredBox(
                      color: media.color.withValues(alpha: 0.92),
                    ),
                  ),
                  SafeArea(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      children: [
                        _art(media, size, maxSize, contrast, position),
                        const SizedBox(height: 24),
                        Text(
                          media.band,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: contrast,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          media.track,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: contrast, fontSize: 20),
                        ),
                        const SizedBox(height: 16),
                        _trackBar(media, position, contrast),
                        _controls(maxSize, contrast),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _art(
    MediaModel media,
    Size size,
    double maxSize,
    Color contrast,
    Duration position,
  ) {
    final height = maxSize * 0.4;
    final caption = closeCaptions
        .where((c) => c.start <= position && c.end >= position)
        .map((c) => c.subtitle)
        .firstOrNull;
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: closeCaptionOn ? 0.08 : 1,
            child: ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.black, Colors.transparent],
                stops: [0, 0.76, 0.96],
              ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height)),
              blendMode: BlendMode.dstIn,
              child: Image.network(
                media.cover,
                height: height,
                width: size.width,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    ColoredBox(color: contrast.withValues(alpha: 0.64)),
              ),
            ),
          ),
          if (closeCaptionOn)
            Text(
              caption ?? '',
              style: TextStyle(color: contrast, fontSize: 20),
            ),
        ],
      ),
    );
  }

  Widget _trackBar(MediaModel media, Duration position, Color contrast) {
    final max = media.length.inSeconds.toDouble();
    return Column(
      children: [
        Slider(
          min: 0,
          max: max,
          value: min(max, position.inSeconds.toDouble()),
          onChangeStart: (_) => setState(() {
            isDragging = true;
            dragged = MediaPlayerCentral.position;
          }),
          onChanged: (value) =>
              setState(() => dragged = Duration(seconds: value.toInt())),
          onChangeEnd: (_) {
            setState(() => isDragging = false);
            MediaPlayerCentral.goTo(dragged);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_print(position), style: TextStyle(color: contrast)),
              IconButton(
                icon: Icon(
                  Icons.closed_caption,
                  size: 48,
                  color: closeCaptionOn
                      ? contrast
                      : contrast.withValues(alpha: 0.48),
                ),
                onPressed: () =>
                    setState(() => closeCaptionOn = !closeCaptionOn),
              ),
              Text(_print(media.length), style: TextStyle(color: contrast)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _controls(double maxSize, Color contrast) {
    final small = maxSize * 0.05;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous),
          iconSize: small,
          onPressed: MediaPlayerCentral.previous,
        ),
        IconButton(
          icon: const Icon(Icons.stop),
          iconSize: small,
          onPressed: MediaPlayerCentral.stop,
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: contrast.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              MediaPlayerCentral.isPlaying
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_filled,
            ),
            padding: EdgeInsets.zero,
            iconSize: maxSize * 0.08,
            onPressed: MediaPlayerCentral.playPause,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.skip_next),
          iconSize: small,
          onPressed: MediaPlayerCentral.hasNext
              ? MediaPlayerCentral.next
              : null,
        ),
      ],
    );
  }

  static String _print(Duration duration) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(duration.inMinutes)}:${two(duration.inSeconds.remainder(60))}';
  }
}
