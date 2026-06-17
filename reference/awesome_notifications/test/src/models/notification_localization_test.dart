import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() {
  group('NotificationLocalization', () {
    test('should create a NotificationLocalization object from a map', () {
      Map<String, dynamic> data = {
        NOTIFICATION_TITLE: 'Title',
        NOTIFICATION_BODY: 'Body',
        NOTIFICATION_SUMMARY: 'Summary',
        NOTIFICATION_LARGE_ICON: 'LargeIcon',
        NOTIFICATION_BIG_PICTURE: 'BigPicture',
        NOTIFICATION_BUTTON_LABELS: {'key1': 'Label1', 'key2': 'Label2'},
      };

      NotificationLocalization? localization =
          NotificationLocalization().fromMap(data);

      expect(localization, isNotNull);
      expect(localization?.title, 'Title');
      expect(localization?.body, 'Body');
      expect(localization?.summary, 'Summary');
      expect(localization?.largeIcon, 'LargeIcon');
      expect(localization?.bigPicture, 'BigPicture');
      expect(localization?.buttonLabels, {'key1': 'Label1', 'key2': 'Label2'});
    });

    test(
        'should not create an empty NotificationLocalization object when given an empty map',
        () {
      Map<String, dynamic> data = {};

      NotificationLocalization? localization =
          NotificationLocalization().fromMap(data);

      expect(localization, isNull);
    });

    test('should convert a NotificationLocalization object to a map', () {
      NotificationLocalization localization = NotificationLocalization(
        title: 'Title',
        body: 'Body',
        summary: 'Summary',
        largeIcon: 'LargeIcon',
        bigPicture: 'BigPicture',
        buttonLabels: {'key1': 'Label1', 'key2': 'Label2'},
      );

      Map<String, dynamic> data = localization.toMap();

      expect(data[NOTIFICATION_TITLE], 'Title');
      expect(data[NOTIFICATION_BODY], 'Body');
      expect(data[NOTIFICATION_SUMMARY], 'Summary');
      expect(data[NOTIFICATION_LARGE_ICON], 'LargeIcon');
      expect(data[NOTIFICATION_BIG_PICTURE], 'BigPicture');
      expect(data[NOTIFICATION_BUTTON_LABELS],
          {'key1': 'Label1', 'key2': 'Label2'});
    });

    test(
        'should not include null or empty values in the map when converting a NotificationLocalization object to a map',
        () {
      NotificationLocalization localization = NotificationLocalization(
        title: null,
        body: '',
        summary: null,
        largeIcon: null,
        bigPicture: null,
        buttonLabels: null,
      );

      Map<String, dynamic> data = localization.toMap();

      expect(data.containsKey(NOTIFICATION_TITLE), false);
      expect(data.containsKey(NOTIFICATION_BODY), false);
      expect(data.containsKey(NOTIFICATION_SUMMARY), false);
      expect(data.containsKey(NOTIFICATION_LARGE_ICON), false);
      expect(data.containsKey(NOTIFICATION_BIG_PICTURE), false);
      expect(data.containsKey(NOTIFICATION_BUTTON_LABELS), false);
    });
  });

  test('validate tests', () {
    NotificationLocalization localization = NotificationLocalization(
      title: null,
      body: '',
      summary: null,
      largeIcon: null,
      bigPicture: null,
      buttonLabels: null,
    );

    expect(() => localization.validate(), returnsNormally);
  });
}
