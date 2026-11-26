// awesome_notifications_calls example: the phone call screen of the 0.12
// example app, in one file. The call is simulated (no audio): the package
// never carries the call, it shows the system's call UI for the app's call and
// sends the user's answers back.
import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_calls/awesome_notifications_calls.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The caller's photo of the 0.12 example, pinned to a commit so it never moves.
const _callerPhoto =
    'https://raw.githubusercontent.com/rafaelsetragni/awesome_notifications/'
    '46032aae60fb47f3c372676c77bb59e470956339/example/assets/images/girl-phonecall.jpg';

const _channelKey = 'calls';
const _notificationId = 300;

const _caller = NotificationPerson(
  key: 'little-mary',
  name: 'Little Mary',
  avatar: _callerPhoto,
  uri: 'tel:+5511999999999',
);

final _navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AwesomeNotifications().initialize(
    // The status bar icon: a white glyph on transparent (Android draws only
    // its alpha). Without it, the full-color app icon shows as a square.
    'resource://drawable/res_notification_icon',
    [
      NotificationChannel(
        channelKey: _channelKey,
        channelName: 'Calls',
        channelDescription: 'Incoming and ongoing calls',
        importance: NotificationImportance.Max,
        defaultRingtoneType: DefaultRingtoneType.Ringtone,
        playSound: true,
        enableVibration: true,
      ),
    ],
  );
  await AwesomeNotifications().setListeners(
    onActionReceivedMethod: onActionReceivedMethod,
    onNotificationDisplayedMethod: onNotificationDisplayedMethod,
  );
  runApp(const CallsExampleApp());
}

/// The answers from the system's call UI (and any other notification action)
/// land here, also with the app killed.
@pragma('vm:entry-point')
Future<void> onActionReceivedMethod(ReceivedAction action) async {
  final command = AwesomeNotificationsCalls.commandOf(action);
  if (command != null) {
    CallCentral.handle(command);
  } else if (AwesomeNotificationsCalls.callIdOf(action) case final callId?) {
    // A tap on the call's notification: show the call.
    CallCentral.open(callId);
  }
}

/// A call that starts ringing while the app is open shows the app's own
/// ringing screen (also a call that arrived by push).
@pragma('vm:entry-point')
Future<void> onNotificationDisplayedMethod(
  ReceivedNotification notification,
) async {
  final callId = AwesomeNotificationsCalls.callIdOf(notification);
  // Not the call (e.g. its missed call notification).
  if (callId == null || notification.id != _notificationId) return;
  final state = CallCentral.state.value;
  final ringing =
      state == null ||
      state == CallState.incoming ||
      callId != CallCentral.callId;
  if (!ringing) return;
  if (callId != CallCentral.callId) {
    CallCentral.callId = callId;
    CallCentral.state.value = CallState.incoming;
  }
  if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
    CallCentral.open(callId);
  }
}

///  *********************************************
///     CALL CENTRAL
///  *********************************************

/// The app's side of the call: what the package can't know (the call's
/// audio, its screen). Here it only keeps the state of a simulated call.
class CallCentral {
  static final state = ValueNotifier<CallState?>(null);
  static String? callId;
  static bool video = false;
  static DateTime? startedAt;
  static final muted = ValueNotifier<bool>(false);

  static NotificationCall _call(CallState state) => NotificationCall(
    callId: callId!,
    caller: _caller,
    handle: _caller.uri,
    video: video,
    state: state,
    startedAt: startedAt,
    ringTimeout: const Duration(seconds: 30),
  );

  static Future<void> _send(CallState newState) async {
    state.value = newState;
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _notificationId,
        channelKey: _channelKey,
        title: _caller.name,
        largeIcon: _callerPhoto,
        category: NotificationCategory.Call,
      ),
      extensions: [_call(newState)],
    );
  }

  /// A call from Little Mary, after [delay] (time to lock the screen).
  static Future<void> simulateIncoming({
    required bool video,
    Duration delay = Duration.zero,
  }) async {
    await Future<void>.delayed(delay);
    callId = 'call-${DateTime.now().millisecondsSinceEpoch}';
    CallCentral.video = video;
    startedAt = null;
    muted.value = false;
    await _send(CallState.incoming);
  }

  /// A call the user starts in the app.
  static Future<void> startOutgoing() async {
    callId = 'call-${DateTime.now().millisecondsSinceEpoch}';
    video = false;
    startedAt = null;
    muted.value = false;
    await _send(CallState.outgoing);
    open(callId!);
    // Little Mary answers after 4 seconds.
    Timer(const Duration(seconds: 4), () {
      if (state.value == CallState.outgoing) answer();
    });
  }

  /// Answered (in the app, by the system UI or by the other side).
  static Future<void> answer() async {
    if (callId == null) return;
    startedAt ??= DateTime.now();
    await _send(CallState.ongoing);
  }

  static Future<void> hangUp() async {
    final id = callId;
    if (id == null) return;
    await AwesomeNotificationsCalls().endCall(id);
    // After the system call ended, so the app reads the calls without it.
    state.value = CallState.ended;
  }

  static Future<void> toggleHold() async {
    if (callId == null) return;
    await _send(
      state.value == CallState.held ? CallState.ongoing : CallState.held,
    );
  }

  /// The commands of the system's call UI. The package already applied them
  /// to the system call: the app only follows.
  static void handle(CallCommand command) {
    if (command.callId != null && command.callId != callId) {
      callId = command.callId;
    }
    switch (command.action) {
      case CallAction.accept:
        startedAt ??= DateTime.now();
        state.value = CallState.ongoing;
        // Send the ongoing state with its start time (the call's timer).
        unawaited(answer());
        open(callId!);
      case CallAction.decline:
      case CallAction.hangUp:
        state.value = CallState.ended;
      case CallAction.timeout:
        state.value = CallState.missed;
      case CallAction.mute:
        muted.value = true;
      case CallAction.unmute:
        muted.value = false;
      case CallAction.hold:
        state.value = CallState.held;
      case CallAction.unhold:
        state.value = CallState.ongoing;
      case CallAction.audioActivated:
      case CallAction.audioDeactivated:
        // iOS: a real app starts (or stops) the call's audio here.
        break;
    }
  }

  /// Whether the call screen is on top.
  static bool pageOpen = false;

  static void open(String id) {
    callId ??= id;
    state.value ??= CallState.incoming;
    if (pageOpen) return;
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;
    navigator.popUntil((route) => route.isFirst);
    pageOpen = true;
    navigator
        .push(MaterialPageRoute<void>(builder: (_) => const PhoneCallPage()))
        .whenComplete(() => pageOpen = false);
  }
}

///  *********************************************
///     HOME PAGE
///  *********************************************

class CallsExampleApp extends StatelessWidget {
  const CallsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Awesome Calls',
      navigatorKey: _navigatorKey,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF7B0AC4)),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  CallCapabilities? _capabilities;
  bool? _fullScreen;
  String? _voipToken;
  List<ActiveCall> _active = const [];
  StreamSubscription<String>? _tokens;
  StreamSubscription<CallCommand>? _commands;

  @override
  void initState() {
    super.initState();
    _refresh();
    _tokens = AwesomeNotificationsCalls().onVoipToken.listen((token) {
      setState(() => _voipToken = token);
    });
    CallCentral.state.addListener(_refreshActive);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _tokens?.cancel();
    _commands?.cancel();
    CallCentral.state.removeListener(_refreshActive);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The app came to the front while a call rings (Android's full-screen
  /// intent over the lock screen, a tap on the app): show the ringing screen.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final callId = CallCentral.callId;
    if (state == AppLifecycleState.resumed &&
        callId != null &&
        CallCentral.state.value == CallState.incoming) {
      CallCentral.open(callId);
    }
  }

  Future<void> _refresh() async {
    final calls = AwesomeNotificationsCalls();
    if (!await AwesomeNotifications().isNotificationAllowed()) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
    final capabilities = await calls.capabilities();
    final fullScreen = await calls.canUseFullScreenIntent();
    final token = await calls.voipToken();
    if (!mounted) return;
    setState(() {
      _capabilities = capabilities;
      _fullScreen = fullScreen;
      _voipToken = token;
    });
    await _refreshActive();
  }

  Future<void> _refreshActive() async {
    final active = await AwesomeNotificationsCalls().activeCalls();
    if (mounted) setState(() => _active = active);
  }

  @override
  Widget build(BuildContext context) {
    final capabilities = _capabilities;
    return Scaffold(
      appBar: AppBar(title: const Text('Awesome Calls')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Section('Incoming calls'),
          const Text(
            'Lock the screen after tapping: the call rings over the lock screen.',
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            icon: const Icon(Icons.call),
            label: const Text('Incoming call in 5 seconds'),
            onPressed: () => CallCentral.simulateIncoming(
              video: false,
              delay: const Duration(seconds: 5),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.videocam),
            label: const Text('Incoming video call in 5 seconds'),
            onPressed: () => CallCentral.simulateIncoming(
              video: true,
              delay: const Duration(seconds: 5),
            ),
          ),
          const _Section('Outgoing calls'),
          OutlinedButton.icon(
            icon: const Icon(Icons.phone_forwarded),
            label: const Text('Call Little Mary'),
            onPressed: CallCentral.startOutgoing,
          ),
          const _Section('Active calls'),
          if (_active.isEmpty) const Text('None'),
          for (final call in _active)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone_in_talk),
              title: Text(call.callId),
              subtitle: Text(call.state.name),
              trailing: IconButton(
                icon: const Icon(Icons.call_end, color: Colors.red),
                onPressed: () =>
                    AwesomeNotificationsCalls().endCall(call.callId),
              ),
            ),
          const _Section('This platform'),
          if (capabilities == null)
            const Text('…')
          else ...[
            _Fact('System call UI', capabilities.systemCallUI),
            _Fact('Over the lock screen', capabilities.lockScreen),
            _Fact('Mute and hold', capabilities.muteAndHold),
            _Fact('Calls by push', capabilities.push),
          ],
          if (_fullScreen == false) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                final allowed = await AwesomeNotificationsCalls()
                    .requestFullScreenIntent();
                setState(() => _fullScreen = allowed);
              },
              child: const Text('Allow full-screen calls'),
            ),
          ],
          if (_voipToken != null) ...[
            const _Section('VoIP push token'),
            SelectableText(
              _voipToken!,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Copy'),
                onPressed: () =>
                    Clipboard.setData(ClipboardData(text: _voipToken!)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);
  final String label;
  final bool value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        value ? Icons.check_circle : Icons.cancel,
        size: 20,
        color: value ? Colors.green : Colors.grey,
      ),
      const SizedBox(width: 8),
      Text(label),
    ],
  );
}

///  *********************************************
///     PHONE CALL PAGE (0.12 example)
///  *********************************************

class PhoneCallPage extends StatefulWidget {
  const PhoneCallPage({super.key});

  @override
  State<PhoneCallPage> createState() => _PhoneCallPageState();
}

class _PhoneCallPageState extends State<PhoneCallPage> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  /// A video call shows your camera from the moment it rings.
  _SelfCamera? _camera;

  bool get _inCall =>
      CallCentral.state.value == CallState.ongoing ||
      CallCentral.state.value == CallState.held;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    CallCentral.state.addListener(_onState);
    _onState();
  }

  void _onState() {
    final state = CallCentral.state.value;
    if (state == CallState.ended ||
        state == CallState.missed ||
        state == null) {
      if (mounted) Navigator.of(context).maybePop();
      return;
    }
    if (CallCentral.video && _camera == null) {
      _camera = _SelfCamera()..start();
    }
    if (_inCall && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        final startedAt = CallCentral.startedAt;
        if (startedAt != null) {
          setState(() => _elapsed = DateTime.now().difference(startedAt));
        }
      });
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _camera?.dispose();
    CallCentral.state.removeListener(_onState);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  String get _status => switch (CallCentral.state.value) {
    CallState.outgoing => 'Calling…',
    CallState.held => 'On hold: ${_printDuration(_elapsed)}',
    CallState.ongoing => 'Call in progress: ${_printDuration(_elapsed)}',
    _ => CallCentral.video ? 'Incoming video call' : 'Incoming call',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final ringing = CallCentral.state.value == CallState.incoming;

    final camera = _camera;
    if (camera != null && _inCall) {
      return _VideoCallView(status: _status, camera: camera);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Material(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // A video call shows your camera while it rings; a voice call,
            // the caller's photo.
            camera?.view() ??
                Image.network(
                  _callerPhoto,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox(),
                ),
            const DecoratedBox(
              decoration: BoxDecoration(color: Colors.black45),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SafeArea(
                child: Column(
                  children: [
                    Text(
                      _caller.name.replaceAll(' ', '\n'),
                      maxLines: 4,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _status,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white54,
                        fontSize: ringing ? 20 : 12,
                      ),
                    ),
                    const SizedBox(height: 48),
                    if (ringing)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _TextIconButton(
                            icon: Icons.schedule,
                            label: 'Remind me',
                            onPressed: () {},
                          ),
                          _TextIconButton(
                            icon: Icons.mail,
                            label: 'Message',
                            onPressed: () {},
                          ),
                        ],
                      ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.all(Radius.circular(44)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: ringing
                            ? [
                                _RoundedButton(
                                  color: Colors.red,
                                  icon: const Icon(
                                    Icons.call_end,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    CallCentral.hangUp();
                                  },
                                ),
                                _SlideToConfirm(
                                  width: width * 0.56,
                                  text: 'Slide to Talk',
                                  onConfirmation: () {
                                    HapticFeedback.mediumImpact();
                                    CallCentral.answer();
                                  },
                                ),
                              ]
                            : [
                                ValueListenableBuilder<bool>(
                                  valueListenable: CallCentral.muted,
                                  builder: (_, muted, _) => _RoundedButton(
                                    color: muted
                                        ? Colors.white54
                                        : Colors.white,
                                    icon: Icon(
                                      muted ? Icons.mic_off : Icons.mic,
                                      color: Colors.black,
                                    ),
                                    onPressed: () =>
                                        CallCentral.muted.value = !muted,
                                  ),
                                ),
                                _RoundedButton(
                                  color: Colors.red,
                                  icon: const Icon(
                                    Icons.call_end,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    CallCentral.hangUp();
                                  },
                                ),
                                _RoundedButton(
                                  color:
                                      CallCentral.state.value == CallState.held
                                      ? Colors.white54
                                      : Colors.white,
                                  icon: const Icon(
                                    Icons.pause,
                                    color: Colors.black,
                                  ),
                                  onPressed: CallCentral.toggleHold,
                                ),
                              ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

///  *********************************************
///     VIDEO CALL (simulated)
///  *********************************************

/// Your camera during a video call: opened when the video call starts to
/// ring and kept through the call, so answering doesn't reopen it.
class _SelfCamera extends ChangeNotifier {
  List<CameraDescription> _cameras = const [];
  CameraController? _controller;
  bool _failed = false;
  bool _disposed = false;

  bool get canFlip => _cameras.length > 1;

  Future<void> start([CameraDescription? description]) async {
    try {
      if (_cameras.isEmpty) _cameras = await availableCameras();
      if (_cameras.isEmpty) throw CameraException('none', 'No camera');
      final chosen =
          description ??
          _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
            orElse: () => _cameras.first,
          );
      final previous = _controller;
      final controller = CameraController(
        chosen,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (_disposed) {
        await controller.dispose();
        return;
      }
      _controller = controller;
      notifyListeners();
      await previous?.dispose();
    } catch (e) {
      // No camera here (macOS, Linux, a denied permission…): an icon instead.
      debugPrint('Camera unavailable: $e');
      if (_disposed) return;
      _failed = true;
      notifyListeners();
    }
  }

  void flip() {
    final current = _controller?.description;
    if (current == null || !canFlip) return;
    start(
      _cameras.firstWhere(
        (c) => c.lensDirection != current.lensDirection,
        orElse: () => current,
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _controller?.dispose();
    super.dispose();
  }

  /// The camera's image, cropped to fill its box.
  Widget view() => ListenableBuilder(
    listenable: this,
    builder: (_, _) {
      final camera = _controller;
      if (camera == null || !camera.value.isInitialized) {
        return ColoredBox(
          color: const Color(0xFF202124),
          child: Center(
            child: _failed
                ? const Icon(
                    Icons.videocam_off,
                    color: Colors.white54,
                    size: 48,
                  )
                : const CircularProgressIndicator(color: Colors.white54),
          ),
        );
      }
      final size = camera.value.previewSize;
      return ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            // The preview size is in the sensor's (landscape) orientation.
            width: size?.height ?? 300,
            height: size?.width ?? 400,
            child: CameraPreview(camera),
          ),
        ),
      );
    },
  );
}

/// The answered video call: your camera, and Little Mary in the small square
/// (simulated: her photo, moving). Tap the small square to swap them.
class _VideoCallView extends StatefulWidget {
  const _VideoCallView({required this.status, required this.camera});
  final String status;
  final _SelfCamera camera;

  @override
  State<_VideoCallView> createState() => _VideoCallViewState();
}

class _VideoCallViewState extends State<_VideoCallView> {
  bool _selfBig = true;

  @override
  Widget build(BuildContext context) {
    final self = widget.camera.view();
    final big = _selfBig ? self : const _SimulatedRemote();
    final small = _selfBig ? const _SimulatedRemote() : self;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Material(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            big,
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _caller.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            shadows: [Shadow(blurRadius: 8)],
                          ),
                        ),
                        Text(
                          widget.status,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            shadows: [Shadow(blurRadius: 8)],
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => setState(() => _selfBig = !_selfBig),
                        child: Container(
                          width: 112,
                          height: 160,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                            boxShadow: const [
                              BoxShadow(blurRadius: 12, color: Colors.black45),
                            ],
                          ),
                          child: small,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.all(Radius.circular(44)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ValueListenableBuilder<bool>(
                              valueListenable: CallCentral.muted,
                              builder: (_, muted, _) => _RoundedButton(
                                color: muted ? Colors.white54 : Colors.white,
                                icon: Icon(
                                  muted ? Icons.mic_off : Icons.mic,
                                  color: Colors.black,
                                ),
                                onPressed: () =>
                                    CallCentral.muted.value = !muted,
                              ),
                            ),
                            _RoundedButton(
                              color: Colors.red,
                              icon: const Icon(
                                Icons.call_end,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                CallCentral.hangUp();
                              },
                            ),
                            _RoundedButton(
                              color: widget.camera.canFlip
                                  ? Colors.white
                                  : Colors.white24,
                              icon: const Icon(
                                Icons.cameraswitch,
                                color: Colors.black,
                              ),
                              onPressed: widget.camera.flip,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Little Mary's side of the call, simulated with her photo moving gently.
class _SimulatedRemote extends StatefulWidget {
  const _SimulatedRemote();

  @override
  State<_SimulatedRemote> createState() => _SimulatedRemoteState();
}

class _SimulatedRemoteState extends State<_SimulatedRemote>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF202124),
      child: AnimatedBuilder(
        animation: _motion,
        builder: (_, child) {
          final t = Curves.easeInOut.transform(_motion.value);
          return Transform.scale(
            scale: 1.04 + 0.04 * t,
            alignment: Alignment(0.2 * t - 0.1, -0.2),
            child: child,
          );
        },
        child: Image.network(
          _callerPhoto,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, _, _) => const Center(
            child: Icon(Icons.person, color: Colors.white54, size: 48),
          ),
        ),
      ),
    );
  }
}

String _printDuration(Duration duration) {
  String two(int n) => n.toString().padLeft(2, '0');
  final hours = duration.inHours;
  final minutes = two(duration.inMinutes.remainder(60));
  final seconds = two(duration.inSeconds.remainder(60));
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

class _TextIconButton extends StatelessWidget {
  const _TextIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(overlayColor: Colors.white12),
    child: Column(
      children: [
        Icon(icon, color: Colors.white54),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    ),
  );
}

class _RoundedButton extends StatelessWidget {
  const _RoundedButton({
    required this.icon,
    required this.onPressed,
    this.color = Colors.white,
  });
  final Icon icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 64,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.all(16),
        shape: const CircleBorder(),
      ),
      onPressed: onPressed,
      child: icon,
    ),
  );
}

/// The 0.12 example's "Slide to Talk": drag the green phone to the end.
class _SlideToConfirm extends StatefulWidget {
  const _SlideToConfirm({
    required this.width,
    required this.text,
    required this.onConfirmation,
  });
  final double width;
  final String text;
  final VoidCallback onConfirmation;

  @override
  State<_SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<_SlideToConfirm> {
  static const _thumb = 64.0;
  double _offset = 0;

  double get _end => widget.width - _thumb;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: _thumb,
      decoration: const BoxDecoration(
        color: Colors.white60,
        borderRadius: BorderRadius.all(Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(left: _thumb),
              child: Text(
                widget.text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.width * 0.08,
                ),
              ),
            ),
          ),
          Positioned(
            left: _offset,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) => setState(
                () => _offset = (_offset + details.delta.dx).clamp(0, _end),
              ),
              onHorizontalDragEnd: (_) {
                if (_offset >= _end - 4) {
                  setState(() => _offset = _end);
                  widget.onConfirmation();
                } else {
                  setState(() => _offset = 0);
                }
              },
              child: const CircleAvatar(
                radius: _thumb / 2,
                backgroundColor: Colors.white,
                child: Icon(Icons.call, color: Colors.green),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
