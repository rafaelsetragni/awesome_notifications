import 'dart:ui' show Color;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/awesome_notifications_empty.dart';
import 'package:awesome_notifications/awesome_notifications_platform.dart';
import 'package:awesome_notifications/method_channel_awesome_notifications.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart' show ImageProvider;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BaseNotificationContent getters', () {
    test('every getter reads', () {
      final c = NotificationContent(
        id: 1,
        channelKey: 'ch',
        title: '<b>Title</b>',
        body: '<i>Body</i>',
        summary: 'S',
        largeIcon: 'asset://l.png',
        bigPicture: 'https://x/b.png',
        icon: 'resource://drawable/ic',
        color: const Color(0xFF00FF00),
        backgroundColor: const Color(0xFF112233),
        payload: {'x': 'y'},
        category: NotificationCategory.Alarm,
        actionType: ActionType.Default,
        timeoutAfter: const Duration(seconds: 1),
        chronometer: const Duration(seconds: 2),
      );

      // Plain field getters.
      expect(c.id, 1);
      expect(c.channelKey, 'ch');
      c.title;
      c.body;
      c.summary;
      c.icon;
      c.largeIcon;
      c.bigPicture;
      c.customSound;
      c.showWhen;
      c.wakeUpScreen;
      c.fullScreenIntent;
      c.criticalAlert;
      c.roundedLargeIcon;
      c.roundedBigPicture;
      c.autoDismissible;
      c.color;
      c.backgroundColor;
      c.timeoutAfter;
      c.chronometer;
      c.actionType;
      c.payload;
      c.category;
      c.groupKey;
      c.createdDate;
      c.createdSource;
      c.createdLifeCycle;
      c.displayedDate;
      c.displayedLifeCycle;
      c.privacy;
      c.largeIconPath;
      c.bigPicturePath;
      // ignore: deprecated_member_use
      c.autoCancel;
      // ignore: deprecated_member_use
      c.autoDismissable;
      c.bodyLockKey;
      c.titleLockKey;
      c.bodyLockArgs;
      c.titleLockArgs;

      // Derived getters.
      expect(c.titleWithoutHtml, 'Title');
      expect(c.bodyWithoutHtml, 'Body');
      expect(c.largeIconImage, isA<ImageProvider>());
      expect(c.bigPictureImage, isA<ImageProvider>());
    });

    test('visibleForTesting setters assign', () {
      final c = NotificationContent(id: 1, channelKey: 'ch');
      c.privacy = NotificationPrivacy.Public;
      c.actionType = ActionType.KeepOnTop;
      c.displayedDate = DateTime(2026, 7, 5);
      c.createdDate = DateTime(2026, 7, 5);
      expect(c.actionType, ActionType.KeepOnTop);
      expect(c.privacy, NotificationPrivacy.Public);
    });

    test('image + html getters are null when absent', () {
      final bare = NotificationContent(id: 1, channelKey: 'ch');
      expect(bare.largeIconImage, isNull);
      expect(bare.bigPictureImage, isNull);
      expect(bare.titleWithoutHtml, isNull);
      expect(bare.bodyWithoutHtml, isNull);
      expect(bare.largeIconPath, isNull);
      expect(bare.bigPicturePath, isNull);
    });

    test('NotificationContent own getters read', () {
      final c = NotificationContent(
        id: 1,
        channelKey: 'ch',
        badge: 3,
        progress: 50,
        ticker: 'tick',
        locked: true,
        playState: NotificationPlayState.playing,
        playbackSpeed: 1.25,
        duration: const Duration(seconds: 1),
        hideLargeIconOnExpand: true,
        notificationLayout: NotificationLayout.Inbox,
        displayOnForeground: false,
        displayOnBackground: false,
      );
      expect(c.badge, 3);
      expect(c.progress, 50);
      expect(c.notificationLayout, NotificationLayout.Inbox);
      c.ticker;
      c.locked;
      c.playState;
      c.playbackSpeed;
      c.duration;
      c.hideLargeIconOnExpand;
      c.displayOnForeground;
      c.displayOnBackground;
    });
  });

  group('AwesomeAssertUtils edge cases', () {
    test('getValueOrDefault', () {
      expect(AwesomeAssertUtils.getValueOrDefault<String>('title', 'x'), 'x');
      // A value of the wrong type falls back to the reference default.
      expect(AwesomeAssertUtils.getValueOrDefault<int>('title', 'not-int'),
          isNull);
    });

    test('extractMap', () {
      expect(AwesomeAssertUtils.extractMap<String, dynamic>('k', {
        'k': {'a': 1}
      }), {'a': 1});
      expect(
          AwesomeAssertUtils.extractMap<String, dynamic>('k', {'k': <String, dynamic>{}}),
          isNull);
      expect(AwesomeAssertUtils.extractMap<String, dynamic>('k', {'k': 'nope'}),
          isNull);
      expect(
          AwesomeAssertUtils.extractMap<String, dynamic>(
              'missing', <String, dynamic>{}),
          isNull);
    });

    test('extractEnum and enumToString', () {
      expect(
          AwesomeAssertUtils.extractEnum<ActionType>(
              'k', {'k': ActionType.KeepOnTop}, ActionType.values),
          ActionType.KeepOnTop);
      expect(
          AwesomeAssertUtils.extractEnum<ActionType>(
              'k', {'k': 5}, ActionType.values),
          isNull);
      expect(
          AwesomeAssertUtils.enumToString<ActionType>(
              'KeepOnTop', ActionType.values, null),
          ActionType.KeepOnTop);
    });

    test('extractValue numeric conversions', () {
      expect(AwesomeAssertUtils.extractValue<double>('k', {'k': '1.5'}), 1.5);
      expect(AwesomeAssertUtils.extractValue<int>('k', {'k': '3.7'}), 3);
      expect(AwesomeAssertUtils.extractValue<int>('k', {'k': 8}), 8);
    });

    test('extractValue for non-string typed values', () {
      expect(AwesomeAssertUtils.extractValue<int>('k', {'k': 3.7}), 4); // rounds
      expect(AwesomeAssertUtils.extractValue<double>('k', {'k': 5}), 5.0);
      expect(AwesomeAssertUtils.extractValue<Color>('k', {'k': 0xFF00FF00}),
          const Color(0xFF00FF00));
      expect(AwesomeAssertUtils.extractValue<Color>('k', {'k': Colors.blue}),
          isA<Color>());
      expect(
          AwesomeAssertUtils.extractValue<Color>('k', {'k': Colors.redAccent}),
          isA<Color>());
      expect(AwesomeAssertUtils.extractValue<Duration>('k', {'k': 30}),
          const Duration(seconds: 30));
      expect(AwesomeAssertUtils.extractValue<Duration>('k', {'k': '45'}),
          const Duration(seconds: 45));
      expect(AwesomeAssertUtils.extractValue<Duration>('k', {'k': -5}), isNull);
      expect(AwesomeAssertUtils.extractValue<bool>('k', {'k': 1}), true);
      expect(AwesomeAssertUtils.extractValue<bool>('k', {'k': true}), true);
      expect(AwesomeAssertUtils.extractValue<List>('k', {'k': [1, 2]}), [1, 2]);
    });

    test('extractValue falls back for bad strings and missing keys', () {
      expect(AwesomeAssertUtils.extractValue<int>('k', {'k': 'notanumber'}),
          isNull);
      expect(AwesomeAssertUtils.extractValue<double>('k', {'k': 'x'}), isNull);
      expect(AwesomeAssertUtils.extractValue<bool>('k', {'k': 'maybe'}), isNull);
      // A missing key with a Definitions default returns that default.
      expect(
          AwesomeAssertUtils.extractValue<bool>(
              NOTIFICATION_AUTO_DISMISSIBLE, <String, dynamic>{}),
          isNotNull);
    });

    test('getValueOrDefault passes through a matching typed value', () {
      expect(
          AwesomeAssertUtils.getValueOrDefault<Color>(
              'color', const Color(0xFF010203)),
          const Color(0xFF010203));
    });

    test('fromListMap builds a typed model list', () {
      final buttons = AwesomeAssertUtils.fromListMap<NotificationActionButton>(
        <Map<String, dynamic>>[
          {'key': 'A', 'label': 'a'}
        ],
        () => NotificationActionButton(key: '', label: ''),
      );
      expect(buttons, hasLength(1));
      expect(buttons!.first.key, 'A');
      expect(
          AwesomeAssertUtils.fromListMap<NotificationActionButton>(
              null, () => NotificationActionButton(key: '', label: '')),
          isNull);
      expect(
          AwesomeAssertUtils.fromListMap<NotificationActionButton>(
              <Map<String, dynamic>>[],
              () => NotificationActionButton(key: '', label: '')),
          isNull);
    });
  });

  group('AwesomeDateUtils conversions', () {
    test('utcToLocal / localToUtc', () {
      expect(AwesomeDateUtils.utcToLocal(DateTime.utc(2026, 7, 5, 20)),
          isA<DateTime>());
      expect(AwesomeDateUtils.localToUtc(DateTime(2026, 7, 5, 20)),
          isA<DateTime>());
    });
  });

  group('enums with logic', () {
    test('NotificationLifeCycle.AppKilled aliases Terminated', () {
      // ignore: deprecated_member_use
      expect(NotificationLifeCycle.AppKilled, NotificationLifeCycle.Terminated);
    });
    test('MediaSourcePrefix value', () {
      expect(const MediaSourcePrefix(3).value, 3);
    });
  });

  group('facade extras', () {
    test('exposes the preset vibration patterns', () {
      expect(lowVibrationPattern, isNotEmpty);
      expect(mediumVibrationPattern, isNotEmpty);
      expect(highVibrationPattern, isNotEmpty);
    });

    test('createNotificationFromJsonData delegates', () async {
      AwesomeNotificationsPlatform.instance = AwesomeNotificationsEmpty();
      expect(
          await AwesomeNotifications().createNotificationFromJsonData({}), isFalse);
    });
  });

  group('AwesomeNotificationsPlatform.instance', () {
    tearDown(() {
      AwesomeNotificationsPlatform.operatingSystem = 'android';
      AwesomeNotificationsPlatform.resetInstance();
    });

    test('resolves the method-channel impl on mobile and empty elsewhere', () {
      AwesomeNotificationsPlatform.operatingSystem = 'android';
      AwesomeNotificationsPlatform.resetInstance();
      expect(AwesomeNotificationsPlatform.instance,
          isA<MethodChannelAwesomeNotifications>());

      AwesomeNotificationsPlatform.operatingSystem = 'ios';
      AwesomeNotificationsPlatform.resetInstance();
      expect(AwesomeNotificationsPlatform.instance,
          isA<MethodChannelAwesomeNotifications>());

      AwesomeNotificationsPlatform.operatingSystem = 'linux';
      AwesomeNotificationsPlatform.resetInstance();
      expect(AwesomeNotificationsPlatform.instance,
          isA<AwesomeNotificationsEmpty>());
    });
  });
}
