import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_schedules/awesome_notifications_schedules.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationInterval', () {
    test('serializes as a schedule extension and round-trips', () {
      final interval = NotificationInterval(
        interval: const Duration(seconds: 90),
        timeZone: 'UTC',
        repeats: true,
        allowWhileIdle: true,
      );

      // NotificationExtension contract: wraps everything under `schedule`.
      final map = interval.toMap();
      final schedule = map[NOTIFICATION_SCHEDULE] as Map<String, dynamic>;
      expect(schedule[NOTIFICATION_SCHEDULE_INTERVAL], 90);
      expect(schedule[NOTIFICATION_SCHEDULE_REPEATS], true);
      expect(schedule[NOTIFICATION_SCHEDULE_TIMEZONE], 'UTC');

      // toScheduleMap round-trips through fromMap.
      final restored =
          NotificationInterval(interval: Duration.zero).fromMap(schedule);
      expect(restored?.interval, const Duration(seconds: 90));
      expect(restored?.repeats, true);
      expect(interval.toString(), contains('interval'));
    });

    test('validate rejects negative and short repeating intervals', () {
      expect(() => NotificationInterval(interval: const Duration(seconds: -1)).validate(),
          throwsA(isA<AwesomeNotificationsException>()));
      expect(
          () => NotificationInterval(
                  interval: const Duration(seconds: 30), repeats: true)
              .validate(),
          throwsA(isA<AwesomeNotificationsException>()));
      // A valid one does not throw.
      NotificationInterval(interval: const Duration(seconds: 60), repeats: true)
          .validate();
    });
  });

  group('NotificationCalendar', () {
    test('serializes calendar components and round-trips', () {
      final calendar = NotificationCalendar(
        hour: 8,
        minute: 30,
        second: 0,
        weekday: 1,
        timeZone: 'UTC',
        repeats: true,
      );
      final schedule =
          calendar.toMap()[NOTIFICATION_SCHEDULE] as Map<String, dynamic>;
      expect(schedule[NOTIFICATION_SCHEDULE_HOUR], 8);
      expect(schedule[NOTIFICATION_SCHEDULE_WEEKDAY], 1);

      final restored = NotificationCalendar().fromMap(schedule);
      expect(restored?.hour, 8);
      expect(restored?.minute, 30);
      expect(calendar.toString(), contains('hour'));
    });

    test('fromDate populates the calendar components', () {
      final calendar =
          NotificationCalendar.fromDate(date: DateTime(2026, 7, 5, 9, 15, 30));
      expect(calendar.year, 2026);
      expect(calendar.hour, 9);
      expect(calendar.minute, 15);
    });

    test('validate requires at least one condition', () {
      expect(() => NotificationCalendar().validate(),
          throwsA(isA<AwesomeNotificationsException>()));
    });

    test('weekOfMonth is not implemented', () {
      expect(() => NotificationCalendar(weekOfMonth: 1),
          throwsA(isA<UnimplementedError>()));
    });
  });

  group('AwesomeNotificationsSchedules API', () {
    const channel = MethodChannel('awesome_notifications');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final schedules = AwesomeNotificationsSchedules();
    final calls = <MethodCall>[];

    setUp(() {
      calls.clear();
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        switch (call.method) {
          case CHANNEL_METHOD_GET_NEXT_DATE:
            return '2026-07-05 09:00:00';
          case CHANNEL_METHOD_LIST_ALL_SCHEDULES:
            return <Object>[
              {
                NOTIFICATION_CONTENT: {NOTIFICATION_ID: 1, NOTIFICATION_CHANNEL_KEY: 'ch'},
                NOTIFICATION_SCHEDULE: {
                  NOTIFICATION_SCHEDULE_HOUR: 9,
                  NOTIFICATION_SCHEDULE_WEEKDAY: 1,
                  NOTIFICATION_SCHEDULE_TIMEZONE: 'UTC',
                  NOTIFICATION_SCHEDULE_REPEATS: true,
                },
              },
              {
                NOTIFICATION_CONTENT: {NOTIFICATION_ID: 2, NOTIFICATION_CHANNEL_KEY: 'ch'},
                NOTIFICATION_SCHEDULE: {
                  NOTIFICATION_SCHEDULE_INTERVAL: 3600,
                  NOTIFICATION_SCHEDULE_TIMEZONE: 'UTC',
                },
              },
            ];
          default:
            return null;
        }
      });
    });

    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('cancel operations route to the shared channel', () async {
      await schedules.cancelSchedule(5);
      await schedules.cancelSchedulesByChannelKey('ch');
      await schedules.cancelSchedulesByGroupKey('grp');
      await schedules.cancelAllSchedules();
      expect(calls.map((c) => c.method), [
        CHANNEL_METHOD_CANCEL_SCHEDULE,
        CHANNEL_METHOD_CANCEL_SCHEDULES_BY_CHANNEL_KEY,
        CHANNEL_METHOD_CANCEL_SCHEDULES_BY_GROUP_KEY,
        CHANNEL_METHOD_CANCEL_ALL_SCHEDULES,
      ]);
      expect(calls.first.arguments, 5);
    });

    test('getNextDate serializes the schedule and parses the reply', () async {
      final next = await schedules.getNextDate(
          NotificationCalendar(hour: 9, minute: 0, second: 0));
      // Like 0.12: the reply's wall clock, read as a local DateTime.
      expect(next, DateTime(2026, 7, 5, 9));
      expect(next!.isUtc, isFalse);
      final args = Map<String, dynamic>.from(calls.single.arguments as Map);
      expect(args[NOTIFICATION_SCHEDULE], isA<Map>());
    });

    test('listScheduledNotifications decodes the returned models', () async {
      final list = await schedules.listScheduledNotifications();
      expect(list, hasLength(2));
      expect(list.first.content?.id, 1);
    });

    test('listed models keep their schedule, like 0.12', () async {
      final list = await schedules.listScheduledNotifications();

      final calendar = list.first.schedule as NotificationCalendar;
      expect([calendar.hour, calendar.weekday, calendar.timeZone, calendar.repeats],
          [9, 1, 'UTC', true]);
      final map = list.first.toMap();
      expect((map[NOTIFICATION_SCHEDULE] as Map)[NOTIFICATION_SCHEDULE_HOUR], 9);
      expect((map[NOTIFICATION_CONTENT] as Map)[NOTIFICATION_ID], 1);

      final interval = list.last.schedule as NotificationInterval;
      expect(interval.interval, const Duration(hours: 1));
    });

    test('a model without schedule is listed without it', () async {
      final model = ScheduledNotificationModel().fromMap({
        NOTIFICATION_CONTENT: {NOTIFICATION_ID: 3, NOTIFICATION_CHANNEL_KEY: 'ch'}
      });
      expect(model?.schedule, isNull);
      expect(model?.toMap().containsKey(NOTIFICATION_SCHEDULE), isFalse);
    });

    test('getNextDate answers null when native has no next date', () async {
      messenger.setMockMethodCallHandler(channel, (call) async => null);
      expect(
          await schedules.getNextDate(NotificationCalendar(hour: 9),
              fixedDate: DateTime.utc(2026, 7, 5, 8, 30)),
          isNull);
    });

    test('cancelSchedule rejects ids beyond 32 bits', () {
      expect(() => schedules.cancelSchedule(0x80000000), throwsArgumentError);
    });
  });
}
