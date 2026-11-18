/// Notification scheduling for awesome_notifications.
///
/// Schedule a notification by passing a concrete [NotificationSchedule]
/// ([NotificationInterval] or [NotificationCalendar]) as an **extension** to the
/// core's `createNotification`:
///
/// ```dart
/// await AwesomeNotifications().createNotification(
///   content: NotificationContent(id: 1, channelKey: 'basic', title: 'Hi'),
///   extensions: [
///     NotificationCalendar(hour: 8, minute: 0, repeats: true),
///   ],
/// );
/// ```
///
/// The native scheduling decorator (installed automatically when this package is
/// added) intercepts the build and registers the delayed delivery. The core
/// stays unaware of scheduling.
///
/// Scheduling exists on Android, iOS, macOS and Windows. Browsers have no API
/// to schedule a local notification, so there is no web support (schedule
/// from your server through push instead); Linux is in progress. Where it is
/// not available, check [AwesomeNotificationsSchedules.isPlatformSupported]:
/// the management calls answer "nothing scheduled" instead of throwing.
library;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'src/notification_schedule.dart';
import 'src/scheduled_notification_model.dart';

export 'src/notification_calendar.dart';
export 'src/notification_interval.dart';
export 'src/notification_schedule.dart';
export 'src/scheduled_notification_model.dart';

/// Entry point of the scheduling decorator's schedule-management API.
///
/// Creating scheduled notifications does **not** require this class — pass a
/// schedule via `createNotification(extensions: [...])`. This class only groups
/// the schedule-specific operations that used to live on the core
/// (cancel-schedule, list, next-date), keeping the core scheduling-agnostic. It
/// talks to the same native plugin over the shared `awesome_notifications`
/// channel.
class AwesomeNotificationsSchedules {
  static final AwesomeNotificationsSchedules _instance =
      AwesomeNotificationsSchedules._();
  factory AwesomeNotificationsSchedules() => _instance;
  AwesomeNotificationsSchedules._();

  static const MethodChannel _channel = MethodChannel('awesome_notifications');

  /// Whether scheduling exists on this platform (Android, iOS, macOS and
  /// Windows).
  ///
  /// Browsers have no API to schedule a local notification, so it is false on
  /// web; Linux is in progress. There the management calls answer "nothing
  /// scheduled" (no-op / empty list / null), and the core does not create a
  /// notification carrying a schedule, so it is never shown immediately by
  /// mistake.
  static bool get isPlatformSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows);

  static bool _warnedUnsupported = false;

  /// False (warning once in debug) where scheduling does not exist.
  bool _ensureSupported() {
    if (isPlatformSupported) return true;
    if (kDebugMode && !_warnedUnsupported) {
      _warnedUnsupported = true;
      debugPrint('Awesome Notifications Schedules: scheduling is not available '
          'on ${kIsWeb ? 'web' : defaultTargetPlatform.name}; the schedule API '
          'answers "nothing scheduled" there.');
    }
    return false;
  }

  /// Cancels a single scheduled notification without dismissing the active one.
  Future<void> cancelSchedule(int id) async {
    _validateId(id);
    if (!_ensureSupported()) return;
    await _channel.invokeMethod(CHANNEL_METHOD_CANCEL_SCHEDULE, id);
  }

  /// Cancels all schedules on the given [channelKey], leaving active
  /// notifications intact.
  Future<void> cancelSchedulesByChannelKey(String channelKey) async {
    if (!_ensureSupported()) return;
    await _channel.invokeMethod(
        CHANNEL_METHOD_CANCEL_SCHEDULES_BY_CHANNEL_KEY, channelKey);
  }

  /// Cancels all schedules on the given [groupKey], leaving active
  /// notifications intact.
  Future<void> cancelSchedulesByGroupKey(String groupKey) async {
    if (!_ensureSupported()) return;
    await _channel.invokeMethod(
        CHANNEL_METHOD_CANCEL_SCHEDULES_BY_GROUP_KEY, groupKey);
  }

  /// Cancels all schedules, leaving active notifications intact.
  Future<void> cancelAllSchedules() async {
    if (!_ensureSupported()) return;
    await _channel.invokeMethod(CHANNEL_METHOD_CANCEL_ALL_SCHEDULES);
  }

  /// Lists all active scheduled notifications, each with its schedule.
  Future<List<ScheduledNotificationModel>> listScheduledNotifications() async {
    if (!_ensureSupported()) return [];
    final List<Object>? returned =
        await _channel.invokeListMethod(CHANNEL_METHOD_LIST_ALL_SCHEDULES);
    final List<ScheduledNotificationModel> scheduled = [];
    if (returned != null) {
      for (final Object object in returned) {
        if (object is Map) {
          final ScheduledNotificationModel? model = ScheduledNotificationModel()
              .fromMap(Map<String, dynamic>.from(object));
          if (model != null) scheduled.add(model);
        }
      }
    }
    return scheduled;
  }

  /// Computes the next valid delivery date for a [schedule], relative to
  /// [fixedDate] (defaults to now). Returns null when the schedule has no future
  /// occurrence.
  Future<DateTime?> getNextDate(NotificationSchedule schedule,
      {DateTime? fixedDate}) async {
    if (!_ensureSupported()) return null;
    fixedDate ??= DateTime.now().toUtc();
    final Map<String, dynamic> parameters = {
      NOTIFICATION_INITIAL_FIXED_DATE:
          AwesomeDateUtils.parseDateToString(fixedDate),
      NOTIFICATION_SCHEDULE: schedule.toScheduleMap(),
    };

    final String? nextDate =
        await _channel.invokeMethod(CHANNEL_METHOD_GET_NEXT_DATE, parameters);
    if (nextDate == null) return null;
    // Like 0.12: the reply is the wall clock of the resulting date, read as a
    // local DateTime.
    return AwesomeDateUtils.parseStringToDate(nextDate)!;
  }

  // Same check as the core's createNotification / 0.12's cancelSchedule.
  void _validateId(int id) {
    if (id > 0x7FFFFFFF || id < -0x80000000) {
      throw ArgumentError(
          'The id field must be the limited to 32-bit size integer');
    }
  }
}
