/// Rendered-notification cases (Android).
///
/// The event suite only sees what Dart sees. These cases post the same raw
/// notification JSON (`createNotificationFromJsonData`) through 0.12 and 1.0,
/// and `render_diff.sh` compares what Android actually shows, as read from
/// `dumpsys notification`: flags, priority, color, visibility, group,
/// ticker, timeout, chronometer, progress and the style's extras.
library;

import 'package:flutter_test/flutter_test.dart';

/// Printed once every case is posted; `render_diff.sh` dumps then.
const renderReadyMarker = 'AWN_RENDER_READY';

const _resourceImage = 'resource://mipmap/ic_launcher';

/// Channels, as `NotificationChannel.toMap()` writes them.
const List<Map<String, dynamic>> renderChannels = [
  {
    'channelKey': 'render_default',
    'channelName': 'Render default',
    'channelDescription': 'Plain channel',
  },
  {
    'channelKey': 'render_options',
    'channelName': 'Render options',
    'channelDescription': 'Every 0.12 channel option',
    'importance': 'High',
    'defaultPrivacy': 'Public',
    'defaultColor': 0xFF00AA00,
    'groupKey': 'channel_group',
    'groupSort': 'Desc',
    'groupAlertBehavior': 'Summary',
    'onlyAlertOnce': true,
    'channelShowBadge': true,
    'enableLights': true,
    'ledColor': 0xFFFF00FF,
    'ledOnMs': 300,
    'ledOffMs': 700,
    'enableVibration': true,
  },
  {
    'channelKey': 'render_low',
    'channelName': 'Render low',
    'channelDescription': 'Low importance, secret',
    'importance': 'Low',
    'defaultPrivacy': 'Secret',
    'playSound': false,
    'enableVibration': false,
  },
];

Map<String, dynamic> _n(int id, Map<String, dynamic> content,
        {String channel = 'render_default', List<Map<String, dynamic>>? buttons}) =>
    {
      'content': {
        'id': id,
        'channelKey': channel,
        'title': 'Case $id',
        'body': 'Body $id',
        ...content,
      },
      if (buttons != null) 'actionButtons': buttons,
    };

/// One notification per 0.12 option or layout; ids are the case numbers.
final List<Map<String, dynamic>> renderNotifications = [
  _n(1001, {}),
  _n(1002, {'summary': 'Summary text'}),
  _n(1003, {'showWhen': false}),
  _n(1004, {'ticker': 'Ticker text'}),
  _n(1005, {'chronometer': 30}),
  _n(1006, {'timeoutAfter': 600}),
  _n(1007, {'color': 0xFFFF0000}),
  _n(1008, {'backgroundColor': 0xFF0000FF}),
  _n(1009, {'badge': 5}),
  _n(1010, {'privacy': 'Public'}),
  _n(1011, {'notificationLayout': 'ProgressBar', 'progress': 50}),
  _n(1012, {'notificationLayout': 'ProgressBar'}),
  _n(1013, {'notificationLayout': 'ProgressBar', 'progress': 150}),
  _n(1014, {
    'notificationLayout': 'BigText',
    'body': 'A long body that only fits when the notification is expanded. ' * 4,
    'summary': 'Big text summary',
  }),
  _n(1015, {
    'notificationLayout': 'Inbox',
    'body': 'First line\nSecond line\nThird line',
    'summary': 'Inbox summary',
  }),
  _n(1016, {
    'notificationLayout': 'BigPicture',
    'bigPicture': _resourceImage,
    'largeIcon': _resourceImage,
    'hideLargeIconOnExpand': true,
  }),
  _n(1017, {'groupKey': 'content_group'}),
  _n(1018, {'groupKey': 'content_group'}),
  _n(1019, {}, channel: 'render_options'),
  _n(1020, {}, channel: 'render_low'),
  _n(1021, {'locked': true, 'autoDismissible': false}),
  _n(1022, {'largeIcon': _resourceImage, 'roundedLargeIcon': true}),
  _n(1023, {'notificationLayout': 'ProgressBar', 'progress': 20}, channel: 'render_options'),
  _n(1024, {'summary': 'With buttons'}, buttons: [
    {'key': 'ACCEPT', 'label': 'Accept'},
    {'key': 'REPLY', 'label': 'Reply', 'requireInputText': true},
  ]),
];

/// Posts every case, prints [renderReadyMarker] and keeps the app alive while
/// the script reads `dumpsys`.
void defineRenderTests({
  required Future<void> Function(List<Map<String, dynamic>> channels) initialize,
  required Future<bool> Function(Map<String, dynamic> notification) create,
}) {
  testWidgets('render cases', (tester) async {
    await tester.runAsync(() async {
      await initialize(renderChannels);
      for (final notification in renderNotifications) {
        final created = await create(notification);
        // ignore: avoid_print
        print('render ${notification['content']['id']}: $created');
      }
      await Future<void>.delayed(const Duration(seconds: 3));
      // ignore: avoid_print
      print(renderReadyMarker);
      await Future<void>.delayed(const Duration(seconds: 20));
    });
  }, timeout: const Timeout(Duration(minutes: 2)));
}
