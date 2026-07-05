import 'dart:ui' show Color;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationChannel', () {
    test('round-trips through toMap/fromMap', () {
      final channel = NotificationChannel(
        channelKey: 'basic',
        channelName: 'Basic',
        channelDescription: 'Basic channel',
        importance: NotificationImportance.High,
        playSound: true,
        channelShowBadge: true,
        defaultColor: const Color(0xFF9D50DD),
      );
      final restored = NotificationChannel(
        channelKey: '',
        channelName: '',
        channelDescription: '',
      ).fromMap(channel.toMap());

      expect(restored.channelKey, 'basic');
      expect(restored.channelName, 'Basic');
      expect(restored.importance, NotificationImportance.High);
      expect(restored.playSound, true);
      expect(restored.channelShowBadge, true);
    });

    test('round-trips enum, color and group fields', () {
      final channel = NotificationChannel(
        channelKey: 'ch',
        channelName: 'C',
        channelDescription: 'd',
        importance: NotificationImportance.Max,
        defaultPrivacy: NotificationPrivacy.Private,
        defaultRingtoneType: DefaultRingtoneType.Notification,
        groupSort: GroupSort.Desc,
        groupAlertBehavior: GroupAlertBehavior.Children,
        ledColor: const Color(0xFFFF0000),
        soundSource: 'resource://raw/snd',
        channelGroupKey: 'grp',
        groupKey: 'gk',
        onlyAlertOnce: true,
        locked: true,
        enableLights: true,
        enableVibration: true,
        criticalAlerts: true,
        ledOnMs: 300,
        ledOffMs: 700,
      );
      final r = NotificationChannel(
              channelKey: '', channelName: '', channelDescription: '')
          .fromMap(channel.toMap());
      expect(r.importance, NotificationImportance.Max);
      expect(r.defaultPrivacy, NotificationPrivacy.Private);
      expect(r.groupSort, GroupSort.Desc);
      expect(r.groupAlertBehavior, GroupAlertBehavior.Children);
      expect(r.defaultRingtoneType, DefaultRingtoneType.Notification);
      expect(r.ledColor?.value, const Color(0xFFFF0000).value);
      expect(r.soundSource, 'resource://raw/snd');
      expect(r.locked, true);
      expect(channel.toString(), contains('channelKey'));
    });

    test('validate throws on any missing required field', () {
      expect(
          () => NotificationChannel(
                  channelKey: '', channelName: 'n', channelDescription: 'd')
              .validate(),
          throwsA(isA<AwesomeNotificationsException>()));
      expect(
          () => NotificationChannel(
                  channelKey: 'k', channelName: '', channelDescription: 'd')
              .validate(),
          throwsA(isA<AwesomeNotificationsException>()));
      expect(
          () => NotificationChannel(
                  channelKey: 'k', channelName: 'n', channelDescription: '')
              .validate(),
          throwsA(isA<AwesomeNotificationsException>()));
    });
  });

  group('NotificationChannelGroup', () {
    test('round-trips key and name', () {
      final group = NotificationChannelGroup(
        channelGroupKey: 'grp',
        channelGroupName: 'Group',
      );
      final restored =
          NotificationChannelGroup(channelGroupKey: '', channelGroupName: '')
              .fromMap(group.toMap());
      expect(restored?.channelGroupKey, 'grp');
      expect(restored?.channelGroupName, 'Group');
    });

    test('validate throws on missing key or name', () {
      expect(
          () => NotificationChannelGroup(
                  channelGroupKey: '', channelGroupName: 'n')
              .validate(),
          throwsA(isA<AwesomeNotificationsException>()));
      expect(
          () => NotificationChannelGroup(
                  channelGroupKey: 'k', channelGroupName: '')
              .validate(),
          throwsA(isA<AwesomeNotificationsException>()));
    });
  });

  group('NotificationActionButton', () {
    test('round-trips key, label, actionType and flags', () {
      final button = NotificationActionButton(
        key: 'YES',
        label: 'Yes',
        actionType: ActionType.SilentAction,
        autoDismissible: false,
        isDangerousOption: true,
      );
      final restored =
          NotificationActionButton(key: '', label: '').fromMap(button.toMap());
      expect(restored?.key, 'YES');
      expect(restored?.label, 'Yes');
      expect(restored?.actionType, ActionType.SilentAction);
      expect(restored?.autoDismissible, false);
      expect(restored?.isDangerousOption, true);
    });
  });

  group('NotificationContent', () {
    test('round-trips extended fields', () {
      final content = NotificationContent(
        id: 1,
        channelKey: 'ch',
        title: 'T',
        body: 'B',
        payload: {'uuid': 'abc'},
        notificationLayout: NotificationLayout.BigPicture,
        color: const Color(0xFF0000FF),
        wakeUpScreen: true,
      );
      final restored =
          NotificationContent(id: 0, channelKey: '').fromMap(content.toMap());
      expect(restored?.id, 1);
      expect(restored?.payload, {'uuid': 'abc'});
      expect(restored?.notificationLayout, NotificationLayout.BigPicture);
      expect(restored?.wakeUpScreen, true);
    });
  });

  group('ReceivedNotification', () {
    test('parses created/displayed lifecycle from a map', () {
      final received = ReceivedNotification().fromMap({
        NOTIFICATION_ID: 5,
        NOTIFICATION_CHANNEL_KEY: 'ch',
        NOTIFICATION_CREATED_DATE: '2026-07-05 20:56:23',
        NOTIFICATION_CREATED_SOURCE: 'Schedule',
        NOTIFICATION_CREATED_LIFECYCLE: 'Foreground',
        NOTIFICATION_DISPLAYED_DATE: '2026-07-05 20:56:30',
        NOTIFICATION_DISPLAYED_LIFECYCLE: 'Background',
      });
      expect(received.id, 5);
      expect(received.createdSource, NotificationSource.Schedule);
      expect(received.createdLifeCycle, NotificationLifeCycle.Foreground);
      expect(received.displayedLifeCycle, NotificationLifeCycle.Background);
      expect(received.createdDate, isA<DateTime>());
    });
  });

  group('ReceivedAction', () {
    test('parses action fields from a map', () {
      final action = ReceivedAction().fromMap({
        NOTIFICATION_ID: 5,
        NOTIFICATION_CHANNEL_KEY: 'ch',
        NOTIFICATION_ACTION_DATE: '2026-07-05 20:56:40',
        NOTIFICATION_ACTION_LIFECYCLE: 'Foreground',
        NOTIFICATION_BUTTON_KEY_PRESSED: 'YES',
        NOTIFICATION_BUTTON_KEY_INPUT: 'hi there',
      });
      expect(action.id, 5);
      expect(action.actionLifeCycle, NotificationLifeCycle.Foreground);
      expect(action.buttonKeyPressed, 'YES');
      expect(action.buttonKeyInput, 'hi there');
      expect(action.actionDate, isA<DateTime>());
    });

    test('re-serializes through toMap', () {
      final action = ReceivedAction().fromMap({
        NOTIFICATION_ID: 5,
        NOTIFICATION_CHANNEL_KEY: 'ch',
        NOTIFICATION_ACTION_DATE: '2026-07-05 20:56:40',
        NOTIFICATION_ACTION_LIFECYCLE: 'Foreground',
        NOTIFICATION_BUTTON_KEY_PRESSED: 'YES',
      });
      final map = action.toMap();
      expect(map[NOTIFICATION_ID], 5);
      expect(map[NOTIFICATION_BUTTON_KEY_PRESSED], 'YES');
      expect(map[NOTIFICATION_ACTION_LIFECYCLE], 'Foreground');
    });
  });

  group('NotificationContent (all fields)', () {
    test('round-trips every property', () {
      final content = NotificationContent(
        id: 7,
        channelKey: 'ch',
        title: 'Title',
        body: 'Body',
        summary: 'Summary',
        titleLocKey: 'title.key',
        bodyLocKey: 'body.key',
        titleLocArgs: ['a', 'b'],
        bodyLocArgs: ['c'],
        groupKey: 'grp',
        icon: 'resource://drawable/ic',
        largeIcon: 'asset://large.png',
        bigPicture: 'https://x/big.png',
        customSound: 'resource://raw/snd',
        showWhen: false,
        wakeUpScreen: true,
        fullScreenIntent: true,
        criticalAlert: true,
        roundedLargeIcon: true,
        roundedBigPicture: true,
        autoDismissible: false,
        color: const Color(0xFF00FF00),
        backgroundColor: const Color(0xFF112233),
        timeoutAfter: const Duration(seconds: 30),
        chronometer: const Duration(seconds: 5),
        actionType: ActionType.SilentAction,
        notificationLayout: NotificationLayout.BigPicture,
        payload: {'uuid': 'abc', 'empty': null},
        category: NotificationCategory.Alarm,
        hideLargeIconOnExpand: true,
        locked: true,
        progress: 42,
        badge: 3,
        ticker: 'tick',
        displayOnForeground: false,
        displayOnBackground: false,
        duration: const Duration(minutes: 2),
        playState: NotificationPlayState.playing,
        playbackSpeed: 1.5,
      );

      final r = NotificationContent(id: 0, channelKey: '').fromMap(content.toMap());
      expect(r, isNotNull);
      expect(r!.id, 7);
      expect(r.title, 'Title');
      expect(r.summary, 'Summary');
      expect(r.notificationLayout, NotificationLayout.BigPicture);
      expect(r.category, NotificationCategory.Alarm);
      expect(r.actionType, ActionType.SilentAction);
      expect(r.criticalAlert, true);
      expect(r.wakeUpScreen, true);
      expect(r.autoDismissible, false);
      expect(r.locked, true);
      expect(r.badge, 3);
      expect(r.progress, 42);
      expect(r.displayOnForeground, false);
      expect(r.color?.value, const Color(0xFF00FF00).value);
      expect(r.chronometer, const Duration(seconds: 5));
      expect(r.payload, {'uuid': 'abc', 'empty': null});
      // toString runs the pretty-printer over the full map.
      expect(content.toString(), contains('channelKey'));
    });

    test('validate throws without id or channelKey', () {
      expect(() => NotificationContent(id: 0, channelKey: '').validate(),
          throwsA(isA<AwesomeNotificationsException>()));
    });

    test('fromMap applies retro-compatibility (autoCancel, AppKilled)', () {
      final c = NotificationContent(id: 0, channelKey: '').fromMap({
        NOTIFICATION_ID: 1,
        NOTIFICATION_CHANNEL_KEY: 'ch',
        'autoCancel': true,
        NOTIFICATION_CREATED_LIFECYCLE: 'AppKilled',
      });
      // The retro-compat pass rewrites autoCancel + AppKilled without failing.
      expect(c, isNotNull);
      expect(c!.id, 1);
    });
  });

  group('NotificationActionButton (all fields)', () {
    test('round-trips every property', () {
      final button = NotificationActionButton(
        key: 'REPLY',
        label: 'Reply',
        icon: 'resource://drawable/ic',
        enabled: true,
        requireInputText: true,
        autoDismissible: false,
        showInCompactView: true,
        isDangerousOption: true,
        actionType: ActionType.SilentBackgroundAction,
        color: const Color(0xFFAABBCC),
        isAuthenticationRequired: true,
      );
      final r =
          NotificationActionButton(key: '', label: '').fromMap(button.toMap());
      expect(r?.key, 'REPLY');
      expect(r?.icon, 'resource://drawable/ic');
      expect(r?.requireInputText, true);
      expect(r?.actionType, ActionType.SilentBackgroundAction);
      expect(r?.isDangerousOption, true);
      expect(r?.color?.value, const Color(0xFFAABBCC).value);
    });

    test('validate throws without a key', () {
      expect(() => NotificationActionButton(key: '', label: 'x').validate(),
          throwsA(isA<AwesomeNotificationsException>()));
    });

    test('omits a null color and accepts the deprecated buttonType key', () {
      expect(
          NotificationActionButton(key: 'K', label: 'L').toMap()[NOTIFICATION_COLOR],
          isNull);
      final button = NotificationActionButton(key: '', label: '').fromMap({
        NOTIFICATION_KEY: 'X',
        NOTIFICATION_BUTTON_LABEL: 'x',
        'buttonType': 'KeepOnTop', // legacy alias path
      });
      expect(button, isNotNull);
      expect(button!.key, 'X');
    });

    test('getters, retro-compat and resource-only icon validation', () {
      final button = NotificationActionButton(
        key: 'K',
        label: 'L',
        requireInputText: true,
        showInCompactView: true,
        isAuthenticationRequired: true,
      );
      // Read the boolean getters.
      button.enabled;
      button.requireInputText;
      button.autoDismissible;
      button.showInCompactView;
      button.isDangerousOption;
      button.isAuthenticationRequired;

      // The deprecated `autoCancel` key maps onto autoDismissible.
      final retro = NotificationActionButton(key: '', label: '').fromMap({
        NOTIFICATION_KEY: 'K',
        NOTIFICATION_BUTTON_LABEL: 'L',
        'autoCancel': false,
      });
      expect(retro?.autoDismissible, false);

      // Action-button icons must be native resources.
      expect(
          () => NotificationActionButton(
                  key: 'K', label: 'L', icon: 'https://x/ic.png')
              .validate(),
          throwsA(isA<AwesomeNotificationsException>()));
    });

    test('deprecated InputField adapts to requireInputText', () {
      final button = NotificationActionButton(
        key: 'K',
        label: 'L',
        // ignore: deprecated_member_use
        actionType: ActionType.InputField,
      );
      final map = button.toMap();
      expect(map[NOTIFICATION_REQUIRE_INPUT_TEXT], true);
      expect(map[NOTIFICATION_ACTION_TYPE], ActionType.SilentAction.name);
    });
  });
}
