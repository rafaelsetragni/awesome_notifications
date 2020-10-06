import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import 'package:awesome_notifications_example/models/media_model.dart';
import 'package:awesome_notifications_example/utils/common_functions.dart';
import 'package:awesome_notifications_example/utils/media_player_central.dart';

/* *********************************************
    LARGE TEXT FOR OUR NOTIFICATIONS TESTS
************************************************ */

String lorenIpsumText =
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut '
    'labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip '
    'ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat '
    'nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit'
    'anim id est laborum';

/* *********************************************
    BASIC NOTIFICATIONS
************************************************ */

Future<void> showBasicNotification(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: 'basic_channel',
          title: 'Simple Notification',
          body: 'Simple body'));
}

Future<void> showNotificationWithPayloadContent(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: 'basic_channel',
          title: 'Simple notification',
          body: 'Only a simple notification',
          payload: {'uuid': 'uuid-test'}));
}

Future<void> showNotificationWithoutTitle(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: 'basic_channel',
          body: 'Only a simple notification',
          payload: {'uuid': 'uuid-test'}));
}

Future<void> showNotificationWithoutBody(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: 'basic_channel',
          title: 'plain title',
          payload: {'uuid': 'uuid-test'}));
}

Future<void> sendBackgroundNotification(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: 'basic_channel',
          payload: {'secret-command': 'block_user'}));
}

/* *********************************************
    ACTION BUTTONS NOTIFICATIONS
************************************************ */

Future<void> showNotificationWithActionButtons(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: 'basic_channel',
          title: 'Anonymous says:',
          body: 'Hi there!',
          payload: {'uuid': 'user-profile-uuid'}),
      actionButtons: [
        NotificationActionButton(
            key: 'READ', label: 'Mark as read', autoCancel: true),
        NotificationActionButton(
            key: 'PROFILE', label: 'Profile', autoCancel: true, enabled: false)
      ]);
}

Future<void> showNotificationWithIconsAndActionButtons(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: 'basic_channel',
          title: 'Anonymous says:',
          body: 'Hi there!',
          payload: {'uuid': 'user-profile-uuid'}),
      actionButtons: [
        NotificationActionButton(
            key: 'READ', label: 'Mark as read', autoCancel: true),
        NotificationActionButton(
            key: 'PROFILE', label: 'Profile', autoCancel: true)
      ]);
}

Future<void> showNotificationWithActionButtonsAndReply(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: 'basic_channel',
          title: 'Anonymous says:',
          body: 'Hi there!',
          payload: {'uuid': 'user-profile-uuid'}),
      actionButtons: [
        NotificationActionButton(
          key: 'REPLY',
          label: 'Reply',
          autoCancel: true,
          buttonType: ActionButtonType.InputField,
        ),
        NotificationActionButton(
            key: 'READ', label: 'Mark as read', autoCancel: true),
        NotificationActionButton(
            key: 'ARCHIVE', label: 'Archive', autoCancel: true)
      ]);
}

/* *********************************************
    LOCKED (ONGOING) NOTIFICATIONS
************************************************ */

Future<void> showLockedNotification(int id) async {
  AwesomeNotifications().setChannel(NotificationChannel(
      channelKey: "locked_notification",
      channelName: "Locked notification",
      channelDescription: "Channel created on the fly with lock option",
      locked: true));

  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: 'basic_channel',
          title: 'Locked notification',
          body: 'This notification is locked and cannot be dismissed',
          payload: {'uuid': 'uuid-test'}));
}

Future<void> showUnlockedNotification(int id) async {
  AwesomeNotifications().setChannel(NotificationChannel(
      channelKey: "locked_notification",
      channelName: "Unlocked notification",
      channelDescription: "Channel created on the fly with lock option",
      locked: false));

  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: 'basic_channel',
          title: 'Unlocked notification',
          body: 'This notification is not locked and can be dismissed',
          payload: {'uuid': 'uuid-test'}));
}

/* *********************************************
    DELAYED NOTIFICATIONS
************************************************ */

Future<void> delayNotification(int id) async {
  var fiveSecondsDelayed = DateTime.now().add(Duration(seconds: 5));

  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: "scheduled",
          title: 'scheduled title',
          body: 'scheduled body',
          payload: {'uuid': 'uuid-test'}),
      schedule: NotificationSchedule(initialDateTime: fiveSecondsDelayed));
}

/* *********************************************
    DELAYED NOTIFICATIONS
************************************************ */

Future<void> showLowVibrationNotification(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: 'low_intensity',
          title: 'Low vibration title',
          body: 'This is a notification with low vibration pattern',
          payload: {'uuid': 'uuid-test'}));
}

Future<void> showMediumVibrationNotification(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: 'medium_intensity',
          title: 'Medium vibration title',
          body: 'This is a notification with medium vibration pattern',
          payload: {'uuid': 'uuid-test'}));
}

Future<void> showHighVibrationNotification(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: 'high_intensity',
          title: 'High vibration title',
          body: 'This is a notification with high vibration pattern',
          payload: {'uuid': 'uuid-test'}));
}

Future<void> showCustomVibrationNotification(int id) async {
  AwesomeNotifications().setChannel(NotificationChannel(
      channelKey: "custom_vibration",
      channelName: "Custom vibration",
      channelDescription: "Channel created on the fly with custom vibration",
      vibrationPattern:
          Int64List.fromList([0, 1000, 200, 200, 1000, 1500, 200, 200]),
      ledOnMs: 1000,
      ledOffMs: 500));

  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: 'custom_vibration',
          title: 'That\'s all for today, folks!',
          bigPicture:
              'https://i0.wp.com/www.jornadageek.com.br/wp-content/uploads/2018/06/Looney-tunes.png?resize=696%2C398&ssl=1',
          notificationLayout: NotificationLayout.BigPicture,
          payload: {'uuid': 'uuid-test'}));
}

/* *********************************************
    COLORFUL AND LED NOTIFICATIONS
************************************************ */

Future<void> redNotification(int id, bool delayLEDTests) async {
  AwesomeNotifications().setChannel(NotificationChannel(
      channelKey: "colorful_notification",
      channelName: "Colorful notifications",
      channelDescription: "A red colorful notification",
      vibrationPattern: lowVibrationPattern,
      defaultColor: Colors.red,
      ledColor: Colors.red,
      ledOnMs: 1000,
      ledOffMs: 500));

  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: "colorful_notification",
          title: "<font color='${Colors.red.value}'>Red Notification</font>",
          body:
              "<font color='${Colors.red.value}'>A colorful notification</font>",
          payload: {
            'uuid': 'uuid-red'
          }),
      actionButtons: [
        NotificationActionButton(
          key: 'REPLY',
          label: 'Reply',
          autoCancel: true,
          buttonType: ActionButtonType.InputField,
        ),
        NotificationActionButton(
            key: 'ARCHIVE', label: 'Archive', autoCancel: true)
      ],
      schedule: delayLEDTests
          ? NotificationSchedule(
              initialDateTime: DateTime.now().add(Duration(seconds: 5)).toUtc())
          : null);
}

Future<void> blueNotification(int id, bool delayLEDTests) async {
  AwesomeNotifications().setChannel(NotificationChannel(
      channelKey: "colorful_notification",
      channelName: "Colorful notifications",
      channelDescription: "A red colorful notification",
      vibrationPattern: lowVibrationPattern,
      defaultColor: Colors.blueAccent,
      ledColor: Colors.blueAccent,
      ledOnMs: 1000,
      ledOffMs: 500));

  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: "colorful_notification",
          title:
              '<font color="${Colors.blueAccent.value}">Blue Notification</font>',
          body: "<font color='${Colors.blueAccent.value}'>A colorful notification</font>",
          payload: {
            'uuid': 'uuid-blue'
          }),
      actionButtons: [
        NotificationActionButton(
          key: 'REPLY',
          label: 'Reply',
          autoCancel: true,
          buttonType: ActionButtonType.InputField,
        ),
        NotificationActionButton(
            key: 'ARCHIVE', label: 'Archive', autoCancel: true)
      ],
      schedule: delayLEDTests
          ? NotificationSchedule(
              initialDateTime: DateTime.now().add(Duration(seconds: 5)).toUtc())
          : null);
}

Future<void> yellowNotification(int id, bool delayLEDTests) async {
  AwesomeNotifications().setChannel(NotificationChannel(
      channelKey: "colorful_notification",
      channelName: "Colorful notifications",
      channelDescription: "A red colorful notification",
      vibrationPattern: lowVibrationPattern,
      defaultColor: CupertinoColors.activeOrange,
      ledColor: CupertinoColors.activeOrange,
      ledOnMs: 1000,
      ledOffMs: 500));

  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: "colorful_notification",
          title: 'Yellow Notification',
          body: 'A colorful notification',
          backgroundColor: CupertinoColors.activeOrange,
          payload: {'uuid': 'uuid-yellow'}),
      actionButtons: [
        NotificationActionButton(
          key: 'REPLY',
          label: 'Reply',
          autoCancel: true,
          buttonType: ActionButtonType.InputField,
        ),
        NotificationActionButton(
            key: 'ARCHIVE', label: 'Archive', autoCancel: true)
      ],
      schedule: delayLEDTests
          ? NotificationSchedule(
              initialDateTime: DateTime.now().add(Duration(seconds: 5)).toUtc())
          : null);
}

Future<void> purpleNotification(int id, bool delayLEDTests) async {
  AwesomeNotifications().setChannel(NotificationChannel(
      channelKey: "colorful_notification",
      channelName: "Colorful notifications",
      channelDescription: "A purple colorful notification",
      vibrationPattern: lowVibrationPattern,
      defaultColor: Colors.deepPurple,
      ledColor: Colors.deepPurple,
      ledOnMs: 1000,
      ledOffMs: 500));

  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: "colorful_notification",
          title:
              '<font color="${Colors.deepPurple.value}">Purple Notification</font>',
          body: "<font color='${Colors.deepPurple.value}'>A colorful notification</font>",
          payload: {
            'uuid': 'uuid-purple'
          }),
      actionButtons: [
        NotificationActionButton(
          key: 'REPLY',
          label: 'Reply',
          autoCancel: true,
          buttonType: ActionButtonType.InputField,
        ),
        NotificationActionButton(
            key: 'ARCHIVE', label: 'Archive', autoCancel: true)
      ],
      schedule: delayLEDTests
          ? NotificationSchedule(
              initialDateTime: DateTime.now().add(Duration(seconds: 5)).toUtc())
          : null);
}

Future<void> greenNotification(int id, bool delayLEDTests) async {
  AwesomeNotifications().setChannel(NotificationChannel(
      channelKey: "colorful_notification",
      channelName: "Colorful notifications",
      channelDescription: "A green colorful notification",
      vibrationPattern: lowVibrationPattern,
      defaultColor: Colors.lightGreen,
      ledColor: Colors.lightGreen,
      ledOnMs: 1000,
      ledOffMs: 500));

  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: "colorful_notification",
          title:
              '<font color="${Colors.lightGreen.value}">Green Notification</font>',
          body: "<font color='${Colors.lightGreen.value}'>A colorful notification</font>",
          payload: {
            'uuid': 'uuid-green'
          }),
      actionButtons: [
        NotificationActionButton(
          key: 'REPLY',
          label: 'Reply',
          autoCancel: true,
          buttonType: ActionButtonType.InputField,
        ),
        NotificationActionButton(
            key: 'ARCHIVE', label: 'Archive', autoCancel: true)
      ],
      schedule: delayLEDTests
          ? NotificationSchedule(
              initialDateTime: DateTime.now().add(Duration(seconds: 5)).toUtc())
          : null);
}

/* *********************************************
    CUSTOM SOUND NOTIFICATIONS
************************************************ */

Future<void> showCustomSoundNotification(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: "custom_sound",
          title: 'It\'s time to morph!',
          body: 'It\'s time to go save the world!',
          notificationLayout: NotificationLayout.BigPicture,
          bigPicture: 'asset://assets/images/fireman-hero.jpg',
          color: Colors.yellow,
          payload: {
        'secret': 'the green ranger and the white ranger are the same person'
      }));
}

/* *********************************************
    SILENCED NOTIFICATIONS
************************************************ */

Future<void> showNotificationWithNoSound(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: "silenced",
          title: 'Silence, please!',
          body: 'Shhhhhh!!!',
          notificationLayout: NotificationLayout.BigPicture,
          bigPicture:
              'https://image.freepik.com/fotos-gratis/medico-serio-mostrando-o-gesto-de-silencio_1262-17188.jpg',
          color: Colors.blueGrey,
          payload: {'advice': 'shhhhhhh'}));
}

/* *********************************************
    BIG PICTURE NOTIFICATIONS
************************************************ */

Future<void> showBigPictureNetworkNotification(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: "big_picture",
          title: 'Big picture (Network)',
          body: '$lorenIpsumText\n\n$lorenIpsumText\n\n$lorenIpsumText',
          bigPicture:
              'https://images.freeimages.com/images/large-previews/d32/space-halo-2-1626962.jpg',
          notificationLayout: NotificationLayout.BigPicture,
          payload: {'uuid': 'uuid-test'}));
}

Future<void> showBigPictureAssetNotification(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: "big_picture",
          title: 'Big picture (Asset)',
          body: '$lorenIpsumText\n\n$lorenIpsumText\n\n$lorenIpsumText',
          bigPicture: 'asset://assets/images/balloons-in-sky.jpg',
          notificationLayout: NotificationLayout.BigPicture,
          payload: {'uuid': 'uuid-test'}));
}

/// Just to simulates a file already saved inside device storage
Future<void> showBigPictureFileNotification(int id) async {
  String newFilePath = await downloadAndSaveImageOnDisk(
      'https://images.freeimages.com/images/large-previews/be7/puppy-2-1456421.jpg',
      'newTestImage.jpg');

  //String newFilePath = await saveImageOnDisk(AssetImage('assets/images/happy-dogs.jpg'),'newTestImage.jpg');
  newFilePath = newFilePath?.replaceFirst('/', '');
  String finalFilePath = 'file://' + (newFilePath ?? '');

  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: "big_picture",
          title: 'Big picture (File)',
          body: '$lorenIpsumText\n\n$lorenIpsumText\n\n$lorenIpsumText',
          bigPicture: finalFilePath,
          notificationLayout: NotificationLayout.BigPicture,
          payload: {'uuid': 'uuid-test'}));
}

Future<void> showBigPictureResourceNotification(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: "big_picture",
          title: 'Big picture (Resource)',
          body: '$lorenIpsumText\n\n$lorenIpsumText\n\n$lorenIpsumText',
          bigPicture: 'resource://drawable/mansion',
          notificationLayout: NotificationLayout.BigPicture,
          payload: {'uuid': 'uuid-test'}));
}

Future<void> showLargeIconNotification(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: "big_picture",
          title: 'Big picture title',
          body: '$lorenIpsumText\n\n$lorenIpsumText\n\n$lorenIpsumText',
          largeIcon:
              'https://image.freepik.com/vetores-gratis/modelo-de-logotipo-de-restaurante-retro_23-2148451519.jpg',
          notificationLayout: NotificationLayout.BigPicture,
          payload: {'uuid': 'uuid-test'}));
}

Future<void> showBigPictureAndLargeIconNotification(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: "big_picture",
          title: 'Big <b>BIG</b> picture title',
          summary: 'Summary <i>text</i>',
          body: '$lorenIpsumText<br><br>$lorenIpsumText<br><br>$lorenIpsumText',
          largeIcon:
              'https://image.freepik.com/vetores-gratis/modelo-de-logotipo-de-restaurante-retro_23-2148451519.jpg',
          bigPicture: 'https://media-cdn.tripadvisor.com/media/photo-s/15/dd/20/61/al-punto.jpg',
          notificationLayout: NotificationLayout.BigPicture,
          payload: {'uuid': 'uuid-test'}));
}

Future<void> showBigPictureNotificationActionButtons(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: "big_picture",
          title: 'Big <b>BIG</b> picture title',
          summary: 'Summary <i>text</i>',
          body: '$lorenIpsumText<br><br>$lorenIpsumText<br><br>$lorenIpsumText',
          largeIcon:
              'https://image.freepik.com/vetores-gratis/modelo-de-logotipo-de-restaurante-retro_23-2148451519.jpg',
          bigPicture: 'https://media-cdn.tripadvisor.com/media/photo-s/15/dd/20/61/al-punto.jpg',
          notificationLayout: NotificationLayout.BigPicture,
          color: Colors.indigoAccent,
          payload: {'uuid': 'uuid-test'}),
      actionButtons: [
        NotificationActionButton(
            key: 'READ', label: 'Mark as read', autoCancel: true),
        NotificationActionButton(
            key: 'REMEMBER', label: 'Remember-me later', autoCancel: false)
      ]);
}

Future<void> showBigPictureNotificationActionButtonsAndReply(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: "big_picture",
          title: 'Big <b>BIG</b> picture title',
          summary: 'Summary <i>text</i>',
          body: '$lorenIpsumText<br><br>$lorenIpsumText<br><br>$lorenIpsumText',
          largeIcon:
              'https://image.freepik.com/vetores-gratis/modelo-de-logotipo-de-restaurante-retro_23-2148451519.jpg',
          bigPicture: 'https://media-cdn.tripadvisor.com/media/photo-s/15/dd/20/61/al-punto.jpg',
          notificationLayout: NotificationLayout.BigPicture,
          color: Colors.indigoAccent,
          payload: {'uuid': 'uuid-test'}),
      actionButtons: [
        NotificationActionButton(
            key: 'REPLY',
            label: 'Reply',
            autoCancel: true,
            buttonType: ActionButtonType.InputField),
        NotificationActionButton(
            key: 'REMEMBER', label: 'Remember-me later', autoCancel: true)
      ]);
}

Future<void> showBigPictureNotificationHideExpandedLargeIcon(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: "big_picture",
          title: 'Big <b>BIG</b> picture title',
          summary: 'Summary <i>text</i>',
          body: '$lorenIpsumText<br><br>$lorenIpsumText<br><br>$lorenIpsumText',
          hideLargeIconOnExpand: true,
          largeIcon:
              'https://img.itdg.com.br/tdg/images/blog/uploads/2019/05/hamburguer.jpg',
          bigPicture: 'https://img.itdg.com.br/tdg/images/blog/uploads/2019/05/hamburguer.jpg',
          notificationLayout: NotificationLayout.BigPicture,
          color: Colors.indigoAccent,
          payload: {'uuid': 'uuid-test'}));
}

/* *********************************************
    BIG TEXT NOTIFICATIONS
************************************************ */

Future<void> showBigTextNotification(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: "big_text",
          title: 'Big text title',
          body: '$lorenIpsumText\n\n$lorenIpsumText\n\n$lorenIpsumText',
          notificationLayout: NotificationLayout.BigText,
          payload: {'uuid': 'uuid-test'}));
}

Future<void> showBigTextNotificationWithDifferentSummary(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: "big_text",
          title: 'Big text title',
          summary: 'Notification summary loren ipsum',
          body: '$lorenIpsumText\n\n$lorenIpsumText\n\n$lorenIpsumText',
          notificationLayout: NotificationLayout.BigText,
          payload: {'uuid': 'uuid-test'}));
}

Future<void> showBigTextHtmlNotification(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: "big_text",
          title: 'Big <b>BIG</b> text title',
          summary: 'Summary <i>text</i>',
          body: '$lorenIpsumText<br><br>$lorenIpsumText<br><br>$lorenIpsumText',
          notificationLayout: NotificationLayout.BigText,
          payload: {'uuid': 'uuid-test'}));
}

Future<void> showBigTextNotificationWithActionAndReply(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: "big_text",
          title: 'Big <b>BIG</b> text title',
          summary: 'Summary <i>text</i>',
          body: '$lorenIpsumText<br><br>$lorenIpsumText<br><br>$lorenIpsumText',
          color: Colors.indigoAccent,
          notificationLayout: NotificationLayout.BigText,
          payload: {'uuid': 'uuid-test'}),
      actionButtons: [
        NotificationActionButton(
            key: 'REPLY',
            label: 'Reply',
            autoCancel: true,
            buttonType: ActionButtonType.InputField),
        NotificationActionButton(
            key: 'REMEMBER', label: 'Remember-me later', autoCancel: true)
      ]);
}

/* *********************************************
    MEDIA CONTROLLER NOTIFICATIONS
************************************************ */

void updateNotificationMediaPlayer(int id, MediaModel mediaNow) {
  if (mediaNow == null) {
    cancelNotification(id);
    return;
  }

  AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: 'media_player',
          title: mediaNow.bandName,
          body: mediaNow.trackName,
          summary: MediaPlayerCentral.isPlaying ? 'Now playing' : '',
          notificationLayout: NotificationLayout.MediaPlayer,
          largeIcon: mediaNow.diskImagePath,
          color: Colors.purple.shade700,
          autoCancel: false,
          showWhen: false),
      actionButtons: [
        NotificationActionButton(
            key: 'MEDIA_PREV',
            icon: 'resource://drawable/ic_prev' +
                (MediaPlayerCentral.hasPreviousMedia ? '' : '_disabled'),
            label: 'Previous',
            autoCancel: false,
            enabled: MediaPlayerCentral.hasPreviousMedia,
            buttonType: ActionButtonType.KeepOnTop),
        MediaPlayerCentral.isPlaying
            ? NotificationActionButton(
                key: 'MEDIA_PAUSE',
                icon: 'resource://drawable/ic_pause',
                label: 'Pause',
                autoCancel: false,
                buttonType: ActionButtonType.KeepOnTop)
            : NotificationActionButton(
                key: 'MEDIA_PLAY',
                icon: 'resource://drawable/ic_play' +
                    (MediaPlayerCentral.hasAnyMedia ? '' : '_disabled'),
                label: 'Play',
                autoCancel: false,
                enabled: MediaPlayerCentral.hasAnyMedia,
                buttonType: ActionButtonType.KeepOnTop),
        NotificationActionButton(
            key: 'MEDIA_NEXT',
            icon: 'resource://drawable/ic_next' +
                (MediaPlayerCentral.hasNextMedia ? '' : '_disabled'),
            label: 'Previous',
            enabled: MediaPlayerCentral.hasNextMedia,
            buttonType: ActionButtonType.KeepOnTop),
        NotificationActionButton(
            key: 'MEDIA_CLOSE',
            icon: 'resource://drawable/ic_close',
            label: 'Close',
            autoCancel: true,
            buttonType: ActionButtonType.KeepOnTop)
      ]);
}

/* *********************************************
    INBOX NOTIFICATIONS
************************************************ */

Future<void> showInboxNotification(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: "inbox",
        title: '5 New mails from tester@gmail.com',
        body:
            '<b>You are our 10.000 visitor! Congratz!</b> You just won our prize'
            '\n'
            '<b>Want to loose weight?</b> Are you tired from false advertisements? '
            '\n'
            '<b>READ MY MESSAGE</b> Stop to ignore me!'
            '\n'
            '<b>READ MY MESSAGE</b> Stop to ignore me!'
            '\n'
            '<b>READ MY MESSAGE</b> Stop to ignore me!'
            '\n'
            '<b>READ MY MESSAGE</b> Stop to ignore me!'
            '\n'
            '<b>READ MY MESSAGE</b> Stop to ignore me!'
            '\n'
            '<b>READ MY MESSAGE</b> Stop to ignore me!'
            '\n'
            '<b>READ MY MESSAGE</b> Stop to ignore me!'
            '\n'
            '<b>READ MY MESSAGE</b> Stop to ignore me!'
            '\n'
            '<b>READ MY MESSAGE</b> Stop to ignore me!'
            '\n'
            '<b>READ MY MESSAGE</b> Stop to ignore me!'
            '\n'
            '<b>READ MY MESSAGE</b> Stop to ignore me!'
            '\n'
            '<b>READ MY MESSAGE</b> Stop to ignore me!',
        summary: 'E-mail inbox',
        largeIcon:
            'https://img.rawpixel.com/s3fs-private/rawpixel_images/website_content/366-mj-7703-fon-jj.jpg?w=800&dpr=1&fit=default&crop=default&q=65&vib=3&con=3&usm=15&bg=F4F4F3&ixlib=js-2.2.1&s=d144b28b5ebf828b7d2a1bb5b31efdb6',
        notificationLayout: NotificationLayout.Inbox,
        payload: {'uuid': 'uuid-test'},
      ),
      actionButtons: [
        NotificationActionButton(
            key: 'DISMISS',
            label: 'Dismiss',
            buttonType: ActionButtonType.DisabledAction,
            autoCancel: true,
            icon: 'resource://drawable/ic_close'),
        NotificationActionButton(
          key: 'READ',
          label: 'Mark as read',
          autoCancel: true,
          //icon: 'resources://drawable/ic_close'
        )
      ]);
}

/* *********************************************
    INBOX NOTIFICATIONS
************************************************ */

Future<void> showGroupedNotifications(id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: 1,
          channelKey: 'grouped',
          title: 'Little Jhonny',
          body: 'Hey dude! Look what i found!'));

  sleep(Duration(microseconds: 700));

  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: 2, channelKey: 'grouped', title: 'Cyclano', body: 'What?'));

  sleep(Duration(seconds: 3));

  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: 3,
          channelKey: 'grouped',
          title: 'Little Jhonny',
          body: 'This push notifications plugin is amazing!'));

  sleep(Duration(seconds: 2));

  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: 3,
          channelKey: 'grouped',
          title: 'Little Jhonny',
          body: 'Its perfect!'));
}

/* *********************************************
    LIST SCHEDULED NOTIFICATIONS
************************************************ */

Future<void> listScheduledNotifications(BuildContext context) async {
  List<PushNotification> activeSchedules =
      await AwesomeNotifications().listScheduledNotifications();
  for (PushNotification schedule in activeSchedules) {
    debugPrint(
        'pending notification: [id: ${schedule.content.id}, title: ${schedule.content.titleWithoutHtml}, initial: ${schedule.schedule.initialDateTime}, cron: ${schedule.schedule.crontabSchedule}]');
  }
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Text('${activeSchedules.length} schedules founded'),
        actions: [
          FlatButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Future<void> repeatMinuteNotification(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: 'schedule',
          title: 'Notification at every single minute',
          body:
              'This notification was schedule to repeat at every single minute.',
          notificationLayout: NotificationLayout.BigPicture,
          bigPicture: 'asset://assets/images/melted-clock.png'),
      schedule: NotificationSchedule(
          crontabSchedule: CronHelper.instance.minutely()));
}

Future<void> repeatPreciseThreeTimes(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: 'schedule',
          title: 'Notification scheduled to play precisely 3 times',
          body: 'This notification was schedule to repeat precisely 3 times.',
          notificationLayout: NotificationLayout.BigPicture,
          bigPicture: 'asset://assets/images/melted-clock.png'),
      schedule: NotificationSchedule(preciseSchedules: [
        DateTime.now().add(Duration(seconds: 10)).toUtc(),
        DateTime.now().add(Duration(seconds: 20)).toUtc(),
        DateTime.now().add(Duration(seconds: 30)).toUtc()
      ]));
}

Future<void> repeatMinuteNotificationOClock(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: 'schedule',
          title: 'Notification at exactly every single minute',
          body:
              'This notification was schedule to repeat at every single minute at clock.',
          notificationLayout: NotificationLayout.BigPicture,
          bigPicture: 'asset://assets/images/melted-clock.png'),
      schedule: NotificationSchedule(
          crontabSchedule: CronHelper.instance.minutely(initialSecond: 0)));
}

Future<void> showNotificationAtScheduleCron(
    int id, DateTime scheduleTime) async {

  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: 'schedule',
          title: 'Just in time!',
          body: 'This notification was schedule to shows at ' +
              DateUtils.parseDateToString(scheduleTime.toLocal()) +
          '('+DateUtils.parseDateToString(scheduleTime.toUtc())+' utc)',
          notificationLayout: NotificationLayout.BigPicture,
          bigPicture: 'asset://assets/images/delivery.jpeg',
          payload: {'uuid': 'uuid-test'}),
      schedule: NotificationSchedule(
          crontabSchedule: CronHelper.instance.atDate(scheduleTime.toUtc(), initialSecond: 0)));
}

Future<void> showScheduleAtWorkweekDay10AmLocal(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: 'schedule',
          title: 'Time to go work!',
          body: 'And the time is ticking...tic, tic, Wake up!',
          payload: {'uuid': 'uuid-test'}),
      schedule: NotificationSchedule(
          crontabSchedule: CronHelper.instance.workweekDay(
              referenceUtcDate:
                  DateUtils.parseStringToDate('10:00', format: 'HH:mm')
                      .toUtc())));
}

Future<void> showNotificationWithNoBadge(int id) async {
  AwesomeNotifications().setChannel(NotificationChannel(
      channelKey: 'no_badge',
      channelName: 'No Badge Notifications',
      channelDescription: 'Notifications with no badge',
      channelShowBadge: false));

  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: 'no_badge',
          title: 'no badge title',
          body: 'no badge body',
          payload: {'uuid': 'uuid-test'}));
}

Future<void> showProgressNotification(int id) async {
  var maxStep = 10;
  for (var simulatedStep = 1; simulatedStep <= maxStep + 1; simulatedStep++) {
    await Future.delayed(Duration(seconds: 1), () async {
      if (simulatedStep > maxStep) {
        await AwesomeNotifications().createNotification(
            content: NotificationContent(
                id: id,
                channelKey: 'progress_bar',
                title: 'Download finished',
                body: 'filename.txt',
                payload: {
                  'file': 'filename.txt',
                  'path': '-rmdir c://ruwindows/system32/huehuehue'
                },
                locked: false));
      } else {
        await AwesomeNotifications().createNotification(
            content: NotificationContent(
                id: id,
                channelKey: 'progress_bar',
                title:
                    'Downloading fake file in progress (${simulatedStep} of $maxStep)',
                body: 'filename.txt',
                payload: {
                  'file': 'filename.txt',
                  'path': '-rmdir c://ruwindows/system32/huehuehue'
                },
                notificationLayout: NotificationLayout.ProgressBar,
                progress: min((simulatedStep / maxStep * 100).round(), 100),
                locked: true));
      }
    });
  }
}

Future<void> showIndeterminateProgressNotification(int id) async {
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: 'progress_bar',
          title: 'Downloading fake file...',
          body: 'filename.txt',
          payload: {
            'file': 'filename.txt',
            'path': '-rmdir c://ruwindows/system32/huehuehue'
          },
          notificationLayout: NotificationLayout.ProgressBar,
          progress: null,
          locked: true));
}

Future<void> showNotificationWithUpdatedChannelDescription(int id) async {
  AwesomeNotifications().setChannel(NotificationChannel(
      channelKey: 'updated_channel',
      channelName: 'Channel to update (updated)',
      channelDescription: 'Notifications with updated channel'));

  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: 'updated_channel',
          title: 'updated notification channel',
          body: 'check settings to see updated channel description',
          payload: {'uuid': '0123456789'}));
}

Future<void> removeChannel() async {
  AwesomeNotifications().removeChannel('updated_channel');
}

Future<void> cancelSchedule(int id) async {
  await AwesomeNotifications().cancelSchedule(id);
}

Future<void> cancelAllSchedules() async {
  await AwesomeNotifications().cancelAllSchedules();
}

Future<void> cancelNotification(int id) async {
  await AwesomeNotifications().cancel(id);
}

Future<void> cancelAllNotifications() async {
  await AwesomeNotifications().cancelAll();
}

String _toTwoDigitString(int value) {
  return value.toString().padLeft(2, '0');
}
