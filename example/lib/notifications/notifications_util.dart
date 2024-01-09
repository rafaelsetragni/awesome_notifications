// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:awesome_notifications/android_foreground_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// TO AVOID CONFLICT WITH MATERIAL DATE UTILS CLASS
import 'package:awesome_notifications/awesome_notifications.dart'
    hide AwesomeDateUtils;
import 'package:awesome_notifications/awesome_notifications.dart' as utils
    show AwesomeDateUtils;

import 'package:awesome_notifications_example/models/media_model.dart';
import 'package:awesome_notifications_example/utils/common_functions.dart'
    if (dart.library.html) 'package:awesome_notifications_example/utils/common_web_functions.dart';
import 'package:awesome_notifications_example/utils/media_player_central.dart';
import 'package:flutter/services.dart';
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

int createUniqueID(int maxValue) {
  Random random = Random();
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
    await AwesomeNotifications()
        .showNotificationConfigPage(channelKey: 'basic_channel');
  }

  static Future<void> redirectToAlarmPage() async {
    await AwesomeNotifications().showAlarmPage();
  }

  static Future<void> redirectToScheduledChannelsPage() async {
    await AwesomeNotifications()
        .showNotificationConfigPage(channelKey: 'scheduled');
  }

  static Future<void> redirectToOverrideDndsPage() async {
    await AwesomeNotifications().showGlobalDndOverridePage();
  }

  static Future<bool> requestBasicPermissionToSendNotifications(
    BuildContext context,
  ) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xfffbfbfb),
          title: const Text(
            'Get Notified!',
            maxLines: 2,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/animated-bell.gif',
                height: MediaQuery.of(context).size.height * 0.3,
                fit: BoxFit.fitWidth,
              ),
              const Text(
                'Allow Awesome Notifications to send you beautiful notifications!',
                maxLines: 4,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Later',
                style: TextStyle(color: Colors.grey, fontSize: 18),
              ),
            ),
            TextButton(
              onPressed: () async {
                isAllowed = await AwesomeNotifications()
                    .requestPermissionToSendNotifications();
                Navigator.pop(context);
              },
              child: const Text(
                'Allow',
                style: TextStyle(
                  color: Colors.deepPurple,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return isAllowed;
  }

  static Future<void> requestFullScheduleChannelPermissions(
    BuildContext context,
    List<NotificationPermission> requestedPermissions,
  ) async {
    String channelKey = 'scheduled';

    await requestUserPermissions(
      context,
      channelKey: channelKey,
      permissionList: requestedPermissions,
    );
  }

  static Future<List<NotificationPermission>> requestUserPermissions(
    BuildContext context, {
    // if you only intends to request the permissions until app level, set the channelKey value to null
    required String? channelKey,
    required List<NotificationPermission> permissionList,
  }) async {
    // Check if the basic permission was conceived by the user
    if (!await requestBasicPermissionToSendNotifications(context)) return [];

    // Check which of the permissions you need are allowed at this time
    List<NotificationPermission> permissionsAllowed =
        await AwesomeNotifications().checkPermissionList(
      channelKey: channelKey,
      permissions: permissionList,
    );

    // If all permissions are allowed, there is nothing to do
    if (permissionsAllowed.length == permissionList.length) {
      return permissionsAllowed;
    }

    // Refresh the permission list with only the disallowed permissions
    List<NotificationPermission> permissionsNeeded =
        permissionList.toSet().difference(permissionsAllowed.toSet()).toList();

    // Check if some of the permissions needed request user's intervention to be enabled
    List<NotificationPermission> lockedPermissions =
        await AwesomeNotifications().shouldShowRationaleToRequest(
      channelKey: channelKey,
      permissions: permissionsNeeded,
    );

    // If there is no permitions depending of user's intervention, so request it directly
    if (lockedPermissions.isEmpty) {
      // Request the permission through native resources.
      await AwesomeNotifications().requestPermissionToSendNotifications(
        channelKey: channelKey,
        permissions: permissionsNeeded,
      );

      // After the user come back, check if the permissions has successfully enabled
      permissionsAllowed = await AwesomeNotifications().checkPermissionList(
        channelKey: channelKey,
        permissions: permissionsNeeded,
      );
    } else {
      // If you need to show a rationale to educate the user to conceed the permission, show it
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xfffbfbfb),
          title: const Text(
            'Awesome Notificaitons needs your permission',
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
                'To proceed, you need to enable the permissions above${channelKey?.isEmpty ?? true ? '' : ' on channel $channelKey'}:',
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Text(
                lockedPermissions
                    .join(', ')
                    .replaceAll('NotificationPermission.', ''),
                maxLines: 2,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Deny',
                style: TextStyle(color: Colors.red, fontSize: 18),
              ),
            ),
            TextButton(
              onPressed: () async {
                // Request the permission through native resources. Only one page redirection is done at this point.
                await AwesomeNotifications()
                    .requestPermissionToSendNotifications(
                  channelKey: channelKey,
                  permissions: lockedPermissions,
                );

                // After the user come back, check if the permissions has successfully enabled
                permissionsAllowed =
                    await AwesomeNotifications().checkPermissionList(
                  channelKey: channelKey,
                  permissions: lockedPermissions,
                );

                Navigator.pop(context);
              },
              child: const Text(
                'Allow',
                style: TextStyle(
                  color: Colors.deepPurple,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Return the updated list of allowed permissions
    return permissionsAllowed;
  }

  static Future<bool> requestCriticalAlertsPermission(
    BuildContext context,
  ) async {
    List<NotificationPermission> requestedPermissions = [
      NotificationPermission.CriticalAlert,
    ];

    List<NotificationPermission> permissionsAllowed =
        await requestUserPermissions(
      context,
      channelKey: null,
      permissionList: requestedPermissions,
    );

    return permissionsAllowed.isNotEmpty;
  }

  static Future<bool> requestFullIntentPermission(BuildContext context) async {
    List<NotificationPermission> requestedPermissions = [
      NotificationPermission.CriticalAlert,
    ];

    List<NotificationPermission> permissionsAllowed =
        await requestUserPermissions(
      context,
      channelKey: null,
      permissionList: requestedPermissions,
    );

    return permissionsAllowed.isNotEmpty;
  }

  static Future<bool> requestPreciseAlarmPermission(
    BuildContext context,
  ) async {
    List<NotificationPermission> requestedPermissions = [
      NotificationPermission.PreciseAlarms,
    ];

    List<NotificationPermission> permissionsAllowed =
        await requestUserPermissions(
      context,
      channelKey: null,
      permissionList: requestedPermissions,
    );

    return permissionsAllowed.isNotEmpty;
  }

  static Future<bool> requestOverrideDndPermission(BuildContext context) async {
    List<NotificationPermission> requestedPermissions = [
      NotificationPermission.OverrideDnD,
    ];

    List<NotificationPermission> permissionsAllowed =
        await requestUserPermissions(
      context,
      channelKey: null,
      permissionList: requestedPermissions,
    );

    return permissionsAllowed.isNotEmpty;
  }

  /* *********************************************
      BASIC NOTIFICATIONS
  ************************************************ */

  static Future<void> showBasicNotification(int id) async {
    try {
      bool success = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'basic_channel',
          title: 'Simple Notification',
          body: 'Simple body',
        ),
      );

      debugPrint(success ? 'Notification created successfully' : '');
    } on PlatformException catch (exception) {
      debugPrint('$exception');
    }
  }

  static Future<void> showNotificationFromJson(
    Map<String, Object> jsonData,
  ) async {
    await AwesomeNotifications().createNotificationFromJsonData(jsonData);
  }

  static Future<void> showEmojiNotification(int id) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'basic_channel',
        category: NotificationCategory.Social,
        title: 'Emojis are awesome too! '
            '${Emojis.smile_face_with_tongue}'
            '${Emojis.smile_smiling_face}'
            '${Emojis.smile_smiling_face_with_heart_eyes}',
        body:
            'Simple body with a bunch of Emojis! ${Emojis.transport_police_car} ${Emojis.animals_dog} ${Emojis.flag_UnitedStates} ${Emojis.person_baby}',
        largeIcon: 'https://tecnoblog.net/wp-content/uploads/2019/09/emoji.jpg',
        bigPicture:
            'https://tecnoblog.net/wp-content/uploads/2019/09/emoji.jpg',
        hideLargeIconOnExpand: true,
        notificationLayout: NotificationLayout.BigPicture,
      ),
    );
  }

  static Future<void> showNotificationWithPayloadContent(int id) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'basic_channel',
        title: 'Simple notification',
        summary: 'Simple subtitle',
        body: 'Only a simple notification',
        payload: {'uuid': 'uuid-test'},
      ),
    );
  }

  static Future<void> showNotificationWithoutTitle(int id) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'basic_channel',
        body: 'Only a simple notification',
        payload: {'uuid': 'uuid-test'},
      ),
    );
  }

  static Future<void> showNotificationWithoutBody(int id) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'basic_channel',
        title: 'plain title',
        payload: {'uuid': 'uuid-test'},
      ),
    );
  }

  static Future<void> sendBackgroundNotification(int id) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'basic_channel',
        payload: {'secret-command': 'block_user'},
      ),
    );
  }

  /* *********************************************
      BADGE NOTIFICATIONS
  ************************************************ */

  static Future<void> showBadgeNotification(int id, {int? badgeAmount}) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        badge: badgeAmount,
        channelKey: 'badge_channel',
        title: 'Badge test notification',
        body: 'This notification does activate badge indicator',
        payload: {'content 1': 'value'},
      ),
      schedule: NotificationInterval(
        interval: 5,
        timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
      ),
    );
  }

  static Future<void> showWithoutBadgeNotification(
    int id, {
    int? badgeAmount,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        badge: badgeAmount,
        channelKey: 'basic_channel',
        title: 'Badge test notification',
        body: 'This notification does not activate badge indicator',
      ),
      schedule: NotificationInterval(
        interval: 5,
        timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
      ),
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
      TIMEOUT NOTIFICATIONS
  ************************************************ */

  static Future<void> showNotificationWithTimeout(int id) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'basic_channel',
        title: 'This notification will expire',
        body: 'This notification will expire in 10 seconds',
        summary: 'Timeout After',
        notificationLayout: NotificationLayout.BigPicture,
        bigPicture: 'asset://assets/images/melted-clock.png',
        timeoutAfter: const Duration(seconds: 10),
        chronometer: Duration.zero, // starts from 0 seconds
        payload: {'uuid': 'user-profile-uuid'},
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'AGREED1',
          label: 'I agree',
          autoDismissible: true,
        ),
        NotificationActionButton(
          key: 'AGREED2',
          label: 'I agree too',
          autoDismissible: true,
        ),
      ],
    );
  }

  /* *********************************************
      TRANSLATED NOTIFICATIONS
  ************************************************ */

  static Future<void> showNotificationWithLocalizationsBlock(int id) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'basic_channel',
        title: 'This title is written in english',
        body: 'Now it is really easy to translate a notification content, '
            'including images and buttons!',
        summary: 'Awesome Notifications Translations',
        notificationLayout: NotificationLayout.BigPicture,
        bigPicture: 'asset://assets/images/awn-rocks-en.jpg',
        largeIcon: 'asset://assets/images/american.jpg',
        payload: {'uuid': 'user-profile-uuid'},
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'AGREED1',
          label: 'I agree',
          autoDismissible: true,
        ),
        NotificationActionButton(
          key: 'AGREED2',
          label: 'I agree too',
          autoDismissible: true,
        ),
      ],
      localizations: {
        'pt-br': NotificationLocalization(
          title: 'Este título está escrito em português do Brasil!',
          body: 'Agora é muito fácil traduzir o conteúdo das notificações, '
              'incluindo imagens e botões!',
          summary: 'Traduções Awesome Notifications',
          bigPicture: 'asset://assets/images/awn-rocks-pt-br.jpg',
          largeIcon: 'asset://assets/images/brazilian.jpg',
          buttonLabels: {
            'AGREED1': 'Eu concordo!',
            'AGREED2': 'Eu concordo também!',
          },
        ),
        'zh': NotificationLocalization(
          title: '这个标题是用中文写的',
          body: '现在，轻松翻译通知内容，包括图像和按钮！',
          summary: '',
          bigPicture: 'asset://assets/images/awn-rocks-zh.jpg',
          largeIcon: 'asset://assets/images/chinese.jpg',
          buttonLabels: {'AGREED1': '我同意', 'AGREED2': '我也同意'},
        ),
        'ko': NotificationLocalization(
          title: '이 타이틀은 한국어로 작성되었습니다',
          body: '이제 이미지 및 버튼을 포함한 알림 콘텐츠를 쉽게 번역할 수 있습니다!',
          summary: '',
          bigPicture: 'asset://assets/images/awn-rocks-ko.jpg',
          largeIcon: 'asset://assets/images/korean.jpg',
          buttonLabels: {'AGREED1': '동의합니다', 'AGREED2': '저도 동의합니다'},
        ),
        'de': NotificationLocalization(
          title: 'Dieser Titel ist in Deutsch geschrieben',
          body:
              'Jetzt ist es wirklich einfach, den Inhalt einer Benachrichtigung zu übersetzen, '
              'einschließlich Bilder und Schaltflächen!',
          summary: '',
          bigPicture: 'asset://assets/images/awn-rocks-de.jpg',
          largeIcon: 'asset://assets/images/german.jpg',
          buttonLabels: {
            'AGREED1': 'Ich stimme zu',
            'AGREED2': 'Ich stimme auch zu',
          },
        ),
        'pt': NotificationLocalization(
          title: 'Este título está escrito em português de Portugal!',
          body: 'Agora é muito fácil traduzir o conteúdo das notificações, '
              'incluindo imagens e botões!',
          summary: 'Traduções Awesome Notifications',
          bigPicture: 'asset://assets/images/awn-rocks-pt.jpg',
          largeIcon: 'asset://assets/images/portuguese.jpg',
          buttonLabels: {
            'AGREED1': 'Eu concordo!',
            'AGREED2': 'Eu concordo também!',
          },
        ),
        'es': NotificationLocalization(
          title: 'Este título está escrito en español!',
          body:
              'Ahora es muy fácil traducir el contenido de las notificaciones, '
              'incluyendo imágenes y botones.',
          summary: 'Traducciones de Awesome Notifications',
          bigPicture: 'asset://assets/images/awn-rocks-es.jpg',
          largeIcon: 'asset://assets/images/spanish.jpg',
          buttonLabels: {
            'AGREED1': 'Estoy de acuerdo',
            'AGREED2': 'También estoy de acuerdo',
          },
        ),
      },
    );
  }

  static Future<void> showNotificationWithLocalizationsKeyBlock(int id) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'basic_channel',
        title: 'Original title in English',
        body: 'Original body in English',
        titleLocKey: 'not_loc_key',
        bodyLocKey: 'not_loc_key',
        titleLocArgs: ['title'],
        bodyLocArgs: ['body'],
        summary: 'Awesome Notifications Translations',
        notificationLayout: NotificationLayout.BigPicture,
        bigPicture: 'asset://assets/images/awn-rocks-en.jpg',
        largeIcon: 'asset://assets/images/american.jpg',
        payload: {'uuid': 'user-profile-uuid'},
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'AGREED1',
          label: 'I agree',
          autoDismissible: true,
        ),
        NotificationActionButton(
          key: 'AGREED2',
          label: 'I agree too',
          autoDismissible: true,
        ),
      ],
      localizations: {
        'pt-br': NotificationLocalization(
          bigPicture: 'asset://assets/images/awn-rocks-pt-br.jpg',
          largeIcon: 'asset://assets/images/brazilian.jpg',
          buttonLabels: {
            'AGREED1': 'Eu concordo!',
            'AGREED2': 'Eu concordo também!',
          },
        ),
        'zh': NotificationLocalization(
          bigPicture: 'asset://assets/images/awn-rocks-zh.jpg',
          largeIcon: 'asset://assets/images/chinese.jpg',
          buttonLabels: {'AGREED1': '我同意', 'AGREED2': '我也同意'},
        ),
        'ko': NotificationLocalization(
          bigPicture: 'asset://assets/images/awn-rocks-ko.jpg',
          largeIcon: 'asset://assets/images/korean.jpg',
          buttonLabels: {'AGREED1': '동의합니다', 'AGREED2': '저도 동의합니다'},
        ),
        'de': NotificationLocalization(
          bigPicture: 'asset://assets/images/awn-rocks-de.jpg',
          largeIcon: 'asset://assets/images/german.jpg',
          buttonLabels: {
            'AGREED1': 'Ich stimme zu',
            'AGREED2': 'Ich stimme auch zu',
          },
        ),
        'pt': NotificationLocalization(
          bigPicture: 'asset://assets/images/awn-rocks-pt.jpg',
          largeIcon: 'asset://assets/images/portuguese.jpg',
          buttonLabels: {
            'AGREED1': 'Eu concordo!',
            'AGREED2': 'Eu concordo também!',
          },
        ),
        'es': NotificationLocalization(
          bigPicture: 'asset://assets/images/awn-rocks-es.jpg',
          largeIcon: 'asset://assets/images/spanish.jpg',
          buttonLabels: {
            'AGREED1': 'Estoy de acuerdo',
            'AGREED2': 'También estoy de acuerdo',
          },
        ),
      },
    );
  }

  static Future<void> setLocalizationForNotification({
    required languageCode,
  }) async {
    await AwesomeNotifications().setLocalization(languageCode: languageCode);
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
        payload: {'uuid': 'user-profile-uuid'},
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'READ',
          label: 'Mark as read',
          autoDismissible: true,
        ),
        NotificationActionButton(
          key: 'PROFILE',
          label: 'Profile',
          autoDismissible: true,
          enabled: false,
        ),
      ],
    );
  }

  static Future<void> showNotificationWithSilentActionButtons(int id) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'basic_channel',
        title: 'Action Type tests',
        body: 'Click on the buttons above to test each action type:'
            '<br>* The notification body has the default action type.'
            '<br>* The silent action runs on background but uses UI Thread.'
            '<br>* The silent bg action runs on Backgrond Thread and does not allows UI.'
            '<br>* The disabled action runs on background and never fires any event method.',
        notificationLayout: NotificationLayout.BigText,
        autoDismissible: false,
        payload: {'uuid': 'user-profile-uuid'},
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'SILENT',
          label: 'Silent',
          actionType: ActionType.SilentAction,
          autoDismissible: false,
        ),
        NotificationActionButton(
          key: 'SILENT_BG',
          label: 'Silent BG',
          actionType: ActionType.SilentBackgroundAction,
          autoDismissible: false,
        ),
        NotificationActionButton(
          key: 'DISMISS',
          label: 'Dismiss',
          actionType: ActionType.DismissAction,
          autoDismissible: true,
          isDangerousOption: true,
        ),
      ],
    );
  }

  static Future<void> showNotificationWithIconsAndActionButtons(int id) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'basic_channel',
        title: 'Anonymous says:',
        body: 'Hi there!',
        payload: {'uuid': 'user-profile-uuid'},
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'READ',
          label: 'Mark as read',
          autoDismissible: true,
        ),
        NotificationActionButton(
          key: 'PROFILE',
          label: 'Profile',
          autoDismissible: true,
          color: Colors.green,
        ),
        NotificationActionButton(
          key: 'DISMISS',
          label: 'Dismiss',
          isDangerousOption: true,
          actionType: ActionType.DismissAction,
        ),
      ],
    );
  }

  static Future<void> showNotificationWithActionButtonsAndReply(int id) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'basic_channel',
        title: 'Anonymous says:',
        body: 'Hi there!',
        payload: {'uuid': 'user-profile-uuid'},
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'REPLY',
          label: 'Reply',
          autoDismissible: true,
          requireInputText: true,
        ),
        NotificationActionButton(
          key: 'READ',
          label: 'Mark as read',
          autoDismissible: true,
        ),
        NotificationActionButton(
          key: 'ARCHIVE',
          label: 'Archive',
          autoDismissible: true,
        ),
      ],
    );
  }

  /* *********************************************
      NOTIFICATION'S SPECIAL CATEGORIES
  ************************************************ */

  static Future<void> showCallNotification(int id, int timeToWait) async {
    String platformVersion = await getPlatformVersion();
    // Schedule only for test purposes. For real applications, you MUST
    // create call or alarm notifications using AndroidForegroundService.
    await AwesomeNotifications().createNotification(
      // await AndroidForegroundService.startAndroidForegroundService(
      //     foregroundStartMode: ForegroundStartMode.stick,
      //     foregroundServiceType: ForegroundServiceType.phoneCall,
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
        backgroundColor: (platformVersion == 'Android-31')
            ? const Color(0xFF00796a)
            : Colors.white,
        payload: {'username': 'Little Mary'},
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'ACCEPT',
          label: 'Accept Call',
          actionType: ActionType.Default,
          color: Colors.green,
          autoDismissible: true,
        ),
        NotificationActionButton(
          key: 'REJECT',
          label: 'Reject',
          actionType: ActionType.SilentAction,
          isDangerousOption: true,
          autoDismissible: true,
        ),
      ],
      schedule: NotificationInterval(interval: timeToWait),
    );
  }

  static Future<void> showAlarmNotification({
    required int id,
    int secondsToWait = 30,
    int snoozeSeconds = 30,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'alarm_channel',
        title: 'Alarm is playing',
        body: 'Hey! Wake Up!',
        category: NotificationCategory.Alarm,
        autoDismissible: true,
        payload: {'snooze': '$snoozeSeconds'},
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'SNOOZE',
          label: 'Snooze for $snoozeSeconds seconds',
          color: Colors.blue,
          actionType: ActionType.SilentBackgroundAction,
          autoDismissible: true,
        ),
      ],
      schedule: (secondsToWait < 5)
          ? null
          : NotificationCalendar.fromDate(
              date: DateTime.now().add(Duration(seconds: secondsToWait)),
            ),
    );
  }

  /* *********************************************
      LOCKED (ONGOING) NOTIFICATIONS
  ************************************************ */

  static Future<void> showLockedNotification(int id) async {
    AwesomeNotifications().setChannel(
      NotificationChannel(
        channelKey: 'locked_notification',
        channelName: 'Locked notification',
        channelDescription: 'Channel created on the fly with lock option',
        locked: true,
      ),
    );

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'locked_notification',
        title: 'Locked notification',
        body: 'This notification is locked and cannot be dismissed',
        payload: {'uuid': 'uuid-test'},
      ),
    );
  }

  static Future<void> showUnlockedNotification(int id) async {
    AwesomeNotifications().setChannel(
      NotificationChannel(
        channelKey: 'locked_notification',
        channelName: 'Unlocked notification',
        channelDescription: 'Channel created on the fly with lock option',
        locked: true,
      ),
    );

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'locked_notification',
        title: 'Unlocked notification',
        body: 'This notification is not locked and can be dismissed',
        payload: {'uuid': 'uuid-test'},
        locked: false,
      ),
    );
  }

  /* *********************************************
      NOTIFICATION CHANNELS MANIPULATION
  ************************************************ */

  static Future<void> showNotificationImportance(
    int id,
    NotificationImportance importance,
  ) async {
    String importanceKey = importance.toString().toLowerCase().split('.').last;
    String channelKey = 'importance_${importanceKey}_channel';
    String title = 'Importance levels ($importanceKey)';
    String body = 'Test of importance levels to $importanceKey';

    await AwesomeNotifications().setChannel(
      NotificationChannel(
        channelKey: channelKey,
        channelName: title,
        channelDescription: body,
        importance: importance,
        defaultColor: Colors.red,
        ledColor: Colors.red,
        vibrationPattern: highVibrationPattern,
      ),
    );

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: channelKey,
        title: title,
        body: body,
        payload: {'uuid': 'uuid-test'},
      ),
    );
  }

  /* *********************************************
      NOTIFICATION CHANNELS MANIPULATION
  ************************************************ */

  static Future<void> createTestChannel(String channelName) async {
    await AwesomeNotifications().setChannel(
      NotificationChannel(
        channelGroupKey: 'channel_tests',
        channelKey: channelName.toLowerCase().replaceAll(' ', '_'),
        channelName: channelName,
        channelDescription:
            "Channel created to test the channels manipulation.",
      ),
    );
  }

  static Future<void> updateTestChannel(String channelName) async {
    await AwesomeNotifications().setChannel(
      NotificationChannel(
        channelGroupKey: 'channel_tests',
        channelKey: channelName.toLowerCase().replaceAll(' ', '_'),
        channelName: "$channelName (updated)",
        channelDescription: "This channel was successfuly updated.",
      ),
    );
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
        payload: {'uuid': 'uuid-test'},
      ),
      schedule: NotificationInterval(
        interval: 5,
        timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
      ),
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
        payload: {'uuid': 'uuid-test'},
      ),
    );
  }

  static Future<void> showMediumVibrationNotification(int id) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'medium_intensity',
        title: 'Medium vibration title',
        body: 'This is a notification with medium vibration pattern',
        payload: {'uuid': 'uuid-test'},
      ),
    );
  }

  static Future<void> showHighVibrationNotification(int id) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'high_intensity',
        title: 'High vibration title',
        body: 'This is a notification with high vibration pattern',
        payload: {'uuid': 'uuid-test'},
      ),
    );
  }

  static Future<void> showCustomVibrationNotification(int id) async {
    AwesomeNotifications().setChannel(
      NotificationChannel(
        channelKey: "custom_vibration",
        channelName: "Custom vibration",
        channelDescription: "Channel created on the fly with custom vibration",
        vibrationPattern:
            Int64List.fromList([0, 1000, 200, 200, 1000, 1500, 200, 200]),
        ledOnMs: 1000,
        ledOffMs: 500,
      ),
    );

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'custom_vibration',
        title: 'That\'s all for today, folks!',
        bigPicture:
            'https://i0.wp.com/www.jornadageek.com.br/wp-content/uploads/2018/06/Looney-tunes.png?resize=696%2C398&ssl=1',
        notificationLayout: NotificationLayout.BigPicture,
        payload: {'uuid': 'uuid-test'},
      ),
    );
  }

  /* *********************************************
      COLORFUL AND LED NOTIFICATIONS
  ************************************************ */

  static Future<void> redNotification(int id, bool delayLEDTests) async {
    AwesomeNotifications().setChannel(
      NotificationChannel(
        channelKey: "colorful_notification",
        channelName: "Colorful notifications",
        channelDescription: "A red colorful notification",
        vibrationPattern: lowVibrationPattern,
        defaultColor: Colors.red,
        ledColor: Colors.red,
        ledOnMs: 1000,
        ledOffMs: 500,
      ),
    );

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: "colorful_notification",
        title: "<font color='${Colors.red.value}'>Red Notification</font>",
        body:
            "<font color='${Colors.red.value}'>A colorful notification</font>",
        payload: {
          'uuid': 'uuid-red',
        },
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'REPLY',
          label: 'Reply',
          autoDismissible: true,
          requireInputText: true,
        ),
        NotificationActionButton(
          key: 'ARCHIVE',
          label: 'Archive',
          autoDismissible: true,
        ),
      ],
      schedule: delayLEDTests
          ? NotificationInterval(
              interval: 5,
              timeZone:
                  await AwesomeNotifications().getLocalTimeZoneIdentifier(),
            )
          : null,
    );
  }

  static Future<void> blueNotification(int id, bool delayLEDTests) async {
    AwesomeNotifications().setChannel(
      NotificationChannel(
        channelKey: "colorful_notification",
        channelName: "Colorful notifications",
        channelDescription: "A red colorful notification",
        vibrationPattern: lowVibrationPattern,
        defaultColor: Colors.blueAccent,
        ledColor: Colors.blueAccent,
        ledOnMs: 1000,
        ledOffMs: 500,
      ),
    );

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: "colorful_notification",
        title:
            '<font color="${Colors.blueAccent.value}">Blue Notification</font>',
        body:
            "<font color='${Colors.blueAccent.value}'>A colorful notification</font>",
        payload: {
          'uuid': 'uuid-blue',
        },
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'REPLY',
          label: 'Reply',
          autoDismissible: true,
          requireInputText: true,
        ),
        NotificationActionButton(
          key: 'ARCHIVE',
          label: 'Archive',
          autoDismissible: true,
        ),
      ],
      schedule: delayLEDTests
          ? NotificationInterval(
              interval: 5,
              timeZone:
                  await AwesomeNotifications().getLocalTimeZoneIdentifier(),
            )
          : null,
    );
  }

  static Future<void> yellowNotification(int id, bool delayLEDTests) async {
    AwesomeNotifications().setChannel(
      NotificationChannel(
        channelKey: "colorful_notification",
        channelName: "Colorful notifications",
        channelDescription: "A red colorful notification",
        vibrationPattern: lowVibrationPattern,
        defaultColor: CupertinoColors.activeOrange,
        ledColor: CupertinoColors.activeOrange,
        ledOnMs: 1000,
        ledOffMs: 500,
      ),
    );

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: "colorful_notification",
        title: 'Yellow Notification',
        body: 'A colorful notification',
        backgroundColor: CupertinoColors.activeOrange,
        payload: {'uuid': 'uuid-yellow'},
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'REPLY',
          label: 'Reply',
          autoDismissible: true,
          requireInputText: true,
        ),
        NotificationActionButton(
          key: 'ARCHIVE',
          label: 'Archive',
          autoDismissible: true,
        ),
      ],
      schedule: delayLEDTests
          ? NotificationInterval(
              interval: 5,
              timeZone:
                  await AwesomeNotifications().getLocalTimeZoneIdentifier(),
            )
          : null,
    );
  }

  static Future<void> purpleNotification(int id, bool delayLEDTests) async {
    AwesomeNotifications().setChannel(
      NotificationChannel(
        channelKey: "colorful_notification",
        channelName: "Colorful notifications",
        channelDescription: "A purple colorful notification",
        vibrationPattern: lowVibrationPattern,
        defaultColor: Colors.deepPurple,
        ledColor: Colors.deepPurple,
        ledOnMs: 1000,
        ledOffMs: 500,
      ),
    );

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: "colorful_notification",
        title:
            '<font color="${Colors.deepPurple.value}">Purple Notification</font>',
        body:
            "<font color='${Colors.deepPurple.value}'>A colorful notification</font>",
        payload: {
          'uuid': 'uuid-purple',
        },
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'REPLY',
          label: 'Reply',
          autoDismissible: true,
          requireInputText: true,
        ),
        NotificationActionButton(
          key: 'ARCHIVE',
          label: 'Archive',
          autoDismissible: true,
        ),
      ],
      schedule: delayLEDTests
          ? NotificationInterval(
              interval: 5,
              timeZone:
                  await AwesomeNotifications().getLocalTimeZoneIdentifier(),
            )
          : null,
    );
  }

  static Future<void> greenNotification(int id, bool delayLEDTests) async {
    AwesomeNotifications().setChannel(
      NotificationChannel(
        channelKey: "colorful_notification",
        channelName: "Colorful notifications",
        channelDescription: "A green colorful notification",
        vibrationPattern: lowVibrationPattern,
        defaultColor: Colors.lightGreen,
        ledColor: Colors.lightGreen,
        ledOnMs: 1000,
        ledOffMs: 500,
      ),
    );

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: "colorful_notification",
        title:
            '<font color="${Colors.lightGreen.value}">Green Notification</font>',
        body:
            "<font color='${Colors.lightGreen.value}'>A colorful notification</font>",
        payload: {
          'uuid': 'uuid-green',
        },
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'REPLY',
          label: 'Reply',
          autoDismissible: true,
          requireInputText: true,
        ),
        NotificationActionButton(
          key: 'ARCHIVE',
          label: 'Archive',
          autoDismissible: true,
        ),
      ],
      schedule: delayLEDTests
          ? NotificationInterval(
              interval: 5,
              timeZone:
                  await AwesomeNotifications().getLocalTimeZoneIdentifier(),
            )
          : null,
    );
  }

  static Future<void> startForegroundServiceNotification(int id) async {
    await AndroidForegroundService.startForeground(
      content: NotificationContent(
        id: id,
        body: 'Service is running!',
        title: 'Android Foreground Service',
        channelKey: 'basic_channel',
        bigPicture: 'asset://assets/images/android-bg-worker.jpg',
        notificationLayout: NotificationLayout.BigPicture,
        category: NotificationCategory.Service,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'SHOW_SERVICE_DETAILS',
          label: 'Show details',
        ),
      ],
    );
  }

  static Future<void> stopForegroundServiceNotification(int id) async {
    await AndroidForegroundService.stopForeground(id);
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
          'secret': 'the green ranger and the white ranger are the same person',
        },
      ),
    );
  }

  /* *********************************************
      WAKE UP LOCK SCREEN NOTIFICATIONS
  ************************************************ */

  static Future<void> scheduleNotificationWithWakeUp(
    int id,
    int seconds,
  ) async {
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
        category: NotificationCategory.Reminder,
      ),
      schedule: NotificationInterval(interval: seconds, preciseAlarm: true),
    );
  }

  /* *********************************************
      FULL SCREEN INTENT NOTIFICATIONS
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
      schedule: NotificationInterval(interval: 5, preciseAlarm: true),
    );
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
        payload: {'advice': 'shhhhhhh'},
      ),
    );
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
        notificationLayout: NotificationLayout.BigPicture,
      ),
    );
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
        payload: {'uuid': 'uuid-test'},
      ),
    );
  }

  /// Just to simulates a file already saved inside device storage
  static Future<void> showBigPictureFileNotification(int id) async {
    String newFilePath = await downloadAndSaveImageOnDisk(
      'https://images.freeimages.com/images/large-previews/be7/puppy-2-1456421.jpg',
      'newTestImage.jpg',
    );

    //String newFilePath = await saveImageOnDisk(AssetImage('assets/images/happy-dogs.jpg'),'newTestImage.jpg');
    newFilePath = newFilePath.replaceFirst('/', '');
    String finalFilePath = 'file://$newFilePath';

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: "big_picture",
        title: 'Big picture (File)',
        body: '$lorenIpsumText\n\n$lorenIpsumText\n\n$lorenIpsumText',
        bigPicture: finalFilePath,
        notificationLayout: NotificationLayout.BigPicture,
        payload: {'uuid': 'uuid-test'},
      ),
    );
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
        payload: {'uuid': 'uuid-test'},
      ),
    );
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
        roundedLargeIcon: true,
        payload: {'uuid': 'uuid-test'},
      ),
    );
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
        bigPicture:
            'https://media-cdn.tripadvisor.com/media/photo-s/15/dd/20/61/al-punto.jpg',
        notificationLayout: NotificationLayout.BigPicture,
        payload: {'uuid': 'uuid-test'},
      ),
    );
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
        bigPicture:
            'https://media-cdn.tripadvisor.com/media/photo-s/15/dd/20/61/al-punto.jpg',
        notificationLayout: NotificationLayout.BigPicture,
        color: Colors.indigoAccent,
        payload: {'uuid': 'uuid-test'},
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'READ',
          label: 'Mark as read',
          autoDismissible: true,
        ),
        NotificationActionButton(
          key: 'REMEMBER',
          label: 'Remember-me later',
          autoDismissible: false,
        ),
      ],
    );
  }

  static Future<void> showNotificationWithAuthenticatedActionButtons(
    int id,
  ) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: "big_picture",
        title: 'Big <b>BIG</b> picture title',
        summary: 'Summary <i>text</i>',
        body: '$lorenIpsumText<br><br>$lorenIpsumText<br><br>$lorenIpsumText',
        largeIcon:
            'https://image.freepik.com/vetores-gratis/modelo-de-logotipo-de-restaurante-retro_23-2148451519.jpg',
        bigPicture:
            'https://media-cdn.tripadvisor.com/media/photo-s/15/dd/20/61/al-punto.jpg',
        notificationLayout: NotificationLayout.BigPicture,
        color: Colors.indigoAccent,
        payload: {'uuid': 'uuid-test'},
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'READ',
          label: 'Mark as read',
          autoDismissible: true,
          isAuthenticationRequired: true,
        ),
        NotificationActionButton(
          key: 'REMEMBER',
          label: 'Remember-me later',
          autoDismissible: false,
          isAuthenticationRequired: true,
        ),
      ],
    );
  }

  static Future<void> showBigPictureNotificationActionButtonsAndReply(
    int id,
  ) async {
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
        bigPicture:
            'https://media-cdn.tripadvisor.com/media/photo-s/15/dd/20/61/al-punto.jpg',
        notificationLayout: NotificationLayout.BigPicture,
        color: Colors.indigoAccent,
        payload: {'uuid': 'uuid-test'},
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'REPLY',
          label: 'Reply',
          autoDismissible: true,
          requireInputText: true,
        ),
        NotificationActionButton(
          key: 'REMEMBER',
          label: 'Remember-me later',
          autoDismissible: true,
        ),
      ],
    );
  }

  static Future<void> showBigPictureNotificationHideExpandedLargeIcon(
    int id,
  ) async {
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
        bigPicture:
            'https://img.itdg.com.br/tdg/images/blog/uploads/2019/05/hamburguer.jpg',
        notificationLayout: NotificationLayout.BigPicture,
        color: Colors.indigoAccent,
        payload: {'uuid': 'uuid-test'},
      ),
    );
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
        payload: {'uuid': 'uuid-test'},
      ),
    );
  }

  static Future<void> showBigTextNotificationWithDifferentSummary(
    int id,
  ) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: "big_text",
        title: 'Big text title',
        summary: 'Notification summary loren ipsum',
        body: '$lorenIpsumText\n\n$lorenIpsumText\n\n$lorenIpsumText',
        notificationLayout: NotificationLayout.BigText,
        payload: {'uuid': 'uuid-test'},
      ),
    );
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
        payload: {'uuid': 'uuid-test'},
      ),
    );
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
        payload: {'uuid': 'uuid-test'},
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'REPLY',
          label: 'Reply',
          autoDismissible: true,
          requireInputText: true,
        ),
        NotificationActionButton(
          key: 'REMEMBER',
          label: 'Remember-me later',
          autoDismissible: true,
        ),
      ],
    );
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
        showWhen: false,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'MEDIA_PREV',
          icon:
              'resource://drawable/res_ic_prev${MediaPlayerCentral.hasPreviousMedia ? '' : '_disabled'}',
          label: 'Previous',
          autoDismissible: false,
          showInCompactView: false,
          enabled: MediaPlayerCentral.hasPreviousMedia,
          actionType: ActionType.KeepOnTop,
        ),
        MediaPlayerCentral.isPlaying
            ? NotificationActionButton(
                key: 'MEDIA_PAUSE',
                icon: 'resource://drawable/res_ic_pause',
                label: 'Pause',
                autoDismissible: false,
                showInCompactView: true,
                actionType: ActionType.KeepOnTop,
              )
            : NotificationActionButton(
                key: 'MEDIA_PLAY',
                icon:
                    'resource://drawable/res_ic_play${MediaPlayerCentral.hasAnyMedia ? '' : '_disabled'}',
                label: 'Play',
                autoDismissible: false,
                showInCompactView: true,
                enabled: MediaPlayerCentral.hasAnyMedia,
                actionType: ActionType.KeepOnTop,
              ),
        NotificationActionButton(
          key: 'MEDIA_NEXT',
          icon:
              'resource://drawable/res_ic_next${MediaPlayerCentral.hasNextMedia ? '' : '_disabled'}',
          label: 'Previous',
          showInCompactView: true,
          enabled: MediaPlayerCentral.hasNextMedia,
          actionType: ActionType.KeepOnTop,
        ),
        NotificationActionButton(
          key: 'MEDIA_CLOSE',
          icon: 'resource://drawable/res_ic_close',
          label: 'Close',
          autoDismissible: true,
          showInCompactView: true,
          actionType: ActionType.KeepOnTop,
        ),
      ],
    );
  }

  static int _messageIncrement = 0;
  static Future<void> simulateChatConversation({
    required String groupKey,
  }) async {
    _messageIncrement++ % 4 < 2
        ? createMessagingNotification(
            channelKey: 'chats',
            groupKey: groupKey,
            chatName: 'Jhonny\'s Group',
            username: 'Jhonny',
            largeIcon: 'asset://assets/images/80s-disc.jpg',
            message: 'Jhonny\'s message $_messageIncrement',
          )
        : createMessagingNotification(
            channelKey: 'chats',
            groupKey: 'jhonny_group',
            chatName: 'Jhonny\'s Group',
            username: 'Michael',
            largeIcon: 'asset://assets/images/dj-disc.jpg',
            message: 'Michael\'s message $_messageIncrement',
          );
  }

  static Future<void> createMessagingNotification({
    required String channelKey,
    required String groupKey,
    required String chatName,
    required String username,
    required String message,
    String? largeIcon,
    bool checkPermission = true,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: createUniqueID(AwesomeNotifications.maxID),
        groupKey: groupKey,
        channelKey: channelKey,
        summary: chatName,
        title: username,
        body: message,
        largeIcon: largeIcon,
        notificationLayout: NotificationLayout.Messaging,
        category: NotificationCategory.Message,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'REPLY',
          label: 'Reply',
          requireInputText: true,
          autoDismissible: false,
        ),
        NotificationActionButton(
          key: 'READ',
          label: 'Mark as Read',
          autoDismissible: true,
          requireInputText: true,
        ),
      ],
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
          actionType: ActionType.DismissAction,
          autoDismissible: true,
          icon: 'resource://drawable/res_ic_close',
        ),
        NotificationActionButton(
          key: 'READ',
          label: 'Mark as read',
          autoDismissible: true,
          //icon: 'resources://drawable/res_ic_close'
        ),
      ],
    );
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
        body: 'Hey dude! Look what i found!',
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 2,
        channelKey: 'grouped',
        title: 'Cyclano',
        body: 'What?',
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 3,
        channelKey: channelKey,
        title: 'Little Jhonny',
        body: 'This push notifications plugin is amazing!',
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 4,
        channelKey: channelKey,
        title: 'Little Jhonny',
        body: 'Its perfect!',
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 5,
        channelKey: channelKey,
        title: 'Little Jhonny',
        body: 'I gonna contribute with the project! For sure!',
      ),
    );
  }

  /* *********************************************
      LIST SCHEDULED NOTIFICATIONS
  ************************************************ */

  static Future<void> listScheduledNotifications(BuildContext context) async {
    List<NotificationModel> activeSchedules =
        await AwesomeNotifications().listScheduledNotifications();

    for (NotificationModel schedule in activeSchedules) {
      debugPrint('pending notification: ['
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
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static Future<DateTime?> pickScheduleDate(
    BuildContext context, {
    required bool isUtc,
  }) async {
    TimeOfDay? timeOfDay;
    DateTime now = isUtc ? DateTime.now().toUtc() : DateTime.now();
    DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (newDate != null) {
      timeOfDay = await showTimePicker(
        context: context,
        initialTime:
            TimeOfDay.fromDateTime(now.add(const Duration(minutes: 1))),
      );

      if (timeOfDay != null) {
        return isUtc
            ? DateTime.utc(
                newDate.year,
                newDate.month,
                newDate.day,
                timeOfDay.hour,
                timeOfDay.minute,
              )
            : DateTime(
                newDate.year,
                newDate.month,
                newDate.day,
                timeOfDay.hour,
                timeOfDay.minute,
              );
      }
    }
    return null;
  }

  static Future<void> getNextValidMonday(BuildContext context) async {
    DateTime? referenceDate = await pickScheduleDate(context, isUtc: false);

    NotificationSchedule schedule = NotificationCalendar(
      weekday: DateTime.monday,
      hour: 0,
      minute: 0,
      second: 0,
      timeZone: AwesomeNotifications.localTimeZoneIdentifier,
    );
    //NotificationCalendar.fromDate(date: expectedDate);

    DateTime? nextValidDate = await AwesomeNotifications()
        .getNextDate(schedule, fixedDate: referenceDate);

    late String response;
    if (nextValidDate == null) {
      response = 'There is no more valid date for this schedule';
    } else {
      response = utils.AwesomeDateUtils.parseDateToString(
        nextValidDate.toUtc(),
        format: 'dd/MM/yyyy',
      )!;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Next valid schedule"),
        content: SizedBox(height: 50, child: Center(child: Text(response))),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () {
              Navigator.of(context).pop(null);
            },
          ),
        ],
      ),
    );
  }

  static Future<String> getCurrentTimeZone() {
    return AwesomeNotifications().getLocalTimeZoneIdentifier();
  }

  static Future<String> getUtcTimeZone() {
    return AwesomeNotifications().getUtcTimeZoneIdentifier();
  }

  static Future<void> repeatMinuteNotification() async {
    String localTimeZone =
        await AwesomeNotifications().getLocalTimeZoneIdentifier();
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: -1,
        channelKey: 'scheduled',
        title: 'Notification at every single minute',
        body:
            'This notification was schedule to repeat at every single minute.',
        notificationLayout: NotificationLayout.BigPicture,
        bigPicture: 'asset://assets/images/melted-clock.png',
        category: NotificationCategory.Reminder,
      ),
      schedule: NotificationInterval(
        interval: 60,
        timeZone: localTimeZone,
        repeats: true,
        preciseAlarm: true,
      ),
    );
  }

  static Future<void> repeatMultiple5Crontab() async {
    var nowDate = DateTime.now();
    String localTimeZone =
        await AwesomeNotifications().getLocalTimeZoneIdentifier();
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: -1,
        channelKey: 'scheduled',
        title: 'Notification at every 5 seconds for 1 minute',
        body: 'This notification was schedule to repeat at every 5 seconds.',
      ),
      schedule: NotificationAndroidCrontab(
        initialDateTime:
            nowDate.copyWith().add(const Duration(seconds: 10)).toUtc(),
        expirationDateTime: nowDate
            .copyWith()
            .add(const Duration(seconds: 10, minutes: 1))
            .toUtc(),
        crontabExpression: '/5 * * * * ? *',
        timeZone: localTimeZone,
        repeats: true,
        preciseAlarm: true,
      ),
    );
  }

  static Future<void> repeatPreciseThreeTimes() async {
    var nowDate = DateTime.now();
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: -1,
        channelKey: 'scheduled',
        title: 'Notification scheduled to play precisely 3 times',
        body: 'This notification was schedule to play precisely 3 times.',
        notificationLayout: NotificationLayout.BigPicture,
        category: NotificationCategory.Alarm,
        bigPicture: 'asset://assets/images/melted-clock.png',
      ),
      schedule: NotificationAndroidCrontab(
        preciseSchedules: [
          nowDate.copyWith().add(const Duration(seconds: 1)).toUtc(),
          nowDate.copyWith().add(const Duration(seconds: 25)).toUtc(),
          nowDate.copyWith().add(const Duration(seconds: 45)).toUtc(),
        ],
        repeats: true,
        preciseAlarm: true,
      ),
    );
  }

  static Future<void> repeatMinuteNotificationOClock() async {
    String localTimeZone =
        await AwesomeNotifications().getLocalTimeZoneIdentifier();
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: -1,
        channelKey: 'scheduled',
        title: 'Notification at exactly every single minute',
        body:
            'This notification was schedule to repeat at every single minute at clock.',
        notificationLayout: NotificationLayout.BigPicture,
        bigPicture: 'asset://assets/images/melted-clock.png',
      ),
      schedule: NotificationCalendar(
        second: 0,
        millisecond: 0,
        timeZone: localTimeZone,
        repeats: true,
      ),
    );
  }

  static Future<void> showNotificationAtSchedulePreciseDate(
    DateTime scheduleTime,
  ) async {
    String timeZoneIdentifier = AwesomeNotifications.localTimeZoneIdentifier;
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: -1,
        channelKey: 'scheduled',
        title: 'Just in time!',
        body:
            'This notification was schedule to shows at ${utils.AwesomeDateUtils.parseDateToString(scheduleTime.toLocal()) ?? '?'} $timeZoneIdentifier (${utils.AwesomeDateUtils.parseDateToString(scheduleTime.toUtc()) ?? '?'} utc)',
        notificationLayout: NotificationLayout.BigPicture,
        bigPicture: 'asset://assets/images/delivery.jpeg',
        payload: {'uuid': 'uuid-test'},
        autoDismissible: false,
      ),
      schedule: NotificationCalendar.fromDate(
        date: scheduleTime,
        preciseAlarm: true,
      ),
    );
  }

  static Future<void> showNotificationWithNoBadge(int id) async {
    AwesomeNotifications().setChannel(
      NotificationChannel(
        channelKey: 'no_badge',
        channelName: 'No Badge Notifications',
        channelDescription: 'Notifications with no badge',
        channelShowBadge: false,
      ),
    );

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'no_badge',
        title: 'no badge title',
        body: 'no badge body',
        payload: {'uuid': 'uuid-test'},
      ),
    );
  }

  static int currentStep = 0;
  static Timer? udpateNotificationAfter1Second;
  static Future<void> showProgressNotification(int id) async {
    int maxStep = 10;
    int fragmentation = 4;
    for (var simulatedStep = 1;
        simulatedStep <= maxStep * fragmentation + 1;
        simulatedStep++) {
      currentStep = simulatedStep;
      await Future.delayed(Duration(milliseconds: 1000 ~/ fragmentation));
      if (udpateNotificationAfter1Second != null) continue;
      udpateNotificationAfter1Second = Timer(const Duration(seconds: 1), () {
        _updateCurrentProgressBar(
          id: id,
          simulatedStep: currentStep,
          maxStep: maxStep * fragmentation,
        );
        udpateNotificationAfter1Second?.cancel();
        udpateNotificationAfter1Second = null;
      });
    }
  }

  static void _updateCurrentProgressBar({
    required int id,
    required int simulatedStep,
    required int maxStep,
  }) {
    if (simulatedStep < maxStep) {
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'progress_bar',
          title: 'Download finished',
          body: 'filename.txt',
          category: NotificationCategory.Progress,
          payload: {
            'file': 'filename.txt',
            'path': '-rmdir c://ruwindows/system32/huehuehue',
          },
          locked: false,
        ),
      );
    } else {
      int progress = min((simulatedStep / maxStep * 100).round(), 100);
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'progress_bar',
          title: 'Downloading fake file in progress ($progress%)',
          body: 'filename.txt',
          category: NotificationCategory.Progress,
          payload: {
            'file': 'filename.txt',
            'path': '-rmdir c://ruwindows/system32/huehuehue',
          },
          notificationLayout: NotificationLayout.ProgressBar,
          progress: progress,
          locked: true,
        ),
      );
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
          'path': '-rmdir c://ruwindows/system32/huehuehue',
        },
        notificationLayout: NotificationLayout.ProgressBar,
        progress: null,
        locked: true,
      ),
    );
  }

  static Future<void> showNotificationWithUpdatedChannelDescription(
    int id,
  ) async {
    AwesomeNotifications().setChannel(
      NotificationChannel(
        channelGroupKey: 'channel_tests',
        channelKey: 'updated_channel',
        channelName: 'Channel to update (updated)',
        channelDescription: 'Notifications with updated channel',
      ),
    );

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'updated_channel',
        title: 'updated notification channel',
        body: 'check settings to see updated channel description',
        category: NotificationCategory.Status,
        payload: {'uuid': '0123456789'},
      ),
    );
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

  static Future<void> dismissNotificationsByChannelKey(
    String channelKey,
  ) async {
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
