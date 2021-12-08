import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_test/flutter_test.dart';

void main() {
  //const MethodChannel channel = MethodChannel('awesome_notifications');
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {});

  tearDown(() {});

  test('getPlatformVersion', () async {
    DateTime referenceDate =
        DateUtils.parseStringToDate('2021-01-12 20:00:00')!;
    DateTime expectedDate = DateUtils.parseStringToDate('2021-01-12 21:00:00')!;
    NotificationSchedule schedule = NotificationCalendar.fromDate(date: expectedDate);

    DateTime? result = await AwesomeNotifications()
        .getNextDate(schedule, fixedDate: referenceDate);
    expect(result, expectedDate);
  });
}
