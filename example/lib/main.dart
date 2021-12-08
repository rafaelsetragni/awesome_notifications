import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:awesome_notifications_example/routes.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_example/models/media_model.dart';
import 'package:awesome_notifications_example/utils/media_player_central.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AwesomeNotifications().initialize(
    'resource://drawable/res_app_icon',
    [
      NotificationChannel(
          channelGroupKey: 'basic_tests',
          channelKey: 'basic_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for basic tests',
          defaultColor: Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.High
      ),
      NotificationChannel(
          channelGroupKey: 'basic_tests',
          channelKey: 'badge_channel',
          channelName: 'Badge indicator notifications',
          channelDescription: 'Notification channel to activate badge indicator',
          channelShowBadge: true,
          defaultColor: Color(0xFF9D50DD),
          ledColor: Colors.yellow),
      NotificationChannel(
          channelGroupKey: 'category_tests',
          channelKey: 'call_channel',
          channelName: 'Calls Channel',
          channelDescription: 'Channel with call ringtone',
          defaultColor: Color(0xFF9D50DD),
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
          defaultColor: Color(0xFF9D50DD),
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
          defaultColor: Color(0xFF9D50DD),
          ledColor: Colors.white),
      NotificationChannel(
          channelGroupKey: 'chat_tests',
          channelKey: 'chats',
          channelName: 'Chat groups',
          channelDescription: 'This is a simple example channel of a chat group',
          channelShowBadge: true,
          importance: NotificationImportance.Max,
          ledColor: Colors.white,
          defaultColor: Color(0xFF9D50DD),
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
          defaultColor: Color(0xFF9D50DD),
          ledColor: Color(0xFF9D50DD),
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
          defaultColor: Color(0xFF9D50DD),
          ledColor: Color(0xFF9D50DD),
          vibrationPattern: mediumVibrationPattern),
      NotificationChannel(
          channelGroupKey: 'schedule_tests',
          channelKey: 'scheduled',
          channelName: 'Scheduled notifications',
          channelDescription: 'Notifications with schedule functionality',
          defaultColor: Color(0xFF9D50DD),
          ledColor: Color(0xFF9D50DD),
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
      NotificationChannelGroup(channelGroupkey: 'basic_tests', channelGroupName: 'Basic tests'),
      NotificationChannelGroup(channelGroupkey: 'category_tests', channelGroupName: 'Category tests'),
      NotificationChannelGroup(channelGroupkey: 'image_tests', channelGroupName: 'Images tests'),
      NotificationChannelGroup(channelGroupkey: 'schedule_tests', channelGroupName: 'Schedule tests'),
      NotificationChannelGroup(channelGroupkey: 'chat_tests', channelGroupName: 'Chat tests'),
      NotificationChannelGroup(channelGroupkey: 'channel_tests', channelGroupName: 'Channel tests'),
      NotificationChannelGroup(channelGroupkey: 'sound_tests', channelGroupName: 'Sound tests'),
      NotificationChannelGroup(channelGroupkey: 'vibration_tests', channelGroupName: 'Vibration tests'),
      NotificationChannelGroup(channelGroupkey: 'privacy_tests', channelGroupName: 'Privacy tests'),
      NotificationChannelGroup(channelGroupkey: 'layout_tests', channelGroupName: 'Layout tests'),
      NotificationChannelGroup(channelGroupkey: 'grouping_tests', channelGroupName: 'Grouping tests'),
      NotificationChannelGroup(channelGroupkey: 'media_player_tests', channelGroupName: 'Media Player tests')
    ],
    debug: true
  );

  // Uncomment those lines after activate google services inside example/android/build.gradle
  // Create the initialization Future outside of `build`:
  //FirebaseApp firebaseApp = await Firebase.initializeApp();
  //FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(App());
}


Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');

  if(
    !StringUtils.isNullOrEmpty(message.notification?.title, considerWhiteSpaceAsEmpty: true) ||
    !StringUtils.isNullOrEmpty(message.notification?.body, considerWhiteSpaceAsEmpty: true)
  ){
    print('message also contained a notification: ${message.notification}');

    String? imageUrl;
    imageUrl ??= message.notification!.android?.imageUrl;
    imageUrl ??= message.notification!.apple?.imageUrl;

    Map<String, dynamic> notificationAdapter = {
      NOTIFICATION_CHANNEL_KEY: 'basic_channel',
      NOTIFICATION_ID:
            message.data[NOTIFICATION_CONTENT]?[NOTIFICATION_ID] ??
            message.messageId ??
            Random().nextInt(2147483647),
      NOTIFICATION_TITLE:
            message.data[NOTIFICATION_CONTENT]?[NOTIFICATION_TITLE] ??
            message.notification?.title,
      NOTIFICATION_BODY:
            message.data[NOTIFICATION_CONTENT]?[NOTIFICATION_BODY] ??
            message.notification?.body ,
      NOTIFICATION_LAYOUT:
          StringUtils.isNullOrEmpty(imageUrl) ? 'Default' : 'BigPicture',
      NOTIFICATION_BIG_PICTURE: imageUrl
    };

    AwesomeNotifications().createNotificationFromJsonData(notificationAdapter);
  }
  else {
    AwesomeNotifications().createNotificationFromJsonData(message.data);
  }
}

class App extends StatefulWidget {
  App();

  static final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

  static String name = 'Awesome Notifications - Example App';
  static Color mainColor = Color(0xFF9D50DD);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    MediaPlayerCentral.addAll([
      MediaModel(
          diskImagePath: 'asset://assets/images/rock-disc.jpg',
          colorCaptureSize: Size(788, 800),
          bandName: 'Bright Sharp',
          trackName: 'Champagne Supernova',
          trackSize: Duration(minutes: 4, seconds: 21)),
      MediaModel(
          diskImagePath: 'asset://assets/images/classic-disc.jpg',
          colorCaptureSize: Size(500, 500),
          bandName: 'Best of Mozart',
          trackName: 'Allegro',
          trackSize: Duration(minutes: 7, seconds: 41)),
      MediaModel(
          diskImagePath: 'asset://assets/images/remix-disc.jpg',
          colorCaptureSize: Size(500, 500),
          bandName: 'Dj Allucard',
          trackName: '21st Century',
          trackSize: Duration(minutes: 4, seconds: 59)),
      MediaModel(
          diskImagePath: 'asset://assets/images/dj-disc.jpg',
          colorCaptureSize: Size(500, 500),
          bandName: 'Dj Brainiak',
          trackName: 'Speed of light',
          trackSize: Duration(minutes: 4, seconds: 59)),
      MediaModel(
          diskImagePath: 'asset://assets/images/80s-disc.jpg',
          colorCaptureSize: Size(500, 500),
          bandName: 'Back to the 80\'s',
          trackName: 'Disco revenge',
          trackSize: Duration(minutes: 4, seconds: 59)),
      MediaModel(
          diskImagePath: 'asset://assets/images/old-disc.jpg',
          colorCaptureSize: Size(500, 500),
          bandName: 'PeacefulMind',
          trackName: 'Never look at back',
          trackSize: Duration(minutes: 4, seconds: 59)),
    ]);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: App.navKey,
      title: App.name,
      color: App.mainColor,
      initialRoute: PAGE_HOME,
      //onGenerateRoute: generateRoute,
      routes: materialRoutes,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
      theme: ThemeData(
        brightness: Brightness.light,

        primaryColor: App.mainColor,
        accentColor: Colors.blueGrey,
        canvasColor: Colors.white,
        focusColor: Colors.blueAccent,
        disabledColor: Colors.grey,

        backgroundColor: Colors.blueGrey.shade400,

        appBarTheme: AppBarTheme(
            brightness: Brightness.dark,
            color: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(
              color: App.mainColor,
            ),
            textTheme: TextTheme(
              headline6: TextStyle(color: App.mainColor, fontSize: 18),
            )),

        fontFamily: 'Robot',

        // Define the default TextTheme. Use this to specify the default
        // text styling for headlines, titles, bodies of text, and more.
        textTheme: TextTheme(
          headline1: TextStyle(
              fontSize: 64.0, height: 1.5, fontWeight: FontWeight.w500),
          headline2: TextStyle(
              fontSize: 52.0, height: 1.5, fontWeight: FontWeight.w500),
          headline3: TextStyle(
              fontSize: 48.0, height: 1.5, fontWeight: FontWeight.w500),
          headline4: TextStyle(
              fontSize: 32.0, height: 1.5, fontWeight: FontWeight.w500),
          headline5: TextStyle(
              fontSize: 28.0, height: 1.5, fontWeight: FontWeight.w500),
          headline6: TextStyle(
              fontSize: 22.0, height: 1.5, fontWeight: FontWeight.w500),
          subtitle1:
              TextStyle(fontSize: 18.0, height: 1.5, color: Colors.black54),
          subtitle2:
              TextStyle(fontSize: 12.0, height: 1.5, color: Colors.black54),
          button: TextStyle(fontSize: 16.0, height: 1.5, color: Colors.black54),
          bodyText1: TextStyle(fontSize: 16.0, height: 1.5),
          bodyText2: TextStyle(fontSize: 16.0, height: 1.5),
        ),

        buttonTheme: ButtonThemeData(
          buttonColor: Colors.grey.shade200,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(5))),
          padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
          textTheme: ButtonTextTheme.accent,
        ),
      ),
    );
  }
}
