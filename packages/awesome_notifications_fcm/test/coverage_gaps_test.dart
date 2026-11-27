import 'package:awesome_notifications/awesome_notifications.dart' show NOTIFICATION_ID;
import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FcmSilentData read twice keeps only the latest data', () {
    final silent = FcmSilentData()
      ..fromMap({NOTIFICATION_ID: 1, 'a': 'x'})
      ..fromMap({NOTIFICATION_ID: 2, 'b': 'y'});
    expect(silent.id, 2);
    expect(silent.data, {'b': 'y'});
    silent.validate(); // nothing to validate
  });
}
