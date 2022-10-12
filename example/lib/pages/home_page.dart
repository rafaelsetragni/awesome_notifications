import 'package:universal_io/io.dart';
import 'dart:math';

import 'package:awesome_notifications_example/common_widgets/led_light.dart';
import 'package:awesome_notifications_example/common_widgets/seconds_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import 'package:awesome_notifications_example/routes/routes.dart';
import 'package:awesome_notifications_example/notifications/notifications_util.dart';

import 'package:awesome_notifications_example/common_widgets/check_button.dart';
import 'package:awesome_notifications_example/common_widgets/remarkble_text.dart';
import 'package:awesome_notifications_example/common_widgets/simple_button.dart';
import 'package:awesome_notifications_example/common_widgets/text_divisor.dart';
import 'package:awesome_notifications_example/common_widgets/text_note.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:vibration/vibration.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool delayLEDTests = false;
  double _secondsToWakeUp = 5;
  double _secondsToCallCategory = 5;

  bool globalNotificationsAllowed = false;
  bool schedulesFullControl = false;
  bool isCriticalAlertsEnabled = false;
  bool isPreciseAlarmEnabled = false;
  bool isOverrideDnDEnabled = false;

  Map<NotificationPermission, bool> scheduleChannelPermissions = {};
  Map<NotificationPermission, bool> dangerousPermissionsStatus = {};

  List<NotificationPermission> channelPermissions = [
    NotificationPermission.Alert,
    NotificationPermission.Sound,
    NotificationPermission.Badge,
    NotificationPermission.Light,
    NotificationPermission.Vibration,
    NotificationPermission.CriticalAlert,
    NotificationPermission.FullScreenIntent
  ];

  List<NotificationPermission> dangerousPermissions = [
    NotificationPermission.CriticalAlert,
    NotificationPermission.OverrideDnD,
    NotificationPermission.PreciseAlarms,
  ];

  String packageName = 'me.carda.awesome_notifications_example';

  Future<DateTime?> pickScheduleDate(BuildContext context,
      {required bool isUtc}) async {
    TimeOfDay? timeOfDay;
    DateTime now = isUtc ? DateTime.now().toUtc() : DateTime.now();
    DateTime? newDate = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now,
        lastDate: now.add(const Duration(days: 365)));

    if (newDate != null) {
      timeOfDay = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now.add(const Duration(minutes: 1))),
      );

      if (timeOfDay != null) {
        return isUtc
            ? DateTime.utc(newDate.year, newDate.month, newDate.day,
                timeOfDay.hour, timeOfDay.minute)
            : DateTime(newDate.year, newDate.month, newDate.day, timeOfDay.hour,
                timeOfDay.minute);
      }
    }
    return null;
  }

  int _pickAmount = 50;
  Future<int?> pickBadgeCounter(BuildContext context, int initialAmount) async {
    setState(() => _pickAmount = initialAmount);

    // show the dialog
    return showDialog<int?>(
        context: context,
        builder: (BuildContext context) => StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) =>
                AlertDialog(
                  title: const Text("Choose the new badge amount"),
                  content: NumberPicker(
                      value: _pickAmount,
                      minValue: 0,
                      maxValue: 9999,
                      onChanged: (newValue) =>
                          setModalState(() => _pickAmount = newValue)),
                  actions: [
                    TextButton(
                      child: const Text("Cancel"),
                      onPressed: () {
                        Navigator.of(context).pop(null);
                      },
                    ),
                    TextButton(
                      child: const Text("OK"),
                      onPressed: () {
                        Navigator.of(context).pop(_pickAmount);
                      },
                    ),
                  ],
                )));
  }

  @override
  void initState() {
    super.initState();

    for (NotificationPermission permission in channelPermissions) {
      scheduleChannelPermissions[permission] = false;
    }

    for (NotificationPermission permission in dangerousPermissions) {
      dangerousPermissionsStatus[permission] = false;
    }

    refreshPermissionsIcons().then((_) =>
        NotificationUtils.requestBasicPermissionToSendNotifications(context)
            .then((allowed) {
          if (allowed != globalNotificationsAllowed) refreshPermissionsIcons();
        }));
  }

  Future<void> refreshPermissionsIcons() async {
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) async {
      setState(() {
        globalNotificationsAllowed = isAllowed;
      });
    });
    refreshScheduleChannelPermissions();
    refreshDangerousChannelPermissions();
  }

  void refreshScheduleChannelPermissions() {
    AwesomeNotifications()
        .checkPermissionList(
            channelKey: 'scheduled', permissions: channelPermissions)
        .then((List<NotificationPermission> permissionsAllowed) => setState(() {
              schedulesFullControl = true;
              for (NotificationPermission permission in channelPermissions) {
                scheduleChannelPermissions[permission] =
                    permissionsAllowed.contains(permission);
                schedulesFullControl = schedulesFullControl &&
                    scheduleChannelPermissions[permission]!;
              }
            }));
  }

  void refreshDangerousChannelPermissions() {
    AwesomeNotifications()
        .checkPermissionList(permissions: dangerousPermissions)
        .then((List<NotificationPermission> permissionsAllowed) => setState(() {
              for (NotificationPermission permission in dangerousPermissions) {
                dangerousPermissionsStatus[permission] =
                    permissionsAllowed.contains(permission);
              }
              isCriticalAlertsEnabled = dangerousPermissionsStatus[
                  NotificationPermission.CriticalAlert]!;
              isPreciseAlarmEnabled = dangerousPermissionsStatus[
                  NotificationPermission.PreciseAlarms]!;
              isOverrideDnDEnabled = dangerousPermissionsStatus[
                  NotificationPermission.OverrideDnD]!;
            }));
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQuery = MediaQuery.of(context);
    ThemeData themeData = Theme.of(context);

    return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          // ignore: deprecated_member_use
          brightness: Brightness.light,
          title: Image.asset(
              'assets/images/awesome-notifications-logo-color.png',
              width: mediaQuery.size.width *
                  0.6), //Text('Local Notification Example App', style: TextStyle(fontSize: 20)),
          elevation: 10,
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          children: <Widget>[
            /* ******************************************************************** */

            TextDivisor(title: 'Package name'),
            RemarkableText(text: packageName, color: themeData.primaryColor),
            SimpleButton('Copy package name', onPressed: () {
              Clipboard.setData(ClipboardData(text: packageName));
            }),

            /* ******************************************************************** */

            SimpleButton('Show notification with\nReply and Action button',
                onPressed: () =>
                    NotificationUtils.showNotificationWithSilentActionButtons(
                        30)),
            SimpleButton('Show notification from Json Data',
                onPressed: () => NotificationUtils.showNotificationFromJson({
                      "content": {
                        "id": 1,
                        "channelKey": "basic_channel",
                        "title": "Huston! The eagle has landed!",
                        "body":
                            "A small step for a man, but a giant leap to Flutter's community!",
                        "notificationLayout": NotificationLayout.BigPicture,
                        "largeIcon":
                            "https://images.moviefit.me/p/m/41735-neil-armstrong.webp",
                        "bigPicture":
                            "https://www.dw.com/image/49519617_303.jpg",
                        "showWhen": true,
                        "autoCancel": true,
                        "privacy": NotificationPrivacy.Private,
                        "payload": {"secret": "Awesome Notifications Rocks!"}
                      },
                      "actionButtons": [
                        {
                          "key": "REDIRECT",
                          "label": "Redirect",
                          "autoCancel": true
                        },
                        {
                          "key": "DISMISS",
                          "label": "Dismiss",
                          "autoCancel": true,
                          "actionType": ActionType.DismissAction,
                          "isDangerousOption": true
                        }
                      ]
                    })),
            SimpleButton('Cancel notification',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: () => NotificationUtils.cancelNotification(30)),

            /* ******************************************************************** */

            TextDivisor(title: 'Global Permission to send Notifications'),
            PermissionIndicator(
                name: null, allowed: globalNotificationsAllowed),
            const TextNote(
                'To send local and push notifications, it is necessary to obtain the user\'s consent. Keep in mind that he user consent can be revoked at any time.\n\n'
                '* Android: notifications are enabled by default and are considered not dangerous.\n'
                '* iOS: notifications are not enabled by default and you must explicitly request it to the user.'),
            SimpleButton('Request permission',
                enabled: !globalNotificationsAllowed, onPressed: () {
              NotificationUtils.requestBasicPermissionToSendNotifications(
                      context)
                  .then((isAllowed) => setState(() {
                        globalNotificationsAllowed = isAllowed;
                        refreshPermissionsIcons();
                      }));
            }),
            SimpleButton('Open notifications permission page',
                onPressed: () => NotificationUtils.redirectToPermissionsPage()
                    .then((isAllowed) => setState(() {
                          globalNotificationsAllowed = isAllowed;
                          refreshPermissionsIcons();
                        }))),
            SimpleButton('Open basic channel permission page',
                enabled: !Platform.isIOS,
                onPressed: () =>
                    NotificationUtils.redirectToBasicChannelPage()),

            /* ******************************************************************** */

            TextDivisor(title: 'Channel\'s Permissions'),
            Wrap(alignment: WrapAlignment.center, children: <Widget>[
              PermissionIndicator(
                  name: 'Alerts',
                  allowed: scheduleChannelPermissions[
                      NotificationPermission.Alert]!),
              PermissionIndicator(
                  name: 'Sounds',
                  allowed: scheduleChannelPermissions[
                      NotificationPermission.Sound]!),
              PermissionIndicator(
                  name: 'Badges',
                  allowed: scheduleChannelPermissions[
                      NotificationPermission.Badge]!),
              PermissionIndicator(
                  name: 'Vibrations',
                  allowed: scheduleChannelPermissions[
                      NotificationPermission.Vibration]!),
              PermissionIndicator(
                  name: 'Lights',
                  allowed: scheduleChannelPermissions[
                      NotificationPermission.Light]!),
              PermissionIndicator(
                  name: 'Full Intents',
                  allowed: scheduleChannelPermissions[
                      NotificationPermission.FullScreenIntent]!),
              PermissionIndicator(
                  name: 'Critical Alerts',
                  allowed: scheduleChannelPermissions[
                      NotificationPermission.CriticalAlert]!),
            ]),
            const TextNote(
                'To send local and push notifications, it is necessary to obtain the user\'s consent. Keep in mind that he user consent can be revoked at any time.\n\n'
                '* OBS: if the feature is not available on device, it will be considered enabled by default.\n'),
            SimpleButton('Open Schedule channel\'s permission page',
                enabled: !Platform.isIOS,
                onPressed: () =>
                    NotificationUtils.redirectToScheduledChannelsPage()
                        .then((_) => refreshPermissionsIcons())),
            SimpleButton('Request full permissions for Schedule\'s channel',
                enabled: !schedulesFullControl,
                onPressed: () =>
                    NotificationUtils.requestFullScheduleChannelPermissions(
                            context, scheduleChannelPermissions.keys.toList())
                        .then((_) => refreshPermissionsIcons())),

            /* ******************************************************************** */

            TextDivisor(title: 'Global Dangerous Permissions'),
            Wrap(alignment: WrapAlignment.center, children: <Widget>[
              PermissionIndicator(
                  name: 'Critical Alerts', allowed: isCriticalAlertsEnabled),
              PermissionIndicator(
                  name: 'Precise Alarms', allowed: isPreciseAlarmEnabled),
              PermissionIndicator(
                  name: 'Override DnD', allowed: isOverrideDnDEnabled),
            ]),
            const TextNote(
                'Dangerous permissions are permissions that can be disabled by default and you must obtain the user\'s consent explicit to enable. Keep in mind that he user consent can be revoked at any time.\n\n'
                '* Android: override DnD mode is disabled by default. When the permission is granted, the DnD device state is downgraded every time when a new critical notification is displayed and all notifications are being fully suppressed by DnD.\n'
                '* iOS: override DnD is automatically enabled with Critical Alert\'s permission.'),
            SimpleButton('Request Precise Alarms mode',
                enabled: !isPreciseAlarmEnabled,
                onPressed: () =>
                    NotificationUtils.requestPreciseAlarmPermission(context)
                        .then((isAllowed) => setState(() {
                              refreshPermissionsIcons();
                            }))),
            SimpleButton('Request Critical Alerts mode',
                enabled: !isCriticalAlertsEnabled,
                onPressed: () =>
                    NotificationUtils.requestCriticalAlertsPermission(context)
                        .then((isAllowed) => setState(() {
                              refreshPermissionsIcons();
                            }))),
            SimpleButton('Request to Override Do not Disturb mode (Android)',
                enabled: !isOverrideDnDEnabled,
                onPressed: () =>
                    NotificationUtils.requestOverrideDndPermission(context)
                        .then((isAllowed) => setState(() {
                              refreshPermissionsIcons();
                            }))),
            SimpleButton('Open Precise Alarm\'s permission page',
                enabled: !Platform.isIOS,
                onPressed: () => NotificationUtils.redirectToAlarmPage()
                    .then((_) => refreshPermissionsIcons())),
            SimpleButton('Open DnD\'s permission page',
                enabled: !Platform.isIOS,
                onPressed: () => NotificationUtils.redirectToOverrideDndsPage()
                    .then((_) => refreshPermissionsIcons())),

            /* ******************************************************************** */

            TextDivisor(title: 'Basic Notifications'),
            const TextNote('A simple and fast notification to fresh start.\n\n'
                'Tap on notification when it appears on your system tray to go to Details page.'),
            SimpleButton('Show the most basic notification',
                onPressed: () => NotificationUtils.showBasicNotification(1)),
            SimpleButton('Show notification with payload',
                onPressed: () =>
                    NotificationUtils.showNotificationWithPayloadContent(1)),
            SimpleButton('Show notification without body content',
                onPressed: () =>
                    NotificationUtils.showNotificationWithoutBody(1)),
            SimpleButton('Show notification without title content',
                onPressed: () =>
                    NotificationUtils.showNotificationWithoutTitle(1)),
            SimpleButton('Send background notification',
                onPressed: () =>
                    NotificationUtils.sendBackgroundNotification(1)),
            SimpleButton('Cancel the basic notification',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: () => NotificationUtils.cancelNotification(1)),

            /* ******************************************************************** */

            TextDivisor(title: 'Notification\'s Special Category'),
            const TextNote(
                'The notification category is a group of predefined categories '
                    'that best describe the nature of the notification and may '
                    'be used by some systems for ranking, delay or filter the '
                    'notifications. Its highly recommended to correctly '
                    'categorize your notifications..\n\n'
                'Slide the bar above to add some delay on notification.'),
            SecondsSlider(
                steps: 12,
                minValue: 0,
                onChanged: (newValue) {
                  setState(() => _secondsToCallCategory = newValue);
                }),
            SimpleButton('Show call notification', onPressed: () {
              Vibration.vibrate(duration: 100);
                NotificationUtils
                    .showCallNotification(42,_secondsToCallCategory.toInt());
            }),
            SimpleButton('Show alarm notification', onPressed: () {
              Vibration.vibrate(duration: 100);
              NotificationUtils.showAlarmNotification(
                  id: 42, secondsToWait: _secondsToCallCategory.toInt());
            }),
            SimpleButton('Stop Alarm / Call',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: () =>
                    NotificationUtils.stopForegroundServiceNotification(42)),

            /* ******************************************************************** */

            TextDivisor(title: 'Big Picture Notifications'),
            const TextNote(
                'To show any images on notification, at any place, you need '
                    'to include the respective source prefix before the path.'
                '\n\n'
                'Images can be defined using 4 prefix types:'
                '\n\n'
                '* Asset: images access through Flutter asset method.\n\t '
                    'Example:\n\t asset://path/to/image-asset.png'
                '\n\n'
                '* Network: images access through internet connection.\n\t '
                    'Example:\n\t http(s)://url.com/to/image-asset.png'
                '\n\n'
                '* File: images access through files stored on device.\n\t '
                    'Example:\n\t file://path/to/image-asset.png'
                '\n\n'
                '* Resource: images access through drawable native resources.\n\t '
                    'Example:\n\t resource://url.com/to/image-asset.png'),
            SimpleButton('Show large icon notification',
                onPressed: () =>
                    NotificationUtils.showLargeIconNotification(2)),
            SimpleButton('Show big picture notification\n(Network Source)',
                onPressed: () =>
                    NotificationUtils.showBigPictureNetworkNotification(2)),
            SimpleButton('Show big picture notification\n(Asset Source)',
                onPressed: () =>
                    NotificationUtils.showBigPictureAssetNotification(2)),
            SimpleButton('Show big picture notification\n(File Source)',
                onPressed: () =>
                    NotificationUtils.showBigPictureFileNotification(2)),
            SimpleButton('Show big picture notification\n(Resource Source)',
                onPressed: () =>
                    NotificationUtils.showBigPictureResourceNotification(2)),
            SimpleButton(
                'Show big picture and\nlarge icon notification simultaneously',
                onPressed: () =>
                    NotificationUtils.showBigPictureAndLargeIconNotification(
                        2)),
            SimpleButton(
                'Show big picture notification,\n but hide large icon on expand',
                onPressed: () => NotificationUtils
                    .showBigPictureNotificationHideExpandedLargeIcon(2)),
            SimpleButton('Cancel notification',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: () => NotificationUtils.cancelNotification(2)),

            /* ******************************************************************** */

            TextDivisor(
                title:
                    'Emojis ${Emojis.smile_alien}${Emojis.transport_air_rocket}'),
            const TextNote(
                'To send local and push notifications with emojis, use the class Emoji concatenated with your text.\n\n'
                'Attention: not all Emojis work with all platforms. Please, test the specific emoji before using it in production.'),
            SimpleButton('Show notification with emojis',
                onPressed: () => NotificationUtils.showEmojiNotification(1)),
            SimpleButton(
              'Go to complete Emojis list (web)',
              onPressed: () => externalUrl(
                  'https://unicode.org/emoji/charts/full-emoji-list.html'),
            ),

            /* ******************************************************************** */

            TextDivisor(title: 'Locked Notifications (onGoing - Android)'),
            const TextNote(
                'To send local or push locked notification, that users cannot dismiss it swiping it, set the "locked" property to true.\n\n'
                    "Attention: Notification's content locked property has priority over the Channel's one."),
            SimpleButton('Send/Update the locked notification',
                onPressed: () => NotificationUtils.showLockedNotification(2)),
            SimpleButton('Send/Update the unlocked notification',
                onPressed: () => NotificationUtils.showUnlockedNotification(2)),

            /* ******************************************************************** */

            TextDivisor(title: 'Android Foreground Service'),
            const TextNote('This feature is only available for Android devices.'),
            SimpleButton('Start foreground service',
                onPressed: () =>
                    NotificationUtils.startForegroundServiceNotification(9999)),
            SimpleButton('Stop foreground service',
                onPressed: () =>
                    NotificationUtils.stopForegroundServiceNotification(9999)),

            /* ******************************************************************** */

            TextDivisor(title: 'Notification Importance (Priority)'),
            const TextNote(
                'To change the importance level of notifications, please set the importance in the respective channel.\n\n'
                'The possible importance levels are the following:\n\n'
                'Max: Makes a sound and appears as a heads-up notification.\n'
                'Higher: shows everywhere, makes noise and peeks. May use full screen intents.\n'
                'Default: shows everywhere, makes noise, but does not visually intrude.\n'
                'Low: Shows in the shade, and potentially in the status bar (see shouldHideSilentStatusBarIcons()), but is not audibly intrusive\n.'
                'Min: only shows in the shade, below the fold.\n'
                'None: disable the channel\n\n'
                "Attention: Notification's channel importance can only be defined on first time."),
            SimpleButton('Display notification with NotificationImportance.Max',
                onPressed: () => NotificationUtils.showNotificationImportance(
                    3, NotificationImportance.Max)),
            SimpleButton(
                'Display notification with NotificationImportance.High',
                onPressed: () => NotificationUtils.showNotificationImportance(
                    3, NotificationImportance.High)),
            SimpleButton(
                'Display notification with NotificationImportance.Default',
                onPressed: () => NotificationUtils.showNotificationImportance(
                    3, NotificationImportance.Default)),
            SimpleButton('Display notification with NotificationImportance.Low',
                onPressed: () => NotificationUtils.showNotificationImportance(
                    3, NotificationImportance.Low)),
            SimpleButton('Display notification with NotificationImportance.Min',
                onPressed: () => NotificationUtils.showNotificationImportance(
                    3, NotificationImportance.Min)),
            SimpleButton(
                'Display notification with NotificationImportance.None',
                onPressed: () => NotificationUtils.showNotificationImportance(
                    3, NotificationImportance.None)),

            /* ******************************************************************** */

            TextDivisor(title: 'Action Buttons'),
            const TextNote('Action buttons can be used in four types:'
                '\n\n'
                '* Default: after user taps, the notification bar is closed and an action event is fired.'
                '\n\n'
                '* InputField: after user taps, a input text field is displayed to capture input by the user.'
                '\n\n'
                '* DisabledAction: after user taps, the notification bar is closed, but the respective action event is not fired.'
                '\n\n'
                '* KeepOnTop: after user taps, the notification bar is not closed, but an action event is fired.'),
            const TextNote(
                'Since Android Nougat, icons are only displayed on media layout. The icon media needs to be a native resource type.'),
            SimpleButton(
                'Show notification with\nsimple Action buttons (one disabled)',
                onPressed: () =>
                    NotificationUtils.showNotificationWithActionButtons(3)),
            SimpleButton('Show notification with\nIcons and Action buttons',
                onPressed: () =>
                    NotificationUtils.showNotificationWithIconsAndActionButtons(
                        3)),
            SimpleButton('Show notification with\nReply and Action button',
                onPressed: () =>
                    NotificationUtils.showNotificationWithActionButtonsAndReply(
                        3)),
            SimpleButton('Show Big picture notification\nwith Action Buttons',
                onPressed: () =>
                    NotificationUtils.showBigPictureNotificationActionButtons(
                        3)),
            SimpleButton(
                'Show Big picture notification\nwith Reply and Action button',
                onPressed: () => NotificationUtils
                    .showBigPictureNotificationActionButtonsAndReply(3)),
            SimpleButton(
                'Show Big text notification\nwith Reply and Action button',
                onPressed: () =>
                    NotificationUtils.showBigTextNotificationWithActionAndReply(
                        3)),
            SimpleButton('Cancel notification',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: () => NotificationUtils.cancelNotification(3)),

            /* ******************************************************************** */

            TextDivisor(title: 'Badge Indicator'),
            const TextNote(
                '"Badge" is an indicator of how many notifications (or anything else) that have not been viewed by the user (iOS and some versions of Android) '
                'or even a reminder of new things arrived (Android native).\n\n'
                'For platforms that show the global indicator over the app icon, is highly recommended to erase this annoying counter as soon '
                'as possible and even let a shortcut menu with this option outside your app, similar to "mark as read" on e-mail. The amount counter '
                'is automatically managed by this plugin for each individual installation, and incremented for every notification sent to channels '
                'with "badge" set to TRUE.\n\n'
                'OBS: Some Android distributions provide badge counter over the app icon, similar to iOS (LG, Samsung, HTC, Sony, etc).'),
            SimpleButton(
                'Show notification with\nbadge indicator channel activate',
                onPressed: () => NotificationUtils.showBadgeNotification(
                    Random().nextInt(100))),
            SimpleButton(
                'Show notification with\nbadge indicator channel deactivate',
                onPressed: () => NotificationUtils.showWithoutBadgeNotification(
                    Random().nextInt(100))),
            SimpleButton(
                'Show notification, setting\nthe badge indicator to 999',
                onPressed: () => NotificationUtils.showBadgeNotification(
                    Random().nextInt(100),
                    badgeAmount: 999)),
            SimpleButton('Read the badge indicator', onPressed: () async {
              int amount = await NotificationUtils.getBadgeIndicator();
              Fluttertoast.showToast(msg: 'Badge count: $amount');
            }),
            SimpleButton('Increment the badge indicator', onPressed: () async {
              int amount = await NotificationUtils.incrementBadgeIndicator();
              Fluttertoast.showToast(msg: 'Badge count: $amount');
            }),
            SimpleButton('Decrement the badge indicator', onPressed: () async {
              int amount = await NotificationUtils.decrementBadgeIndicator();
              Fluttertoast.showToast(msg: 'Badge count: $amount');
            }),
            SimpleButton('Set manually the badge indicator',
                onPressed: () async {
              int? amount = await pickBadgeCounter(
                  context, await NotificationUtils.getBadgeIndicator());
              if (amount != null) {
                NotificationUtils.setBadgeIndicator(amount);
              }
            }),
            SimpleButton('Reset the badge indicator',
                onPressed: () => NotificationUtils.resetBadgeIndicator()),
            SimpleButton('Cancel all the badge test notifications',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: () => NotificationUtils.cancelAllNotifications()),

            /* ******************************************************************** */

            TextDivisor(title: 'Vibration Patterns'),
            const TextNote(
                'The NotificationModel plugin has 3 vibration patters as example, but you perfectly can create your own patter.'
                '\n'
                'The patter is made by a list of big integer, separated between ON and OFF duration in milliseconds.'),
            const TextNote(
                'A vibration pattern pre-configured in a channel could be updated at any time using the method NotificationModel.setChannel'),
            SimpleButton('Show plain notification with low vibration pattern',
                onPressed: () =>
                    NotificationUtils.showLowVibrationNotification(4)),
            SimpleButton(
                'Show plain notification with medium vibration pattern',
                onPressed: () =>
                    NotificationUtils.showMediumVibrationNotification(4)),
            SimpleButton('Show plain notification with high vibration pattern',
                onPressed: () =>
                    NotificationUtils.showHighVibrationNotification(4)),
            SimpleButton(
                'Show plain notification with custom vibration pattern',
                onPressed: () =>
                    NotificationUtils.showCustomVibrationNotification(4)),
            SimpleButton('Cancel notification',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: () => NotificationUtils.cancelNotification(4)),

            /* ******************************************************************** */

            TextDivisor(title: 'Notification Channels'),
            const TextNote(
                'The channel is a category identifier which notifications are pre-configured and organized before sent.'
                '\n\n'
                'On Android, since Oreo version, the notification channel is mandatory and can be managed by the user on your app config page.\n'
                'Also channels can only update his title and description. All the other parameters could only be change if you erase the channel and recreates it with a different ID.'
                'For other devices, such iOS, notification channels are emulated and used only as pre-configurations.'),
            SimpleButton('Create a test channel called "Editable channel"',
                onPressed: () =>
                    NotificationUtils.createTestChannel('Editable channel')),
            SimpleButton(
                'Update the title and description of "Editable channel"',
                onPressed: () =>
                    NotificationUtils.updateTestChannel('Editable channel')),
            SimpleButton('Remove "Editable channel"',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: () =>
                    NotificationUtils.removeTestChannel('Editable channel')),

            /* ******************************************************************** */

            TextDivisor(title: 'LEDs and Colors'),
            const TextNote(
                'The led colors and the default layout color are independent'),
            const TextNote('Some devices need to be locked to activate LED lights.'
                '\n'
                'If that is your case, please delay the notification to give to you enough time.'),
            CheckButton('Delay notifications for 5 seconds', delayLEDTests,
                onPressed: (value) {
              setState(() {
                delayLEDTests = value;
              });
            }),
            SimpleButton('Notification with red text color\nand red LED',
                onPressed: () =>
                    NotificationUtils.redNotification(5, delayLEDTests)),
            SimpleButton('Notification with yellow text color\nand yellow LED',
                onPressed: () =>
                    NotificationUtils.yellowNotification(5, delayLEDTests)),
            SimpleButton('Notification with green text color\nand green LED',
                onPressed: () =>
                    NotificationUtils.greenNotification(5, delayLEDTests)),
            SimpleButton('Notification with blue text color\nand blue LED',
                onPressed: () =>
                    NotificationUtils.blueNotification(5, delayLEDTests)),
            SimpleButton('Notification with purple text color\nand purple LED',
                onPressed: () =>
                    NotificationUtils.purpleNotification(5, delayLEDTests)),
            SimpleButton('Cancel notification',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: () => NotificationUtils.cancelNotification(5)),

            /* ******************************************************************** */

            TextDivisor(title: 'Wake Up Locked Screen Notifications'),
            const TextNote(
                'Wake Up Locked Screen notifications are notifications that can wake up the device screen to call the user attention, if the device is on lock screen.\n\n'
                'To enable this feature on Android, is necessary to add the WAKE_LOCK permission into your AndroidManifest.xml file. For iOS, this is the default behavior for high priority channels.'),
            SecondsSlider(
                steps: 11,
                onChanged: (newValue) {
                  setState(() => _secondsToWakeUp = newValue);
                }),
            SimpleButton(
                'Schedule notification with wake up locked screen option',
                onPressed: () =>
                    NotificationUtils.scheduleNotificationWithWakeUp(
                        27, _secondsToWakeUp.toInt())),
            SimpleButton('Cancel notification',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: () => NotificationUtils.cancelNotification(27)),

            /* ******************************************************************** */

            TextDivisor(title: 'Full Screen Intent Notifications'),
            const TextNote(
                'Full-Screen Intents are notifications that can launch in full-screen mode. They are indicate since Android 9 to receiving calls and alarm features.\n\n'
                'To enable this feature on Android, is necessary to add the USE_FULL_SCREEN_INTENT permission into your AndroidManifest.xml file and explicit request the user permission since Android 11. For iOS, this option has no effect.'),
            SimpleButton(
                'Schedule notification with full screen locked screen option',
                onPressed: () =>
                    NotificationUtils.scheduleFullScrenNotification(27)),
            SimpleButton('Cancel notification',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: () => NotificationUtils.cancelNotification(27)),

            /* ******************************************************************** */

            TextDivisor(title: 'Notification Sound'),
            SimpleButton('Show notification with custom sound',
                onPressed: () =>
                    NotificationUtils.showCustomSoundNotification(6)),
            SimpleButton('Cancel notification',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: () => NotificationUtils.cancelNotification(6)),

            /* ******************************************************************** */

            TextDivisor(title: 'Silenced Notifications'),
            SimpleButton('Show notification with no sound',
                onPressed: () =>
                    NotificationUtils.showNotificationWithNoSound(7)),
            SimpleButton('Cancel notification',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: () => NotificationUtils.cancelNotification(7)),

            /* ******************************************************************** */

            TextDivisor(title: 'Scheduled Notifications'),
            SimpleButton('Schedule notification with local time zone',
                onPressed: () async {
              DateTime? pickedDate =
                  await pickScheduleDate(context, isUtc: false);
              if (pickedDate != null) {
                NotificationUtils.showNotificationAtSchedulePreciseDate(
                    pickedDate);
              }
            }),
            SimpleButton('Schedule notification with utc time zone',
                onPressed: () async {
              DateTime? pickedDate =
                  await pickScheduleDate(context, isUtc: true);
              if (pickedDate != null) {
                NotificationUtils.showNotificationAtSchedulePreciseDate(
                    pickedDate);
              }
            }),
            SimpleButton(
              'Show notification at every single minute',
              onPressed: () => NotificationUtils.repeatMinuteNotification(),
            ),
            SimpleButton(
              'Show notifications repeatedly in 10 sec, spaced 5 sec from each other for 1 minute (only for Android)',
              onPressed: () => NotificationUtils.repeatMultiple5Crontab(),
            ),
            SimpleButton(
              'Show notification with 3 precise times (only for Android)',
              onPressed: () => NotificationUtils.repeatPreciseThreeTimes(),
            ),
            SimpleButton(
              'Show notification at every single minute o\'clock',
              onPressed: () =>
                  NotificationUtils.repeatMinuteNotificationOClock(),
            ),
            SimpleButton('Get current time zone reference name',
                onPressed: () => NotificationUtils.getCurrentTimeZone()
                    .then((timeZone) => showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                            backgroundColor: const Color(0xfffbfbfb),
                            title: const Center(child: Text('Current Time Zone')),
                            content: SizedBox(
                                height: 80.0,
                                child: Center(
                                    child: Column(
                                  children: [
                                    Text(AwesomeDateUtils.parseDateToString(
                                        DateTime.now())!),
                                    Text(timeZone),
                                  ],
                                ))))))),
            SimpleButton('Get utc time zone reference name',
                onPressed: () => NotificationUtils.getUtcTimeZone()
                    .then((timeZone) => showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                            backgroundColor: const Color(0xfffbfbfb),
                            title: const Center(child: Text('UTC Time Zone')),
                            content: SizedBox(
                                height: 80.0,
                                child: Center(
                                    child: Column(
                                  children: [
                                    Text(AwesomeDateUtils.parseDateToString(
                                        DateTime.now().toUtc())!),
                                    Text(timeZone),
                                  ],
                                ))))))),
            SimpleButton('List all active schedules',
                onPressed: () =>
                    NotificationUtils.listScheduledNotifications(context)),
            SimpleButton(
                'Dismiss the displayed scheduled notifications without cancel the respective schedules',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: () =>
                    NotificationUtils.dismissNotificationsByChannelKey(
                        'scheduled')),
            SimpleButton(
                'Cancel the active schedules without dismiss the displayed notifications',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: () =>
                    NotificationUtils.cancelSchedulesByChannelKey('scheduled')),
            SimpleButton(
                'Cancel all schedules and dismiss the respective displayed notifications',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: () =>
                    NotificationUtils.cancelNotificationsByChannelKey(
                        'scheduled')),

            /* ******************************************************************** */

            TextDivisor(title: 'Get Next Schedule Date'),
            const TextNote(
                'This is a simple example to show how to query the next valid '
                    'schedule date. The date components follow the ISO 8601 '
                    'standard.'),
            SimpleButton('Get next Monday after date', onPressed: () async {
              DateTime? referenceDate =
                  await pickScheduleDate(context, isUtc: false);

              NotificationSchedule schedule = NotificationCalendar(
                  weekday: DateTime.monday,
                  hour: 0,
                  minute: 0,
                  second: 0,
                  timeZone: AwesomeNotifications.localTimeZoneIdentifier);
              //NotificationCalendar.fromDate(date: expectedDate);

              DateTime? nextValidDate = await AwesomeNotifications()
                  .getNextDate(schedule, fixedDate: referenceDate);

              late String response;
              if (nextValidDate == null) {
                response = 'There is no more valid date for this schedule';
              } else {
                response = AwesomeDateUtils.parseDateToString(
                    nextValidDate.toUtc(),
                    format: 'dd/MM/yyyy')!;
              }

              showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                        title: const Text("Next valid schedule"),
                        content: SizedBox(
                            height: 50, child: Center(child: Text(response))),
                        actions: [
                          TextButton(
                            child: const Text("OK"),
                            onPressed: () {
                              Navigator.of(context).pop(null);
                            },
                          )
                        ],
                      ));
            }),

            /* ******************************************************************** */

            TextDivisor(title: 'Media Player'),
            const TextNote(
                'The media player its just emulated and was built to help me to '
                    'check if the notification media control contemplates the '
                    'dev demands, such as sync state, etc.'
                '\n\n'
                'The layout itself was built just for fun, you can use it as '
                    'you wish for.'
                '\n\n'
                'ATTENTION: There is no media reproducing in any place, its '
                    'just a Timer to pretend a time passing.'),
            SimpleButton('Show media player',
                onPressed: () =>
                    Navigator.pushNamed(context, PAGE_MEDIA_DETAILS)),
            SimpleButton('Cancel notification',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: () => NotificationUtils.cancelNotification(100)),

            /* ******************************************************************** */

            TextDivisor(title: 'Progress Notifications'),
            SimpleButton('Show indeterminate progress notification',
                onPressed: () =>
                    NotificationUtils.showIndeterminateProgressNotification(9)),
            SimpleButton('Show progress notification - updates every second',
                onPressed: () => NotificationUtils.showProgressNotification(9)),
            SimpleButton('Cancel notification',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: () => NotificationUtils.cancelNotification(9)),

            /* ******************************************************************** */

            TextDivisor(title: 'Inbox Notifications'),
            SimpleButton(
              'Show Inbox notification',
              onPressed: () => NotificationUtils.showInboxNotification(10),
            ),
            SimpleButton('Cancel notification',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: () => NotificationUtils.cancelNotification(10)),

            /* ******************************************************************** */

            TextDivisor(title: 'Messaging Notifications'),
            SimpleButton('Simulate Chat Messaging notification',
                onPressed: () => NotificationUtils.simulateChatConversation(
                    groupKey: 'jhonny_group')),
            SimpleButton('Cancel Chat notification by group key',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: () =>
                    NotificationUtils.cancelNotificationsByGroupKey(
                        'jhonny_group')),

            /* ******************************************************************** */

            TextDivisor(title: 'Grouped Notifications'),
            SimpleButton('Show grouped notifications',
                onPressed: () =>
                    NotificationUtils.showGroupedNotifications('grouped')),
            SimpleButton('Cancel grouped notifications',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: () =>
                    NotificationUtils.dismissNotificationsByChannelKey(
                        'grouped')),

            /* ******************************************************************** */
            TextDivisor(),
            SimpleButton('Dismiss all notifications by channel key',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: () =>
                    NotificationUtils.dismissNotificationsByChannelKey(
                        'scheduled')),
            SimpleButton('Dismiss all notifications by group key',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: () =>
                    NotificationUtils.dismissNotificationsByGroupKey(
                        'grouped')),
            SimpleButton('Cancel all schedules by channel key',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: () =>
                    NotificationUtils.cancelSchedulesByChannelKey('scheduled')),
            SimpleButton('Cancel all schedules by group key',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: () =>
                    NotificationUtils.cancelSchedulesByGroupKey('grouped')),
            SimpleButton('Cancel all notifications by channel key',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: () =>
                    NotificationUtils.cancelNotificationsByChannelKey(
                        'scheduled')),
            SimpleButton('Cancel all notifications by group key',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: () =>
                    NotificationUtils.cancelNotificationsByGroupKey('grouped')),
            const SimpleButton('Dismiss all notifications',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: NotificationUtils.dismissAllNotifications),
            const SimpleButton('Cancel all active schedules',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: NotificationUtils.cancelAllSchedules),
            const SimpleButton('Cancel all notifications and schedules',
                backgroundColor: Colors.red,
                labelColor: Colors.white,
                onPressed: NotificationUtils.cancelAllNotifications),
          ],
        ));
  }
}

class PermissionIndicator extends StatelessWidget {
  const PermissionIndicator(
      {Key? key, required this.name, required this.allowed})
      : super(key: key);

  final String? name;
  final bool allowed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      width: 125,
      child: Column(
        children: [
          (name != null)
              ? Text('${name!}:', textAlign: TextAlign.center)
              : const SizedBox(),
          Text(allowed ? 'Allowed' : 'Not allowed',
              style: TextStyle(color: allowed ? Colors.green : Colors.red)),
          LedLight(allowed)
        ],
      ),
    );
  }
}
