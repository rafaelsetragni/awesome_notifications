import 'dart:ui' show Color;

import 'package:awesome_notifications/awesome_notifications.dart';

import 'live_activity_keys.dart';

/// What the app asks for an activity.
enum LiveActivityState {
  /// Shown and updating.
  active,

  /// Over: shows its final content, then leaves as [LiveActivityDismissal]
  /// says.
  ended,
}

/// How the package draws the activity where it draws it itself (iOS's
/// widget, Android's own layout before Android 16). Every other surface
/// shows the same content as text.
enum LiveActivityLayout {
  /// The title and body, the progress bar, the metrics in columns.
  standard,

  /// Two sides facing each other, as a scoreboard: the first metric on the
  /// left, the second on the right (each with its [LiveActivityMetric.image],
  /// its label and its value in large type), the short text and the clock in
  /// the middle, and the body below them (the latest play). Needs exactly
  /// two metrics.
  versus,
}

/// A part of the progress bar, in its own color (a ride's legs, a
/// delivery's stages). Lengths are relative to each other.
class LiveActivitySegment {
  final int length;
  final Color? color;

  const LiveActivitySegment(this.length, {this.color});

  Map<String, dynamic> toMap() => {
        LiveActivityKeys.length: length,
        if (color != null) LiveActivityKeys.color: color!.toARGB32(),
      };
}

/// A mark on the progress bar (a stop, a milestone), at a position in the
/// segments' total length.
class LiveActivityPoint {
  final int position;
  final Color? color;

  const LiveActivityPoint(this.position, {this.color});

  Map<String, dynamic> toMap() => {
        LiveActivityKeys.position: position,
        if (color != null) LiveActivityKeys.color: color!.toARGB32(),
      };
}

/// How the progress bar looks. Its value is the notification's
/// `content.progress` (0 to 100; indeterminate when null).
///
/// Android 16+ draws segments, points and icons (`ProgressStyle`); iOS draws
/// them in the package's widget; elsewhere they collapse to a plain bar.
class LiveActivityProgress {
  /// Empty: one segment.
  final List<LiveActivitySegment> segments;
  final List<LiveActivityPoint> points;

  /// Images (`resource://`, `asset://`, `file://`, `https://`), as in the
  /// core's `largeIcon`. The tracker moves with the progress.
  final String? trackerIcon;
  final String? startIcon;
  final String? endIcon;

  const LiveActivityProgress({
    this.segments = const [],
    this.points = const [],
    this.trackerIcon,
    this.startIcon,
    this.endIcon,
  });

  int get _total => segments.isEmpty ? 100 : segments.fold(0, (sum, s) => sum + s.length);

  Map<String, dynamic> toMap() => {
        LiveActivityKeys.segments: [for (final s in segments) s.toMap()],
        LiveActivityKeys.points: [for (final p in points) p.toMap()],
        if (trackerIcon != null) LiveActivityKeys.trackerIcon: trackerIcon,
        if (startIcon != null) LiveActivityKeys.startIcon: startIcon,
        if (endIcon != null) LiveActivityKeys.endIcon: endIcon,
      };
}

/// A clock the system runs by itself, with no updates: a countdown to [end]
/// or the time elapsed since [start].
class LiveActivityTimer {
  final DateTime? start;
  final DateTime? end;

  const LiveActivityTimer._({this.start, this.end});

  /// Counts down to [end]; with [start], also fills the progress bar on iOS.
  const LiveActivityTimer.countDown({required DateTime end, DateTime? start})
      : this._(start: start, end: end);

  /// Counts up from [start].
  const LiveActivityTimer.elapsed({required DateTime start}) : this._(start: start);

  bool get countDown => end != null;

  Map<String, dynamic> toMap() => {
        if (start != null) LiveActivityKeys.start: start!.toUtc().millisecondsSinceEpoch,
        if (end != null) LiveActivityKeys.end: end!.toUtc().millisecondsSinceEpoch,
        LiveActivityKeys.countDown: countDown,
      };
}

/// A labeled value (a score, a speed, a distance). Up to three per activity.
class LiveActivityMetric {
  final String label;
  final String value;

  /// Left out where space is short (Android's collapsed view).
  final String? unit;

  /// A picture of the side in [LiveActivityLayout.versus] (a team's logo):
  /// `resource://`, `asset://`, `file://` or `https://`, as the core's
  /// `largeIcon`. The standard layout doesn't draw it.
  final String? image;

  const LiveActivityMetric({required this.label, required this.value, this.unit, this.image});

  Map<String, dynamic> toMap() => {
        LiveActivityKeys.label: label,
        LiveActivityKeys.value: value,
        if (unit != null) LiveActivityKeys.unit: unit,
        if (image != null) LiveActivityKeys.image: image,
      };
}

/// When an ended activity leaves the Lock Screen (iOS) or the notification
/// goes away (elsewhere).
class LiveActivityDismissal {
  final DateTime? _at;
  final String _kind;

  /// The system's default: iOS keeps it up to 4 hours; elsewhere it stays
  /// until the user dismisses it.
  static const system = LiveActivityDismissal._(LiveActivityKeys.dismissalDefault);

  /// Right away.
  static const immediate = LiveActivityDismissal._(LiveActivityKeys.dismissalImmediate);

  const LiveActivityDismissal._(this._kind) : _at = null;

  /// At [at] (iOS caps it at 4 hours after the end).
  LiveActivityDismissal.at(DateTime at)
      : _at = at,
        _kind = '';

  Object toValue() => _at?.toUtc().millisecondsSinceEpoch ?? _kind;
}

/// A live activity, attached to a notification through `createNotification`'s
/// `extensions`: iOS shows a Live Activity (Lock Screen, Dynamic Island),
/// Android 16+ a Live Update, and every other platform its notification,
/// updated in place. Send it again (same notification id) on every change;
/// [LiveActivityState.ended], or the core's cancel or dismiss, ends it.
///
/// The notification's `title`, `body`, `progress`, `largeIcon` and
/// `actionButtons` are part of the activity.
///
/// ```dart
/// await AwesomeNotifications().createNotification(
///   content: NotificationContent(
///     id: 400,
///     channelKey: 'live',
///     title: 'Your order is on the way',
///     body: 'Arriving in 12 min',
///     progress: 60,
///   ),
///   extensions: [
///     NotificationLiveActivity(
///       shortText: '12 min',
///       timer: LiveActivityTimer.countDown(end: arrival),
///     ),
///   ],
/// );
/// ```
class NotificationLiveActivity implements NotificationExtension {
  /// Stable across updates and pushes. The notification id when absent.
  final String? activityId;
  final LiveActivityState state;
  final LiveActivityProgress? progress;
  final LiveActivityTimer? timer;

  /// Up to three ([LiveActivityLayout.versus]: exactly two).
  final List<LiveActivityMetric> metrics;

  /// How the package's own views draw it.
  final LiveActivityLayout layout;

  /// A few characters for the tightest places: Android's status bar chip,
  /// iOS's compact Dynamic Island.
  final String? shortText;

  /// Tints the progress bar and the icons.
  final Color? accentColor;

  /// After this the activity shows as out of date (iOS); Android removes the
  /// notification.
  final DateTime? staleAt;

  /// Order among the app's activities (iOS): higher shows first.
  final double? relevance;

  /// This update alerts (sound, banner). Only the first one does by default.
  final bool alert;

  /// For [LiveActivityState.ended].
  final LiveActivityDismissal dismissal;

  /// iOS 18+: the broadcast channel whose pushes update this activity.
  final String? pushChannel;

  /// Android 16+: shown as a Live Update, promoted by the system (the status
  /// bar chip, the top of the shade and the Lock Screen), drawn with the
  /// system's own styles. False: drawn by the package's own layout, as
  /// before Android 16 (the [LiveActivityLayout.versus] scoreboard included),
  /// as an ongoing notification among the others, with no chip. Android 16+
  /// only promotes the system's styles, so it is one or the other.
  final bool androidLiveUpdate;

  /// The app's own layout, by name (lowercase letters, digits and `_`):
  /// - Android: the app's layout resources `res/layout/<name>.xml`
  ///   (collapsed) and, optional, `<name>_expanded.xml`, which the package
  ///   fills by view id (`@id/awn_live_title`, `@id/awn_live_clock`…). A
  ///   custom layout is never a Live Update (Android 16+ promotes only the
  ///   system's styles).
  /// - iOS: the app's own widget reads it (`context.state.customLayout`) and
  ///   draws it; the package's widget ignores it.
  /// - Elsewhere: ignored (the activity shows as text).
  final String? customLayout;

  const NotificationLiveActivity({
    this.activityId,
    this.state = LiveActivityState.active,
    this.progress,
    this.timer,
    this.metrics = const [],
    this.layout = LiveActivityLayout.standard,
    this.shortText,
    this.accentColor,
    this.staleAt,
    this.relevance,
    this.alert = false,
    this.dismissal = LiveActivityDismissal.system,
    this.pushChannel,
    this.androidLiveUpdate = true,
    this.customLayout,
  });

  /// Throws [AwesomeNotificationsException] when the model is invalid. Whether
  /// it suits the notification (a schedule, the iOS 4 KB limit) is checked
  /// natively.
  void validate() {
    void fail(String message) => throw AwesomeNotificationsException(message: message);
    if (activityId != null && activityId!.trim().isEmpty) {
      fail('The live activity\'s activityId can\'t be empty (leave it out to use the notification id)');
    }
    if (metrics.length > 3) fail('A live activity has at most 3 metrics');
    if (layout == LiveActivityLayout.versus && metrics.length != 2) {
      fail('A versus live activity needs exactly 2 metrics, one per side');
    }
    for (final metric in metrics) {
      if (metric.label.trim().isEmpty) fail('A live activity metric needs a label');
    }
    if (shortText != null && shortText!.trim().isEmpty) {
      fail('The live activity\'s shortText can\'t be empty');
    }
    if (customLayout != null && !RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(customLayout!)) {
      fail('The live activity\'s customLayout must be a resource name: lowercase letters, digits and _');
    }
    if (pushChannel != null && pushChannel!.trim().isEmpty) {
      fail('The live activity\'s pushChannel can\'t be empty');
    }
    final progress = this.progress;
    if (progress != null) {
      for (final segment in progress.segments) {
        if (segment.length <= 0) fail('A live activity segment needs a positive length');
      }
      for (final point in progress.points) {
        if (point.position < 0 || point.position > progress._total) {
          fail('A live activity point must sit within the segments (0 to ${progress._total})');
        }
      }
    }
    final timer = this.timer;
    if (timer != null &&
        timer.start != null &&
        timer.end != null &&
        !timer.end!.isAfter(timer.start!)) {
      fail('A live activity countdown must end after it starts');
    }
  }

  /// Validates, then serializes under the `liveActivity` key (called by the
  /// core's `createNotification`, before anything reaches the platform).
  @override
  Map<String, dynamic> toMap() {
    validate();
    return {
      LiveActivityKeys.liveActivity: {
        if (activityId != null) LiveActivityKeys.activityId: activityId,
        LiveActivityKeys.state: state.name,
        if (progress != null) LiveActivityKeys.progress: progress!.toMap(),
        if (timer != null) LiveActivityKeys.timer: timer!.toMap(),
        LiveActivityKeys.metrics: [for (final m in metrics) m.toMap()],
        if (layout != LiveActivityLayout.standard) LiveActivityKeys.layout: layout.name,
        if (shortText != null) LiveActivityKeys.shortText: shortText,
        if (accentColor != null) LiveActivityKeys.accentColor: accentColor!.toARGB32(),
        if (staleAt != null) LiveActivityKeys.staleAt: staleAt!.toUtc().millisecondsSinceEpoch,
        if (relevance != null) LiveActivityKeys.relevance: relevance,
        LiveActivityKeys.alert: alert,
        LiveActivityKeys.dismissal: dismissal.toValue(),
        if (pushChannel != null) LiveActivityKeys.pushChannel: pushChannel,
        if (!androidLiveUpdate) LiveActivityKeys.androidLiveUpdate: false,
        if (customLayout != null) LiveActivityKeys.customLayout: customLayout,
      },
    };
  }
}
