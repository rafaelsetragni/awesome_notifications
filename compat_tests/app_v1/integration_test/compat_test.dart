// Adapter: the compat suite over the 1.0 monorepo packages.
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_localizations/awesome_notifications_localizations.dart';
import 'package:awesome_notifications_schedules/awesome_notifications_schedules.dart';
import 'package:awn_compat_suite/awn_compat_suite.dart';
import 'package:integration_test/integration_test.dart';

@pragma('vm:entry-point')
Future<void> onAction(ReceivedAction action) async {}

@pragma('vm:entry-point')
Future<void> onDisplayed(ReceivedNotification received) async =>
    CompatEvents.displayed.add(received.toMap());

NotificationSchedule? _schedule(ScheduleSpec? spec) => switch (spec) {
      null => null,
      CalendarSpec s => NotificationCalendar(
          era: s.era,
          year: s.year,
          month: s.month,
          day: s.day,
          hour: s.hour,
          minute: s.minute,
          second: s.second,
          millisecond: s.millisecond,
          weekday: s.weekday,
          weekOfMonth: s.weekOfMonth,
          weekOfYear: s.weekOfYear,
          timeZone: s.timeZone,
          repeats: s.repeats),
      IntervalSpec s =>
        NotificationInterval(interval: s.interval, timeZone: s.timeZone, repeats: s.repeats),
    };

class V1Api implements CompatApi {
  final AwesomeNotifications _awn = AwesomeNotifications();
  final AwesomeNotificationsSchedules _schedules = AwesomeNotificationsSchedules();
  final AwesomeNotificationsLocalizations _localizations = AwesomeNotificationsLocalizations();

  @override
  String get name => 'awesome_notifications 1.0 (monorepo)';

  @override
  Future<void> initialize() async {
    await _awn.initialize(null, [
      NotificationChannel(
          channelKey: compatChannelKey,
          channelName: 'Compat',
          channelDescription: 'Black-box compat suite'),
    ]);
    await _awn.setListeners(
        onActionReceivedMethod: onAction, onNotificationDisplayedMethod: onDisplayed);
  }

  @override
  Future<bool> isNotificationAllowed() => _awn.isNotificationAllowed();

  @override
  Future<bool> requestPermission() => _awn.requestPermissionToSendNotifications();

  @override
  Future<bool> setLocalization(String? languageCode) =>
      _localizations.setLocalization(languageCode: languageCode);

  @override
  Future<String> getLocalization() => _localizations.getLocalization();

  @override
  Future<bool> createNotification(NotificationSpec spec) {
    final schedule = _schedule(spec.schedule);
    return _awn.createNotification(
      content: NotificationContent(
        id: spec.id,
        channelKey: compatChannelKey,
        title: spec.title,
        body: spec.body,
        summary: spec.summary,
        titleLocKey: spec.titleLocKey,
        titleLocArgs: spec.titleLocArgs,
        bodyLocKey: spec.bodyLocKey,
        bodyLocArgs: spec.bodyLocArgs,
        groupKey: spec.groupKey,
        duration: spec.duration,
        progress: spec.progress,
        playbackSpeed: spec.playbackSpeed,
        playState: spec.playState == null
            ? null
            : NotificationPlayState.values.byName(spec.playState!),
        notificationLayout: spec.layout == null
            ? NotificationLayout.Default
            : NotificationLayout.values.byName(spec.layout!),
        category: spec.category == null
            ? null
            : NotificationCategory.values.byName(spec.category!),
        fullScreenIntent: spec.fullScreenIntent ?? false,
        wakeUpScreen: spec.wakeUpScreen ?? false,
        locked: spec.locked ?? false,
      ),
      actionButtons: spec.buttons.isEmpty
          ? null
          : [
              for (final b in spec.buttons.entries)
                NotificationActionButton(
                    key: b.key,
                    label: b.value,
                    showInCompactView: spec.compactButtons.contains(b.key))
            ],
      extensions: [
        if (schedule != null) schedule,
        if (spec.localizations != null)
          NotificationLocalizations(spec.localizations!.map((code, l) => MapEntry(
              code,
              NotificationLocalization(
                  title: l.title,
                  body: l.body,
                  summary: l.summary,
                  buttonLabels: l.buttonLabels)))),
      ],
    );
  }

  @override
  Future<DateTime?> getNextDate(ScheduleSpec schedule, DateTime fixedDate) =>
      _schedules.getNextDate(_schedule(schedule)!, fixedDate: fixedDate);

  @override
  Future<List<Map<String, dynamic>>> listScheduledNotifications() async =>
      [for (final model in await _schedules.listScheduledNotifications()) model.toMap()];

  @override
  Future<void> cancelSchedule(int id) => _schedules.cancelSchedule(id);

  @override
  Future<void> cancelSchedulesByChannelKey(String channelKey) =>
      _schedules.cancelSchedulesByChannelKey(channelKey);

  @override
  Future<void> cancelAllSchedules() => _schedules.cancelAllSchedules();

  @override
  Future<void> cancelAll() => _awn.cancelAll();

  @override
  Future<void> dismiss(int id) => _awn.dismiss(id);

  @override
  Future<Map<String, String>> permissionStatuses(List<String> permissions) async {
    final statuses = await _awn.getPermissionStatusList(
        channelKey: compatChannelKey,
        permissions: [for (final p in permissions) NotificationPermission.values.byName(p)]);
    return {for (final e in statuses.entries) e.key.name: e.value.name};
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  defineCompatTests(V1Api());
}
