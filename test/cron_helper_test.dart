import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_notifications/src/enumerators/time_and_date.dart';
import 'package:awesome_notifications/src/helpers/cron_helper.dart';

void main() {

  TestWidgetsFlutterBinding.ensureInitialized();
  DateTime fixedDate;
  CronHelper cronTest;

  setUp(() {
    fixedDate = DateTime.utc(2020, 8, 20, 20, 38, 5);
    cronTest = CronHelper.private(fixedNow: fixedDate);
  });

  tearDown(() {
  });

  test('test crontab helpers', () async {
    expect(cronTest.atDate(fixedDate), '5 38 20 20 8 ? 2020');
    expect(cronTest.yearly(),          '5 38 20 20 8 ? *');
    expect(cronTest.monthly(),         '5 38 20 20 * ? *');
    expect(cronTest.weekly(),          '5 38 20 ? 8 $THU *');
    expect(cronTest.daily(),           '5 38 20 * * ? *');
    expect(cronTest.hourly(),          '5 38 * * * ? *');
    expect(cronTest.minutely(),        '5 * * * * ? *');
    expect(cronTest.workweekDay(),     '5 38 20 ? * $MON-$FRI *');
    expect(cronTest.weekendDay(),      '5 38 20 ? * $SAT,$SUN *');
  });
}
