import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() {
  group('NotificationChannel', () {
    test('should create a NotificationChannel object from a map', () {
      Map<String, dynamic> data = {
        NOTIFICATION_CHANNEL_KEY: 'channelKey',
        NOTIFICATION_CHANNEL_NAME: 'channelName',
        NOTIFICATION_CHANNEL_DESCRIPTION: 'channelDescription',
        NOTIFICATION_CHANNEL_SHOW_BADGE: true,
        NOTIFICATION_PLAY_SOUND: true,
        NOTIFICATION_SOUND_SOURCE: 'soundSource',
        NOTIFICATION_IMPORTANCE: NotificationImportance.Max.name,
        NOTIFICATION_DEFAULT_PRIVACY: NotificationPrivacy.Private.name,
        NOTIFICATION_DEFAULT_RINGTONE_TYPE: DefaultRingtoneType.Ringtone.name,
        NOTIFICATION_ENABLE_VIBRATION: true,
        NOTIFICATION_ENABLE_LIGHTS: true,
        NOTIFICATION_LED_COLOR: Colors.red.value,
        NOTIFICATION_LED_ON_MS: 1000,
        NOTIFICATION_LED_OFF_MS: 1000,
        NOTIFICATION_ICON: 'icon',
        NOTIFICATION_DEFAULT_COLOR: Colors.blue.value,
      };

      NotificationChannel channel = NotificationChannel(
              channelKey: '', channelName: '', channelDescription: '')
          .fromMap(data);

      expect(channel.channelKey, 'channelKey');
      expect(channel.channelName, 'channelName');
      expect(channel.channelDescription, 'channelDescription');
      expect(channel.channelShowBadge, true);
      expect(channel.playSound, true);
      expect(channel.soundSource, 'soundSource');
      expect(channel.importance, NotificationImportance.Max);
      expect(channel.defaultPrivacy, NotificationPrivacy.Private);
      expect(channel.defaultRingtoneType, DefaultRingtoneType.Ringtone);
      expect(channel.enableVibration, true);
      expect(channel.enableLights, true);
      expect(channel.ledColor, Colors.red.shade500);
      expect(channel.ledOnMs, 1000);
      expect(channel.ledOffMs, 1000);
      expect(channel.icon, 'icon');
      expect(channel.defaultColor, Colors.blue.shade500);
    });

    test(
        'should throw an exception when creating a NotificationChannel object with an empty or null channelKey, channelName, or channelDescription',
        () {
      Map<String, dynamic> data = {
        NOTIFICATION_CHANNEL_KEY: null,
        NOTIFICATION_CHANNEL_NAME: 'channelName',
        NOTIFICATION_CHANNEL_DESCRIPTION: 'channelDescription',
      };

      expect(
          () => NotificationChannel(
                  channelKey: '', channelName: '', channelDescription: '')
              .fromMap(data)
              .validate(),
          throwsA(isA<AwesomeNotificationsException>()));

      data[NOTIFICATION_CHANNEL_KEY] = '';
      expect(
          () => NotificationChannel(
                  channelKey: '', channelName: '', channelDescription: '')
              .fromMap(data)
              .validate(),
          throwsA(isA<AwesomeNotificationsException>()));

      data[NOTIFICATION_CHANNEL_KEY] = 'channelKey';
      data[NOTIFICATION_CHANNEL_NAME] = null;
      expect(
          () => NotificationChannel(
                  channelKey: '', channelName: '', channelDescription: '')
              .fromMap(data)
              .validate(),
          throwsA(isA<AwesomeNotificationsException>()));

      data[NOTIFICATION_CHANNEL_NAME] = '';
      expect(
          () => NotificationChannel(
                  channelKey: '', channelName: '', channelDescription: '')
              .fromMap(data)
              .validate(),
          throwsA(isA<AwesomeNotificationsException>()));

      data[NOTIFICATION_CHANNEL_NAME] = 'channelName';
      data[NOTIFICATION_CHANNEL_DESCRIPTION] = null;
      expect(
          () => NotificationChannel(
                  channelKey: '', channelName: '', channelDescription: '')
              .fromMap(data)
              .validate(),
          throwsA(isA<AwesomeNotificationsException>()));

      data[NOTIFICATION_CHANNEL_DESCRIPTION] = '';
      expect(
          () => NotificationChannel(
                  channelKey: '', channelName: '', channelDescription: '')
              .fromMap(data)
              .validate(),
          throwsA(isA<AwesomeNotificationsException>()));
    });

    test('should convert a NotificationChannel object to a map', () {
      NotificationChannel channel = NotificationChannel(
          channelKey: 'channelKey',
          channelName: 'channelName',
          channelDescription: 'channelDescription',
          channelShowBadge: true);

      Map<String, dynamic> data = channel.toMap();

      expect(data[NOTIFICATION_CHANNEL_KEY], 'channelKey');
      expect(data[NOTIFICATION_CHANNEL_NAME], 'channelName');
      expect(data[NOTIFICATION_CHANNEL_DESCRIPTION], 'channelDescription');
      expect(data[NOTIFICATION_CHANNEL_SHOW_BADGE], true);
    });
  });
  group('NotificationChannel constructor assert', () {
    test('throws AssertionError if icon is not a resource media type', () {
      expect(
        () => NotificationChannel(
          channelKey: 'channelKey',
          channelName: 'channelName',
          channelDescription: 'channelDescription',
          icon: 'http://example.com/icon.png',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('does not throw AssertionError if icon is a resource media type', () {
      expect(
        () => NotificationChannel(
          channelKey: 'channelKey',
          channelName: 'channelName',
          channelDescription: 'channelDescription',
          icon: 'resource://drawable/res_icon',
        ),
        returnsNormally,
      );
    });

    test('does not throw AssertionError if icon is null', () {
      expect(
        () => NotificationChannel(
          channelKey: 'channelKey',
          channelName: 'channelName',
          channelDescription: 'channelDescription',
          icon: null,
        ),
        returnsNormally,
      );
    });
  });
}
