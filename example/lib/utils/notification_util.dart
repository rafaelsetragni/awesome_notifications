import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:awesome_notifications/android_foreground_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// TO AVOID CONFLICT WITH MATERIAL DATE UTILS CLASS
import 'package:awesome_notifications/awesome_notifications.dart'
    hide DateUtils;
import 'package:awesome_notifications/awesome_notifications.dart' as Utils
    show DateUtils;

import 'package:awesome_notifications_example/models/media_model.dart';
import 'package:awesome_notifications_example/utils/common_functions.dart';
import 'package:awesome_notifications_example/utils/media_player_central.dart';
import 'package:url_launcher/url_launcher.dart';

/* *********************************************
    LARGE TEXT FOR OUR NOTIFICATIONS TESTS
************************************************ */

String lorenIpsumText =
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut '
    'labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip '
    'ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat '
    'nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit'
    'anim id est laborum';

Future<void> externalUrl(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

int createUniqueID(int maxValue){
  Random random = new Random();
  return random.nextInt(maxValue);
}

/* *********************************************
    PERMISSIONS
************************************************ */

class NotificationUtils {

  static Future<bool> redirectToPermissionsPage() async {
    await AwesomeNotifications().showNotificationConfigPage();
    return await AwesomeNotifications().isNotificationAllowed();
  }
  
  static Future<void> redirectToBasicChannelPage() async {
    await AwesomeNotifications().showNotificationConfigPage(channelKey: 'basic_channel');
  }
  
  static Future<void> redirectToAlarmPage() async {
    await AwesomeNotifications().showAlarmPage();
  }

  static Future<void> redirectToScheduledChannelsPage() async {
    await AwesomeNotifications().showNotificationConfigPage(channelKey: 'scheduled');
  }

  static Future<void> redirectToOverrideDndsPage() async {
    await AwesomeNotifications().showGlobalDndOverridePage();
  }
  
  static Future<bool> requestBasicPermissionToSendNotifications(BuildContext context) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if(!isAllowed){
      await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Color(0xfffbfbfb),
            title: Text(
                'Get Notified!',
                maxLines: 2,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.w600)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/animated-bell.gif',
                  height: MediaQuery.of(context).size.height * 0.3,
                  fit: BoxFit.fitWidth,
                ),
                Text(
                  'Allow Awesome Notifications to send you beautiful notifications!',
                  maxLines: 4,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: (){ Navigator.pop(context); },
                  child: Text(
                    'Later',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  )
              ),
              TextButton(
                onPressed: () async {
                  isAllowed = await AwesomeNotifications().requestPermissionToSendNotifications();
                  Navigator.pop(context);
                },
                child: Text(
                  'Allow',
                  style: TextStyle(color: Colors.deepPurple, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          )
      );
    }
    return isAllowed;
  }

  static Future<void> requestFullScheduleChannelPermissions(BuildContext context, List<NotificationPermission> requestedPermissions) async {
    String channelKey = 'scheduled';

    await requestUserPermissions(context, channelKey: channelKey, permissionList: requestedPermissions);
  }

  static Future<List<NotificationPermission>> requestUserPermissions(
      BuildContext context,{
      // if you only intends to request the permissions until app level, set the channelKey value to null
      required String? channelKey,
      required List<NotificationPermission> permissionList}
    ) async {

    // Check if the basic permission was conceived by the user
    if(!await requestBasicPermissionToSendNotifications(context))
      return [];

    // Check which of the permissions you need are allowed at this time
    List<NotificationPermission> permissionsAllowed = await AwesomeNotifications().checkPermissionList(
        channelKey: channelKey,
        permissions: permissionList
    );

    // If all permissions are allowed, there is nothing to do
    if(permissionsAllowed.length == permissionList.length)
      return permissionsAllowed;

    // Refresh the permission list with only the disallowed permissions
    List<NotificationPermission> permissionsNeeded =
      permissionList.toSet().difference(permissionsAllowed.toSet()).toList();

    // Check if some of the permissions needed request user's intervention to be enabled
    List<NotificationPermission> lockedPermissions = await AwesomeNotifications().shouldShowRationaleToRequest(
        channelKey: channelKey,
        permissions: permissionsNeeded
    );

    // If there is no permitions depending of user's intervention, so request it directly
    if(lockedPermissions.isEmpty){

      // Request the permission through native resources.
      await AwesomeNotifications().requestPermissionToSendNotifications(
          channelKey: channelKey,
          permissions: permissionsNeeded
      );

      // After the user come back, check if the permissions has successfully enabled
      permissionsAllowed = await AwesomeNotifications().checkPermissionList(
          channelKey: channelKey,
          permissions: permissionsNeeded
      );
    }
    else {
      // If you need to show a rationale to educate the user to conceed the permission, show it
      await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Color(0xfffbfbfb),
            title: Text('Awesome Notificaitons needs your permission',
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/animated-clock.gif',
                  height: MediaQuery.of(context).size.height * 0.3,
                  fit: BoxFit.fitWidth,
                ),
                Text(
                  'To proceede, you need to enable the permissions above'+
                      (channelKey?.isEmpty ?? true ? '' : ' on channel $channelKey')+':',
                  maxLines: 2,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 5),
                Text(
                  lockedPermissions.join(', ').replaceAll('NotificationPermission.', ''),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: (){ Navigator.pop(context); },
                  child: Text(
                    'Deny',
                    style: TextStyle(color: Colors.red, fontSize: 18),
                  )
              ),
              TextButton(
                onPressed: () async {

                  // Request the permission through native resources. Only one page redirection is done at this point.
                  await AwesomeNotifications().requestPermissionToSendNotifications(
                      channelKey: channelKey,
                      permissions: lockedPermissions
                  );

                  // After the user come back, check if the permissions has successfully enabled
                  permissionsAllowed = await AwesomeNotifications().checkPermissionList(
                      channelKey: channelKey,
                      permissions: lockedPermissions
                  );

                  Navigator.pop(context);
                },
                child: Text(
                  'Allow',
                  style: TextStyle(color: Colors.deepPurple, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          )
      );
    }

    // Return the updated list of allowed permissions
    return permissionsAllowed;
  }

  static Future<bool> requestCriticalAlertsPermission(BuildContext context) async {

    List<NotificationPermission> requestedPermissions = [
      NotificationPermission.CriticalAlert
    ];

    List<NotificationPermission> permissionsAllowed =
    await requestUserPermissions(
        context,
        channelKey: null,
        permissionList: requestedPermissions);

    return permissionsAllowed.isNotEmpty;
  }

  static Future<bool> requestFullIntentPermission(BuildContext context) async {

    List<NotificationPermission> requestedPermissions = [
      NotificationPermission.CriticalAlert
    ];

    List<NotificationPermission> permissionsAllowed =
    await requestUserPermissions(
        context,
        channelKey: null,
        permissionList: requestedPermissions);

    return permissionsAllowed.isNotEmpty;
  }

  static Future<bool> requestPreciseAlarmPermission(BuildContext context) async {

    List<NotificationPermission> requestedPermissions = [
      NotificationPermission.PreciseAlarms
    ];

    List<NotificationPermission> permissionsAllowed =
    await requestUserPermissions(
        context,
        channelKey: null,
        permissionList: requestedPermissions);

    return permissionsAllowed.isNotEmpty;
  }

  static Future<bool> requestOverrideDndPermission(BuildContext context) async {

    List<NotificationPermission> requestedPermissions = [
      NotificationPermission.OverrideDnD
    ];

    List<NotificationPermission> permissionsAllowed =
    await requestUserPermissions(
        context,
        channelKey: null,
        permissionList: requestedPermissions);

    return permissionsAllowed.isNotEmpty;
  }

  /* *********************************************
      BASIC NOTIFICATIONS
  ************************************************ */
  
  static Future<void> showBasicNotification(int id) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'basic_channel',
        title: 'Simple Notification',
        body: 'Simple body'
      )
    );
  }
  
  static Future<void> showEmojiNotification(int id) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'basic_channel',
        category: NotificationCategory.Social,
        title: 'Emojis are awesome too! ' +
            Emojis.smile_face_with_tongue +
            Emojis.smile_smiling_face +
            Emojis.smile_smiling_face_with_heart_eyes,
        body:
            'Simple body with a bunch of Emojis! ${Emojis.transport_police_car} ${Emojis.animals_dog} ${Emojis.flag_UnitedStates} ${Emojis.person_baby}',
        largeIcon: 'https://tecnoblog.net/wp-content/uploads/2019/09/emoji.jpg',
        bigPicture: 'https://tecnoblog.net/wp-content/uploads/2019/09/emoji.jpg',
        hideLargeIconOnExpand: true,
        notificationLayout: NotificationLayout.BigPicture,
    ));
  }
  
  static Future<void> showNotificationWithPayloadContent(int id) async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: 'basic_channel',
            title: 'Simple notification',
            body: 'Only a simple notification',
            payload: {'uuid': 'uuid-test'}));
  }
  
  static Future<void> showNotificationWithoutTitle(int id) async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: 'basic_channel',
            body: 'Only a simple notification',
            payload: {'uuid': 'uuid-test'}));
  }
  
  static Future<void> showNotificationWithoutBody(int id) async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: 'basic_channel',
            title: 'plain title',
            payload: {'uuid': 'uuid-test'}));
  }
  
  static Future<void> sendBackgroundNotification(int id) async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: 'basic_channel',
            payload: {'secret-command': 'block_user'}));
  }
  
  /* *********************************************
      BADGE NOTIFICATIONS
  ************************************************ */
  
  static Future<void> showBadgeNotification(int id) async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: 'badge_channel',
            title: 'Badge test notification',
            body: 'This notification does activate badge indicator'),
        schedule: NotificationInterval(interval: 5, timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier())
    );
  }
  
  static Future<void> showWithoutBadgeNotification(int id) async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: 'basic_channel',
            title: 'Badge test notification',
            body: 'This notification does not activate badge indicator'),
        schedule: NotificationInterval(interval: 5, timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier())
    );
  }
  
  // ON BADGE METHODS, NULL CHANNEL SETS THE GLOBAL COUNTER
  
  static Future<int> getBadgeIndicator() async {
    int amount = await AwesomeNotifications().getGlobalBadgeCounter();
    return amount;
  }
  
  static Future<void> setBadgeIndicator(int amount) async {
    await AwesomeNotifications().setGlobalBadgeCounter(amount);
  }
  
  static Future<int> incrementBadgeIndicator() async {
    return await AwesomeNotifications().incrementGlobalBadgeCounter();
  }
  
  static Future<int> decrementBadgeIndicator() async {
    return await AwesomeNotifications().decrementGlobalBadgeCounter();
  }
  
  static Future<void> resetBadgeIndicator() async {
    await AwesomeNotifications().resetGlobalBadge();
  }
  
  /* *********************************************
      ACTION BUTTONS NOTIFICATIONS
  ************************************************ */
  
  static Future<void> showNotificationWithActionButtons(int id) async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: 'basic_channel',
            title: 'Anonymous says:',
            body: 'Hi there!',
            payload: {'uuid': 'user-profile-uuid'}),
        actionButtons: [
          NotificationActionButton(
              key: 'READ', label: 'Mark as read', autoDismissible: true),
          NotificationActionButton(
              key: 'PROFILE', label: 'Profile', autoDismissible: true, enabled: false)
        ]);
  }
  
  static Future<void> showNotificationWithIconsAndActionButtons(int id) async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: 'basic_channel',
            title: 'Anonymous says:',
            body: 'Hi there!',
            payload: {'uuid': 'user-profile-uuid'}),
        actionButtons: [
          NotificationActionButton(
              key: 'READ', label: 'Mark as read', autoDismissible: true),
          NotificationActionButton(
              key: 'PROFILE', label: 'Profile', autoDismissible: true, color: Colors.green),
          NotificationActionButton(
              key: 'DISMISS',
              label: 'Dismiss',
              autoDismissible: true,
              buttonType: ActionButtonType.DisabledAction,
              isDangerousOption: true)
        ]);
  }
  
  static Future<void> showNotificationWithActionButtonsAndReply(int id) async {
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
            autoDismissible: true,
            buttonType: ActionButtonType.InputField,
          ),
          NotificationActionButton(
              key: 'READ', label: 'Mark as read', autoDismissible: true),
          NotificationActionButton(
              key: 'ARCHIVE', label: 'Archive', autoDismissible: true)
        ]);
  }

  /* *********************************************
      NOTIFICATION'S SPECIAL CATEGORIES
  ************************************************ */

  static Future<void> showCallNotification(int id) async {
    String platformVersion = await getPlatformVersion();
    AndroidForegroundService.startForeground(
    //await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: 'call_channel',
            title: 'Incoming Call',
            body: 'from Little Mary',
            category: NotificationCategory.Call,
            largeIcon: 'asset://assets/images/girl-phonecall.jpg',
            wakeUpScreen: true,
            fullScreenIntent: true,
            autoDismissible: false,
            backgroundColor: (platformVersion == 'Android-31') ?
              Color(0x00796a) : Colors.white,
            payload: {
              'username': 'Little Mary'
            }
        ),
        actionButtons: [
          NotificationActionButton(
              key: 'ACCEPT',
              label: 'Accept Call',
              color: Colors.green,
              autoDismissible: true
          ),
          NotificationActionButton(
              key: 'REJECT',
              label: 'Reject',
              isDangerousOption: true,
              autoDismissible: true
          ),
        ]
    );
  }

  static Future<void> showAlarmNotification(int id) async {
    AndroidForegroundService.startForeground(
        content: NotificationContent(
            id: id,
            channelKey: 'alarm_channel',
            title: 'Alarm is playing',
            body: 'Hey! Wake Up!',
            category: NotificationCategory.Alarm
        ),
        actionButtons: [
          NotificationActionButton(
              key: 'SNOOZE',
              label: 'Snooze for 5 minutes',
              color: Colors.blue,
              autoDismissible: true
          ),
        ]
    );
  }
  
  /* *********************************************
      LOCKED (ONGOING) NOTIFICATIONS
  ************************************************ */
  
  static Future<void> showLockedNotification(int id) async {
    AwesomeNotifications().setChannel(NotificationChannel(
        channelKey: 'locked_notification',
        channelName: 'Locked notification',
        channelDescription: 'Channel created on the fly with lock option',
        locked: true));
  
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: 'locked_notification',
            title: 'Locked notification',
            body: 'This notification is locked and cannot be dismissed',
            payload: {'uuid': 'uuid-test'}));
  }
  
  static Future<void> showUnlockedNotification(int id) async {
    AwesomeNotifications().setChannel(NotificationChannel(
        channelKey: 'locked_notification',
        channelName: 'Unlocked notification',
        channelDescription: 'Channel created on the fly with lock option',
        locked: true));
  
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: 'locked_notification',
            title: 'Unlocked notification',
            body: 'This notification is not locked and can be dismissed',
            payload: {'uuid': 'uuid-test'},
            locked: false));
  }
  
  /* *********************************************
      NOTIFICATION CHANNELS MANIPULATION
  ************************************************ */
  
  static Future<void> showNotificationImportance(
      int id, NotificationImportance importance) async {
    String importanceKey = importance.toString().toLowerCase().split('.').last;
    String channelKey = 'importance_' + importanceKey + '_channel';
    String title = 'Importance levels (' + importanceKey + ')';
    String body = 'Test of importance levels to ' + importanceKey;
  
    await AwesomeNotifications().setChannel(NotificationChannel(
        channelKey: channelKey,
        channelName: title,
        channelDescription: body,
        importance: importance,
        defaultColor: Colors.red,
        ledColor: Colors.red,
        vibrationPattern: highVibrationPattern));
  
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: channelKey,
            title: title,
            body: body,
            payload: {'uuid': 'uuid-test'}));
  }
  
  /* *********************************************
      NOTIFICATION CHANNELS MANIPULATION
  ************************************************ */
  
  static Future<void> createTestChannel(String channelName) async {
    await AwesomeNotifications().setChannel(NotificationChannel(
        channelGroupKey: 'channel_tests',
        channelKey: channelName.toLowerCase().replaceAll(' ', '_'),
        channelName: channelName,
        channelDescription:
            "Channel created to test the channels manipulation."));
  }
  
  static Future<void> updateTestChannel(String channelName) async {
    await AwesomeNotifications().setChannel(NotificationChannel(
        channelGroupKey: 'channel_tests',
        channelKey: channelName.toLowerCase().replaceAll(' ', '_'),
        channelName: channelName + " (updated)",
        channelDescription: "This channel was successfuly updated."));
  }
  
  static Future<void> removeTestChannel(String channelName) async {
    await AwesomeNotifications()
        .removeChannel(channelName.toLowerCase().replaceAll(' ', '_'));
  }
  
  /* *********************************************
      DELAYED NOTIFICATIONS
  ************************************************ */
  
  static Future<void> delayNotification(int id) async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: "scheduled",
            title: 'scheduled title',
            body: 'scheduled body',
            payload: {'uuid': 'uuid-test'}),
        schedule: NotificationInterval(interval: 5, timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier())
    );
  }
  
  /* *********************************************
      DELAYED NOTIFICATIONS
  ************************************************ */
  
  static Future<void> showLowVibrationNotification(int id) async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: 'low_intensity',
            title: 'Low vibration title',
            body: 'This is a notification with low vibration pattern',
            payload: {'uuid': 'uuid-test'}));
  }
  
  static Future<void> showMediumVibrationNotification(int id) async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: 'medium_intensity',
            title: 'Medium vibration title',
            body: 'This is a notification with medium vibration pattern',
            payload: {'uuid': 'uuid-test'}));
  }
  
  static Future<void> showHighVibrationNotification(int id) async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: 'high_intensity',
            title: 'High vibration title',
            body: 'This is a notification with high vibration pattern',
            payload: {'uuid': 'uuid-test'}));
  }
  
  static Future<void> showCustomVibrationNotification(int id) async {
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
  
  static Future<void> redNotification(int id, bool delayLEDTests) async {
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
            payload: {'uuid': 'uuid-red'}),
        actionButtons: [
          NotificationActionButton(
            key: 'REPLY',
            label: 'Reply',
            autoDismissible: true,
            buttonType: ActionButtonType.InputField,
          ),
          NotificationActionButton(
              key: 'ARCHIVE', label: 'Archive', autoDismissible: true)
        ],
        schedule: delayLEDTests ? NotificationInterval(
            interval: 5,
            timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier()) : null);
  }
  
  static Future<void> blueNotification(int id, bool delayLEDTests) async {
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
            payload: {'uuid': 'uuid-blue'}),
        actionButtons: [
          NotificationActionButton(
            key: 'REPLY',
            label: 'Reply',
            autoDismissible: true,
            buttonType: ActionButtonType.InputField,
          ),
          NotificationActionButton(
              key: 'ARCHIVE', label: 'Archive', autoDismissible: true)
        ],
        schedule: delayLEDTests ? NotificationInterval(interval: 5, timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier()) : null);
  }
  
  static Future<void> yellowNotification(int id, bool delayLEDTests) async {
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
            autoDismissible: true,
            buttonType: ActionButtonType.InputField,
          ),
          NotificationActionButton(
              key: 'ARCHIVE', label: 'Archive', autoDismissible: true)
        ],
        schedule: delayLEDTests ? NotificationInterval(interval: 5, timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier()) : null);
  }
  
  static Future<void> purpleNotification(int id, bool delayLEDTests) async {
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
            payload: {'uuid': 'uuid-purple'}),
        actionButtons: [
          NotificationActionButton(
            key: 'REPLY',
            label: 'Reply',
            autoDismissible: true,
            buttonType: ActionButtonType.InputField,
          ),
          NotificationActionButton(
              key: 'ARCHIVE', label: 'Archive', autoDismissible: true)
        ],
        schedule: delayLEDTests ? NotificationInterval(interval: 5, timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier()) : null);
  }
  
  static Future<void> greenNotification(int id, bool delayLEDTests) async {
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
            payload: {'uuid': 'uuid-green'}),
        actionButtons: [
          NotificationActionButton(
            key: 'REPLY',
            label: 'Reply',
            autoDismissible: true,
            buttonType: ActionButtonType.InputField,
          ),
          NotificationActionButton(
              key: 'ARCHIVE', label: 'Archive', autoDismissible: true)
        ],
        schedule: delayLEDTests ? NotificationInterval(interval: 5, timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier()) : null
    );
  }
  
  static Future<void> startForegroundServiceNotification() async {
    await AndroidForegroundService.startForeground(
        content: NotificationContent(
            id: 2341234,
            body: 'Service is running!',
            title: 'Android Foreground Service',
            channelKey: 'basic_channel',
            bigPicture: 'asset://assets/images/android-bg-worker.jpg',
            notificationLayout: NotificationLayout.BigPicture,
            category: NotificationCategory.Service
        ),
        actionButtons: [
          NotificationActionButton(
              key: 'SHOW_SERVICE_DETAILS',
              label: 'Show details'
          )
        ]
    );
  }
  
  static Future<void> stopForegroundServiceNotification() async {
    await AndroidForegroundService.stopForeground();
  }
  
  /* *********************************************
      CUSTOM SOUND NOTIFICATIONS
  ************************************************ */
  
  static Future<void> showCustomSoundNotification(int id) async {
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
      WAKE UP LOCK SCREEN NOTIFICATIONS
  ************************************************ */
  
  static Future<void> scheduleNotificationWithWakeUp(int id, int seconds) async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: 'basic_channel',
            title: 'Hey! Wake up!!',
            body: 'Its time to wake up!',
            wakeUpScreen: true,
            notificationLayout: NotificationLayout.BigPicture,
            bigPicture: 'asset://assets/images/melted-clock.png',
            color: Colors.blueGrey,
            category: NotificationCategory.Alarm,
        ),
        schedule: NotificationInterval(interval: seconds, preciseAlarm: true));
  }
  
  /* *********************************************
      FULL SCREEEN INTENT NOTIFICATIONS
  ************************************************ */
  
  static Future<void> scheduleFullScrenNotification(int id) async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'scheduled',
          title: 'Hey! Wake up!!',
          body: 'Its time to wake up!',
          fullScreenIntent: true,
          wakeUpScreen: true,
          category: NotificationCategory.Reminder,
          notificationLayout: NotificationLayout.BigPicture,
          bigPicture: 'asset://assets/images/melted-clock.png',
          payload: {'uuid': 'uuid-test'},
          autoDismissible: false,
        ),
        schedule: NotificationInterval(interval: 5, preciseAlarm: true));
  }
  
  /* *********************************************
      SILENCED NOTIFICATIONS
  ************************************************ */
  
  static Future<void> showNotificationWithNoSound(int id) async {
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
  
  static Future<void> showBigPictureNetworkNotification(int id) async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 11,
            channelKey: 'big_picture',
            title: 'Big picture (Network)',
            body: '$lorenIpsumText\n\n$lorenIpsumText\n\n$lorenIpsumText',
            bigPicture:
                'https://media.wired.com/photos/598e35994ab8482c0d6946e0/master/w_2560%2Cc_limit/phonepicutres-TA.jpg',
            notificationLayout: NotificationLayout.BigPicture));
  }
  
  static Future<void> showBigPictureAssetNotification(int id) async {
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
  static Future<void> showBigPictureFileNotification(int id) async {
    String newFilePath = await downloadAndSaveImageOnDisk(
        'https://images.freeimages.com/images/large-previews/be7/puppy-2-1456421.jpg',
        'newTestImage.jpg');
  
    //String newFilePath = await saveImageOnDisk(AssetImage('assets/images/happy-dogs.jpg'),'newTestImage.jpg');
    newFilePath = newFilePath.replaceFirst('/', '');
    String finalFilePath = 'file://' + (newFilePath);
  
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
  
  static Future<void> showBigPictureResourceNotification(int id) async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: "big_picture",
            title: 'Big picture (Resource)',
            body: '$lorenIpsumText\n\n$lorenIpsumText\n\n$lorenIpsumText',
            bigPicture: 'resource://drawable/res_mansion',
            notificationLayout: NotificationLayout.BigPicture,
            payload: {'uuid': 'uuid-test'}));
  }
  
  static Future<void> showLargeIconNotification(int id) async {
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
  
  static Future<void> showBigPictureAndLargeIconNotification(int id) async {
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
  
  static Future<void> showBigPictureNotificationActionButtons(int id) async {
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
              key: 'READ', label: 'Mark as read', autoDismissible: true),
          NotificationActionButton(
              key: 'REMEMBER', label: 'Remember-me later', autoDismissible: false)
        ]);
  }
  
  static Future<void> showBigPictureNotificationActionButtonsAndReply(int id) async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: "big_picture",
            title: 'Big <b>BIG</b> picture title',
            summary: 'Summary <i>text</i>',
            category: NotificationCategory.Promo,
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
              autoDismissible: true,
              buttonType: ActionButtonType.InputField),
          NotificationActionButton(
              key: 'REMEMBER', label: 'Remember-me later', autoDismissible: true)
        ]);
  }
  
  static Future<void> showBigPictureNotificationHideExpandedLargeIcon(int id) async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: "big_picture",
            category: NotificationCategory.Promo,
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
  
  static Future<void> showBigTextNotification(int id) async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: "big_text",
            title: 'Big text title',
            body: '$lorenIpsumText\n\n$lorenIpsumText\n\n$lorenIpsumText',
            notificationLayout: NotificationLayout.BigText,
            payload: {'uuid': 'uuid-test'}));
  }
  
  static Future<void> showBigTextNotificationWithDifferentSummary(int id) async {
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
  
  static Future<void> showBigTextHtmlNotification(int id) async {
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
  
  static Future<void> showBigTextNotificationWithActionAndReply(int id) async {
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
              autoDismissible: true,
              buttonType: ActionButtonType.InputField),
          NotificationActionButton(
              key: 'REMEMBER', label: 'Remember-me later', autoDismissible: true)
        ]);
  }
  
  /* *********************************************
      MEDIA CONTROLLER NOTIFICATIONS
  ************************************************ */
  
  static void updateNotificationMediaPlayer(int id, MediaModel? mediaNow) {
    if (mediaNow == null) {
      cancelNotification(id);
      return;
    }
  
    AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: 'media_player',
            category: NotificationCategory.Transport,
            title: mediaNow.bandName,
            body: mediaNow.trackName,
            summary: MediaPlayerCentral.isPlaying ? 'Now playing' : '',
            notificationLayout: NotificationLayout.MediaPlayer,
            largeIcon: mediaNow.diskImagePath,
            color: Colors.purple.shade700,
            autoDismissible: false,
            showWhen: false),
        actionButtons: [
          NotificationActionButton(
              key: 'MEDIA_PREV',
              icon: 'resource://drawable/res_ic_prev' +
                  (MediaPlayerCentral.hasPreviousMedia ? '' : '_disabled'),
              label: 'Previous',
              autoDismissible: false,
              showInCompactView: false,
              enabled: MediaPlayerCentral.hasPreviousMedia,
              buttonType: ActionButtonType.KeepOnTop),
          MediaPlayerCentral.isPlaying
              ? NotificationActionButton(
                  key: 'MEDIA_PAUSE',
                  icon: 'resource://drawable/res_ic_pause',
                  label: 'Pause',
                  autoDismissible: false,
                  showInCompactView: true,
                  buttonType: ActionButtonType.KeepOnTop)
              : NotificationActionButton(
                  key: 'MEDIA_PLAY',
                  icon: 'resource://drawable/res_ic_play' +
                      (MediaPlayerCentral.hasAnyMedia ? '' : '_disabled'),
                  label: 'Play',
                  autoDismissible: false,
                  showInCompactView: true,
                  enabled: MediaPlayerCentral.hasAnyMedia,
                  buttonType: ActionButtonType.KeepOnTop),
          NotificationActionButton(
              key: 'MEDIA_NEXT',
              icon: 'resource://drawable/res_ic_next' +
                  (MediaPlayerCentral.hasNextMedia ? '' : '_disabled'),
              label: 'Previous',
              showInCompactView: true,
              enabled: MediaPlayerCentral.hasNextMedia,
              buttonType: ActionButtonType.KeepOnTop),
          NotificationActionButton(
              key: 'MEDIA_CLOSE',
              icon: 'resource://drawable/res_ic_close',
              label: 'Close',
              autoDismissible: true,
              showInCompactView: true,
              buttonType: ActionButtonType.KeepOnTop)
        ]);
  }
  
  static int _messageIncrement = 0;
  static Future<void> simulateChatConversation({required String groupKey}) async {
    _messageIncrement++ % 4 < 2 ?
      createMessagingNotification(
        channelKey: 'chats',
        groupKey: groupKey,
        chatName: 'Jhonny\'s Group',
        username: 'Jhonny',
        largeIcon: 'asset://assets/images/80s-disc.jpg',
        message: 'Jhonny\'s message $_messageIncrement',
      ):
      createMessagingNotification(
        channelKey: 'chats',
        groupKey: 'jhonny_group',
        chatName: 'Jhonny\'s Group',
        username: 'Michael',
        largeIcon: 'asset://assets/images/dj-disc.jpg',
        message: 'Michael\'s message $_messageIncrement',
      );
  }
  
  static Future<void> simulateSendResponseChatConversation({required String msg, required String groupKey}) async {
    createMessagingNotification(
      channelKey: 'chats',
      groupKey: groupKey,
      chatName: 'Jhonny\'s Group',
      username: 'you',
      largeIcon: 'asset://assets/images/rock-disc.jpg',
      message: msg,
    );
  }
  
  static Future<void> createMessagingNotification({
    required String channelKey,
    required String groupKey,
    required String chatName,
    required String username,
    required String message,
    String? largeIcon,
    bool checkPermission = true
  }) async {
      await AwesomeNotifications().createNotification(
          content:
          NotificationContent(
              id: createUniqueID(AwesomeNotifications.maxID),
              groupKey: groupKey,
              channelKey: channelKey,
              summary: chatName,
              title: username,
              body: message,
              largeIcon: largeIcon,
              notificationLayout: NotificationLayout.Messaging,
              category: NotificationCategory.Message
          ),
          actionButtons: [
            NotificationActionButton(
              key: 'REPLY',
              label: 'Reply',
              buttonType: ActionButtonType.InputField,
              autoDismissible: false,
            ),
            NotificationActionButton(
              key: 'READ',
              label: 'Mark as Read',
              autoDismissible: true,
              buttonType: ActionButtonType.InputField,
            )
          ]
      );
  }
  
  /* *********************************************
      INBOX NOTIFICATIONS
  ************************************************ */
  
  static Future<void> showInboxNotification(int id) async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: "inbox",
          title: '5 New mails from tester@gmail.com',
          category: NotificationCategory.Email,
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
              autoDismissible: true,
              icon: 'resource://drawable/res_ic_close'),
          NotificationActionButton(
            key: 'READ',
            label: 'Mark as read',
            autoDismissible: true,
            //icon: 'resources://drawable/res_ic_close'
          )
        ]);
  }
  
  /* *********************************************
      INBOX NOTIFICATIONS
  ************************************************ */
  
  static Future<void> showGroupedNotifications(String channelKey) async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 1,
            channelKey: channelKey,
            title: 'Little Jhonny',
            body: 'Hey dude! Look what i found!'));
  
    sleep(Duration(seconds: 2));
  
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 2, channelKey: 'grouped', title: 'Cyclano', body: 'What?'));
  
    sleep(Duration(seconds: 2));
  
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 3,
            channelKey: channelKey,
            title: 'Little Jhonny',
            body: 'This push notifications plugin is amazing!'));
  
    sleep(Duration(seconds: 2));
  
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 4,
            channelKey: channelKey,
            title: 'Little Jhonny',
            body: 'Its perfect!'));
  
    sleep(Duration(seconds: 2));
  
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 5,
            channelKey: channelKey,
            title: 'Little Jhonny',
            body: 'I gonna contribute with the project! For sure!'));
  }
  
  /* *********************************************
      LIST SCHEDULED NOTIFICATIONS
  ************************************************ */
  
  static Future<void> listScheduledNotifications(BuildContext context) async {
    List<NotificationModel> activeSchedules =
        await AwesomeNotifications().listScheduledNotifications();
    for (NotificationModel schedule in activeSchedules) {
      debugPrint(
          'pending notification: ['
              'id: ${schedule.content!.id}, '
              'title: ${schedule.content!.titleWithoutHtml}, '
              'schedule: ${schedule.schedule.toString()}'
          ']');
    }
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text('${activeSchedules.length} schedules founded'),
          actions: [
            TextButton(
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
  
  static Future<String> getCurrentTimeZone(){
    return AwesomeNotifications().getLocalTimeZoneIdentifier();
  }
  
  static Future<String> getUtcTimeZone(){
    return AwesomeNotifications().getUtcTimeZoneIdentifier();
  }
  
  static Future<void> repeatMinuteNotification() async {
    String localTimeZone = await AwesomeNotifications().getLocalTimeZoneIdentifier();
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: -1,
            channelKey: 'scheduled',
            title: 'Notification at every single minute',
            body:
                'This notification was schedule to repeat at every single minute.',
            notificationLayout: NotificationLayout.BigPicture,
            bigPicture: 'asset://assets/images/melted-clock.png',
            category: NotificationCategory.Reminder
        ),
        schedule: NotificationInterval(interval: 60, timeZone: localTimeZone, repeats: true, preciseAlarm: true));
  }
  
  static Future<void> repeatMultiple5Crontab() async {
    String localTimeZone = await AwesomeNotifications().getLocalTimeZoneIdentifier();
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: -1,
            channelKey: 'scheduled',
            title: 'Notification at every 5 seconds for 1 minute',
            body:
            'This notification was schedule to repeat at every 5 seconds.'),
        schedule: NotificationAndroidCrontab(
            initialDateTime: DateTime.now().add(Duration(seconds: 10)).toUtc(),
            expirationDateTime: DateTime.now().add(Duration(seconds: 10, minutes: 1)).toUtc(),
            crontabExpression: '/5 * * * * ? *',
            timeZone: localTimeZone,
            repeats: true));
  }
  
  static Future<void> repeatPreciseThreeTimes() async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: -1,
            channelKey: 'scheduled',
            title: 'Notification scheduled to play precisely 3 times',
            body: 'This notification was schedule to play precisely 3 times.',
            notificationLayout: NotificationLayout.BigPicture,
            bigPicture: 'asset://assets/images/melted-clock.png'),
        schedule: NotificationAndroidCrontab(preciseSchedules: [
              DateTime.now().add(Duration(seconds: 10)).toUtc(),
              DateTime.now().add(Duration(seconds: 25)).toUtc(),
              DateTime.now().add(Duration(seconds: 45)).toUtc()
            ],
            repeats: true));
  }
  
  static Future<void> repeatMinuteNotificationOClock() async {
    String localTimeZone = await AwesomeNotifications().getLocalTimeZoneIdentifier();
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: -1,
            channelKey: 'scheduled',
            title: 'Notification at exactly every single minute',
            body:
                'This notification was schedule to repeat at every single minute at clock.',
            notificationLayout: NotificationLayout.BigPicture,
            bigPicture: 'asset://assets/images/melted-clock.png'),
        schedule: NotificationCalendar(second: 0, millisecond: 0, timeZone: localTimeZone, repeats: true));
  }
  
  static Future<void> showNotificationAtSchedulePreciseDate(
      DateTime scheduleTime) async {
    String timeZoneIdentifier = AwesomeNotifications.localTimeZoneIdentifier;
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: -1,
          channelKey: 'scheduled',
          title: 'Just in time!',
          body: 'This notification was schedule to shows at ' +
              (Utils.DateUtils.parseDateToString(scheduleTime.toLocal()) ?? '?') +
              ' $timeZoneIdentifier (' +
              (Utils.DateUtils.parseDateToString(scheduleTime.toUtc()) ?? '?') +
              ' utc)',
          notificationLayout: NotificationLayout.BigPicture,
          bigPicture: 'asset://assets/images/delivery.jpeg',
          payload: {'uuid': 'uuid-test'},
          autoDismissible: false,
        ),
        schedule: NotificationCalendar.fromDate(date: scheduleTime, preciseAlarm: true));
  }
  
  static Future<void> showNotificationWithNoBadge(int id) async {
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
  
  static Future<void> showProgressNotification(int id) async {
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
                  category: NotificationCategory.Progress,
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
                      'Downloading fake file in progress ($simulatedStep of $maxStep)',
                  body: 'filename.txt',
                  category: NotificationCategory.Progress,
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
  
  static Future<void> showIndeterminateProgressNotification(int id) async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: 'progress_bar',
            title: 'Downloading fake file...',
            body: 'filename.txt',
            category: NotificationCategory.Progress,
            payload: {
              'file': 'filename.txt',
              'path': '-rmdir c://ruwindows/system32/huehuehue'
            },
            notificationLayout: NotificationLayout.ProgressBar,
            progress: null,
            locked: true));
  }
  
  static Future<void> showNotificationWithUpdatedChannelDescription(int id) async {
    AwesomeNotifications().setChannel(NotificationChannel(
        channelGroupKey: 'channel_tests',
        channelKey: 'updated_channel',
        channelName: 'Channel to update (updated)',
        channelDescription: 'Notifications with updated channel'));
  
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: 'updated_channel',
            title: 'updated notification channel',
            body: 'check settings to see updated channel description',
            category: NotificationCategory.Status,
            payload: {'uuid': '0123456789'}));
  }
  
  static Future<void> removeChannel() async {
    AwesomeNotifications().removeChannel('updated_channel');
  }

  static Future<void> dismissNotification(int id) async {
    await AwesomeNotifications().dismiss(id);
  }

  static Future<void> cancelSchedule(int id) async {
    await AwesomeNotifications().cancelSchedule(id);
  }
  
  static Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }
  
  static Future<void> dismissNotificationsByChannelKey(String channelKey) async {
    await AwesomeNotifications().dismissNotificationsByChannelKey(channelKey);
  }
  
  static Future<void> dismissNotificationsByGroupKey(String groupKey) async {
    await AwesomeNotifications().dismissNotificationsByGroupKey(groupKey);
  }
  
  static Future<void> cancelSchedulesByChannelKey(String channelKey) async {
    await AwesomeNotifications().cancelSchedulesByChannelKey(channelKey);
  }
  
  static Future<void> cancelSchedulesByGroupKey(String groupKey) async {
    await AwesomeNotifications().cancelSchedulesByGroupKey(groupKey);
  }
  
  static Future<void> cancelNotificationsByChannelKey(String channelKey) async {
    await AwesomeNotifications().cancelNotificationsByChannelKey(channelKey);
  }
  
  static Future<void> cancelNotificationsByGroupKey(String groupKey) async {
    await AwesomeNotifications().cancelNotificationsByGroupKey(groupKey);
  }

  static Future<void> dismissAllNotifications() async {
    await AwesomeNotifications().dismissAllNotifications();
  }

  static Future<void> cancelAllSchedules() async {
    await AwesomeNotifications().cancelAllSchedules();
  }
  
  static Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }
  
  String toTwoDigitString(int value) {
    return value.toString().padLeft(2, '0');
  }

}