/// Black-box compatibility suite.
///
/// The SAME tests run, unchanged, against the published awesome_notifications
/// 0.12 (the reference behavior) and against the 1.0 monorepo packages. Each
/// host app only provides a thin [CompatApi] adapter that maps these neutral
/// calls onto its library's public Dart API; the tests only see what an app
/// developer sees (return values, dates, events). Any difference is a breaking
/// change.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Neutral input models
// ---------------------------------------------------------------------------

sealed class ScheduleSpec {
  const ScheduleSpec();
}

class CalendarSpec extends ScheduleSpec {
  final int? era, year, month, day, hour, minute, second, millisecond;
  final int? weekday, weekOfMonth, weekOfYear;
  final String? timeZone;
  final bool repeats;

  const CalendarSpec({
    this.era,
    this.year,
    this.month,
    this.day,
    this.hour,
    this.minute,
    this.second,
    this.millisecond,
    this.weekday,
    this.weekOfMonth,
    this.weekOfYear,
    this.timeZone,
    this.repeats = false,
  });
}

class IntervalSpec extends ScheduleSpec {
  final Duration interval;
  final String? timeZone;
  final bool repeats;

  const IntervalSpec(this.interval, {this.timeZone, this.repeats = false});
}

class LocalizationSpec {
  final String? title, body, summary;
  final Map<String, String>? buttonLabels;

  const LocalizationSpec({this.title, this.body, this.summary, this.buttonLabels});
}

class NotificationSpec {
  final int id;
  final String title, body;
  final String? summary;
  final Map<String, String> buttons; // key → label
  final String? titleLocKey, bodyLocKey;
  final List<String>? titleLocArgs, bodyLocArgs;
  final Map<String, LocalizationSpec>? localizations;
  final ScheduleSpec? schedule;

  const NotificationSpec({
    required this.id,
    this.title = 'Hello',
    this.body = 'World',
    this.summary,
    this.buttons = const {},
    this.titleLocKey,
    this.bodyLocKey,
    this.titleLocArgs,
    this.bodyLocArgs,
    this.localizations,
    this.schedule,
  });
}

// ---------------------------------------------------------------------------
// Adapter contract
// ---------------------------------------------------------------------------

/// The channel every notification of the suite is created on.
const String compatChannelKey = 'compat_channel';

/// What each host app implements with its own library.
abstract class CompatApi {
  /// Label of the implementation under test (shown in failures).
  String get name;

  /// Initializes the plugin with [compatChannelKey] and wires the displayed
  /// listener to [CompatEvents.displayed].
  Future<void> initialize();

  Future<bool> isNotificationAllowed();

  /// Asks the user (used only where the runner can't pre-grant it: macOS).
  Future<bool> requestPermission();

  Future<bool> setLocalization(String? languageCode);
  Future<String> getLocalization();

  /// May throw; the suite records exceptions as part of the behavior.
  Future<bool> createNotification(NotificationSpec spec);

  Future<DateTime?> getNextDate(ScheduleSpec schedule, DateTime fixedDate);

  /// The scheduled notifications, as `NotificationModel.toMap()`.
  Future<List<Map<String, dynamic>>> listScheduledNotifications();

  Future<void> cancelSchedule(int id);
  Future<void> cancelSchedulesByChannelKey(String channelKey);
  Future<void> cancelAllSchedules();
  Future<void> cancelAll();
}

/// Events published by the adapters' static listeners.
class CompatEvents {
  /// `ReceivedNotification.toMap()` of every displayed notification.
  static final StreamController<Map<String, dynamic>> displayed =
      StreamController<Map<String, dynamic>>.broadcast();
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Everything an app sees of a returned DateTime: its wall clock AND whether
/// it is flagged UTC (both change how the app reads it).
String describeDate(DateTime? date) {
  if (date == null) return 'null';
  String two(int v) => v.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)} '
      '${two(date.hour)}:${two(date.minute)}:${two(date.second)}'
      '${date.isUtc ? ' UTC' : ' local'}';
}

/// Every device runs the suite in this time zone (run_compat.sh pins it), so
/// local DateTimes are comparable across machines.
const String deviceTimeZone = 'America/Sao_Paulo';

/// The fixed "now" every date test starts from: a Sunday.
final DateTime fixedDate = DateTime.utc(2026, 7, 5, 8, 30);

Future<String> _outcome(Future<bool> Function() call) async {
  try {
    return (await call()).toString();
  } catch (e) {
    return 'exception';
  }
}

int _nextId = 1000;
int _id() => _nextId++;

Future<Map<String, dynamic>?> _createAndAwaitDisplayed(
    CompatApi api, NotificationSpec spec) async {
  final shown = CompatEvents.displayed.stream
      .firstWhere((event) => event['id'] == spec.id)
      .timeout(const Duration(seconds: 10), onTimeout: () => <String, dynamic>{});
  final created = await api.createNotification(spec);
  if (!created) return null;
  final event = await shown;
  return event.isEmpty ? null : event;
}

// ---------------------------------------------------------------------------
// The suite
// ---------------------------------------------------------------------------

void defineCompatTests(CompatApi api) {
  setUpAll(() async {
    expect(DateTime(2026, 7, 5).timeZoneOffset, const Duration(hours: -3),
        reason: 'run the suite with the device in $deviceTimeZone (run_compat.sh)');
    await api.initialize();
    // The runner script grants the notification permission right after the
    // app is installed; wait for it instead of prompting. macOS can't be
    // pre-granted: ask once (the answer persists for the app).
    if (Platform.isMacOS && !await api.isNotificationAllowed()) {
      await api.requestPermission();
    }
    for (var i = 0; i < 60 && !await api.isNotificationAllowed(); i++) {
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    expect(await api.isNotificationAllowed(), isTrue,
        reason: 'notification permission must be granted for ${api.name}');
  });

  tearDown(() async {
    await api.cancelAll();
    await api.setLocalization(null);
  });

  group('localization language', () {
    test('defaults to the system language, lowercase', () async {
      await api.setLocalization(null);
      final language = await api.getLocalization();
      expect(language, isNotEmpty);
      expect(language, language.toLowerCase());
    });

    test('stores the given code lowercased', () async {
      expect(await api.setLocalization('PT-BR'), isTrue);
      expect(await api.getLocalization(), 'pt-br');
    });

    test('an empty code', () async {
      final system = await () async {
        await api.setLocalization(null);
        return api.getLocalization();
      }();
      expect(await api.setLocalization(''), isTrue);
      final language = await api.getLocalization();
      expect(language == system ? 'system' : 'stored "$language"', 'stored ""');
    });
  });

  group('localizations block', () {
    Future<Map<String, dynamic>?> show(String language,
        Map<String, LocalizationSpec> localizations,
        {String? titleLocKey, List<String>? titleLocArgs}) async {
      await api.setLocalization(language);
      return _createAndAwaitDisplayed(
          api,
          NotificationSpec(
            id: _id(),
            summary: 'Summary',
            buttons: const {'YES': 'Yes'},
            localizations: localizations,
            titleLocKey: titleLocKey,
            titleLocArgs: titleLocArgs,
          ));
    }

    test('translates title, body and summary', () async {
      final shown = await show('pt-br', {
        'pt-br': const LocalizationSpec(title: 'Olá', body: 'Mundo', summary: 'Resumo'),
      });
      expect([shown?['title'], shown?['body'], shown?['summary']],
          ['Olá', 'Mundo', 'Resumo']);
    });

    test('empty translations keep the original', () async {
      final shown = await show('pt-br', {'pt-br': const LocalizationSpec(title: '')});
      expect(shown?['title'], 'Hello');
    });

    test('language without a translation keeps the original', () async {
      final shown = await show('fr', {'pt-br': const LocalizationSpec(title: 'Olá')});
      expect(shown?['title'], 'Hello');
    });

    for (final (language, key) in [
      ('pt-br', 'pt'),
      ('pt', 'pt-br'),
      ('pt-br', 'pt_BR'),
      ('pt-br', 'PT-BR'),
      ('PT_BR', 'pt-br'),
      ('pt-br', 'pt-pt'),
      ('en', 'english'),
    ]) {
      test('language "$language" with key "$key"', () async {
        final shown = await show(language, {key: const LocalizationSpec(title: 'Translated')});
        expect(shown?['title'], _matchTable['$language|$key']);
      });
    }

    test('picks among several candidates', () async {
      final shown = await show('pt', {
        'pt-pt': const LocalizationSpec(title: 'PT'),
        'pt-br': const LocalizationSpec(title: 'BR'),
      });
      expect(shown?['title'], 'BR');
    });
  });

  group('localization keys', () {
    Future<Map<String, dynamic>?> show(String language, NotificationSpec spec) async {
      await api.setLocalization(language);
      return _createAndAwaitDisplayed(api, spec);
    }

    test('title and body keys with one argument', () async {
      final shown = await show(
          'pt-br',
          NotificationSpec(
            id: _id(),
            titleLocKey: 'compat_greeting',
            titleLocArgs: const ['Ana'],
            bodyLocKey: 'compat_plain',
          ));
      expect([shown?['title'], shown?['body']], ['Olá, Ana!', 'Texto simples']);
    });

    test('follows the chosen language, not the device one', () async {
      final shown = await show(
          'es',
          NotificationSpec(
              id: _id(), titleLocKey: 'compat_greeting', titleLocArgs: const ['Ana']));
      expect(shown?['title'], '¡Hola, Ana!');
    });

    test('a key with two arguments', () async {
      final shown = await show(
          'pt-br',
          NotificationSpec(
              id: _id(), titleLocKey: 'compat_news', titleLocArgs: const ['Ana', '3']));
      expect(shown?['title'], _locKeyTable['two-args']);
    });

    test('an unknown key', () async {
      final shown = await show('pt-br', NotificationSpec(id: _id(), titleLocKey: 'compat_missing'));
      expect(shown?['title'], _locKeyTable['unknown']);
    });

    test('the localizations block wins over the key', () async {
      final shown = await show(
          'pt-br',
          NotificationSpec(
            id: _id(),
            titleLocKey: 'compat_greeting',
            titleLocArgs: const ['Ana'],
            bodyLocKey: 'compat_plain',
            localizations: const {'pt-br': LocalizationSpec(title: 'Do bloco')},
          ));
      expect([shown?['title'], shown?['body']], ['Do bloco', 'Texto simples']);
    });
  });

  group('getNextDate', () {
    for (final entry in _nextDateTable.entries) {
      test(entry.key, () async {
        final (schedule, expected) = entry.value;
        expect(describeDate(await api.getNextDate(schedule, fixedDate)), expected);
      });
    }
  });

  group('scheduling', () {
    for (final entry in _createTable.entries) {
      test('create: ${entry.key}', () async {
        final (schedule, expected) = entry.value;
        final id = _id();
        final created = await _outcome(
            () => api.createNotification(NotificationSpec(id: id, schedule: schedule)));
        final listed = (await api.listScheduledNotifications())
            .any((model) => (model['content'] as Map?)?['id'] == id);
        expect('$created, listed=$listed', expected);
      });
    }

    test('lists the schedule as it was given', () async {
      final id = _id();
      await api.createNotification(NotificationSpec(
          id: id,
          schedule: const CalendarSpec(
              hour: 9, minute: 15, second: 0, timeZone: 'UTC', repeats: true)));
      final model = (await api.listScheduledNotifications())
          .firstWhere((m) => (m['content'] as Map?)?['id'] == id);
      final schedule = Map<String, dynamic>.from(model['schedule'] as Map);
      expect([
        schedule['hour'],
        schedule['minute'],
        schedule['second'],
        schedule['timeZone'],
        schedule['repeats'],
      // 0.12 iOS lists the device time zone instead of the given one.
      ], [9, 15, 0, p(android: 'UTC', ios: 'America/Sao_Paulo'), true]);
    });

    test('a calendar schedule keeps its ISO weekday when listed', () async {
      final id = _id();
      await api.createNotification(NotificationSpec(
          id: id, schedule: const CalendarSpec(weekday: 1, hour: 10, timeZone: 'UTC')));
      final model = (await api.listScheduledNotifications())
          .firstWhere((m) => (m['content'] as Map?)?['id'] == id);
      expect((model['schedule'] as Map)['weekday'], 1);
    });

    test('cancelSchedulesByChannelKey removes the channel schedules', () async {
      const schedule = IntervalSpec(Duration(hours: 1), repeats: true);
      await api.createNotification(NotificationSpec(id: _id(), schedule: schedule));
      await api.cancelSchedulesByChannelKey(compatChannelKey);
      expect(await api.listScheduledNotifications(), isEmpty);
    });

    test('cancelAllSchedules removes every schedule', () async {
      const schedule = IntervalSpec(Duration(hours: 1), repeats: true);
      await api.createNotification(NotificationSpec(id: _id(), schedule: schedule));
      await api.createNotification(NotificationSpec(id: _id(), schedule: schedule));
      await api.cancelAllSchedules();
      expect(await api.listScheduledNotifications(), isEmpty);
    });

    test('cancelSchedule removes only that schedule', () async {
      final a = _id(), b = _id();
      const schedule = IntervalSpec(Duration(hours: 1), repeats: true);
      await api.createNotification(NotificationSpec(id: a, schedule: schedule));
      await api.createNotification(NotificationSpec(id: b, schedule: schedule));
      await api.cancelSchedule(a);
      final ids = (await api.listScheduledNotifications())
          .map((m) => (m['content'] as Map?)?['id'])
          .toList();
      expect([ids.contains(a), ids.contains(b)], [false, true]);
    });
  });
}

// ---------------------------------------------------------------------------
// Expected behavior (the 0.12 reference)
// ---------------------------------------------------------------------------
//
// Recorded from awesome_notifications 0.12 itself. 0.12 did not always behave
// the same on Android and iOS; where it differed, [p] keeps each platform's
// own reference, because what matters is that an app sees no change when it
// moves from 0.12 to 1.0 on the platform it runs on.

/// The reference value for the current platform.
///
/// 0.12 had no macOS implementation; macOS runs the same Apple code as iOS, so
/// it is held to the 0.12 iOS reference.
String p({required String android, required String ios}) =>
    Platform.isIOS || Platform.isMacOS ? ios : android;

/// language|key → displayed title ('Hello' = not translated).
final Map<String, String> _matchTable = {
  'pt-br|pt': 'Translated',
  'pt|pt-br': 'Translated',
  'pt-br|pt_BR': p(android: 'Translated', ios: 'Hello'),
  'pt-br|PT-BR': 'Translated',
  'PT_BR|pt-br': 'Translated',
  'pt-br|pt-pt': 'Hello',
  'en|english': 'Hello',
};

final Map<String, String> _locKeyTable = {
  // 0.12 Android formats one argument at a time, so two placeholders fail
  // and the original title is kept.
  'two-args': p(android: 'Hello', ios: 'Ana tem 3 novidades'),
  // 0.12 iOS shows NSLocalizedString's answer for a missing key: the key.
  'unknown': p(android: 'Hello', ios: 'compat_missing'),
};

/// name → (schedule, describeDate(result)) from [fixedDate] (Sunday
/// 2026-07-05 08:30:00 UTC).
final Map<String, (ScheduleSpec, String)> _nextDateTable = {
  'interval of 90 s': (
    const IntervalSpec(Duration(seconds: 90), timeZone: 'UTC'),
    p(android: '2026-07-05 08:31:30 local', ios: '2026-07-05 05:31:30 local')
  ),
  'calendar 09:00:00 UTC': (
    const CalendarSpec(hour: 9, minute: 0, second: 0, timeZone: 'UTC'),
    '2026-07-05 09:00:00 local'
  ),
  'calendar 09:00:00 São Paulo': (
    const CalendarSpec(hour: 9, minute: 0, second: 0, timeZone: 'America/Sao_Paulo'),
    // 0.12 answers the wall clock of the schedule's time zone.
    p(android: '2026-07-05 09:00:00 local', ios: '2026-07-05 09:00:00 local')
  ),
  'only hour': (const CalendarSpec(hour: 9, timeZone: 'UTC'), '2026-07-05 09:00:00 local'),
  // 0.12 Android: the second is free, so 08:30:00 + 1 s still matches.
  'only minute': (
    const CalendarSpec(minute: 30, timeZone: 'UTC'),
    p(android: '2026-07-05 08:30:01 local', ios: '2026-07-05 06:30:00 local')
  ),
  'only second': (
    const CalendarSpec(second: 15, timeZone: 'UTC'),
    p(android: '2026-07-05 08:30:15 local', ios: '2026-07-05 05:30:15 local')
  ),
  'only day': (const CalendarSpec(day: 10, timeZone: 'UTC'), '2026-07-10 00:00:00 local'),
  'weekday 1': (
    const CalendarSpec(weekday: 1, hour: 10, timeZone: 'UTC'),
    '2026-07-06 10:00:00 local'
  ),
  'weekday 7': (
    const CalendarSpec(weekday: 7, hour: 10, timeZone: 'UTC'),
    '2026-07-05 10:00:00 local'
  ),
  'week of year 28': (
    const CalendarSpec(weekOfYear: 28, weekday: 3, timeZone: 'UTC'),
    '2026-07-08 00:00:00 local'
  ),
  'February 29': (
    const CalendarSpec(month: 2, day: 29, hour: 12, timeZone: 'UTC'),
    p(android: '2028-02-29 12:00:00 local', ios: '2027-03-01 00:00:00 local')
  ),
  'past date': (
    const CalendarSpec(year: 2020, month: 1, day: 1, hour: 0, timeZone: 'UTC'),
    'null'
  ),
  'future date': (
    const CalendarSpec(year: 2027, month: 2, day: 1, hour: 8, timeZone: 'UTC'),
    '2027-02-01 08:00:00 local'
  ),
  'repeating interval of 90 s': (
    const IntervalSpec(Duration(seconds: 90), timeZone: 'UTC', repeats: true),
    p(android: '2026-07-05 08:31:30 local', ios: '2026-07-05 05:31:30 local')
  ),
  'interval in São Paulo': (
    const IntervalSpec(Duration(seconds: 90), timeZone: 'America/Sao_Paulo'),
    p(android: '2026-07-05 08:31:30 local', ios: '2026-07-05 05:31:30 local')
  ),
  'hour and minute only': (
    const CalendarSpec(hour: 9, minute: 15, timeZone: 'UTC'),
    '2026-07-05 09:15:00 local'
  ),
  'month only': (const CalendarSpec(month: 9, timeZone: 'UTC'), '2026-09-01 00:00:00 local'),
  'same minute already passed': (
    const CalendarSpec(hour: 8, minute: 30, second: 0, timeZone: 'UTC'),
    p(android: '2026-07-06 08:30:00 local', ios: '2026-07-05 08:30:00 local')
  ),
  'New York across DST': (
    const CalendarSpec(hour: 9, minute: 0, second: 0, timeZone: 'America/New_York'),
    p(android: '2026-07-05 09:00:00 local', ios: '2026-07-05 09:00:00 local')
  ),
};

/// name → (schedule, "createNotification result, listed=...").
final Map<String, (ScheduleSpec, String)> _createTable = {
  // 0.12 Android answers false for a scheduled notification, yet schedules it.
  'interval 1 h': (
    const IntervalSpec(Duration(hours: 1)),
    p(android: 'false, listed=true', ios: 'true, listed=true')
  ),
  'repeating interval of 30 s': (
    const IntervalSpec(Duration(seconds: 30), repeats: true),
    'exception, listed=false'
  ),
  'interval of 0 s': (const IntervalSpec(Duration.zero), 'exception, listed=false'),
  'calendar in the past': (
    const CalendarSpec(year: 2020, month: 1, day: 1, hour: 0),
    'false, listed=false'
  ),
  'invalid hour 24': (const CalendarSpec(hour: 24), 'exception, listed=false'),
  'empty calendar': (const CalendarSpec(), 'exception, listed=false'),
  'repeating interval of 60 s': (
    const IntervalSpec(Duration(seconds: 60), repeats: true),
    p(android: 'false, listed=true', ios: 'true, listed=true')
  ),
  'repeating calendar': (
    const CalendarSpec(second: 0, repeats: true),
    p(android: 'false, listed=true', ios: 'true, listed=true')
  ),
};
