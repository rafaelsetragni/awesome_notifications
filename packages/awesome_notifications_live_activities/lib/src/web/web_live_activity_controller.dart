import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/services.dart';

import '../../awesome_notifications_live_activities.dart';
import '../live_activity_keys.dart';

/// The browser's notifications (`Notification`), behind an interface so the
/// logic is testable without a browser.
///
/// What a page can do on the web, without a service worker (the core has
/// none yet):
/// * it shows a page notification (`new Notification(…)`), replaced in place
///   when shown again with the same tag: silently with `renotify: false`,
///   alerting again with `renotify: true`;
/// * it keeps it on screen with `requireInteraction` (Chrome and Edge;
///   Firefox and Safari ignore it);
/// * a click on its body and its closing by the user reach the page;
/// * it can't have buttons (only a service worker's persistent notification
///   can), no live progress bar, no running clock: progress, metrics, timer
///   and short text are written into the body.
abstract class LiveNotificationApi {
  /// The browser shows notifications and the user allowed them.
  bool get available;

  /// Asks the browser for the permission: true when granted.
  Future<bool> requestPermission();

  /// Shows (or replaces, same [tag]) a notification. [onClose] runs when the
  /// user (or the browser) closes it, not on [close].
  void show(
    String tag, {
    required String title,
    required String body,
    String? icon,
    required bool requireInteraction,
    required bool renotify,
    required void Function() onClick,
    required void Function() onClose,
  });

  /// Closes the notification of [tag], when shown.
  void close(String tag);

  /// Brings the page to the front.
  void focusPage();
}

/// Emits the core's action event of a model.
typedef WebActionDispatcher = Future<void> Function(
  Map<String, dynamic> model, {
  required String buttonKey,
  String? input,
  Map<String, dynamic>? button,
});

typedef WebTimerFactory = Timer Function(Duration duration, void Function() callback);

/// The URL the browser loads an image from: http(s) as is, asset:// through
/// [assetUrl]; null for sources a page can't load (file://, resource://).
String? webImageUrlOf(String? image, String Function(String key) assetUrl) {
  if (image == null || image.isEmpty) return null;
  if (image.startsWith('http://') || image.startsWith('https://')) return image;
  const asset = 'asset://';
  if (image.startsWith(asset)) return assetUrl(image.substring(asset.length));
  return null;
}

const _invalidDetail = 'arguments.invalid.notificationLiveActivity';

PlatformException _invalid(String message, [String detail = _invalidDetail]) =>
    PlatformException(code: 'INVALID_ARGUMENTS', message: message, details: detail);

/// Validates a `liveActivity` block as `NotificationLiveActivity.validate`
/// does (a model may come from JSON without passing through Dart's model)
/// and returns it with its defaults filled in: the activityId defaults to
/// [notificationId]. Throws a [PlatformException] when it's invalid.
Map<String, dynamic> parseWebLiveActivity(Object? raw, int notificationId) {
  if (raw is! Map) throw _invalid('The liveActivity block must be a map');
  final block = Map<String, dynamic>.from(raw);

  String? optionalText(String key, String what) {
    final value = block[key];
    if (value == null) return null;
    if (value is! String || value.trim().isEmpty) throw _invalid('The live activity\'s $what can\'t be empty');
    return value;
  }

  final activityId = optionalText(LiveActivityKeys.activityId, 'activityId') ?? '$notificationId';
  optionalText(LiveActivityKeys.shortText, 'shortText');
  optionalText(LiveActivityKeys.pushChannel, 'pushChannel');

  final state = block[LiveActivityKeys.state] ?? LiveActivityState.active.name;
  if (!LiveActivityState.values.any((s) => s.name == state)) {
    throw _invalid('Unknown live activity state: $state');
  }

  final rawMetrics = block[LiveActivityKeys.metrics] ?? const [];
  if (rawMetrics is! List) throw _invalid('The live activity metrics must be a list');
  if (rawMetrics.length > 3) throw _invalid('A live activity has at most 3 metrics');
  for (final metric in rawMetrics) {
    if (metric is! Map) throw _invalid('A live activity metric must be a map');
    final label = metric[LiveActivityKeys.label];
    if (label is! String || label.trim().isEmpty) throw _invalid('A live activity metric needs a label');
    if (metric[LiveActivityKeys.value] is! String) throw _invalid('A live activity metric needs a value');
    final unit = metric[LiveActivityKeys.unit];
    if (unit != null && unit is! String) throw _invalid('A live activity metric unit must be a string');
  }

  final progress = block[LiveActivityKeys.progress];
  if (progress != null) {
    if (progress is! Map) throw _invalid('The live activity progress must be a map');
    final segments = progress[LiveActivityKeys.segments] ?? const [];
    final points = progress[LiveActivityKeys.points] ?? const [];
    if (segments is! List || points is! List) throw _invalid('The live activity segments and points must be lists');
    var total = 0;
    for (final segment in segments) {
      final length = segment is Map ? segment[LiveActivityKeys.length] : null;
      if (length is! num || length <= 0) throw _invalid('A live activity segment needs a positive length');
      total += length.toInt();
    }
    if (segments.isEmpty) total = 100;
    for (final point in points) {
      final position = point is Map ? point[LiveActivityKeys.position] : null;
      if (position is! num || position < 0 || position > total) {
        throw _invalid('A live activity point must sit within the segments (0 to $total)');
      }
    }
  }

  final timer = block[LiveActivityKeys.timer];
  if (timer != null) {
    if (timer is! Map) throw _invalid('The live activity timer must be a map');
    final start = timer[LiveActivityKeys.start], end = timer[LiveActivityKeys.end];
    if ((start != null && start is! num) || (end != null && end is! num)) {
      throw _invalid('The live activity timer start and end must be milliseconds');
    }
    if (start == null && end == null) throw _invalid('The live activity timer needs a start or an end');
    if (start is num && end is num && end <= start) {
      throw _invalid('A live activity countdown must end after it starts');
    }
  }

  for (final key in [LiveActivityKeys.staleAt, LiveActivityKeys.relevance, LiveActivityKeys.accentColor]) {
    if (block[key] != null && block[key] is! num) throw _invalid('The live activity $key must be a number');
  }
  final alert = block[LiveActivityKeys.alert] ?? false;
  if (alert is! bool) throw _invalid('The live activity alert must be a bool');
  final dismissal = block[LiveActivityKeys.dismissal] ?? LiveActivityKeys.dismissalDefault;
  if (!_isDismissal(dismissal)) throw _invalid('Unknown live activity dismissal: $dismissal');

  return {
    ...block,
    LiveActivityKeys.activityId: activityId,
    LiveActivityKeys.state: state,
    LiveActivityKeys.metrics: rawMetrics,
    LiveActivityKeys.alert: alert,
    LiveActivityKeys.dismissal: dismissal is num ? dismissal.toInt() : dismissal,
  };
}

bool _isDismissal(Object? value) =>
    value == LiveActivityKeys.dismissalDefault ||
    value == LiveActivityKeys.dismissalImmediate ||
    value is num;

String _two(int n) => n.toString().padLeft(2, '0');

/// The local time of [ms] (UTC milliseconds), as `HH:mm`.
String webTimeOf(num ms) {
  final time = DateTime.fromMillisecondsSinceEpoch(ms.toInt(), isUtc: true).toLocal();
  return '${_two(time.hour)}:${_two(time.minute)}';
}

/// The body of an activity's page notification: the app's body, then what
/// the browser can't draw, as text: the progress (a bar of ten cells and the
/// percentage) with the short text, the timer (a page notification has no
/// running clock: the time it ends or started) and the metrics.
String webLiveBodyOf(Map<String, dynamic> content, Map<String, dynamic> block) {
  final lines = <String>[];
  final body = content[NOTIFICATION_BODY];
  if (body is String && body.isNotEmpty) lines.add(body);

  final status = <String>[];
  final progress = content[NOTIFICATION_PROGRESS];
  if (progress is num) {
    final percent = progress.clamp(0, 100).round();
    final filled = (percent / 10).round();
    status.add('${'▰' * filled}${'▱' * (10 - filled)} $percent%');
  }
  if (block[LiveActivityKeys.shortText] case final String shortText) status.add(shortText);
  if (status.isNotEmpty) lines.add(status.join(' · '));

  if (block[LiveActivityKeys.timer] case final Map timer) {
    final start = timer[LiveActivityKeys.start], end = timer[LiveActivityKeys.end];
    if (end is num) {
      lines.add('Ends at ${webTimeOf(end)}');
    } else if (start is num) {
      lines.add('Started at ${webTimeOf(start)}');
    }
  }

  final metrics = [
    for (final metric in (block[LiveActivityKeys.metrics] as List? ?? const []))
      if (metric is Map)
        [metric[LiveActivityKeys.label], metric[LiveActivityKeys.value], metric[LiveActivityKeys.unit]]
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .join(' '),
  ];
  if (metrics.isNotEmpty) lines.add(metrics.join(' · '));
  return lines.join('\n');
}

class _Activity {
  _Activity(this.model, this.block);

  /// The model as reported in the events (content with the activityId
  /// payload).
  Map<String, dynamic> model;

  /// The validated `liveActivity` block.
  Map<String, dynamic> block;

  bool ended = false;
  Timer? staleTimer, dismissTimer;

  String get activityId => block[LiveActivityKeys.activityId] as String;
  Map<String, dynamic> get content => (model[NOTIFICATION_CONTENT] as Map).cast<String, dynamic>();
  int? get notificationId => content[NOTIFICATION_ID] as int?;

  void cancelTimers() {
    staleTimer?.cancel();
    dismissTimer?.cancel();
    staleTimer = dismissTimer = null;
  }
}

/// The web live activity layer: a page notification per activity, replaced
/// in place (silently, unless `alert`) on every update, closed by its
/// dismissal, its `staleAt`, the core's cancel / dismiss or the user.
class WebLiveActivityController implements LiveActivitiesPlatformBridge {
  WebLiveActivityController(
    this.api, {
    required this.dispatchAction,
    required this.assetUrl,
    WebTimerFactory? timer,
    DateTime Function()? now,
  })  : _timer = timer ?? Timer.new,
        _now = now ?? DateTime.now;

  final LiveNotificationApi api;
  final WebActionDispatcher dispatchAction;
  final String Function(String key) assetUrl;
  final WebTimerFactory _timer;
  final DateTime Function() _now;

  final _events = StreamController<Object?>.broadcast();

  /// activityId → the activity the page shows.
  final Map<String, _Activity> _activities = {};

  @override
  Stream<Object?> get events => _events.stream;

  static String tagOf(String activityId) => 'awn.live.$activityId';

  /// The core's web builder: null when the model has no live activity.
  Future<bool?> build(Map<String, dynamic> model) async {
    final raw = model[LiveActivityKeys.liveActivity];
    if (raw == null) return null;
    if (model[NOTIFICATION_SCHEDULE] != null) {
      throw _invalid('Live activities can\'t be scheduled', '$_invalidDetail.schedule');
    }
    final content = Map<String, dynamic>.from((model[NOTIFICATION_CONTENT] as Map?) ?? const {});
    final notificationId = content[NOTIFICATION_ID];
    if (notificationId is! int) throw _invalid('A live activity needs the notification id');
    final block = parseWebLiveActivity(raw, notificationId);
    final activityId = block[LiveActivityKeys.activityId] as String;
    content[NOTIFICATION_PAYLOAD] = <String, String?>{
      ...?(content[NOTIFICATION_PAYLOAD] as Map?)?.cast<String, String?>(),
      LiveActivityKeys.payloadActivityId: activityId,
    };
    // The core reports the updated model in the created / displayed events.
    model[NOTIFICATION_CONTENT] = content;
    model[LiveActivityKeys.liveActivity] = block;

    if (!api.available) return false;

    // Another activity on the same notification is replaced by this one.
    for (final other in _activities.values.toList()) {
      if (other.activityId != activityId && other.notificationId == notificationId) _drop(other);
    }

    final previous = _activities[activityId];
    previous?.cancelTimers();
    final entry = _Activity(model, block);
    // Only the first post of an activity alerts; updates are silent unless
    // `alert`.
    final first = previous == null || previous.ended;
    _activities[activityId] = entry;

    final ended = block[LiveActivityKeys.state] == LiveActivityState.ended.name;
    _show(entry, renotify: !first && block[LiveActivityKeys.alert] == true, active: !ended);
    if (block[LiveActivityKeys.staleAt] case final num staleAt) {
      entry.staleTimer = _after(staleAt, () => _drop(entry));
    }
    if (ended) {
      entry.ended = true;
      if (previous?.ended != true) _emitState(activityId, LiveActivityStatus.ended);
      _dismiss(entry, block[LiveActivityKeys.dismissal]);
    }
    return true;
  }

  void _show(_Activity activity, {required bool renotify, required bool active}) {
    final content = activity.content;
    api.show(
      tagOf(activity.activityId),
      title: content[NOTIFICATION_TITLE] as String? ?? '',
      body: webLiveBodyOf(content, activity.block),
      icon: webImageUrlOf(content[NOTIFICATION_LARGE_ICON] as String?, assetUrl),
      // Kept on screen while active; the final content may go to the
      // notification center as any other.
      requireInteraction: active,
      renotify: renotify,
      onClick: () => _onClick(activity),
      onClose: () => _onClosed(activity),
    );
  }

  /// A timer that runs [callback] at [ms] (UTC), right away when past.
  Timer _after(num ms, void Function() callback) {
    final delay = DateTime.fromMillisecondsSinceEpoch(ms.toInt(), isUtc: true).difference(_now());
    return _timer(delay.isNegative ? Duration.zero : delay, callback);
  }

  /// Applies an ended activity's dismissal: `default` leaves it until the
  /// user closes it, `immediate` closes it now, milliseconds close it then.
  void _dismiss(_Activity activity, Object? dismissal) {
    activity.dismissTimer?.cancel();
    activity.dismissTimer = null;
    if (dismissal == LiveActivityKeys.dismissalImmediate) {
      _drop(activity);
    } else if (dismissal is num) {
      activity.dismissTimer = _after(dismissal, () => _drop(activity));
    }
  }

  void _emitState(String activityId, LiveActivityStatus status) => _events.add({
        LiveActivityKeys.kind: LiveActivityKeys.kindState,
        LiveActivityKeys.activityId: activityId,
        LiveActivityKeys.state: status.name,
      });

  /// Removes the activity, closes its notification and reports it dismissed.
  void _drop(_Activity activity) {
    activity.cancelTimers();
    if (!identical(_activities[activity.activityId], activity)) return;
    _activities.remove(activity.activityId);
    api.close(tagOf(activity.activityId));
    _emitState(activity.activityId, LiveActivityStatus.dismissed);
  }

  /// The user (or the browser) closed the notification.
  void _onClosed(_Activity activity) {
    if (!identical(_activities[activity.activityId], activity)) return;
    activity.cancelTimers();
    _activities.remove(activity.activityId);
    _emitState(activity.activityId, LiveActivityStatus.dismissed);
  }

  /// A click on the body opens the app, as a tap on any notification does.
  Future<void> _onClick(_Activity activity) async {
    if (!identical(_activities[activity.activityId], activity)) return;
    api.focusPage();
    await dispatchAction(activity.model,
        buttonKey: '', button: {NOTIFICATION_ACTION_TYPE: ActionType.Default.name});
  }

  /// The core's removal hook: a cancel / dismiss of an activity's
  /// notification ([removes] tells it from its model) ends it right away.
  void onRemoved(bool Function(Map<String, dynamic> model) removes) {
    for (final activity in _activities.values.toList()) {
      if (removes(activity.model)) _drop(activity);
    }
  }

  /// `liveActivityEnd`: shows the final content (silently), then applies
  /// [dismissal].
  void _end(String activityId, Object? dismissal) {
    final activity = _activities[activityId];
    if (activity == null) return;
    dismissal = _isDismissal(dismissal) ? dismissal : LiveActivityKeys.dismissalDefault;
    activity.block = {
      ...activity.block,
      LiveActivityKeys.state: LiveActivityState.ended.name,
      LiveActivityKeys.dismissal: dismissal,
    };
    activity.model = {...activity.model, LiveActivityKeys.liveActivity: activity.block};
    if (!activity.ended) {
      activity.ended = true;
      _show(activity, renotify: false, active: false);
      _emitState(activityId, LiveActivityStatus.ended);
    }
    _dismiss(activity, dismissal);
  }

  @override
  Future<Object?> invokeMethod(String method, [Object? arguments]) async {
    switch (method) {
      case LiveActivityKeys.methodEnd:
        final map = (arguments as Map).cast<String, dynamic>();
        _end(map[LiveActivityKeys.activityId] as String, map[LiveActivityKeys.dismissal]);
        return null;
      case LiveActivityKeys.methodList:
        return [
          for (final activity in _activities.values)
            {
              LiveActivityKeys.activityId: activity.activityId,
              LiveActivityKeys.state:
                  (activity.ended ? LiveActivityStatus.ended : LiveActivityStatus.active).name,
            },
        ];
      case LiveActivityKeys.methodCapabilities:
        // A page notification: no surface of its own, a text progress, no
        // buttons without a service worker, nothing by push.
        return {
          LiveActivityKeys.capSystemSurface: false,
          LiveActivityKeys.capProgressSegments: false,
          LiveActivityKeys.capMetrics: false,
          LiveActivityKeys.capButtons: false,
          LiveActivityKeys.capPush: false,
        };
      case LiveActivityKeys.methodAreEnabled:
        return api.available;
      case LiveActivityKeys.methodRequestPermission:
        return api.requestPermission();
      case LiveActivityKeys.methodPushToStartToken:
      case LiveActivityKeys.methodPushToken:
        return null;
    }
    throw MissingPluginException('No web implementation for $method');
  }
}
