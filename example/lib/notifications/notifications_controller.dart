import 'package:awesome_notifications_example/main_complete.dart';
import 'package:awesome_notifications_example/routes/routes.dart';
import 'package:awesome_notifications_example/utils/common_functions.dart' if (dart.library.html)
'package:awesome_notifications_example/utils/common_web_functions.dart';
import 'package:awesome_notifications_example/utils/media_player_central.dart';
import 'package:awesome_notifications_example/notifications/notifications_util.dart';

import 'package:awesome_notifications/awesome_notifications.dart';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsController {
  static ReceivedAction? initialCallAction;

  // ***************************************************************
  //    INITIALIZATIONS
  // ***************************************************************
  static Future<void> initializeLocalNotifications() async {
    await AwesomeNotifications().initialize(
        'resource://drawable/res_app_icon',
        [
          NotificationChannel(
              channelGroupKey: 'basic_tests',
              channelKey: 'basic_channel',
              channelName: 'Basic notifications',
              channelDescription: 'Notification channel for basic tests',
              defaultColor: const Color(0xFF9D50DD),
              ledColor: Colors.white,
              importance: NotificationImportance.High),
          NotificationChannel(
              channelGroupKey: 'basic_tests',
              channelKey: 'badge_channel',
              channelName: 'Badge indicator notifications',
              channelDescription:
                  'Notification channel to activate badge indicator',
              channelShowBadge: true,
              defaultColor: const Color(0xFF9D50DD),
              ledColor: Colors.yellow),
          NotificationChannel(
              channelGroupKey: 'category_tests',
              channelKey: 'call_channel',
              channelName: 'Calls Channel',
              channelDescription: 'Channel with call ringtone',
              defaultColor: const Color(0xFF9D50DD),
              importance: NotificationImportance.Max,
              ledColor: Colors.white,
              channelShowBadge: true,
              locked: true,
              defaultRingtoneType: DefaultRingtoneType.Ringtone),
          NotificationChannel(
              channelGroupKey: 'category_tests',
              channelKey: 'alarm_channel',
              channelName: 'Alarms Channel',
              channelDescription: 'Channel with alarm ringtone',
              defaultColor: const Color(0xFF9D50DD),
              importance: NotificationImportance.Max,
              ledColor: Colors.white,
              channelShowBadge: true,
              locked: true,
              defaultRingtoneType: DefaultRingtoneType.Alarm),
          NotificationChannel(
              channelGroupKey: 'channel_tests',
              channelKey: 'updated_channel',
              channelName: 'Channel to update',
              channelDescription: 'Notifications with not updated channel',
              defaultColor: const Color(0xFF9D50DD),
              ledColor: Colors.white),
          NotificationChannel(
            channelGroupKey: 'chat_tests',
            channelKey: 'chats',
            channelName: 'Chat groups',
            channelDescription:
                'This is a simple example channel of a chat group',
            channelShowBadge: true,
            importance: NotificationImportance.Max,
            ledColor: Colors.white,
            defaultColor: const Color(0xFF9D50DD),
          ),
          NotificationChannel(
              channelGroupKey: 'vibration_tests',
              channelKey: 'low_intensity',
              channelName: 'Low intensity notifications',
              channelDescription:
                  'Notification channel for notifications with low intensity',
              defaultColor: Colors.green,
              ledColor: Colors.green,
              vibrationPattern: lowVibrationPattern),
          NotificationChannel(
              channelGroupKey: 'vibration_tests',
              channelKey: 'medium_intensity',
              channelName: 'Medium intensity notifications',
              channelDescription:
                  'Notification channel for notifications with medium intensity',
              defaultColor: Colors.yellow,
              ledColor: Colors.yellow,
              vibrationPattern: mediumVibrationPattern),
          NotificationChannel(
              channelGroupKey: 'vibration_tests',
              channelKey: 'high_intensity',
              channelName: 'High intensity notifications',
              channelDescription:
                  'Notification channel for notifications with high intensity',
              defaultColor: Colors.red,
              ledColor: Colors.red,
              vibrationPattern: highVibrationPattern),
          NotificationChannel(
              channelGroupKey: 'privacy_tests',
              channelKey: "private_channel",
              channelName: "Privates notification channel",
              channelDescription: "Privates notification from lock screen",
              playSound: true,
              defaultColor: Colors.red,
              ledColor: Colors.red,
              vibrationPattern: lowVibrationPattern,
              defaultPrivacy: NotificationPrivacy.Private),
          NotificationChannel(
              channelGroupKey: 'sound_tests',
              icon: 'resource://drawable/res_power_ranger_thunder',
              channelKey: "custom_sound",
              channelName: "Custom sound notifications",
              channelDescription: "Notifications with custom sound",
              playSound: true,
              soundSource: 'resource://raw/res_morph_power_rangers',
              defaultColor: Colors.red,
              ledColor: Colors.red,
              vibrationPattern: lowVibrationPattern),
          NotificationChannel(
              channelGroupKey: 'sound_tests',
              channelKey: "silenced",
              channelName: "Silenced notifications",
              channelDescription: "The most quiet notifications",
              playSound: false,
              enableVibration: false,
              enableLights: false),
          NotificationChannel(
              channelGroupKey: 'media_player_tests',
              icon: 'resource://drawable/res_media_icon',
              channelKey: 'media_player',
              channelName: 'Media player controller',
              channelDescription: 'Media player controller',
              defaultPrivacy: NotificationPrivacy.Public,
              enableVibration: false,
              enableLights: false,
              playSound: false,
              locked: true),
          NotificationChannel(
              channelGroupKey: 'image_tests',
              channelKey: 'big_picture',
              channelName: 'Big pictures',
              channelDescription: 'Notifications with big and beautiful images',
              defaultColor: const Color(0xFF9D50DD),
              ledColor: const Color(0xFF9D50DD),
              vibrationPattern: lowVibrationPattern,
              importance: NotificationImportance.High),
          NotificationChannel(
              channelGroupKey: 'layout_tests',
              channelKey: 'big_text',
              channelName: 'Big text notifications',
              channelDescription: 'Notifications with a expandable body text',
              defaultColor: Colors.blueGrey,
              ledColor: Colors.blueGrey,
              vibrationPattern: lowVibrationPattern),
          NotificationChannel(
              channelGroupKey: 'layout_tests',
              channelKey: 'inbox',
              channelName: 'Inbox notifications',
              channelDescription: 'Notifications with inbox layout',
              defaultColor: const Color(0xFF9D50DD),
              ledColor: const Color(0xFF9D50DD),
              vibrationPattern: mediumVibrationPattern),
          NotificationChannel(
            channelGroupKey: 'schedule_tests',
            channelKey: 'scheduled',
            channelName: 'Scheduled notifications',
            channelDescription: 'Notifications with schedule functionality',
            defaultColor: const Color(0xFF9D50DD),
            ledColor: const Color(0xFF9D50DD),
            vibrationPattern: lowVibrationPattern,
            importance: NotificationImportance.High,
            defaultRingtoneType: DefaultRingtoneType.Alarm,
            criticalAlerts: true,
          ),
          NotificationChannel(
              channelGroupKey: 'layout_tests',
              icon: 'resource://drawable/res_download_icon',
              channelKey: 'progress_bar',
              channelName: 'Progress bar notifications',
              channelDescription: 'Notifications with a progress bar layout',
              defaultColor: Colors.deepPurple,
              ledColor: Colors.deepPurple,
              vibrationPattern: lowVibrationPattern,
              onlyAlertOnce: true),
          NotificationChannel(
              channelGroupKey: 'grouping_tests',
              channelKey: 'grouped',
              channelName: 'Grouped notifications',
              channelDescription: 'Notifications with group functionality',
              groupKey: 'grouped',
              groupSort: GroupSort.Desc,
              groupAlertBehavior: GroupAlertBehavior.Children,
              defaultColor: Colors.lightGreen,
              ledColor: Colors.lightGreen,
              vibrationPattern: lowVibrationPattern,
              importance: NotificationImportance.High)
        ],
        channelGroups: [
          NotificationChannelGroup(
              channelGroupKey: 'basic_tests', channelGroupName: 'Basic tests'),
          NotificationChannelGroup(
              channelGroupKey: 'category_tests',
              channelGroupName: 'Category tests'),
          NotificationChannelGroup(
              channelGroupKey: 'image_tests', channelGroupName: 'Images tests'),
          NotificationChannelGroup(
              channelGroupKey: 'schedule_tests',
              channelGroupName: 'Schedule tests'),
          NotificationChannelGroup(
              channelGroupKey: 'chat_tests', channelGroupName: 'Chat tests'),
          NotificationChannelGroup(
              channelGroupKey: 'channel_tests',
              channelGroupName: 'Channel tests'),
          NotificationChannelGroup(
              channelGroupKey: 'sound_tests', channelGroupName: 'Sound tests'),
          NotificationChannelGroup(
              channelGroupKey: 'vibration_tests',
              channelGroupName: 'Vibration tests'),
          NotificationChannelGroup(
              channelGroupKey: 'privacy_tests',
              channelGroupName: 'Privacy tests'),
          NotificationChannelGroup(
              channelGroupKey: 'layout_tests',
              channelGroupName: 'Layout tests'),
          NotificationChannelGroup(
              channelGroupKey: 'grouping_tests',
              channelGroupName: 'Grouping tests'),
          NotificationChannelGroup(
              channelGroupKey: 'media_player_tests',
              channelGroupName: 'Media Player tests')
        ],
        debug: true);
  }

  static Future<void> initializeNotificationsEventListeners() async {
    // Only after at least the action method is set, the notification events are delivered
    AwesomeNotifications().setListeners(
        onActionReceivedMethod: NotificationsController.onActionReceivedMethod,
        onNotificationCreatedMethod:
            NotificationsController.onNotificationCreatedMethod,
        onNotificationDisplayedMethod:
            NotificationsController.onNotificationDisplayedMethod,
        onDismissActionReceivedMethod:
            NotificationsController.onDismissActionReceivedMethod);
  }

  // ***************************************************************
  //    NOTIFICATIONS EVENT LISTENERS
  // ***************************************************************

  static String _toSimpleEnum(NotificationLifeCycle lifeCycle) =>
      lifeCycle.toString().split('.').last;

  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    Fluttertoast.showToast(
        msg:
            'Notification created on ${_toSimpleEnum(receivedNotification.createdLifeCycle!)}',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.green,
        gravity: ToastGravity.BOTTOM);
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    Fluttertoast.showToast(
        msg:
            'Notification displayed on ${_toSimpleEnum(receivedNotification.displayedLifeCycle!)}',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.blue,
        gravity: ToastGravity.BOTTOM);
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    Fluttertoast.showToast(
        msg:
            'Notification dismissed on ${_toSimpleEnum(receivedAction.dismissedLifeCycle!)}',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.orange,
        gravity: ToastGravity.BOTTOM);
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Always ensure that all plugins was initialized
    WidgetsFlutterBinding.ensureInitialized();

    bool isSilentAction =
        receivedAction.actionType == ActionType.SilentAction ||
            receivedAction.actionType == ActionType.SilentBackgroundAction;

    // SilentBackgroundAction runs on background thread and cannot show
    // UI/visual elements
    if (receivedAction.actionType != ActionType.SilentBackgroundAction) {
      Fluttertoast.showToast(
          msg:
              '${isSilentAction ? 'Silent action' : 'Action'} received on ${_toSimpleEnum(receivedAction.actionLifeCycle!)}',
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: isSilentAction ? Colors.blueAccent : App.mainColor,
          gravity: ToastGravity.BOTTOM);
    }

    switch (receivedAction.channelKey) {
      case 'call_channel':
        if (receivedAction.actionLifeCycle != NotificationLifeCycle.AppKilled){
          await receiveCallNotificationAction(receivedAction);
        }
        break;

      case 'alarm_channel':
        await receiveAlarmNotificationAction(receivedAction);
        break;

      case 'media_player':
        await receiveMediaNotificationAction(receivedAction);
        break;

      case 'chats':
        await receiveChatNotificationAction(receivedAction);
        break;

      default:
        if (isSilentAction) {
          debugPrint(receivedAction.toString());
          debugPrint("start");
          await Future.delayed(const Duration(seconds: 4));
          final url = Uri.parse("http://google.com");
          final re = await http.get(url);
          debugPrint(re.body);
          debugPrint("long task done");
          break;
        }
        if (!AwesomeStringUtils.isNullOrEmpty(receivedAction.buttonKeyInput)) {
          receiveButtonInputText(receivedAction);
        } else {
          receiveStandardNotificationAction(receivedAction);
        }
        break;
    }
  }

  // ***************************************************************
  //    NOTIFICATIONS HANDLING METHODS
  // ***************************************************************

  static Future<void> receiveButtonInputText(
      ReceivedAction receivedAction) async {
    debugPrint('Input Button Message: "${receivedAction.buttonKeyInput}"');
    Fluttertoast.showToast(
        msg: 'Msg: ${receivedAction.buttonKeyInput}',
        backgroundColor: App.mainColor,
        textColor: Colors.white);
  }

  static Future<void> receiveStandardNotificationAction(
      ReceivedAction receivedAction) async {
    loadSingletonPage(App.navigatorKey.currentState,
        targetPage: PAGE_NOTIFICATION_DETAILS, receivedAction: receivedAction);
  }

  static Future<void> receiveMediaNotificationAction(
      ReceivedAction receivedAction) async {
    switch (receivedAction.buttonKeyPressed) {
      case 'MEDIA_CLOSE':
        MediaPlayerCentral.stop();
        break;

      case 'MEDIA_PLAY':
      case 'MEDIA_PAUSE':
        MediaPlayerCentral.playPause();
        break;

      case 'MEDIA_PREV':
        MediaPlayerCentral.previousMedia();
        break;

      case 'MEDIA_NEXT':
        MediaPlayerCentral.nextMedia();
        break;

      default:
        loadSingletonPage(App.navigatorKey.currentState,
            targetPage: PAGE_MEDIA_DETAILS, receivedAction: receivedAction);
        break;
    }
  }

  static Future<void> receiveChatNotificationAction(
      ReceivedAction receivedAction) async {
    if (receivedAction.buttonKeyPressed == 'REPLY') {
      await NotificationUtils.createMessagingNotification(
        channelKey: 'chats',
        groupKey: 'jhonny_group',
        chatName: 'Jhonny\'s Group',
        username: 'you',
        largeIcon: 'asset://assets/images/rock-disc.jpg',
        message: receivedAction.buttonKeyInput,
      );
    } else {
      loadSingletonPage(App.navigatorKey.currentState,
          targetPage: PAGE_NOTIFICATION_DETAILS, receivedAction: receivedAction);
    }
  }

  static Future<void> receiveAlarmNotificationAction(
      ReceivedAction receivedAction) async {
    if (receivedAction.buttonKeyPressed == 'SNOOZE') {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('stringValue', "abc");
      await NotificationUtils.showAlarmNotification(id: receivedAction.id!);
    }
  }

  static Future<void> receiveCallNotificationAction(
      ReceivedAction receivedAction) async {
    switch (receivedAction.buttonKeyPressed) {
      case 'REJECT':
        // Is not necessary to do anything, because the reject button is
        // already auto dismissible
        break;

      case 'ACCEPT':
        loadSingletonPage(App.navigatorKey.currentState,
            targetPage: PAGE_PHONE_CALL, receivedAction: receivedAction);
        break;

      default:
        loadSingletonPage(App.navigatorKey.currentState,
            targetPage: PAGE_PHONE_CALL, receivedAction: receivedAction);
        break;
    }
  }

  static Future<void> interceptInitialCallActionRequest() async {
    ReceivedAction? receivedAction = await AwesomeNotifications()
        .getInitialNotificationAction();

    if(receivedAction?.channelKey == 'call_channel') {
      initialCallAction = receivedAction;
    }
  }
}
