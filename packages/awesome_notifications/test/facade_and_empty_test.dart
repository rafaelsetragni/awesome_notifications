import 'dart:typed_data';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/awesome_notifications_empty.dart';
import 'package:awesome_notifications/awesome_notifications_platform.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _onAction(ReceivedAction a) async {}

/// A platform that records the last delegated call (method + salient argument)
/// and returns distinctive sentinels, so the facade tests can assert each
/// `AwesomeNotifications()` method forwards the right call AND passes the result
/// back — real delegation verification, not just "did not throw".
class _RecordingPlatform extends AwesomeNotificationsEmpty {
  String? method;
  Object? arg;

  T _rec<T>(String m, T ret, [Object? a]) {
    method = m;
    arg = a;
    return ret;
  }

  @override
  Future<bool> initialize(String? defaultIcon, List<NotificationChannel> channels,
          {List<NotificationChannelGroup>? channelGroups, bool debug = false}) async =>
      _rec('initialize', true);

  @override
  Future<bool> setListeners(
          {required ActionHandler onActionReceivedMethod,
          NotificationHandler? onNotificationCreatedMethod,
          NotificationHandler? onNotificationDisplayedMethod,
          ActionHandler? onDismissActionReceivedMethod}) async =>
      _rec('setListeners', true);

  @override
  Future<Uint8List?> getDrawableData(String path) async =>
      _rec('getDrawableData', Uint8List.fromList([9]), path);

  @override
  Future<bool> createNotification(
          {required NotificationContent content,
          List<NotificationActionButton>? actionButtons,
          List<NotificationExtension>? extensions}) async =>
      _rec('createNotification', true, content.id);

  @override
  Future<bool> createNotificationFromJsonData(Map<String, dynamic> mapData) async =>
      _rec('createNotificationFromJsonData', true);

  @override
  Future<ReceivedAction?> getInitialNotificationAction(
          {bool removeFromActionEvents = false}) async =>
      _rec('getInitialNotificationAction', null);

  @override
  Future<void> showNotificationConfigPage({String? channelKey}) async =>
      _rec('showNotificationConfigPage', null, channelKey);

  @override
  Future<void> showAlarmPage() async => _rec('showAlarmPage', null);

  @override
  Future<void> showGlobalDndOverridePage() async =>
      _rec('showGlobalDndOverridePage', null);

  @override
  Future<bool> isNotificationAllowed() async => _rec('isNotificationAllowed', true);

  @override
  Future<bool> isNotificationActiveOnStatusBar({required int id}) async =>
      _rec('isNotificationActiveOnStatusBar', true, id);

  @override
  Future<List<int>> getAllActiveNotificationIdsOnStatusBar() async =>
      _rec('getAllActiveNotificationIdsOnStatusBar', <int>[7]);

  @override
  Future<bool> requestPermissionToSendNotifications(
          {String? channelKey,
          List<NotificationPermission> permissions = const []}) async =>
      _rec('requestPermissionToSendNotifications', true);

  @override
  Future<List<NotificationPermission>> checkPermissionList(
          {String? channelKey,
          List<NotificationPermission> permissions = const []}) async =>
      _rec('checkPermissionList', const [NotificationPermission.Alert], channelKey);

  @override
  Future<List<NotificationPermission>> shouldShowRationaleToRequest(
          {String? channelKey,
          List<NotificationPermission> permissions = const []}) async =>
      _rec('shouldShowRationaleToRequest', const [NotificationPermission.Sound]);

  @override
  Future<void> setChannel(NotificationChannel channel,
          {bool forceUpdate = false}) async =>
      _rec('setChannel', null, channel.channelKey);

  @override
  Future<bool> removeChannel(String channelKey) async =>
      _rec('removeChannel', true, channelKey);

  @override
  Future<int> getGlobalBadgeCounter() async => _rec('getGlobalBadgeCounter', 11);

  @override
  Future<void> setGlobalBadgeCounter(int? amount) async =>
      _rec('setGlobalBadgeCounter', null, amount);

  @override
  Future<int> incrementGlobalBadgeCounter() async =>
      _rec('incrementGlobalBadgeCounter', 12);

  @override
  Future<int> decrementGlobalBadgeCounter() async =>
      _rec('decrementGlobalBadgeCounter', 13);

  @override
  Future<void> resetGlobalBadge() async => _rec('resetGlobalBadge', null);

  @override
  Future<String> getUtcTimeZoneIdentifier() async =>
      _rec('getUtcTimeZoneIdentifier', 'UTCZ');

  @override
  Future<String> getLocalTimeZoneIdentifier() async =>
      _rec('getLocalTimeZoneIdentifier', 'LOCZ');

  @override
  Future<NotificationLifeCycle> getAppLifeCycle() async =>
      _rec('getAppLifeCycle', NotificationLifeCycle.Foreground);

  @override
  Future<void> cancel(int id) async => _rec('cancel', null, id);

  @override
  Future<void> dismiss(int id) async => _rec('dismiss', null, id);

  @override
  Future<void> dismissNotificationsByChannelKey(String channelKey) async =>
      _rec('dismissNotificationsByChannelKey', null, channelKey);

  @override
  Future<void> cancelNotificationsByChannelKey(String channelKey) async =>
      _rec('cancelNotificationsByChannelKey', null, channelKey);

  @override
  Future<void> dismissNotificationsByGroupKey(String groupKey) async =>
      _rec('dismissNotificationsByGroupKey', null, groupKey);

  @override
  Future<void> cancelNotificationsByGroupKey(String groupKey) async =>
      _rec('cancelNotificationsByGroupKey', null, groupKey);

  @override
  Future<void> dismissAllNotifications() async =>
      _rec('dismissAllNotifications', null);

  @override
  Future<void> cancelAll() async => _rec('cancelAll', null);

  @override
  void dispose() => _rec('dispose', null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AwesomeNotificationsEmpty', () {
    final empty = AwesomeNotificationsEmpty();

    test('honors its documented no-op contract', () async {
      AwesomeNotifications.localTimeZoneIdentifier = 'Local/Zone';
      AwesomeNotifications.utcTimeZoneIdentifier = 'UTC';

      expect(await empty.initialize(null, const []), isTrue);
      expect(
          await empty.createNotification(
              content: NotificationContent(id: 1, channelKey: 'ch')),
          isFalse);
      expect(await empty.createNotificationFromJsonData({}), isFalse);
      expect(await empty.isNotificationAllowed(), isFalse);
      expect(await empty.removeChannel('x'), isFalse);
      expect(await empty.requestPermissionToSendNotifications(), isFalse);
      expect(await empty.isNotificationActiveOnStatusBar(id: 1), isFalse);
      expect(await empty.getGlobalBadgeCounter(), 0);
      expect(await empty.incrementGlobalBadgeCounter(), 0);
      expect(await empty.decrementGlobalBadgeCounter(), 0);
      expect(await empty.getAppLifeCycle(), NotificationLifeCycle.Terminated);
      expect(await empty.getDrawableData('x'), isNull);
      expect(await empty.getInitialNotificationAction(), isNull);
      expect(await empty.getAllActiveNotificationIdsOnStatusBar(), <int>[]);
      expect(await empty.shouldShowRationaleToRequest(),
          <NotificationPermission>[]);
      const perms = [NotificationPermission.Alert];
      expect(await empty.checkPermissionList(permissions: perms), perms);
      expect(await empty.getLocalTimeZoneIdentifier(), 'Local/Zone');
      expect(await empty.getUtcTimeZoneIdentifier(), 'UTC');
      expect(
          await empty.setListeners(onActionReceivedMethod: _onAction), isTrue);

      // The void operations must complete without throwing.
      await empty.cancel(1);
      await empty.cancelAll();
      await empty.dismiss(1);
      await empty.dismissAllNotifications();
      await empty.cancelNotificationsByChannelKey('c');
      await empty.dismissNotificationsByChannelKey('c');
      await empty.cancelNotificationsByGroupKey('g');
      await empty.dismissNotificationsByGroupKey('g');
      await empty.setChannel(NotificationChannel(
          channelKey: 'ch', channelName: 'Ch', channelDescription: 'd'));
      await empty.setGlobalBadgeCounter(1);
      await empty.resetGlobalBadge();
      await empty.showAlarmPage();
      await empty.showGlobalDndOverridePage();
      await empty.showNotificationConfigPage();
      empty.dispose();
    });
  });

  group('AwesomeNotifications facade', () {
    late _RecordingPlatform p;
    final awn = AwesomeNotifications();

    setUp(() {
      p = _RecordingPlatform();
      AwesomeNotificationsPlatform.instance = p;
    });

    test('forwards every method to the platform and passes results back',
        () async {
      final channel = NotificationChannel(
          channelKey: 'ch', channelName: 'Ch', channelDescription: 'd');

      expect(await awn.initialize(null, [channel]), isTrue);
      expect(p.method, 'initialize');

      expect(await awn.setListeners(onActionReceivedMethod: _onAction), isTrue);
      expect(p.method, 'setListeners');

      expect(await awn.getDrawableData('res'), isA<Uint8List>());
      expect(p.arg, 'res');

      expect(
          await awn.createNotification(
              content: NotificationContent(id: 42, channelKey: 'ch')),
          isTrue);
      expect(p.method, 'createNotification');
      expect(p.arg, 42);

      expect(await awn.createNotificationFromJsonData({}), isTrue);
      expect(p.method, 'createNotificationFromJsonData');

      expect(await awn.getInitialNotificationAction(), isNull);
      expect(p.method, 'getInitialNotificationAction');

      expect(await awn.isNotificationAllowed(), isTrue);
      expect(await awn.isNotificationActiveOnStatusBar(id: 5), isTrue);
      expect(p.arg, 5);
      expect(await awn.getAllActiveNotificationIdsOnStatusBar(), [7]);
      expect(await awn.requestPermissionToSendNotifications(), isTrue);
      expect(await awn.checkPermissionList(channelKey: 'ch'),
          const [NotificationPermission.Alert]);
      expect(p.arg, 'ch');
      expect(await awn.shouldShowRationaleToRequest(),
          const [NotificationPermission.Sound]);

      await awn.setChannel(channel);
      expect(p.method, 'setChannel');
      expect(p.arg, 'ch');
      expect(await awn.removeChannel('ch'), isTrue);

      expect(await awn.getGlobalBadgeCounter(), 11);
      await awn.setGlobalBadgeCounter(7);
      expect(p.arg, 7);
      expect(await awn.incrementGlobalBadgeCounter(), 12);
      expect(await awn.decrementGlobalBadgeCounter(), 13);
      await awn.resetGlobalBadge();
      expect(p.method, 'resetGlobalBadge');

      expect(await awn.getUtcTimeZoneIdentifier(), 'UTCZ');
      expect(await awn.getLocalTimeZoneIdentifier(), 'LOCZ');
      expect(await awn.getAppLifeCycle(), NotificationLifeCycle.Foreground);

      await awn.cancel(3);
      expect(p.arg, 3);
      await awn.dismiss(8);
      expect(p.arg, 8);
      await awn.dismissNotificationsByChannelKey('a');
      expect(p.method, 'dismissNotificationsByChannelKey');
      await awn.cancelNotificationsByChannelKey('b');
      expect(p.method, 'cancelNotificationsByChannelKey');
      await awn.dismissNotificationsByGroupKey('c');
      expect(p.method, 'dismissNotificationsByGroupKey');
      await awn.cancelNotificationsByGroupKey('d');
      expect(p.method, 'cancelNotificationsByGroupKey');
      await awn.dismissAllNotifications();
      expect(p.method, 'dismissAllNotifications');
      await awn.cancelAll();
      expect(p.method, 'cancelAll');

      await awn.showNotificationConfigPage(channelKey: 'x');
      await awn.showAlarmPage();
      await awn.showGlobalDndOverridePage();
      expect(p.method, 'showGlobalDndOverridePage');

      awn.dispose();
      expect(p.method, 'dispose');
    });
  });
}
