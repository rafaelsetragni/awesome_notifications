import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() {
  group('NotificationAndroidCrontab', () {
    test('Constructors and toMap', () {
      DateTime initialDate = DateTime(2023, 5, 1);
      DateTime expirationDate = DateTime(2023, 5, 31);
      DateTime referenceDate = DateTime(2023, 5, 15, 14, 30);
      String crontabExpression = '0 30 14 * * *';

      // Test main constructor
      NotificationAndroidCrontab crontab = NotificationAndroidCrontab(
          initialDateTime: initialDate,
          expirationDateTime: expirationDate,
          crontabExpression: crontabExpression);
      expect(crontab.initialDateTime, initialDate);
      expect(crontab.expirationDateTime, expirationDate);
      expect(crontab.crontabExpression, crontabExpression);

      // Test fromDate constructor
      NotificationAndroidCrontab crontabFromDate =
          NotificationAndroidCrontab.fromDate(date: referenceDate);
      expect(crontabFromDate.initialDateTime, referenceDate);

      // Test daily constructor
      NotificationAndroidCrontab crontabDaily =
          NotificationAndroidCrontab.daily(referenceDateTime: referenceDate);
      // Check if crontabDaily has a crontabExpression

      // Test other constructors similarly...

      // Test toMap
      Map<String, dynamic> crontabMap = crontab.toMap();
      expect(crontabMap[NOTIFICATION_INITIAL_DATE_TIME],
          AwesomeDateUtils.parseDateToString(initialDate));
      expect(crontabMap[NOTIFICATION_EXPIRATION_DATE_TIME],
          AwesomeDateUtils.parseDateToString(expirationDate));
      expect(crontabMap[NOTIFICATION_CRONTAB_EXPRESSION], crontabExpression);
    });

    test('fromMap', () {
      DateTime initialDate = DateTime(2023, 5, 1);
      DateTime expirationDate = DateTime(2023, 5, 31);
      String crontabExpression = '0 30 14 * * *';

      Map<String, dynamic> crontabMap = {
        NOTIFICATION_INITIAL_DATE_TIME:
            AwesomeDateUtils.parseDateToString(initialDate),
        NOTIFICATION_EXPIRATION_DATE_TIME:
            AwesomeDateUtils.parseDateToString(expirationDate),
        NOTIFICATION_CRONTAB_EXPRESSION: crontabExpression
      };

      NotificationAndroidCrontab crontab = NotificationAndroidCrontab()
          .fromMap(crontabMap) as NotificationAndroidCrontab;

      expect(crontab.initialDateTime, initialDate);
      expect(crontab.expirationDateTime, expirationDate);
      expect(crontab.crontabExpression, crontabExpression);
    });
  });
}
