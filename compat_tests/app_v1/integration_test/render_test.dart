// Posts the rendered-notification cases (see suite/lib/render_cases.dart);
// render_diff.sh compares what Android shows for 0.12 and 1.0.
import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awn_compat_suite/render_cases.dart';
import 'package:integration_test/integration_test.dart';

Map<String, dynamic> _copy(Map<String, dynamic> map) =>
    (jsonDecode(jsonEncode(map)) as Map).cast<String, dynamic>();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  defineRenderTests(
    initialize: (channels) => AwesomeNotifications().initialize(null, [
      for (final channel in channels)
        NotificationChannel(channelKey: '', channelName: '', channelDescription: '')
            .fromMap(_copy(channel)),
    ]).then((_) {}),
    create: (notification) =>
        AwesomeNotifications().createNotificationFromJsonData(_copy(notification)),
  );
}
