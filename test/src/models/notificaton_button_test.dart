import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

void main() {
  group('NotificationActionButton', () {
    test('toMap and fromMap should work properly', () {
      NotificationActionButton actionButton = NotificationActionButton(
        key: 'test_key',
        label: 'test_label',
        icon: 'test_icon',
        enabled: true,
        requireInputText: false,
        autoDismissible: true,
        showInCompactView: false,
        isDangerousOption: true,
        color: Colors.red,
        actionType: ActionType.Default,
      );

      Map<String, dynamic> actionButtonMap = actionButton.toMap();

      expect(actionButton.key, actionButtonMap['key']);
      expect(actionButton.label, actionButtonMap['label']);
      expect(actionButton.icon, actionButtonMap['icon']);
      expect(actionButton.enabled, actionButtonMap['enabled']);
      expect(
          actionButton.requireInputText, actionButtonMap['requireInputText']);
      expect(actionButton.autoDismissible, actionButtonMap['autoDismissible']);
      expect(
          actionButton.showInCompactView, actionButtonMap['showInCompactView']);
      expect(
          actionButton.isDangerousOption, actionButtonMap['isDangerousOption']);
      expect(actionButton.color!.value, actionButtonMap['color']);
      expect(actionButton.actionType!.name, actionButtonMap['actionType']);
    });

    test('fromMap should work properly', () {
      Map<String, dynamic> actionButtonMap = {
        'key': 'test_key',
        'label': 'test_label',
        'icon': 'test_icon',
        'enabled': true,
        'requireInputText': false,
        'autoDismissible': true,
        'showInCompactView': false,
        'isDangerousOption': true,
        'color': Colors.red.value,
        'actionType': ActionType.Default.name,
      };

      NotificationActionButton? actionButton =
          NotificationActionButton(key: '', label: '').fromMap(actionButtonMap);

      expect(actionButton, isNotNull);
      expect(actionButton?.key, 'test_key');
      expect(actionButton?.label, 'test_label');
      expect(actionButton?.icon, 'test_icon');
      expect(actionButton?.enabled, true);
      expect(actionButton?.requireInputText, false);
      expect(actionButton?.autoDismissible, true);
      expect(actionButton?.showInCompactView, false);
      expect(actionButton?.isDangerousOption, true);
      expect(actionButton?.color, Colors.red.shade500);
      expect(actionButton?.actionType, ActionType.Default);
    });
  });

  group('Validate tests', () {
    test('should throw exception if key is null or empty', () {
      NotificationActionButton actionButton = NotificationActionButton(
          key: '', label: 'test_label', actionType: ActionType.Default);
      expect(() => actionButton.validate(),
          throwsA(isA<AwesomeNotificationsException>()));
    });

    test('should throw exception if label is null or empty', () {
      NotificationActionButton actionButton = NotificationActionButton(
          key: 'test_key', label: '', actionType: ActionType.Default);
      expect(() => actionButton.validate(),
          throwsA(isA<AwesomeNotificationsException>()));
    });

    test('should throw exception if icon is not a native resource media type',
        () {
      NotificationActionButton actionButton = NotificationActionButton(
          key: 'test_key',
          label: 'test_label',
          icon: 'http://example.com/icon.png',
          actionType: ActionType.Default);
      expect(() => actionButton.validate(),
          throwsA(isA<AwesomeNotificationsException>()));
    });

    test('should not throw exception for valid action button', () {
      NotificationActionButton actionButton = NotificationActionButton(
          key: 'test_key',
          label: 'test_label',
          icon: 'resource://test_icon',
          actionType: ActionType.Default);
      expect(() => actionButton.validate(), returnsNormally);
    });
  });

  group('NotificationActionButton processRetroCompatibility', () {
    test('should process autoCancel', () {
      NotificationActionButton actionButton = NotificationActionButton(
          key: 'test_key', label: 'test_label', actionType: ActionType.Default);
      Map<String, dynamic> dataMap = actionButton.toMap();
      dataMap['autoCancel'] = true;

      actionButton.processRetroCompatibility(dataMap);

      expect(dataMap[NOTIFICATION_AUTO_DISMISSIBLE], isTrue);
    });

    test('should process buttonType', () {
      NotificationActionButton actionButton = NotificationActionButton(
          key: 'test_key', label: 'test_label', actionType: ActionType.Default);
      Map<String, dynamic> dataMap = actionButton.toMap();
      dataMap['buttonType'] = ActionType.InputField.name;

      actionButton.processRetroCompatibility(dataMap);

      expect(actionButton.requireInputText, equals(true));
    });
  });

  group('NotificationActionButton adaptInputFieldToRequireText', () {
    test('should adapt InputField to requireInputText', () {
      NotificationActionButton actionButton = NotificationActionButton(
          key: 'test_key',
          label: 'test_label',
          actionType: ActionType.InputField);

      actionButton.adaptInputFieldToRequireText();

      expect(actionButton.requireInputText, isTrue);
      expect(actionButton.actionType, equals(ActionType.SilentAction));
    });

    test('should not change anything for other actionTypes', () {
      NotificationActionButton actionButton = NotificationActionButton(
          key: 'test_key', label: 'test_label', actionType: ActionType.Default);

      actionButton.adaptInputFieldToRequireText();

      expect(actionButton.requireInputText, isFalse);
      expect(actionButton.actionType, equals(ActionType.Default));
    });
  });
}
