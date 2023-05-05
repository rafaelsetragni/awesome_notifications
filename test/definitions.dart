import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Definitions', () {
    test('initialValues default values', () {
      expect(Definitions.initialValues[NOTIFICATION_ID], 0);
      expect(Definitions.initialValues[NOTIFICATION_GROUP_SORT], GroupSort.Desc);
      expect(Definitions.initialValues[NOTIFICATION_GROUP_ALERT_BEHAVIOR], GroupAlertBehavior.All);
      expect(Definitions.initialValues[NOTIFICATION_IMPORTANCE], NotificationImportance.Default);
      expect(Definitions.initialValues[NOTIFICATION_LAYOUT], NotificationLayout.Default);
      expect(Definitions.initialValues[NOTIFICATION_DEFAULT_PRIVACY], NotificationPrivacy.Private);
      expect(Definitions.initialValues[NOTIFICATION_ACTION_TYPE], ActionType.Default);
      expect(Definitions.initialValues[NOTIFICATION_PRIVACY], NotificationPrivacy.Private);
      expect(Definitions.initialValues[NOTIFICATION_DEFAULT_RINGTONE_TYPE], DefaultRingtoneType.Notification);
      expect(Definitions.initialValues[NOTIFICATION_DISPLAY_ON_FOREGROUND], true);
      expect(Definitions.initialValues[NOTIFICATION_DISPLAY_ON_BACKGROUND], true);
      expect(Definitions.initialValues[NOTIFICATION_CHANNEL_DESCRIPTION], 'Notifications');
      expect(Definitions.initialValues[NOTIFICATION_CHANNEL_NAME], 'Notifications');
      expect(Definitions.initialValues[NOTIFICATION_SHOW_WHEN], true);
      expect(Definitions.initialValues[NOTIFICATION_CHANNEL_SHOW_BADGE], false);
      expect(Definitions.initialValues[NOTIFICATION_ENABLED], true);
      expect(Definitions.initialValues[NOTIFICATION_PAYLOAD], null);
      expect(Definitions.initialValues[NOTIFICATION_ENABLE_VIBRATION], true);
      expect(Definitions.initialValues[NOTIFICATION_COLOR], Colors.black);
      expect(Definitions.initialValues[NOTIFICATION_LED_COLOR], Colors.white);
      expect(Definitions.initialValues[NOTIFICATION_ENABLE_LIGHTS], true);
      expect(Definitions.initialValues[NOTIFICATION_LED_OFF_MS], 700);
      expect(Definitions.initialValues[NOTIFICATION_LED_ON_MS], 300);
      expect(Definitions.initialValues[NOTIFICATION_PLAY_SOUND], true);
      expect(Definitions.initialValues[NOTIFICATION_AUTO_DISMISSIBLE], true);
      expect(Definitions.initialValues[NOTIFICATION_LOCKED], false);
      expect(Definitions.initialValues[NOTIFICATION_TICKER], 'ticker');
      expect(Definitions.initialValues[NOTIFICATION_ALLOW_WHILE_IDLE], false);
      expect(Definitions.initialValues[NOTIFICATION_ONLY_ALERT_ONCE], false);
      expect(Definitions.initialValues[NOTIFICATION_SHOW_IN_COMPACT_VIEW], true);
      expect(Definitions.initialValues[NOTIFICATION_SCHEDULE_REPEATS], false);
      expect(Definitions.initialValues[NOTIFICATION_BUTTON_KEY_PRESSED], '');
      expect(Definitions.initialValues[NOTIFICATION_BUTTON_KEY_INPUT], '');
      expect(Definitions.initialValues[NOTIFICATION_IS_DANGEROUS_OPTION], false);
      expect(Definitions.initialValues[NOTIFICATION_WAKE_UP_SCREEN], false);
      expect(Definitions.initialValues[NOTIFICATION_FULL_SCREEN_INTENT], false);
      expect(Definitions.initialValues[NOTIFICATION_CRITICAL_ALERT], false);
      expect(Definitions.initialValues[NOTIFICATION_CHANNEL_CRITICAL_ALERTS], false);
      expect(Definitions.initialValues[NOTIFICATION_ROUNDED_LARGE_ICON], false);
      expect(Definitions.initialValues[NOTIFICATION_ROUNDED_BIG_PICTURE], false);
    });
  });
}
