import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/src/models/base_notification_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore_for_file: deprecated_member_use_from_same_package

void main() {
  group('BaseNotificationContent tests', () {
    group('toMap method', () {
      test('id field', () {
        String failureReason =
            'The id field was not correctly exported as a map';
        int? defaultValue = Definitions.initialValues[NOTIFICATION_ID] as int?;

        expect(BaseNotificationContent(id: 1).toMap()[NOTIFICATION_ID], 1,
            reason: failureReason);
        expect(BaseNotificationContent(id: 0).toMap()[NOTIFICATION_ID], 0,
            reason: failureReason);
        expect(BaseNotificationContent(id: -1).toMap()[NOTIFICATION_ID], -1,
            reason: failureReason);
        expect(BaseNotificationContent().toMap()[NOTIFICATION_ID], defaultValue,
            reason: failureReason);
      });

      test('channelKey field', () {
        String failureReason =
            'The channelKey field was not correctly exported as a map';
        String? defaultValue =
            Definitions.initialValues[NOTIFICATION_CHANNEL_KEY] as String?;

        expect(
            BaseNotificationContent(channelKey: 'channel_1')
                .toMap()[NOTIFICATION_CHANNEL_KEY],
            'channel_1',
            reason: '$failureReason: normal string value');
        expect(
            BaseNotificationContent(channelKey: '')
                .toMap()[NOTIFICATION_CHANNEL_KEY],
            '',
            reason: '$failureReason: empty string value');
        expect(
            BaseNotificationContent(channelKey: '  ')
                .toMap()[NOTIFICATION_CHANNEL_KEY],
            '  ',
            reason: '$failureReason: string with white spaces value');
        expect(BaseNotificationContent().toMap()[NOTIFICATION_CHANNEL_KEY],
            defaultValue,
            reason: '$failureReason: default value');
      });

      test('groupKey field', () {
        String failureReason =
            'The groupKey field was not correctly exported as a map';
        String? defaultValue =
            Definitions.initialValues[NOTIFICATION_GROUP_KEY] as String?;

        expect(
            BaseNotificationContent(groupKey: 'group_1')
                .toMap()[NOTIFICATION_GROUP_KEY],
            'group_1',
            reason: '$failureReason: normal string value');
        expect(
            BaseNotificationContent(groupKey: '')
                .toMap()[NOTIFICATION_GROUP_KEY],
            '',
            reason: '$failureReason: empty string value');
        expect(
            BaseNotificationContent(groupKey: '  ')
                .toMap()[NOTIFICATION_GROUP_KEY],
            '  ',
            reason: '$failureReason: string with white spaces value');
        expect(BaseNotificationContent().toMap()[NOTIFICATION_GROUP_KEY],
            defaultValue,
            reason: '$failureReason: default value');
      });

      test('actionType field', () {
        String failureReason =
            'The action field was not correctly exported as a map';
        String? defaultValue =
            (Definitions.initialValues[NOTIFICATION_ACTION_TYPE] as ActionType?)
                ?.name;

        expect(
            BaseNotificationContent(actionType: ActionType.Default)
                .toMap()[NOTIFICATION_ACTION_TYPE],
            ActionType.Default.name,
            reason: '$failureReason: Default value');
        expect(
            BaseNotificationContent(actionType: ActionType.InputField)
                .toMap()[NOTIFICATION_ACTION_TYPE],
            ActionType.InputField.name,
            reason: '$failureReason: InputField value (deprecated)');
        expect(
            BaseNotificationContent(actionType: ActionType.DisabledAction)
                .toMap()[NOTIFICATION_ACTION_TYPE],
            ActionType.DisabledAction.name,
            reason: '$failureReason: DisabledAction value');
        expect(
            BaseNotificationContent(actionType: ActionType.KeepOnTop)
                .toMap()[NOTIFICATION_ACTION_TYPE],
            ActionType.KeepOnTop.name,
            reason: '$failureReason: KeepOnTop value');
        expect(
            BaseNotificationContent(actionType: ActionType.SilentAction)
                .toMap()[NOTIFICATION_ACTION_TYPE],
            ActionType.SilentAction.name,
            reason: '$failureReason: SilentAction value');
        expect(
            BaseNotificationContent(
                    actionType: ActionType.SilentBackgroundAction)
                .toMap()[NOTIFICATION_ACTION_TYPE],
            ActionType.SilentBackgroundAction.name,
            reason: '$failureReason: SilentBackgroundAction value');
        expect(
            BaseNotificationContent(actionType: ActionType.DismissAction)
                .toMap()[NOTIFICATION_ACTION_TYPE],
            ActionType.DismissAction.name,
            reason: '$failureReason: DismissAction value');
        expect(BaseNotificationContent().toMap()[NOTIFICATION_ACTION_TYPE],
            defaultValue,
            reason: '$failureReason: default value');
      });

      test('title field', () {
        String failureReason =
            'The title field was not correctly exported as a map';
        String? defaultValue =
            Definitions.initialValues[NOTIFICATION_TITLE] as String?;

        expect(
            BaseNotificationContent(title: 'notification title')
                .toMap()[NOTIFICATION_TITLE],
            'notification title',
            reason: '$failureReason: normal string value');
        expect(
            BaseNotificationContent(title: '').toMap()[NOTIFICATION_TITLE], '',
            reason: '$failureReason: empty string value');
        expect(BaseNotificationContent(title: '  ').toMap()[NOTIFICATION_TITLE],
            '  ',
            reason: '$failureReason: string with white spaces value');
        expect(
            BaseNotificationContent().toMap()[NOTIFICATION_TITLE], defaultValue,
            reason: '$failureReason: default value');
      });

      test('body field', () {
        String failureReason =
            'The body field was not correctly exported as a map';
        String? defaultValue =
            Definitions.initialValues[NOTIFICATION_BODY] as String?;

        expect(
            BaseNotificationContent(body: 'notification body')
                .toMap()[NOTIFICATION_BODY],
            'notification body',
            reason: '$failureReason: normal string value');
        expect(BaseNotificationContent(body: '').toMap()[NOTIFICATION_BODY], '',
            reason: '$failureReason: empty string value');
        expect(BaseNotificationContent(body: '  ').toMap()[NOTIFICATION_BODY],
            '  ',
            reason: '$failureReason: string with white spaces value');
        expect(
            BaseNotificationContent().toMap()[NOTIFICATION_BODY], defaultValue,
            reason: '$failureReason: default value');
      });

      test('summary field', () {
        String failureReason =
            'The summary field was not correctly exported as a map';
        String? defaultValue =
            Definitions.initialValues[NOTIFICATION_SUMMARY] as String?;

        expect(
            BaseNotificationContent(summary: 'notification summary')
                .toMap()[NOTIFICATION_SUMMARY],
            'notification summary',
            reason: '$failureReason: normal string value');
        expect(
            BaseNotificationContent(summary: '').toMap()[NOTIFICATION_SUMMARY],
            '',
            reason: '$failureReason: empty string value');
        expect(
            BaseNotificationContent(summary: '  ')
                .toMap()[NOTIFICATION_SUMMARY],
            '  ',
            reason: '$failureReason: string with white spaces value');
        expect(BaseNotificationContent().toMap()[NOTIFICATION_SUMMARY],
            defaultValue,
            reason: '$failureReason: default value');
      });

      test('showWhen field', () {
        String failureReason =
            'The showWhen field was not correctly exported as a map';
        bool? defaultValue =
            Definitions.initialValues[NOTIFICATION_SHOW_WHEN] as bool?;

        expect(
            BaseNotificationContent(showWhen: true)
                .toMap()[NOTIFICATION_SHOW_WHEN],
            true,
            reason: '$failureReason: true value');
        expect(
            BaseNotificationContent(showWhen: false)
                .toMap()[NOTIFICATION_SHOW_WHEN],
            false,
            reason: '$failureReason: false value');
        expect(BaseNotificationContent().toMap()[NOTIFICATION_SHOW_WHEN],
            defaultValue,
            reason: '$failureReason: default value');
      });

      test('icon field', () {
        String failureReason =
            'The icon field was not correctly exported as a map';
        String? defaultValue =
            Definitions.initialValues[NOTIFICATION_ICON] as String?;

        expect(
            BaseNotificationContent(icon: 'icon_name')
                .toMap()[NOTIFICATION_ICON],
            'icon_name',
            reason: '$failureReason: normal string value');
        expect(BaseNotificationContent(icon: '').toMap()[NOTIFICATION_ICON], '',
            reason: '$failureReason: empty string value');
        expect(BaseNotificationContent(icon: '  ').toMap()[NOTIFICATION_ICON],
            '  ',
            reason: '$failureReason: string with white spaces value');
        expect(
            BaseNotificationContent().toMap()[NOTIFICATION_ICON], defaultValue,
            reason: '$failureReason: default value');
      });

      test('largeIcon field', () {
        String failureReason =
            'The largeIcon field was not correctly exported as a map';
        String? defaultValue =
            Definitions.initialValues[NOTIFICATION_LARGE_ICON] as String?;

        expect(
            BaseNotificationContent(largeIcon: 'large_icon_name')
                .toMap()[NOTIFICATION_LARGE_ICON],
            'large_icon_name',
            reason: '$failureReason: normal string value');
        expect(
            BaseNotificationContent(largeIcon: '')
                .toMap()[NOTIFICATION_LARGE_ICON],
            '',
            reason: '$failureReason: empty string value');
        expect(
            BaseNotificationContent(largeIcon: '  ')
                .toMap()[NOTIFICATION_LARGE_ICON],
            '  ',
            reason: '$failureReason: string with white spaces value');
        expect(BaseNotificationContent().toMap()[NOTIFICATION_LARGE_ICON],
            defaultValue,
            reason: '$failureReason: default value');
      });

      test('bigPicture field', () {
        String failureReason =
            'The bigPicture field was not correctly exported as a map';
        String? defaultValue =
            Definitions.initialValues[NOTIFICATION_BIG_PICTURE] as String?;

        expect(
            BaseNotificationContent(bigPicture: 'big_picture_name')
                .toMap()[NOTIFICATION_BIG_PICTURE],
            'big_picture_name',
            reason: '$failureReason: normal string value');
        expect(
            BaseNotificationContent(bigPicture: '')
                .toMap()[NOTIFICATION_BIG_PICTURE],
            '',
            reason: '$failureReason: empty string value');
        expect(
            BaseNotificationContent(bigPicture: '  ')
                .toMap()[NOTIFICATION_BIG_PICTURE],
            '  ',
            reason: '$failureReason: string with white spaces value');
        expect(BaseNotificationContent().toMap()[NOTIFICATION_BIG_PICTURE],
            defaultValue,
            reason: '$failureReason: default value');
      });

      test('wakeUpScreen field', () {
        String failureReason =
            'The wakeUpScreen field was not correctly exported as a map';
        bool? defaultValue =
            Definitions.initialValues[NOTIFICATION_WAKE_UP_SCREEN] as bool?;

        expect(
            BaseNotificationContent(wakeUpScreen: true)
                .toMap()[NOTIFICATION_WAKE_UP_SCREEN],
            true,
            reason: '$failureReason: true value');
        expect(
            BaseNotificationContent(wakeUpScreen: false)
                .toMap()[NOTIFICATION_WAKE_UP_SCREEN],
            false,
            reason: '$failureReason: false value');
        expect(BaseNotificationContent().toMap()[NOTIFICATION_WAKE_UP_SCREEN],
            defaultValue,
            reason: '$failureReason: default value');
      });

      test('fullScreenIntent field', () {
        String failureReason =
            'The fullScreenIntent field was not correctly exported as a map';
        bool? defaultValue =
            Definitions.initialValues[NOTIFICATION_FULL_SCREEN_INTENT] as bool?;

        expect(
            BaseNotificationContent(fullScreenIntent: true)
                .toMap()[NOTIFICATION_FULL_SCREEN_INTENT],
            true,
            reason: '$failureReason: true value');
        expect(
            BaseNotificationContent(fullScreenIntent: false)
                .toMap()[NOTIFICATION_FULL_SCREEN_INTENT],
            false,
            reason: '$failureReason: false value');
        expect(
            BaseNotificationContent().toMap()[NOTIFICATION_FULL_SCREEN_INTENT],
            defaultValue,
            reason: '$failureReason: default value');
      });

      test('criticalAlert field', () {
        String failureReason =
            'The criticalAlert field was not correctly exported as a map';
        bool? defaultValue =
            Definitions.initialValues[NOTIFICATION_CRITICAL_ALERT] as bool?;

        expect(
            BaseNotificationContent(criticalAlert: true)
                .toMap()[NOTIFICATION_CRITICAL_ALERT],
            true,
            reason: '$failureReason: true value');
        expect(
            BaseNotificationContent(criticalAlert: false)
                .toMap()[NOTIFICATION_CRITICAL_ALERT],
            false,
            reason: '$failureReason: false value');
        expect(BaseNotificationContent().toMap()[NOTIFICATION_CRITICAL_ALERT],
            defaultValue,
            reason: '$failureReason: default value');
      });

      test('category field', () {
        String failureReason =
            'The category field was not correctly exported as a map';
        NotificationCategory? defaultValue = Definitions
            .initialValues[NOTIFICATION_CATEGORY] as NotificationCategory?;

        for (var category in NotificationCategory.values) {
          expect(
              BaseNotificationContent(category: category)
                  .toMap()[NOTIFICATION_CATEGORY],
              category.toString().split('.').last,
              reason:
                  '$failureReason: ${category.toString().split('.').last} value');
        }
        expect(BaseNotificationContent().toMap()[NOTIFICATION_CATEGORY],
            defaultValue?.name,
            reason: '$failureReason: default value');
      });

      test('color field', () {
        String failureReason =
            'The showWhen field was not correctly exported as a map';
        int? defaultValue =
            (Definitions.initialValues[NOTIFICATION_COLOR] as Color?)?.value;

        expect(
            BaseNotificationContent(color: Colors.red)
                .toMap()[NOTIFICATION_COLOR],
            Colors.red.value,
            reason: '$failureReason: without transparency value');
        expect(
            BaseNotificationContent(color: Colors.transparent)
                .toMap()[NOTIFICATION_COLOR],
            Colors.transparent.value,
            reason: '$failureReason: with transparency value');
        expect(
            BaseNotificationContent().toMap()[NOTIFICATION_COLOR], defaultValue,
            reason: '$failureReason: default value');
      });

      test('backgroundColor field', () {
        String failureReason =
            'The showWhen field was not correctly exported as a map';
        int? defaultValue =
            (Definitions.initialValues[NOTIFICATION_BACKGROUND_COLOR] as Color?)
                ?.value;

        expect(
            BaseNotificationContent(backgroundColor: Colors.red)
                .toMap()[NOTIFICATION_BACKGROUND_COLOR],
            Colors.red.value,
            reason: '$failureReason: without transparency value');
        expect(
            BaseNotificationContent(backgroundColor: Colors.transparent)
                .toMap()[NOTIFICATION_BACKGROUND_COLOR],
            Colors.transparent.value,
            reason: '$failureReason: with transparency value');
        expect(BaseNotificationContent().toMap()[NOTIFICATION_BACKGROUND_COLOR],
            defaultValue,
            reason: '$failureReason: default value');
      });

      test('timeoutAfter field', () {
        String failureReason =
            'The timeoutAfter field was not correctly exported as a map';
        int? defaultValue =
            Definitions.initialValues[NOTIFICATION_TIMEOUT_AFTER] as int?;

        expect(
            BaseNotificationContent(timeoutAfter: const Duration(seconds: 1000))
                .toMap()[NOTIFICATION_TIMEOUT_AFTER],
            1000,
            reason: '$failureReason: positive value');
        expect(
            BaseNotificationContent(timeoutAfter: const Duration(seconds: 1))
                .toMap()[NOTIFICATION_TIMEOUT_AFTER],
            1,
            reason: '$failureReason: minimal positive value');
        expect(
            BaseNotificationContent(timeoutAfter: const Duration(seconds: 0))
                .toMap()[NOTIFICATION_TIMEOUT_AFTER],
            0,
            reason: '$failureReason: zero value returning valid duration');

        expect(
            BaseNotificationContent(timeoutAfter: const Duration(seconds: -1))
                .toMap()[NOTIFICATION_TIMEOUT_AFTER],
            null,
            reason: '$failureReason: zero or negative value');
        expect(
            BaseNotificationContent(timeoutAfter: const Duration(seconds: -1000))
                .toMap()[NOTIFICATION_TIMEOUT_AFTER],
            null,
            reason: '$failureReason: zero or negative value');
        expect(BaseNotificationContent().toMap()[NOTIFICATION_TIMEOUT_AFTER],
            defaultValue,
            reason: '$failureReason: default value');
      });

      test('customSound field', () {
        String failureReason =
            'The customSound field was not correctly exported as a map';
        String? defaultValue =
            Definitions.initialValues[NOTIFICATION_CUSTOM_SOUND] as String?;

        expect(
            BaseNotificationContent(customSound: 'sound_1')
                .toMap()[NOTIFICATION_CUSTOM_SOUND],
            'sound_1',
            reason: '$failureReason: normal string value');
        expect(
            BaseNotificationContent(customSound: '')
                .toMap()[NOTIFICATION_CUSTOM_SOUND],
            '',
            reason: '$failureReason: empty string value');
        expect(
            BaseNotificationContent(customSound: '  ')
                .toMap()[NOTIFICATION_CUSTOM_SOUND],
            '  ',
            reason: '$failureReason: string with white spaces value');
        expect(BaseNotificationContent().toMap()[NOTIFICATION_CUSTOM_SOUND],
            defaultValue,
            reason: '$failureReason: default value');
      });

      test('roundedLargeIcon field', () {
        String failureReason =
            'The roundedLargeIcon field was not correctly exported as a map';
        bool? defaultValue =
            Definitions.initialValues[NOTIFICATION_ROUNDED_LARGE_ICON] as bool?;

        expect(
            BaseNotificationContent(roundedLargeIcon: true)
                .toMap()[NOTIFICATION_ROUNDED_LARGE_ICON],
            true,
            reason: '$failureReason: true value');
        expect(
            BaseNotificationContent(roundedLargeIcon: false)
                .toMap()[NOTIFICATION_ROUNDED_LARGE_ICON],
            false,
            reason: '$failureReason: false value');
        expect(
            BaseNotificationContent().toMap()[NOTIFICATION_ROUNDED_LARGE_ICON],
            defaultValue,
            reason: '$failureReason: default value');
      });

      test('roundedBigPicture field', () {
        String failureReason =
            'The roundedBigPicture field was not correctly exported as a map';
        bool? defaultValue = Definitions
            .initialValues[NOTIFICATION_ROUNDED_BIG_PICTURE] as bool?;

        expect(
            BaseNotificationContent(roundedBigPicture: true)
                .toMap()[NOTIFICATION_ROUNDED_BIG_PICTURE],
            true,
            reason: '$failureReason: true value');
        expect(
            BaseNotificationContent(roundedBigPicture: false)
                .toMap()[NOTIFICATION_ROUNDED_BIG_PICTURE],
            false,
            reason: '$failureReason: false value');
        expect(
            BaseNotificationContent().toMap()[NOTIFICATION_ROUNDED_BIG_PICTURE],
            defaultValue,
            reason: '$failureReason: default value');
      });

      test('autoDismissible field', () {
        String failureReason =
            'The autoDismissible field was not correctly exported as a map';
        bool? defaultValue =
            Definitions.initialValues[NOTIFICATION_AUTO_DISMISSIBLE] as bool?;

        expect(
            BaseNotificationContent(autoDismissible: true)
                .toMap()[NOTIFICATION_AUTO_DISMISSIBLE],
            true,
            reason: '$failureReason: true value');
        expect(
            BaseNotificationContent(autoDismissible: false)
                .toMap()[NOTIFICATION_AUTO_DISMISSIBLE],
            false,
            reason: '$failureReason: false value');
        expect(
            BaseNotificationContent(autoCancel: true)
                .toMap()[NOTIFICATION_AUTO_DISMISSIBLE],
            true,
            reason: '$failureReason: true value');
        expect(
            BaseNotificationContent(autoCancel: false)
                .toMap()[NOTIFICATION_AUTO_DISMISSIBLE],
            false,
            reason: '$failureReason: false value');
        expect(BaseNotificationContent().toMap()[NOTIFICATION_AUTO_DISMISSIBLE],
            defaultValue,
            reason: '$failureReason: default value');
      });

      test('payload field', () {
        String failureReason =
            'The payload field was not correctly exported as a map';
        Map<String, String?>? defaultValue = Definitions
            .initialValues[NOTIFICATION_PAYLOAD] as Map<String, String?>?;

        Map<String, String?> emptyPayload = {};
        expect(
            BaseNotificationContent(payload: emptyPayload)
                .toMap()[NOTIFICATION_PAYLOAD],
            emptyPayload,
            reason: '$failureReason: empty payload');
        expect(BaseNotificationContent().toMap()[NOTIFICATION_PAYLOAD],
            defaultValue,
            reason: '$failureReason: default value');

        Map<String, String?> customPayload = {
          'key1': 'value1',
          'key2': 'value2'
        };
        final customBaseWithPayload =
            BaseNotificationContent(payload: customPayload).toMap();
        expect(customBaseWithPayload[NOTIFICATION_PAYLOAD], customPayload,
            reason: '$failureReason: custom payload');
        expect(customBaseWithPayload[NOTIFICATION_PAYLOAD]['key1'], 'value1',
            reason: '$failureReason: custom payload');
        expect(customBaseWithPayload[NOTIFICATION_PAYLOAD]['key2'], 'value2',
            reason: '$failureReason: custom payload');
        expect(customBaseWithPayload[NOTIFICATION_PAYLOAD].length, 2,
            reason: '$failureReason: custom payload');
      });
    });

    group('fromMap method', () {
      test('id field fromMap', () {
        String failureReason =
            'The id field was not correctly imported from a map';
        int? defaultValue = Definitions.initialValues[NOTIFICATION_ID] as int?;

        expect(BaseNotificationContent().fromMap({NOTIFICATION_ID: 1})?.id, 1,
            reason: '$failureReason: positive value');
        expect(BaseNotificationContent().fromMap({NOTIFICATION_ID: 0})?.id, 0,
            reason: '$failureReason: positive value');
        expect(BaseNotificationContent().fromMap({NOTIFICATION_ID: -1})?.id, -1,
            reason: '$failureReason: positive value');
        expect(BaseNotificationContent().fromMap({NOTIFICATION_ID: "1"})?.id, 1,
            reason: '$failureReason: positive value');
        expect(BaseNotificationContent().fromMap({NOTIFICATION_ID: "0"})?.id, 0,
            reason: '$failureReason: positive value');
        expect(
            BaseNotificationContent().fromMap({NOTIFICATION_ID: "-1"})?.id, -1,
            reason: '$failureReason: positive value');
        expect(BaseNotificationContent().fromMap({NOTIFICATION_ID: null})?.id,
            defaultValue,
            reason: '$failureReason: positive value');
        expect(BaseNotificationContent().fromMap({NOTIFICATION_ID: ""})?.id,
            defaultValue,
            reason: '$failureReason: positive value');
      });

      test('channelKey field fromMap', () {
        String failureReason =
            'The channelKey field was not correctly imported from a map';
        String? defaultValue =
            Definitions.initialValues[NOTIFICATION_CHANNEL_KEY] as String?;

        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_CHANNEL_KEY: 'channel_1'})?.channelKey,
            'channel_1',
            reason: '$failureReason: normal string value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_CHANNEL_KEY: ''})?.channelKey,
            '',
            reason: '$failureReason: empty string value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_CHANNEL_KEY: '  '})?.channelKey,
            '  ',
            reason: '$failureReason: string with white spaces value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_CHANNEL_KEY: null})?.channelKey,
            defaultValue,
            reason: '$failureReason: null value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_CHANNEL_KEY: 1})?.channelKey,
            defaultValue,
            reason: '$failureReason: non-string value');
      });

      test('actionType field fromMap', () {
        String failureReason =
            'The actionType field was not correctly imported from a map';
        expect(
            BaseNotificationContent().fromMap(
                {NOTIFICATION_ACTION_TYPE: 'SilentAction'})?.actionType,
            ActionType.SilentAction,
            reason: '$failureReason: normal string value');

        expect(
            BaseNotificationContent().fromMap({
              NOTIFICATION_ACTION_TYPE: 'SilentBackgroundAction'
            })?.actionType,
            ActionType.SilentBackgroundAction,
            reason: '$failureReason: normal string value');

        expect(
            BaseNotificationContent().fromMap(
                {NOTIFICATION_ACTION_TYPE: 'DisabledAction'})?.actionType,
            ActionType.DisabledAction,
            reason: '$failureReason: normal string value');

        expect(
            BaseNotificationContent().fromMap(
                {NOTIFICATION_ACTION_TYPE: 'DismissAction'})?.actionType,
            ActionType.DismissAction,
            reason: '$failureReason: normal string value');
      });

      test('groupKey field fromMap', () {
        String failureReason =
            'The groupKey field was not correctly imported from a map';
        String? defaultValue =
            Definitions.initialValues[NOTIFICATION_GROUP_KEY] as String?;

        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_GROUP_KEY: 'group_1'})?.groupKey,
            'group_1',
            reason: '$failureReason: normal string value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_GROUP_KEY: ''})?.groupKey,
            '',
            reason: '$failureReason: empty string value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_GROUP_KEY: '  '})?.groupKey,
            '  ',
            reason: '$failureReason: string with white spaces value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_GROUP_KEY: null})?.groupKey,
            defaultValue,
            reason: '$failureReason: null value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_GROUP_KEY: 1})?.groupKey,
            defaultValue,
            reason: '$failureReason: non-string value');
      });

      test('title field fromMap', () {
        String failureReason =
            'The title field was not correctly imported from a map';
        String? defaultValue =
            Definitions.initialValues[NOTIFICATION_TITLE] as String?;

        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_TITLE: 'notification title'})?.title,
            'notification title',
            reason: '$failureReason: normal string value');
        expect(
            BaseNotificationContent().fromMap({NOTIFICATION_TITLE: ''})?.title,
            '',
            reason: '$failureReason: empty string value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_TITLE: '  '})?.title,
            '  ',
            reason: '$failureReason: string with white spaces value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_TITLE: null})?.title,
            defaultValue,
            reason: '$failureReason: null value');
        expect(
            BaseNotificationContent().fromMap({NOTIFICATION_TITLE: 1})?.title,
            defaultValue,
            reason: '$failureReason: non-string value');
      });

      test('body field fromMap', () {
        String failureReason =
            'The body field was not correctly imported from a map';
        String? defaultValue =
            Definitions.initialValues[NOTIFICATION_BODY] as String?;

        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_BODY: 'notification body'})?.body,
            'notification body',
            reason: '$failureReason: normal string value');
        expect(BaseNotificationContent().fromMap({NOTIFICATION_BODY: ''})?.body,
            '',
            reason: '$failureReason: empty string value');
        expect(
            BaseNotificationContent().fromMap({NOTIFICATION_BODY: '  '})?.body,
            '  ',
            reason: '$failureReason: string with white spaces value');
        expect(
            BaseNotificationContent().fromMap({NOTIFICATION_BODY: null})?.body,
            defaultValue,
            reason: '$failureReason: null value');
        expect(BaseNotificationContent().fromMap({NOTIFICATION_BODY: 1})?.body,
            defaultValue,
            reason: '$failureReason: non-string value');
      });

      test('summary field fromMap', () {
        String failureReason =
            'The summary field was not correctly imported from a map';
        String? defaultValue =
            Definitions.initialValues[NOTIFICATION_SUMMARY] as String?;

        expect(
            BaseNotificationContent().fromMap(
                {NOTIFICATION_SUMMARY: 'notification summary'})?.summary,
            'notification summary',
            reason: '$failureReason: normal string value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_SUMMARY: ''})?.summary,
            '',
            reason: '$failureReason: empty string value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_SUMMARY: '  '})?.summary,
            '  ',
            reason: '$failureReason: string with white spaces value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_SUMMARY: null})?.summary,
            defaultValue,
            reason: '$failureReason: null value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_SUMMARY: 1})?.summary,
            defaultValue,
            reason: '$failureReason: non-string value');
      });

      test('showWhen field fromMap', () {
        String failureReason =
            'The showWhen field was not correctly imported from a map';
        bool? defaultValue =
            Definitions.initialValues[NOTIFICATION_SHOW_WHEN] as bool?;

        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_SHOW_WHEN: true})?.showWhen,
            true,
            reason: '$failureReason: true value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_SHOW_WHEN: false})?.showWhen,
            false,
            reason: '$failureReason: false value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_SHOW_WHEN: null})?.showWhen,
            defaultValue,
            reason: '$failureReason: null value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_SHOW_WHEN: 'true'})?.showWhen,
            defaultValue,
            reason: '$failureReason: non-boolean value (string)');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_SHOW_WHEN: 1})?.showWhen,
            defaultValue,
            reason: '$failureReason: non-boolean value (integer)');
      });

      test('icon field fromMap', () {
        String failureReason =
            'The icon field was not correctly imported from a map';
        String? defaultValue =
            Definitions.initialValues[NOTIFICATION_ICON] as String?;

        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_ICON: 'icon_1'})?.icon,
            'icon_1',
            reason: '$failureReason: normal string value');
        expect(BaseNotificationContent().fromMap({NOTIFICATION_ICON: ''})?.icon,
            '',
            reason: '$failureReason: empty string value');
        expect(
            BaseNotificationContent().fromMap({NOTIFICATION_ICON: '  '})?.icon,
            '  ',
            reason: '$failureReason: string with white spaces value');
        expect(
            BaseNotificationContent().fromMap({NOTIFICATION_ICON: null})?.icon,
            defaultValue,
            reason: '$failureReason: null value');
        expect(BaseNotificationContent().fromMap({NOTIFICATION_ICON: 1})?.icon,
            defaultValue,
            reason: '$failureReason: non-string value (integer)');
      });

      test('largeIcon field fromMap', () {
        String failureReason =
            'The largeIcon field was not correctly imported from a map';
        String? defaultValue =
            Definitions.initialValues[NOTIFICATION_LARGE_ICON] as String?;

        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_LARGE_ICON: 'large_icon_1'})?.largeIcon,
            'large_icon_1',
            reason: '$failureReason: normal string value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_LARGE_ICON: ''})?.largeIcon,
            '',
            reason: '$failureReason: empty string value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_LARGE_ICON: '  '})?.largeIcon,
            '  ',
            reason: '$failureReason: string with white spaces value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_LARGE_ICON: null})?.largeIcon,
            defaultValue,
            reason: '$failureReason: null value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_LARGE_ICON: 1})?.largeIcon,
            defaultValue,
            reason: '$failureReason: non-string value (integer)');
      });

      test('bigPicture field fromMap', () {
        String failureReason =
            'The bigPicture field was not correctly imported from a map';
        String? defaultValue =
            Definitions.initialValues[NOTIFICATION_BIG_PICTURE] as String?;

        expect(
            BaseNotificationContent().fromMap(
                {NOTIFICATION_BIG_PICTURE: 'big_picture_1'})?.bigPicture,
            'big_picture_1',
            reason: '$failureReason: normal string value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_BIG_PICTURE: ''})?.bigPicture,
            '',
            reason: '$failureReason: empty string value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_BIG_PICTURE: '  '})?.bigPicture,
            '  ',
            reason: '$failureReason: string with white spaces value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_BIG_PICTURE: null})?.bigPicture,
            defaultValue,
            reason: '$failureReason: null value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_BIG_PICTURE: 1})?.bigPicture,
            defaultValue,
            reason: '$failureReason: non-string value (integer)');
      });

      test('wakeUpScreen field fromMap', () {
        String failureReason =
            'The wakeUpScreen field was not correctly imported from a map';
        bool? defaultValue =
            Definitions.initialValues[NOTIFICATION_WAKE_UP_SCREEN] as bool?;

        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_WAKE_UP_SCREEN: true})?.wakeUpScreen,
            true,
            reason: '$failureReason: true value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_WAKE_UP_SCREEN: false})?.wakeUpScreen,
            false,
            reason: '$failureReason: false value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_WAKE_UP_SCREEN: null})?.wakeUpScreen,
            defaultValue,
            reason: '$failureReason: null value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_WAKE_UP_SCREEN: 'true'})?.wakeUpScreen,
            true,
            reason: '$failureReason: non-boolean value (string)');
      });

      test('fullScreenIntent field fromMap', () {
        String failureReason =
            'The fullScreenIntent field was not correctly imported from a map';
        bool? defaultValue =
            Definitions.initialValues[NOTIFICATION_FULL_SCREEN_INTENT] as bool?;

        expect(
            BaseNotificationContent().fromMap(
                {NOTIFICATION_FULL_SCREEN_INTENT: true})?.fullScreenIntent,
            true,
            reason: '$failureReason: true value');
        expect(
            BaseNotificationContent().fromMap(
                {NOTIFICATION_FULL_SCREEN_INTENT: false})?.fullScreenIntent,
            false,
            reason: '$failureReason: false value');
        expect(
            BaseNotificationContent().fromMap(
                {NOTIFICATION_FULL_SCREEN_INTENT: 'true'})?.fullScreenIntent,
            true,
            reason: '$failureReason: non-boolean value (string)');
        expect(
            BaseNotificationContent().fromMap(
                {NOTIFICATION_FULL_SCREEN_INTENT: 'false'})?.fullScreenIntent,
            false,
            reason: '$failureReason: non-boolean value (string)');
        expect(
            BaseNotificationContent().fromMap(
                {NOTIFICATION_FULL_SCREEN_INTENT: 1})?.fullScreenIntent,
            true,
            reason: '$failureReason: non-boolean value (int)');
        expect(
            BaseNotificationContent().fromMap(
                {NOTIFICATION_FULL_SCREEN_INTENT: 0})?.fullScreenIntent,
            false,
            reason: '$failureReason: non-boolean value (int)');
        expect(
            BaseNotificationContent().fromMap(
                {NOTIFICATION_FULL_SCREEN_INTENT: null})?.fullScreenIntent,
            defaultValue,
            reason: '$failureReason: null value');
      });

      test('criticalAlert field fromMap', () {
        String failureReason =
            'The criticalAlert field was not correctly imported from a map';
        bool? defaultValue =
            Definitions.initialValues[NOTIFICATION_CRITICAL_ALERT] as bool?;

        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_CRITICAL_ALERT: true})?.criticalAlert,
            true,
            reason: '$failureReason: true value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_CRITICAL_ALERT: false})?.criticalAlert,
            false,
            reason: '$failureReason: false value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_CRITICAL_ALERT: 'true'})?.criticalAlert,
            true,
            reason: '$failureReason: non-boolean value (string)');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_CRITICAL_ALERT: 'false'})?.criticalAlert,
            false,
            reason: '$failureReason: non-boolean value (string)');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_CRITICAL_ALERT: '1'})?.criticalAlert,
            true,
            reason: '$failureReason: non-boolean value (string)');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_CRITICAL_ALERT: '0'})?.criticalAlert,
            false,
            reason: '$failureReason: non-boolean value (string)');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_CRITICAL_ALERT: 1})?.criticalAlert,
            true,
            reason: '$failureReason: non-boolean value (int)');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_CRITICAL_ALERT: 0})?.criticalAlert,
            false,
            reason: '$failureReason: non-boolean value (int)');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_CRITICAL_ALERT: null})?.criticalAlert,
            defaultValue,
            reason: '$failureReason: null value');
      });

      test('category field fromMap', () {
        String failureReason =
            'The category field was not correctly imported from a map';
        NotificationCategory? defaultValue = Definitions
            .initialValues[NOTIFICATION_CATEGORY] as NotificationCategory?;

        for (var category in NotificationCategory.values) {
          expect(
              BaseNotificationContent()
                  .fromMap({NOTIFICATION_CATEGORY: category.name})?.category,
              category,
              reason: '$failureReason: valid enum value');
        }
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_CATEGORY: 'invalid_value'})?.category,
            defaultValue,
            reason: '$failureReason: invalid enum value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_CATEGORY: null})?.category,
            defaultValue,
            reason: '$failureReason: null value');
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_CATEGORY: 1})?.category,
            defaultValue,
            reason: '$failureReason: non-string value (integer)');
      });

      test('color field fromMap', () {
        String failureReason =
            'The color field was not correctly imported from a map';
        Color? defaultValue =
            Definitions.initialValues[NOTIFICATION_COLOR] as Color?;

        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_COLOR: '#FF0000'})?.color,
            const Color(0xFFFF0000),
            reason: '$failureReason: valid hex color value');

        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_COLOR: '#FFFF0000'})?.color,
            const Color(0xFFFF0000),
            reason: '$failureReason: valid hex color value with hash symbol');

        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_COLOR: 'invalid_color'})?.color,
            defaultValue,
            reason: '$failureReason: invalid color value');

        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_COLOR: null})?.color,
            defaultValue,
            reason: '$failureReason: null value');
      });

      test('backgroundColor field fromMap', () {
        String failureReason =
            'The backgroundColor field was not correctly imported from a map';
        Color? defaultValue =
            Definitions.initialValues[NOTIFICATION_BACKGROUND_COLOR] as Color?;

        expect(
            BaseNotificationContent().fromMap(
                {NOTIFICATION_BACKGROUND_COLOR: '#00FF00'})?.backgroundColor,
            const Color(0xFF00FF00),
            reason: '$failureReason: valid hex color value');

        expect(
            BaseNotificationContent().fromMap(
                {NOTIFICATION_BACKGROUND_COLOR: '#FF00FF00'})?.backgroundColor,
            const Color(0xFF00FF00),
            reason: '$failureReason: valid hex color value with hash symbol');

        expect(
            BaseNotificationContent().fromMap({
              NOTIFICATION_BACKGROUND_COLOR: 'invalid_color'
            })?.backgroundColor,
            defaultValue,
            reason: '$failureReason: invalid color value');

        expect(
            BaseNotificationContent().fromMap(
                {NOTIFICATION_BACKGROUND_COLOR: null})?.backgroundColor,
            defaultValue,
            reason: '$failureReason: null value');
      });

      test('timeoutAfter field fromMap', () {
        String failureReason =
            'The timeoutAfter field was not correctly imported from a map';
        int? defaultValue =
            Definitions.initialValues[NOTIFICATION_TIMEOUT_AFTER] as int?;

        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_TIMEOUT_AFTER: 1000})?.timeoutAfter,
            const Duration(seconds: 1000),
            reason: '$failureReason: positive value');

        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_TIMEOUT_AFTER: '1000'})?.timeoutAfter,
            const Duration(seconds: 1000),
            reason: '$failureReason: valid value in string form');

        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_TIMEOUT_AFTER: 0})?.timeoutAfter,
            Duration.zero,
            reason: '$failureReason: zero value returning valid duration');

        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_TIMEOUT_AFTER: -1})?.timeoutAfter,
            null,
            reason: '$failureReason: valid value in string form');

        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_TIMEOUT_AFTER: null})?.timeoutAfter,
            defaultValue,
            reason: '$failureReason: null value');
      });

      test('payload field fromMap', () {
        String failureReason =
            'The payload field was not correctly imported from a map';
        String? defaultValue =
            Definitions.initialValues[NOTIFICATION_PAYLOAD] as String?;

        Map<String, String?> customPayload = {
          'key1': 'value1',
          'key2': 'value2'
        };
        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_PAYLOAD: customPayload})?.payload,
            {'key1': 'value1', 'key2': 'value2'},
            reason: '$failureReason: valid value');

        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_PAYLOAD: null})?.payload,
            defaultValue,
            reason: '$failureReason: null value');
      });

      test('customSound field fromMap', () {
        String failureReason =
            'The customSound field was not correctly imported from a map';
        String? defaultValue =
            Definitions.initialValues[NOTIFICATION_CUSTOM_SOUND] as String?;

        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_CUSTOM_SOUND: 'sound.wav'})?.customSound,
            'sound.wav',
            reason: '$failureReason: valid value');

        expect(
            BaseNotificationContent()
                .fromMap({NOTIFICATION_CUSTOM_SOUND: null})?.customSound,
            defaultValue,
            reason: '$failureReason: null value');
      });

      test('roundedLargeIcon field fromMap', () {
        String failureReason =
            'The roundedLargeIcon field was not correctly imported from a map';
        bool? defaultValue =
            Definitions.initialValues[NOTIFICATION_ROUNDED_LARGE_ICON] as bool?;

        expect(
            BaseNotificationContent().fromMap(
                {NOTIFICATION_ROUNDED_LARGE_ICON: true})?.roundedLargeIcon,
            true,
            reason: '$failureReason: true value');

        expect(
            BaseNotificationContent().fromMap(
                {NOTIFICATION_ROUNDED_LARGE_ICON: false})?.roundedLargeIcon,
            false,
            reason: '$failureReason: false value');

        expect(
            BaseNotificationContent().fromMap(
                {NOTIFICATION_ROUNDED_LARGE_ICON: null})?.roundedLargeIcon,
            defaultValue,
            reason: '$failureReason: null value');
      });

      test('roundedBigPicture field fromMap', () {
        String failureReason =
            'The roundedBigPicture field was not correctly imported from a map';
        bool? defaultValue = Definitions
            .initialValues[NOTIFICATION_ROUNDED_BIG_PICTURE] as bool?;

        expect(
            BaseNotificationContent().fromMap(
                {NOTIFICATION_ROUNDED_BIG_PICTURE: true})?.roundedBigPicture,
            true,
            reason: '$failureReason: true value');

        expect(
            BaseNotificationContent().fromMap(
                {NOTIFICATION_ROUNDED_BIG_PICTURE: false})?.roundedBigPicture,
            false,
            reason: '$failureReason: false value');

        expect(
            BaseNotificationContent().fromMap(
                {NOTIFICATION_ROUNDED_BIG_PICTURE: null})?.roundedBigPicture,
            defaultValue,
            reason: '$failureReason: null value');
      });

      test('autoDismissible field fromMap', () {
        String failureReason =
            'The autoDismissible field was not correctly imported from a map';
        bool? defaultValue =
            Definitions.initialValues[NOTIFICATION_AUTO_DISMISSIBLE] as bool?;

        expect(
            BaseNotificationContent().fromMap(
                {NOTIFICATION_AUTO_DISMISSIBLE: true})?.autoDismissible,
            true,
            reason: '$failureReason: true value');

        expect(
            BaseNotificationContent().fromMap(
                {NOTIFICATION_AUTO_DISMISSIBLE: false})?.autoDismissible,
            false,
            reason: '$failureReason: false value');

        expect(
            BaseNotificationContent().fromMap(
                {NOTIFICATION_AUTO_DISMISSIBLE: null})?.autoDismissible,
            defaultValue,
            reason: '$failureReason: null value');

        expect(
            BaseNotificationContent()
                .fromMap({'autoCancel': true})?.autoDismissible,
            true,
            reason: '$failureReason: true value');

        expect(
            BaseNotificationContent()
                .fromMap({'autoCancel': false})?.autoDismissible,
            false,
            reason: '$failureReason: false value');

        expect(
            BaseNotificationContent()
                .fromMap({'autoCancel': null})?.autoDismissible,
            defaultValue,
            reason: '$failureReason: null value');
      });
    });

    group('processRetroCompatibility method', () {
      test('autoCancel field fromMap', () {
        expect(
            BaseNotificationContent().processRetroCompatibility(
                {'autoCancel': true})['autoDismissible'],
            true,
            reason:
                'The deprecated autoCancel field should have been removed.');

        expect(
            BaseNotificationContent().processRetroCompatibility(
                {'autoCancel': false})['autoDismissible'],
            false,
            reason:
                'The deprecated autoCancel field should have been removed.');

        expect(
            BaseNotificationContent().processRetroCompatibility(
                {'autoCancel': 'true'})['autoDismissible'],
            true,
            reason:
                'The deprecated autoCancel field should have been removed.');

        expect(
            BaseNotificationContent().processRetroCompatibility(
                {'autoCancel': 'false'})['autoDismissible'],
            false,
            reason:
                'The deprecated autoCancel field should have been removed.');

        expect(
            BaseNotificationContent().processRetroCompatibility(
                {'autoCancel': 1})['autoDismissible'],
            true,
            reason:
                'The deprecated autoCancel field should have been removed.');

        expect(
            BaseNotificationContent().processRetroCompatibility(
                {'autoCancel': 0})['autoDismissible'],
            false,
            reason:
                'The deprecated autoCancel field should have been removed.');

        expect(
            BaseNotificationContent().processRetroCompatibility(
                {'autoCancel': '1'})['autoDismissible'],
            true,
            reason:
                'The deprecated autoCancel field should have been removed.');

        expect(
            BaseNotificationContent().processRetroCompatibility(
                {'autoCancel': '0'})['autoDismissible'],
            false,
            reason:
                'The deprecated autoCancel field should have been removed.');

        expect(
            BaseNotificationContent().processRetroCompatibility(
                {'autoCancel': null})['autoDismissible'],
            null,
            reason:
                'The deprecated autoCancel field should have been removed.');
      });

      test('AppKilled enum deprecated', () {
        expect(
            BaseNotificationContent().processRetroCompatibility(
                {'someField': 'AppKilled'})['someField'],
            NotificationLifeCycle.Terminated.name,
            reason: 'The deprecated AppKilled value should have been '
                'replaced with Terminated.');

        expect(
            BaseNotificationContent().processRetroCompatibility({
              'someField': NotificationLifeCycle.Terminated.name
            })['someField'],
            NotificationLifeCycle.Terminated.name,
            reason: 'The Terminated value must be preserved');

        expect(
            BaseNotificationContent().processRetroCompatibility(
                {'anotherField': 'NotAppKilled'})['anotherField'],
            'NotAppKilled',
            reason: 'Values that are not AppKilled should remain unchanged.');
      });
    });

    group('validate method', () {
      test('All valid fields', () {
        expect(
            () => BaseNotificationContent(id: 1, channelKey: 'channel_key')
                .validate(),
            returnsNormally,
            reason: 'Valid content should not throw an exception.');

        expect(
            () => BaseNotificationContent(id: null, channelKey: 'channel_key')
                .validate(),
            returnsNormally,
            reason: 'id have a value of -1');
      });
    });

    test('bigPictureImage method', () {
      BaseNotificationContent contentWithBigPicture =
          BaseNotificationContent(bigPicture: 'asset://path/to/bigPicture');

      expect(contentWithBigPicture.bigPictureImage, isNotNull,
          reason: 'bigPictureImage should not be null when bigPicture is set.');

      BaseNotificationContent contentWithoutBigPicture =
          BaseNotificationContent();

      expect(contentWithoutBigPicture.bigPictureImage, isNull,
          reason: 'bigPictureImage should be null when bigPicture is not set.');
    });

    test('largeIconImage method', () {
      BaseNotificationContent contentWithLargeIcon =
          BaseNotificationContent(largeIcon: 'asset://path/to/largeIcon');

      expect(contentWithLargeIcon.largeIconImage, isNotNull,
          reason: 'largeIconImage should not be null when largeIcon is set.');

      BaseNotificationContent contentWithoutLargeIcon =
          BaseNotificationContent();

      expect(contentWithoutLargeIcon.largeIconImage, isNull,
          reason: 'largeIconImage should be null when largeIcon is not set.');
    });

    test('bigPicturePath method', () {
      BaseNotificationContent contentWithBigPicture =
          BaseNotificationContent(bigPicture: 'asset://path/to/bigPicture');

      expect(contentWithBigPicture.bigPicturePath, 'path/to/bigPicture',
          reason:
              'bigPicturePath should return the correct path when bigPicture is set.');

      BaseNotificationContent contentWithoutBigPicture =
          BaseNotificationContent();

      expect(contentWithoutBigPicture.bigPicturePath, isNull,
          reason: 'bigPicturePath should be null when bigPicture is not set.');
    });

    test('largeIconPath method', () {
      BaseNotificationContent contentWithLargeIcon =
          BaseNotificationContent(largeIcon: 'asset://path/to/largeIcon');

      expect(contentWithLargeIcon.largeIconPath, 'path/to/largeIcon',
          reason:
              'largeIconPath should return the correct path when largeIcon is set.');

      BaseNotificationContent contentWithoutLargeIcon =
          BaseNotificationContent();

      expect(contentWithoutLargeIcon.largeIconPath, isNull,
          reason: 'largeIconPath should be null when largeIcon is not set.');
    });

    test('titleWithoutHtml method', () {
      BaseNotificationContent contentWithTitle =
          BaseNotificationContent(title: '<b>Title</b>');

      expect(contentWithTitle.titleWithoutHtml, 'Title',
          reason:
              'titleWithoutHtml should return the title without HTML tags.');

      BaseNotificationContent contentWithoutTitle = BaseNotificationContent();

      expect(contentWithoutTitle.titleWithoutHtml, isNull,
          reason: 'titleWithoutHtml should be null when title is not set.');
    });

    test('bodyWithoutHtml method', () {
      BaseNotificationContent contentWithBody =
          BaseNotificationContent(body: '<i>Body</i>');

      expect(contentWithBody.bodyWithoutHtml, 'Body',
          reason: 'bodyWithoutHtml should return the body without HTML tags.');

      BaseNotificationContent contentWithoutBody = BaseNotificationContent();

      expect(contentWithoutBody.bodyWithoutHtml, isNull,
          reason: 'bodyWithoutHtml should be null when body is not set.');
    });
  });

  test('Getters and Setters', () {
    BaseNotificationContent content = BaseNotificationContent();

    content.displayedDate = DateTime(2023, 5, 1);
    expect(content.displayedDate, DateTime(2023, 5, 1),
        reason: 'displayedDate setter and getter should work correctly.');

    content.createdDate = DateTime(2023, 5, 2);
    expect(content.createdDate, DateTime(2023, 5, 2),
        reason: 'createdDate setter and getter should work correctly.');

    content.createdSource = NotificationSource.Firebase;
    expect(content.createdSource, NotificationSource.Firebase,
        reason: 'createdSource setter and getter should work correctly.');

    content.createdLifeCycle = NotificationLifeCycle.Terminated;
    expect(content.createdLifeCycle, NotificationLifeCycle.Terminated,
        reason: 'createdLifeCycle setter and getter should work correctly.');

    content.displayedLifeCycle = NotificationLifeCycle.Background;
    expect(content.displayedLifeCycle, NotificationLifeCycle.Background,
        reason: 'displayedLifeCycle setter and getter should work correctly.');

    content.actionType = ActionType.SilentAction;
    expect(content.actionType, ActionType.SilentAction,
        reason: 'displayedLifeCycle setter and getter should work correctly.');

    content.privacy = NotificationPrivacy.Private;
    expect(content.privacy, NotificationPrivacy.Private,
        reason: 'displayedLifeCycle setter and getter should work correctly.');
  });

  test('Deprecated Getters and Setters', () {
    // Deprecated getters
    BaseNotificationContent content =
        BaseNotificationContent(autoCancel: false);
    expect(content.autoCancel, false,
        reason: 'autoCancel getter should return the same as autoDismissible.');
    expect(content.autoCancel, false,
        reason: 'autoCancel getter should return the same as autoDismissible.');

    content = BaseNotificationContent(autoDismissible: false);
    expect(content.autoCancel, false,
        reason: 'autoCancel getter should return the same as autoDismissible.');
    expect(content.autoDismissable, false,
        reason: 'autoCancel getter should return the same as autoDismissible.');
  });
}
