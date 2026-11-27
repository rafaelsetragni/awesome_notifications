// Awesome Live: the awesome_notifications_live_activities example.
//
// Three live activities, each one notification with a `liveActivity` block:
// a delivery (segmented progress, countdown, Track / Cancel), a match (two
// metrics, a running clock, goal buttons that update it from the Lock
// Screen) and a focus timer (countdown only). iOS shows them as Live
// Activities (Lock Screen, Dynamic Island), Android 16+ as Live Updates
// (status bar chip), and macOS, Windows, Linux and Web as their notification,
// updated in place.
//
// Each activity keeps its state in the notification's payload, so a button
// pressed with the app in the background still knows what to send next.
import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_live_activities/awesome_notifications_live_activities.dart';
import 'package:flutter/material.dart';

const _channel = 'live_activities';
const _purple = Color(0xFF7B0AC4);
const _pink = Color(0xFFC2188E);

const _deliveryId = 400;
const _matchId = 401;
const _focusId = 402;

/// What every screen shows at the bottom: actions, statuses and tokens.
final _log = ValueNotifier<List<String>>([]);

void _add(String line) {
  final time = TimeOfDay.now();
  final stamp = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  _log.value = ['$stamp  $line', ..._log.value].take(30).toList();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AwesomeNotifications().initialize('resource://drawable/res_notification_icon', [
    NotificationChannel(
      channelKey: _channel,
      channelName: 'Live activities',
      channelDescription: 'Deliveries, matches and timers that update in place',
      defaultColor: _purple,
      importance: NotificationImportance.High,
    ),
  ]);
  await AwesomeNotifications().setListeners(onActionReceivedMethod: onAction);
  runApp(const LiveApp());
}

/// Every press of an activity's button, and every tap on one.
@pragma('vm:entry-point')
Future<void> onAction(ReceivedAction action) async {
  final payload = action.payload ?? const {};
  final key = action.buttonKeyPressed;
  _add(
    'action ${key.isEmpty ? 'tap' : key} on ${AwesomeNotificationsLiveActivities.activityIdOf(action)}',
  );
  switch (payload['demo']) {
    case 'delivery':
      if (key == 'TRACK') await Delivery.advance(Delivery.stepOf(payload));
      if (key == 'CANCEL') await Delivery.cancel();
    case 'match':
      if (key == 'GOAL_HOME' || key == 'GOAL_AWAY') {
        await Match.goal(Match.fromPayload(payload), home: key == 'GOAL_HOME');
      }
    case 'focus':
      if (key == 'PLUS_5') await Focus.extend(Focus.endOf(payload));
      if (key == 'STOP') await Focus.stop();
  }
}

// ---------------------------------------------------------------------------
// The three activities
// ---------------------------------------------------------------------------

/// A food delivery in five steps, on a three-part road: the store, the ride,
/// the door.
abstract final class Delivery {
  static const _steps = [
    ('Order received', 'The restaurant is preparing it', 8.0),
    ('Picked up', 'Your courier left the restaurant', 30.0),
    ('On the way', 'Riding to you', 60.0),
    ('Almost there', 'Your courier is around the corner', 88.0),
    ('Delivered', 'Enjoy your meal', 100.0),
  ];
  static const _minutesLeft = [25, 18, 10, 2, 0];

  /// The stage, in a few characters: the clock already tells the time.
  static const _stages = ['Cooking', 'Picked up', 'On way', 'Nearby', 'Here!'];

  static int stepOf(Map<String, String?> payload) => int.tryParse(payload['step'] ?? '') ?? 0;

  static Future<void> start() => _post(0);

  /// The next step; the last one ends the activity.
  static Future<void> advance(int step) => _post((step + 1).clamp(0, _steps.length - 1));

  static Future<void> cancel() => _post(-1);

  static Future<void> _post(int step) async {
    final cancelled = step < 0;
    final last = step == _steps.length - 1;
    final (title, body, progress) = cancelled
        ? ('Order cancelled', 'No charge was made', 0.0)
        : _steps[step];
    final minutes = cancelled ? 0 : _minutesLeft[step];
    await _postActivity(
      content: NotificationContent(
        id: _deliveryId,
        channelKey: _channel,
        title: title,
        body: body,
        progress: progress,
        largeIcon: 'https://picsum.photos/id/1080/256/256',
        payload: {'demo': 'delivery', 'step': '$step'},
      ),
      actionButtons: cancelled || last
          ? null
          : [
              NotificationActionButton(
                key: 'TRACK',
                label: 'Next step',
                actionType: ActionType.SilentAction,
                autoDismissible: false,
              ),
              NotificationActionButton(
                key: 'CANCEL',
                label: 'Cancel order',
                actionType: ActionType.SilentAction,
                isDangerousOption: true,
                autoDismissible: false,
              ),
            ],
      activity: NotificationLiveActivity(
        activityId: 'delivery',
        state: cancelled || last ? LiveActivityState.ended : LiveActivityState.active,
        shortText: cancelled ? 'Cancelled' : _stages[step],
        accentColor: _pink,
        progress: const LiveActivityProgress(
          segments: [
            LiveActivitySegment(25, color: Color(0xFFFFB300)),
            LiveActivitySegment(60, color: _pink),
            LiveActivitySegment(15, color: Color(0xFF43A047)),
          ],
          points: [
            LiveActivityPoint(25, color: Color(0xFFFFB300)),
            LiveActivityPoint(85, color: Color(0xFF43A047)),
          ],
        ),
        timer: cancelled || last
            ? null
            : LiveActivityTimer.countDown(end: DateTime.now().add(Duration(minutes: minutes))),
        // Delivered: a minute on the Lock Screen, then gone.
        dismissal: last
            ? LiveActivityDismissal.at(DateTime.now().add(const Duration(minutes: 1)))
            : LiveActivityDismissal.immediate,
        alert: last,
      ),
    );
    _add(cancelled ? 'delivery cancelled' : 'delivery: $title');
  }
}

/// A match, drawn as a scoreboard (the versus layout): each team's logo,
/// name and score, the half and the clock running by itself between them,
/// the latest play below. Goals come from the app or straight from the
/// activity's buttons.
class Match {
  final int home, away;
  final DateTime kickOff;

  const Match(this.home, this.away, this.kickOff);

  static Match fromPayload(Map<String, String?> payload) => Match(
    int.tryParse(payload['home'] ?? '') ?? 0,
    int.tryParse(payload['away'] ?? '') ?? 0,
    DateTime.fromMillisecondsSinceEpoch(int.tryParse(payload['kickOff'] ?? '') ?? 0),
  );

  static Future<void> start() => _post(Match(0, 0, DateTime.now()));

  static Future<void> goal(Match match, {required bool home}) => _post(
    Match(match.home + (home ? 1 : 0), match.away + (home ? 0 : 1), match.kickOff),
    alert: true,
    play: home ? 'Goal! The Lions finish a quick counterattack' : 'Goal! The Eagles head in a corner',
  );

  static Future<void> finish(Match match) => _post(match, ended: true);

  static Future<void> _post(Match m, {bool alert = false, bool ended = false, String? play}) async {
    await _postActivity(
      content: NotificationContent(
        id: _matchId,
        channelKey: _channel,
        title: ended ? 'Full time' : 'Lions vs Eagles',
        body: ended
            ? (m.home == m.away ? 'A draw' : '${m.home > m.away ? 'Lions' : 'Eagles'} win')
            : play ?? 'Kick off! The Lions start with the ball',
        // The player of the latest play.
        largeIcon: 'https://picsum.photos/id/64/128/128',
        payload: {
          'demo': 'match',
          'home': '${m.home}',
          'away': '${m.away}',
          'kickOff': '${m.kickOff.millisecondsSinceEpoch}',
        },
      ),
      actionButtons: ended
          ? null
          : [
              NotificationActionButton(
                key: 'GOAL_HOME',
                label: 'Goal Lions',
                actionType: ActionType.SilentAction,
                autoDismissible: false,
              ),
              NotificationActionButton(
                key: 'GOAL_AWAY',
                label: 'Goal Eagles',
                actionType: ActionType.SilentAction,
                autoDismissible: false,
              ),
            ],
      activity: NotificationLiveActivity(
        activityId: 'match',
        state: ended ? LiveActivityState.ended : LiveActivityState.active,
        layout: LiveActivityLayout.versus,
        // Android 16+: the scoreboard (the package's own layout) instead of a
        // Live Update, which draws only the system's styles (no scoreboard).
        androidLiveUpdate: false,
        metrics: [
          LiveActivityMetric(
            label: 'LIO',
            value: '${m.home}',
            image: 'https://picsum.photos/id/1074/128/128',
          ),
          LiveActivityMetric(
            label: 'EAG',
            value: '${m.away}',
            image: 'https://picsum.photos/id/1024/128/128',
          ),
        ],
        shortText: ended ? 'Final' : '2nd half',
        accentColor: _purple,
        timer: ended ? null : LiveActivityTimer.elapsed(start: m.kickOff),
        alert: alert,
      ),
    );
    _add(ended ? 'match over ${m.home}–${m.away}' : 'match ${m.home}–${m.away}');
  }
}

/// A focus timer: a countdown the system runs, no progress bar.
abstract final class Focus {
  static DateTime endOf(Map<String, String?> payload) =>
      DateTime.fromMillisecondsSinceEpoch(int.tryParse(payload['end'] ?? '') ?? 0);

  static Future<void> start() => _post(DateTime.now().add(const Duration(minutes: 25)));

  static Future<void> extend(DateTime end) =>
      _post((end.isBefore(DateTime.now()) ? DateTime.now() : end).add(const Duration(minutes: 5)));

  static Future<void> stop() async {
    await AwesomeNotificationsLiveActivities().end(
      'focus',
      dismissal: LiveActivityDismissal.immediate,
    );
    _add('focus stopped');
  }

  static Future<void> _post(DateTime end) async {
    final start = DateTime.now();
    await _postActivity(
      content: NotificationContent(
        id: _focusId,
        channelKey: _channel,
        title: 'Deep work',
        body:
            'Focus until ${TimeOfDay.fromDateTime(end).hour.toString().padLeft(2, '0')}:'
            '${TimeOfDay.fromDateTime(end).minute.toString().padLeft(2, '0')}',
        payload: {'demo': 'focus', 'end': '${end.millisecondsSinceEpoch}'},
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'PLUS_5',
          label: '+5 min',
          actionType: ActionType.SilentAction,
          autoDismissible: false,
        ),
        NotificationActionButton(
          key: 'STOP',
          label: 'Stop',
          actionType: ActionType.SilentAction,
          autoDismissible: false,
        ),
      ],
      activity: NotificationLiveActivity(
        activityId: 'focus',
        // The app's own layout: android/app/src/main/res/layout/focus_timer.xml
        // and, on iOS, FocusTimerView in ios/LiveActivityWidget.
        customLayout: 'focus_timer',
        shortText: 'Focus',
        accentColor: const Color(0xFF1E88E5),
        timer: LiveActivityTimer.countDown(start: start, end: end),
        staleAt: end,
      ),
    );
    _add('focus until ${TimeOfDay.fromDateTime(end).format24()}');
  }
}

extension on TimeOfDay {
  String format24() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// UI
// ---------------------------------------------------------------------------

class LiveApp extends StatelessWidget {
  const LiveApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Awesome Live',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: _purple, useMaterial3: true),
    darkTheme: ThemeData(colorSchemeSeed: _purple, useMaterial3: true, brightness: Brightness.dark),
    home: const HomePage(),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final _live = AwesomeNotificationsLiveActivities();
  final _subscriptions = <StreamSubscription<Object>>[];
  LiveActivityCapabilities? _capabilities;
  bool _allowed = false, _enabled = false;
  List<ActiveLiveActivity> _activities = const [];
  String? _pushToStartToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscriptions.addAll([
      _live.onStatusChanged.listen((a) {
        _add('${a.activityId} is ${a.status.name}');
        _refresh();
      }),
      _live.onPushToken.listen((t) => _add('push token of ${t.activityId}: ${_short(t.token)}')),
      _live.onPushToStartToken.listen((t) {
        _add('push-to-start token: ${_short(t)}');
        setState(() => _pushToStartToken = t);
      }),
    ]);
    _log.addListener(_refresh);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _log.removeListener(_refresh);
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  static String _short(String token) => token.length <= 12 ? token : '${token.substring(0, 12)}…';

  Future<void> _refresh() async {
    final capabilities = await _live.capabilities();
    final allowed = await AwesomeNotifications().isNotificationAllowed();
    final enabled = await _live.areEnabled();
    final activities = await _live.activities();
    final token = await _live.pushToStartToken();
    if (!mounted) return;
    setState(() {
      _capabilities = capabilities;
      _allowed = allowed;
      _enabled = enabled;
      _activities = activities;
      _pushToStartToken = token ?? _pushToStartToken;
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (!_allowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
    try {
      await action();
    } on Exception catch (e) {
      _add('refused: $e');
    }
    await _refresh();
  }

  ActiveLiveActivity? _activity(String id) =>
      _activities.where((a) => a.activityId == id).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final delivery = _activity('delivery');
    final match = _activity('match');
    final focus = _activity('focus');
    return Scaffold(
      appBar: AppBar(title: const Text('Awesome Live')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusCard(
            capabilities: _capabilities,
            allowed: _allowed,
            enabled: _enabled,
            pushToStartToken: _pushToStartToken,
            onAllow: () => _run(() async {
              if (!_allowed) await AwesomeNotifications().requestPermissionToSendNotifications();
              if (!await _live.areEnabled()) await _live.requestPermission();
            }),
          ),
          const SizedBox(height: 16),
          _DemoCard(
            icon: Icons.delivery_dining,
            title: 'Delivery',
            subtitle: 'Segmented progress, countdown, Next step and Cancel buttons',
            activity: delivery,
            actions: [
              FilledButton(
                onPressed: () => _run(Delivery.start),
                child: Text(delivery == null ? 'Order' : 'Order again'),
              ),
              OutlinedButton(
                onPressed: delivery?.status == LiveActivityStatus.active
                    ? () => _run(() async => Delivery.advance(await _deliveryStep()))
                    : null,
                child: const Text('Next step'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DemoCard(
            icon: Icons.sports_soccer,
            title: 'Match',
            subtitle: 'A scoreboard (versus layout), a running clock, goals from the Lock Screen',
            activity: match,
            actions: [
              FilledButton(onPressed: () => _run(Match.start), child: const Text('Kick off')),
              OutlinedButton(
                onPressed: match?.status == LiveActivityStatus.active
                    ? () => _run(() async => Match.goal(await _match(), home: true))
                    : null,
                child: const Text('Goal Lions'),
              ),
              OutlinedButton(
                onPressed: match?.status == LiveActivityStatus.active
                    ? () => _run(() async => Match.finish(await _match()))
                    : null,
                child: const Text('Full time'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DemoCard(
            icon: Icons.timer_outlined,
            title: 'Focus timer',
            subtitle: 'The app\'s own layout (customLayout): a 25 minute countdown',
            activity: focus,
            actions: [
              FilledButton(onPressed: () => _run(Focus.start), child: const Text('Start')),
              OutlinedButton(
                onPressed: focus != null ? () => _run(Focus.stop) : null,
                child: const Text('Stop'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _run(() => AwesomeNotifications().cancelAll()),
            icon: const Icon(Icons.clear_all),
            label: const Text('End everything (core cancelAll)'),
          ),
          const SizedBox(height: 24),
          Text('Events', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final line in _log.value)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(line, style: theme.textTheme.bodySmall),
            ),
          if (_log.value.isEmpty)
            Text(
              'Start an activity, then press its buttons from the notification.',
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  Future<Map<String, String?>> _payloadOf(int id) async => _lastPayload[id] ?? const {};

  Future<int> _deliveryStep() async => Delivery.stepOf(await _payloadOf(_deliveryId));
  Future<Match> _match() async => Match.fromPayload(await _payloadOf(_matchId));
}

/// The last payload posted for each demo, for the app's own buttons. (The
/// activity's buttons read theirs from the action, so they also work when the
/// app was killed.)
final Map<int, Map<String, String?>> _lastPayload = {};

/// Posts an activity and remembers its payload.
Future<bool> _postActivity({
  required NotificationContent content,
  List<NotificationActionButton>? actionButtons,
  required NotificationLiveActivity activity,
}) {
  _lastPayload[content.id!] = content.payload ?? const {};
  return AwesomeNotifications().createNotification(
    content: content,
    actionButtons: actionButtons,
    extensions: [activity],
  );
}

class _StatusCard extends StatelessWidget {
  final LiveActivityCapabilities? capabilities;
  final bool allowed, enabled;
  final String? pushToStartToken;
  final VoidCallback onAllow;

  const _StatusCard({
    required this.capabilities,
    required this.allowed,
    required this.enabled,
    required this.pushToStartToken,
    required this.onAllow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = capabilities;
    Widget chip(String label, bool on) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: on ? 0.24 : 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            on ? Icons.check_circle : Icons.remove_circle_outline,
            size: 16,
            color: Colors.white.withValues(alpha: on ? 1 : 0.6),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: on ? 1 : 0.6),
            ),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [_purple, _pink]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            c?.systemSurface == true
                ? 'This device shows live activities on its own surface'
                : 'This device shows live activities as a notification updated in place',
            style: theme.textTheme.titleSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              chip('System surface', c?.systemSurface == true),
              chip('Segments', c?.progressSegments == true),
              chip('Metrics', c?.metrics == true),
              chip('Buttons', c?.buttons == true),
              chip('Push', c?.push == true),
            ],
          ),
          if (!allowed || !enabled) ...[
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onAllow,
              child: Text(!allowed ? 'Allow notifications' : 'Allow live activities'),
            ),
          ],
          if (pushToStartToken != null) ...[
            const SizedBox(height: 12),
            SelectableText(
              'Push-to-start token: $pushToStartToken',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final ActiveLiveActivity? activity;
  final List<Widget> actions;

  const _DemoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.activity,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
                if (activity != null)
                  Text(
                    activity!.status.name,
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ),
      ),
    );
  }
}
