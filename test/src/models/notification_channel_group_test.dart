import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() {
  group('NotificationChannelGroup', () {
    test('should create a NotificationChannelGroup object from a map', () {
      Map<String, dynamic> data = {
        NOTIFICATION_CHANNEL_GROUP_KEY: 'groupKey',
        NOTIFICATION_CHANNEL_GROUP_NAME: 'groupName',
      };

      NotificationChannelGroup? channelGroup =
          NotificationChannelGroup(channelGroupKey: '', channelGroupName: '')
              .fromMap(data);

      expect(channelGroup, isNotNull);
      expect(channelGroup?.channelGroupKey, 'groupKey');
      expect(channelGroup?.channelGroupName, 'groupName');
    });

    test(
        'should throw an exception when creating a NotificationChannelGroup object with an empty or null channelGroupKey',
        () {
      Map<String, dynamic> data = {
        NOTIFICATION_CHANNEL_GROUP_NAME: 'groupName',
      };

      expect(
          () => NotificationChannelGroup(
                  channelGroupKey: '', channelGroupName: '')
              .fromMap(data)
              ?.validate(),
          throwsA(isA<AwesomeNotificationsException>()));

      data[NOTIFICATION_CHANNEL_GROUP_KEY] = '';

      expect(
          () => NotificationChannelGroup(
                  channelGroupKey: '', channelGroupName: '')
              .fromMap(data)
              ?.validate(),
          throwsA(isA<AwesomeNotificationsException>()));
    });

    test(
        'should throw an exception when creating a NotificationChannelGroup object with an empty or null channelGroupName',
        () {
      Map<String, dynamic> data = {
        NOTIFICATION_CHANNEL_GROUP_KEY: 'groupKey',
        NOTIFICATION_CHANNEL_GROUP_NAME: null,
      };

      expect(
          () => NotificationChannelGroup(
                  channelGroupKey: '', channelGroupName: '')
              .fromMap(data)
              ?.validate(),
          throwsA(isA<AwesomeNotificationsException>()));

      data[NOTIFICATION_CHANNEL_GROUP_NAME] = '';

      expect(
          () => NotificationChannelGroup(
                  channelGroupKey: '', channelGroupName: '')
              .fromMap(data)
              ?.validate(),
          throwsA(isA<AwesomeNotificationsException>()));
    });

    test('should convert a NotificationChannelGroup object to a map', () {
      NotificationChannelGroup channelGroup = NotificationChannelGroup(
        channelGroupKey: 'groupKey',
        channelGroupName: 'groupName',
      );

      Map<String, dynamic> data = channelGroup.toMap();

      expect(data[NOTIFICATION_CHANNEL_GROUP_KEY], 'groupKey');
      expect(data[NOTIFICATION_CHANNEL_GROUP_NAME], 'groupName');
    });
  });
}
