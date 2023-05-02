import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fromMap and toMap', () {
    test('using notification interval', () {
      NotificationContent content = NotificationContent(
        id: 1,
        channelKey: 'test_channel',
        title: 'Test Title',
        body: 'Test Body',
      );

      NotificationSchedule schedule = NotificationInterval(interval: 60);

      List<NotificationActionButton> actionButtons = [
        NotificationActionButton(
          label: 'Accept',
          key: 'accept',
        ),
        NotificationActionButton(
          label: 'Decline',
          key: 'decline',
        ),
      ];

      Map<String, NotificationLocalization> localizations = {
        'en_US': NotificationLocalization(
          title: 'English Title',
          body: 'English Body',
        ),
        'es_ES': NotificationLocalization(
          title: 'Título en Español',
          body: 'Cuerpo en Español',
        ),
      };

      Map<String, dynamic> dataMap = {
        'content': content.toMap(),
        'schedule': schedule.toMap(),
        'actionButtons': actionButtons.map((button) => button.toMap()).toList(),
        'localizations':
            localizations.map((key, value) => MapEntry(key, value.toMap())),
      };

      NotificationModel? notificationModel =
          NotificationModel().fromMap(dataMap);

      expect(notificationModel, isNotNull);
      expect(notificationModel?.content, isNotNull);
      expect(notificationModel?.content?.title, 'Test Title');
      expect(notificationModel?.content?.body, 'Test Body');

      expect(notificationModel?.schedule, isNotNull);

      expect(notificationModel?.actionButtons, isNotNull);
      expect(notificationModel?.actionButtons?.length, 2);
      expect(notificationModel?.actionButtons?[0].label, 'Accept');
      expect(notificationModel?.actionButtons?[1].label, 'Decline');

      expect(notificationModel?.localizations, isNotNull);
      expect(
          notificationModel?.localizations?['en_US']?.title, 'English Title');
      expect(notificationModel?.localizations?['es_ES']?.title,
          'Título en Español');

      Map<String, dynamic> newDataMap = notificationModel?.toMap() ?? {};
      expect(newDataMap['content']['title'], 'Test Title');
      expect(newDataMap['content']['body'], 'Test Body');

      // ... add assertions for schedule properties in newDataMap
      expect(newDataMap['actionButtons'][0]['label'], 'Accept');
      expect(newDataMap['actionButtons'][1]['label'], 'Decline');

      expect(newDataMap['localizations']['en_US']['title'], 'English Title');
      expect(
          newDataMap['localizations']['es_ES']['title'], 'Título en Español');
    });

    test('using notification callendar', () {
      NotificationContent content = NotificationContent(
        id: 1,
        channelKey: 'test_channel',
        title: 'Test Title',
        body: 'Test Body',
      );

      NotificationSchedule schedule = NotificationCalendar(second: 0);

      List<NotificationActionButton> actionButtons = [
        NotificationActionButton(
          label: 'Accept',
          key: 'accept',
        ),
        NotificationActionButton(
          label: 'Decline',
          key: 'decline',
        ),
      ];

      Map<String, NotificationLocalization> localizations = {
        'en_US': NotificationLocalization(
          title: 'English Title',
          body: 'English Body',
        ),
        'es_ES': NotificationLocalization(
          title: 'Título en Español',
          body: 'Cuerpo en Español',
        ),
      };

      Map<String, dynamic> dataMap = {
        'content': content.toMap(),
        'schedule': schedule.toMap(),
        'actionButtons': actionButtons.map((button) => button.toMap()).toList(),
        'localizations':
            localizations.map((key, value) => MapEntry(key, value.toMap())),
      };

      NotificationModel? notificationModel =
          NotificationModel().fromMap(dataMap);

      expect(notificationModel, isNotNull);
      expect(notificationModel?.content, isNotNull);
      expect(notificationModel?.content?.title, 'Test Title');
      expect(notificationModel?.content?.body, 'Test Body');

      expect(notificationModel?.schedule, isNotNull);

      expect(notificationModel?.actionButtons, isNotNull);
      expect(notificationModel?.actionButtons?.length, 2);
      expect(notificationModel?.actionButtons?[0].label, 'Accept');
      expect(notificationModel?.actionButtons?[1].label, 'Decline');

      expect(notificationModel?.localizations, isNotNull);
      expect(
          notificationModel?.localizations?['en_US']?.title, 'English Title');
      expect(notificationModel?.localizations?['es_ES']?.title,
          'Título en Español');

      Map<String, dynamic> newDataMap = notificationModel?.toMap() ?? {};
      expect(newDataMap['content']['title'], 'Test Title');
      expect(newDataMap['content']['body'], 'Test Body');

      // ... add assertions for schedule properties in newDataMap
      expect(newDataMap['actionButtons'][0]['label'], 'Accept');
      expect(newDataMap['actionButtons'][1]['label'], 'Decline');

      expect(newDataMap['localizations']['en_US']['title'], 'English Title');
      expect(
          newDataMap['localizations']['es_ES']['title'], 'Título en Español');
    });

    test('using notification crontab', () {
      NotificationContent content = NotificationContent(
        id: 1,
        channelKey: 'test_channel',
        title: 'Test Title',
        body: 'Test Body',
      );

      NotificationSchedule schedule =
          NotificationAndroidCrontab(crontabExpression: '0 30 14 * * *');

      List<NotificationActionButton> actionButtons = [
        NotificationActionButton(
          label: 'Accept',
          key: 'accept',
        ),
        NotificationActionButton(
          label: 'Decline',
          key: 'decline',
        ),
      ];

      Map<String, NotificationLocalization> localizations = {
        'en_US': NotificationLocalization(
          title: 'English Title',
          body: 'English Body',
        ),
        'es_ES': NotificationLocalization(
          title: 'Título en Español',
          body: 'Cuerpo en Español',
        ),
      };

      Map<String, dynamic> dataMap = {
        'content': content.toMap(),
        'schedule': schedule.toMap(),
        'actionButtons': actionButtons.map((button) => button.toMap()).toList(),
        'localizations':
            localizations.map((key, value) => MapEntry(key, value.toMap())),
      };

      NotificationModel? notificationModel =
          NotificationModel().fromMap(dataMap);

      expect(notificationModel, isNotNull);
      expect(notificationModel?.content, isNotNull);
      expect(notificationModel?.content?.title, 'Test Title');
      expect(notificationModel?.content?.body, 'Test Body');

      expect(notificationModel?.schedule, isNotNull);

      expect(notificationModel?.actionButtons, isNotNull);
      expect(notificationModel?.actionButtons?.length, 2);
      expect(notificationModel?.actionButtons?[0].label, 'Accept');
      expect(notificationModel?.actionButtons?[1].label, 'Decline');

      expect(notificationModel?.localizations, isNotNull);
      expect(
          notificationModel?.localizations?['en_US']?.title, 'English Title');
      expect(notificationModel?.localizations?['es_ES']?.title,
          'Título en Español');

      Map<String, dynamic> newDataMap = notificationModel?.toMap() ?? {};
      expect(newDataMap['content']['title'], 'Test Title');
      expect(newDataMap['content']['body'], 'Test Body');

      // ... add assertions for schedule properties in newDataMap
      expect(newDataMap['actionButtons'][0]['label'], 'Accept');
      expect(newDataMap['actionButtons'][1]['label'], 'Decline');

      expect(newDataMap['localizations']['en_US']['title'], 'English Title');
      expect(
          newDataMap['localizations']['es_ES']['title'], 'Título en Español');
    });
  });

  group('validate', () {
    test('validate throws an exception when content is null', () {
      NotificationModel notificationModel = NotificationModel();

      expect(
        () => notificationModel.validate(),
        throwsA(isA<AwesomeNotificationsException>()),
      );
    });

    test('validate does not throw an exception when content is not null', () {
      NotificationContent content = NotificationContent(
        id: 1,
        channelKey: 'test_channel',
        title: 'Test Title',
        body: 'Test Body',
      );

      NotificationModel notificationModel = NotificationModel(content: content);

      expect(
        () => notificationModel.validate(),
        returnsNormally,
      );
    });
  });
}
