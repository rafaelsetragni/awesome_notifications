
# Awesome Notifications for Flutter

![](https://raw.githubusercontent.com/rafaelsetragni/awesome_notifications/master/example/assets/readme/awesome-notifications.jpg)

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](#)
[![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)](#)
[![Discord](https://img.shields.io/discord/888523488376279050.svg?style=for-the-badge&colorA=7289da&label=Chat%20on%20Discord)](https://discord.awesome-notifications.carda.me)

[![Open Source Love](https://badges.frapsoft.com/os/v1/open-source.svg?v=103)](#)
[![pub package](https://img.shields.io/pub/v/awesome_notifications.svg)](https://pub.dev/packages/awesome_notifications)
![Full tests workflow](https://github.com/rafaelsetragni/awesome_notifications/actions/workflows/dart.yml/badge.svg?branch=master)
![codecov badge](https://codecov.io/gh/rafaelsetragni/awesome_notifications/branch/master/graph/badge.svg)


Engage your users with custom local and push notifications on Flutter. Get real-time events and never miss a user interaction with Awesome Notifications.

<br>
<br>

### **Key Features:**

* **Create custom notifications:** Use Awesome Notifications to easily create and customize local and push notifications for your Flutter app.
* **Engage your users:** Keep your users engaged with your app by sending notifications with images, sounds, emoticons, buttons, and many different layouts.
* **Real-time events:** Receive real-time events on the Flutter level code for notifications that are created, displayed, dismissed, or tapped by the user.
* **Highly customizable:** With a range of customizable options, including translations, you can tailor notifications to fit your specific needs.
* **Scheduled notifications:** Schedule notifications repeatedly or at specific times with second precision to keep your users up-to-date.
* **Trusted performance:** Receive notifications with confidence and trust in any application lifecycle.
* **Easy to use:** With an easy-to-use interface, you can start creating custom notifications in minutes.
<br>
<br>

***Android** notification examples:*

![](https://raw.githubusercontent.com/rafaelsetragni/awesome_notifications/master/example/assets/readme/awesome-notifications-android-examples.jpg)


<br>

***iOS** notification examples:*

![](https://raw.githubusercontent.com/rafaelsetragni/awesome_notifications/master/example/assets/readme/awesome-notifications-ios-examples.jpg)


<br>

## Notification Types Available

Here are some of the notification types available with Awesome Notifications:

- Basic notification
- Big picture notification
- Media notification
- Big text notification
- Inbox notification
- Messaging notification
- Messaging group notification
- Notifications with action buttons
- Grouped notifications
- Progress bar notifications (only for Android)

All notification types can be created locally or via remote push services, with all the features and customizations available.

<br>

# 🛑 ATTENTION - PLUGIN UNDER DEVELOPMENT
    
![image](https://user-images.githubusercontent.com/40064496/155188371-48e22104-8bb8-4f38-ba1a-1795eeb7b81b.png)

*Working Progress Percentages of Awesome Notifications Plugin*

OBS: Please note that these progress percentages are estimates and are subject to change. We are continually working to improve the Awesome Notifications plugin and add support for new platforms.

<br>
<br>

# 🛑 ATTENTION <br> Users from flutter_local_notifications plugin
awesome_notifications plugin is incompatible with `flutter_local_notifications`, as both plugins will compete each other to accquire global notification resources to send notifications and to receive notification actions.

So, you MUST not use `flutter_local_notifications` with `awesome_notifications`. Awesome Notifications contains all features available in flutter_local_notifications plugin and more, so you can replace totally flutter_local_notifications in your project.

    
<br>
<br>

# 🛑 ATTENTION <br> Users from firebase_messaging plugin
The support for `firebase_messaging` plugin is now deprecated, but all other firebase plugins are still being supported. This is because firebase_messaging plugin and awesome_notifications plugin will compete with each other to acquire global notification resources.

To use FCM services with Awesome Notifications, you need to use the Awesome Notifications FCM add-on plugin.

Only by using `awesome_notifications_fcm` will you be capable of achieving all Firebase Cloud Messaging features + all Awesome Notifications features. To continue using `firebase_messaging`, you will need to implement workarounds with silent push notifications, which is not recommended for displaying visual notifications and will result in several background penalties for your application.

So, you MUST not use `firebase_messaging` with `awesome_notifications`. Use `awesome_notifications` with `awesome_notifications_fcm` instead.
    
<br>
<br>
    
# ✅ Next steps

- Include `Web support`
- Include `Desktop support`
- Include `Live Activities notifications`
- Include `Time Sensitive notifications`
- Include `Communication notifications`
- Include full `Media Player notifications`
- Implement test cases for native libraries to achieve +90% test coverage in each one
- Include support for other push notification services (Wonderpush, One Signal, IBM, AWS, Azure, etc)
- Replicate all Android layouts for iOS (almost accomplished)
- Custom layouts for notifications

We are constantly working to improve Awesome Notifications and provide support for new platforms and services. Stay tuned for more updates!

<br>
<br>

# 💰 Donate via Stripe or BuyMeACoffee

Help us improve and maintain our work with donations of any amount via Stripe or BuyMeACoffee. Your donation will mainly be used to purchase new devices and equipment, which we will use to test and ensure that our plugins work correctly on all platforms and their respective versions.

[*![Donate With Stripe](https://github.com/rafaelsetragni/awesome_notifications/blob/68c963206885290f8a44eee4bfc7e7b223610e4a/example/assets/readme/stripe.png?raw=true)*](https://donate.stripe.com/3cs14Yf79dQcbU4001)
[*![Donate With Buy Me A Coffee](https://github.com/rafaelsetragni/awesome_notifications/blob/95ee986af0aa59ccf9a80959bbf3dd60b5a4f048/example/assets/readme/buy-me-a-coffee.jpeg?raw=true)*](https://www.buymeacoffee.com/rafaelsetragni)
    
<br>
<br>

# 💬 Discord Chat Server 

Stay up to date with new updates and get community support by subscribing to our Discord chat server:

[![Discord Banner 3](https://discordapp.com/api/guilds/888523488376279050/widget.png?style=banner3)](https://discord.awesome-notifications.carda.me)

<br>
<br>
<br>

# 📙 Table of Contents

- [Awesome Notifications for Flutter](#awesome-notifications-for-flutter)
    - [**Key Features:**](#key-features)
  - [Notification Types Available](#notification-types-available)
- [🛑 ATTENTION - PLUGIN UNDER DEVELOPMENT](#-attention---plugin-under-development)
- [🛑 ATTENTION  Users from flutter\_local\_notifications plugin](#-attention--users-from-flutter_local_notifications-plugin)
- [🛑 ATTENTION  Users from firebase\_messaging plugin](#-attention--users-from-firebase_messaging-plugin)
- [✅ Next steps](#-next-steps)
- [💰 Donate via Stripe or BuyMeACoffee](#-donate-via-stripe-or-buymeacoffee)
- [💬 Discord Chat Server](#-discord-chat-server)
- [📙 Table of Contents](#-table-of-contents)
- [🔶 Main Philosophy](#-main-philosophy)
- [🚚 Migrating from version 0.6.X to 0.7.XBreaking changes](#-migrating-from-version-06x-to-07xbreaking-changes)
- [🛠 Getting Started](#-getting-started)
  - [Initial Configurations](#initial-configurations)
    - [🤖 Configuring Android:](#-configuring-android)
    - [🍎 Configuring iOS:](#-configuring-ios)
- [📨 How to show Local Notifications](#-how-to-show-local-notifications)
  - [📝 Getting started - Important notes](#-getting-started---important-notes)
- [🍎⁺ Extra iOS Setup for Background Actions](#-extra-ios-setup-for-background-actions)
- [📱 Example Apps](#-example-apps)
- [🔷 Awesome Notification's Flowchart](#-awesome-notifications-flowchart)
- [⚡️ Notification Events](#️-notification-events)
- [👊 Notification Action Types](#-notification-action-types)
- [🟦 Notification's Category](#-notifications-category)
- [👮‍♀️ Requesting Permissions](#️-requesting-permissions)
    - [Notification's Permissions:](#notifications-permissions)
    - [Notification's Permission Level](#notifications-permission-level)
    - [Full example on how to request permissions](#full-example-on-how-to-request-permissions)
- [📡 Notification channels](#-notification-channels)
  - [Notification Channel Attributes](#notification-channel-attributes)
  - [📝 Notification Channel's Important Notes:](#-notification-channels-important-notes)
- [📅 Scheduling a Notification](#-scheduling-a-notification)
  - [⏰ Schedule Precision](#-schedule-precision)
  - [📝 Schedule Notification's Important Notes:](#-schedule-notifications-important-notes)
  - [Deprecated Schedule Class for Cron Rules (Versions Prior to 0.0.6)](#deprecated-schedule-class-for-cron-rules-versions-prior-to-006)
- [🌎 Translation of Notification Content](#-translation-of-notification-content)
- [⏱ Chronometer and Timeout (Expiration)](#-chronometer-and-timeout-expiration)
- [⌛️ Progress Bar Notifications (Only for Android)](#️-progress-bar-notifications-only-for-android)
- [😃 Emojis (Emoticons)](#-emojis-emoticons)
- [🎨 Notification Layout Types](#-notification-layout-types)
- [📷 Media Source Types](#-media-source-types)
- [⬆️ Notification Importance](#️-notification-importance)
- [🔆 Wake Up Screen Notifications](#-wake-up-screen-notifications)
- [🖥 Full Screen Notifications (only for Android)](#-full-screen-notifications-only-for-android)
- [🏗 Notification Structures](#-notification-structures)
  - [NotificationContent ("content" in Push data) - (required)](#notificationcontent-content-in-push-data---required)
  - [📝 Notification Content's Important Notes:](#-notification-contents-important-notes)
  - [NotificationActionButton ("actionButtons" in Push data) - (optional)](#notificationactionbutton-actionbuttons-in-push-data---optional)
  - [Schedules](#schedules)
    - [NotificationInterval ("schedule" in Push data) - (optional)](#notificationinterval-schedule-in-push-data---optional)
    - [NotificationCalendar ("schedule" in Push data) - (optional)](#notificationcalendar-schedule-in-push-data---optional)
    - [NotificationAndroidCrontab (Only for Android)("schedule" in Push data) - (optional)](#notificationandroidcrontab-only-for-androidschedule-in-push-data---optional)
- [Common Known Issues](#common-known-issues)
  - [***Issue***: Targeting S+ (version 31 and above) requires that an explicit value for android:exported be defined when intent filters are present](#issue-targeting-s-version-31-and-above-requires-that-an-explicit-value-for-androidexported-be-defined-when-intent-filters-are-present)
  - [***Issue***: Notification is not showing up or is showing up inconsistently.](#issue-notification-is-not-showing-up-or-is-showing-up-inconsistently)
  - [***Issue:*** My schedules are only displayed immediately after I open my app](#issue-my-schedules-are-only-displayed-immediately-after-i-open-my-app)
  - [***Issue***: DecoderBufferCallback not found / Uint8List not found](#issue-decoderbuffercallback-not-found--uint8list-not-found)
  - [***Issue***: Using bridging headers with module interfaces is unsupported](#issue-using-bridging-headers-with-module-interfaces-is-unsupported)
  - [***Issue***: Invalid notification content](#issue-invalid-notification-content)
  - [***Issue***: Undefined symbol: OBJC\_CLASS$\_FlutterStandardTypedData / OBJC\_CLASS$\_FlutterError / OBJC\_CLASS$\_FlutterMethodChannel](#issue-undefined-symbol-objc_class_flutterstandardtypeddata--objc_class_fluttererror--objc_class_fluttermethodchannel)
- [Android Foreground Services (Optional)](#android-foreground-services-optional)
    - [IMPORTANT](#important)
    - [Foreground Services behaviour on platforms other than Android](#foreground-services-behaviour-on-platforms-other-than-android)


<br>
<br>

# 🔶 Main Philosophy

At Awesome Notifications, we believe that notifications should be transparent to developers with all available features, simplifying the many different hardware and software resources available on different devices. This way, developers can focus on `what to do` instead of `how to do`. To achieve this, we adopt the philosophy of showing notifications with all available features requested, but ignoring any features that are not available on the device.

For example, if a device has LED colored lights, we will use them for notifications. If it doesn't have LED lights, we will ignore that feature but still show the notification with all the other available features. We follow the same philosophy for Notification Channels: if there is no channel segregation of notifications, we use the channel configuration as default. If the device has channels, we use them as expected.

All notifications sent while the app was killed are registered and delivered as soon as possible to the Application after the plugin initialization and the event listeners being set, respecting the delivery order. This way, your application will receive all notification events at the Flutter level code.

For the app badge number manipulation, we consider as expected behavior how iOS handles it. For all other platforms, we try to mimic its behavior as much close as possible.

By following our main philosophy, we ensure that Awesome Notifications delivers notifications that work consistently across different devices and provide the best user experience possible for your users.
    
<br>
<br>

#  🚚 Migrating from version 0.6.X to 0.7.X<br>Breaking changes

We have made some changes to Awesome Notifications in version 0.7.X that may require you to update your code. Here are the main breaking changes:

- ***Action events:*** Now it's possible to receive action events without bringing the app to the foreground. Please refer to the action type's topic for more information on how to implement this.

- ***Streams replaced by global static methods:*** All streams (createdStream, displayedStream, actionStream, and dismissedStream) have been replaced by global static methods. You must replace your old stream methods with static and global methods. These must be static Future<void> and use async/await. Make sure to use @pragma("vm:entry-point") to preserve dart addressing. To use context and redirect the user to another page inside static methods, please use Flutter navigatorKey or another third-party library, such as GetX. Check our How to show Local Notifications topic to know more.

- ***Delayed notification events:*** All notification events are now delivered only after the first setListeners being called. Please make sure to update your code accordingly.

- ***Renamed ButtonType class:*** The ButtonType class has been renamed to ActionType. Please update your code to use the new class name.

- ***Deprecated InputField action type:*** The action type InputField is now deprecated. You just need to set the property requireInputText to true to achieve the same result, but it now works combined with all other action types.

- ***Deprecated support for firebase_messaging plugin:*** The support for firebase_messaging plugin is now deprecated. You need to use the [Awesome's FCM add-on plugin](https://pub.dev/packages/awesome_notifications_fcm) to achieve all Firebase Cloud Messaging features without violating the platform rules. This is the only way to fully integrate with Awesome Notifications, running all in native level.


<br>
<br>

# 🛠 Getting Started

<br>

## Initial Configurations

Bellow are the obligatory configurations that your app must meet to use awesome_notifications:

<br>

### 🤖 Configuring Android:

1 - Is required the minimum android SDK to 21 (Android 5.0 Lollipop), Grade 7.3.0 or greater and Java compiled SDK Version to 34 (Android 14). You can change the `minSdkVersion` to 21 and the `compileSdkVersion` and `targetSdkVersion` to 34, inside the file `build.gradle`, located inside "android/app/" folder.
```Gradle
buildscript {
    ...
    
    dependencies {
        classpath 'com.android.tools.build:gradle:7.2.2'
    }
}

android {
    compileSdkVersion 34

    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
        ...
    }
    ...
}
```

2 - In the app’s `AndroidManifest.xml` file (which can be found in the android/app/src/main directory of your Flutter project), add the following permissions:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.myapp">
   <application>
        ...
    </application>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
</manifest>
```

3 -  If you're using any `<activity>`, `<activity-alias>`, `<service>`, or `<receiver>` components with `<intent-filter>` declared inside, add the attribute `android:exported="true"` to make them accessible from outside the app's context.:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.myapp">
   <application>
        ...
        <activity
            android:name=".MainActivity"
            ...
            android:exported="true">
                ...
        </activity>
        ...
    </application>
</manifest>
```

<br>
<br>

### 🍎 Configuring iOS:

To use Awesome Notifications and build your app correctly, you need to ensure to set some `build settings` options for your app targets. In your project view, click on *Runner -> Target Runner -> Build settings*...  

![image](https://user-images.githubusercontent.com/40064496/194729267-6fbfc78c-8cba-422b-8af7-d7099f359adb.png)

... and set the following options:

In *Runner* Target:
* Build libraries for distribution => NO
* Only safe API extensions => NO
* iOS Deployment Target => 11 or greater

In *all other* Targets:
* Build libraries for distribution => NO
* Only safe API extensions => YES
* iOS Deployment Target => 11 or greater

<br>
<br>

# 📨 How to show Local Notifications

<br>

1. Add *awesome_notifications* as a dependency in your `pubspec.yaml` file.

```yaml
awesome_notifications: any # Any attribute updates automatically your source to the last version
```

2. import the plugin package to your dart code

```dart
import 'package:awesome_notifications/awesome_notifications.dart';
```

3. Initialize the plugin on main.dart, before MaterialApp widget (preferentially inside `main()` method), with at least one native icon and one channel

```dart
AwesomeNotifications().initialize(
  // set the icon to null if you want to use the default app icon
  'resource://drawable/res_app_icon',
  [
    NotificationChannel(
        channelGroupKey: 'basic_channel_group',
        channelKey: 'basic_channel',
        channelName: 'Basic notifications',
        channelDescription: 'Notification channel for basic tests',
        defaultColor: Color(0xFF9D50DD),
        ledColor: Colors.white)
  ],
  // Channel groups are only visual and are not required
  channelGroups: [
    NotificationChannelGroup(
        channelGroupKey: 'basic_channel_group',
        channelGroupName: 'Basic group')
  ],
  debug: true
);
```

4. Inside the MaterialApp widget, create your named routes and set your global navigator key. Also, inside initState, initialize your static listeners methods to capture notification's actions.
OBS 1: With the navigator key, you can redirect pages and get context even inside static classes.
OBS 2: Only after setListeners being called, the notification events starts to be delivered.

```dart
class MyApp extends StatefulWidget {

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const String name = 'Awesome Notifications - Example App';
  static const Color mainColor = Colors.deepPurple;

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {

    // Only after at least the action method is set, the notification events are delivered
    AwesomeNotifications().setListeners(
        onActionReceivedMethod:         NotificationController.onActionReceivedMethod,
        onNotificationCreatedMethod:    NotificationController.onNotificationCreatedMethod,
        onNotificationDisplayedMethod:  NotificationController.onNotificationDisplayedMethod,
        onDismissActionReceivedMethod:  NotificationController.onDismissActionReceivedMethod
    );

    super.initState();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      // The navigator key is necessary to allow to navigate through static methods
      navigatorKey: MyApp.navigatorKey,

      title: MyApp.name,
      color: MyApp.mainColor,

      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) =>
                MyHomePage(title: MyApp.name)
            );

          case '/notification-page':
            return MaterialPageRoute(builder: (context) {
              final ReceivedAction receivedAction = settings
                  .arguments as ReceivedAction;
              return MyNotificationPage(receivedAction: receivedAction);
            });

          default:
            assert(false, 'Page ${settings.name} not found');
            return null;
        }
      },

      theme: ThemeData(
          primarySwatch: Colors.deepPurple
      ),
    );
  }
}
```

OBS: Note that the example below is not a valid static or global method. You can retrieve the current context from the NavigatorKey instance, declared on MaterialApp widget, at any time.
```Dart
    AwesomeNotifications().setListeners(
        onActionReceivedMethod: (ReceivedAction receivedAction){
            NotificationController.onActionReceivedMethod(context, receivedAction);
        },
        onNotificationCreatedMethod: (ReceivedNotification receivedNotification){
            NotificationController.onNotificationCreatedMethod(context, receivedNotification);
        },
        onNotificationDisplayedMethod: (ReceivedNotification receivedNotification){
            NotificationController.onNotificationDisplayedMethod(context, receivedNotification);
        },
        onDismissActionReceivedMethod: (ReceivedAction receivedAction){
            NotificationController.onDismissActionReceivedMethod(context, receivedAction);
        },
    );
```

5. Create in any place or class, the static methods to capture the respective notification events.
OBS: You need to use `@pragma("vm:entry-point")` in each static method to identify to the Flutter engine that the dart address will be called from native and should be preserved.

```dart
class NotificationController {

  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future <void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future <void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future <void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    // Your code goes here
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future <void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    // Your code goes here

    // Navigate into pages, avoiding to open the notification details page over another details page already opened
    MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil('/notification-page',
            (route) => (route.settings.name != '/notification-page') || route.isFirst,
        arguments: receivedAction);
  }
}
```

6. Request the user authorization to send local and push notifications (Remember to show a dialog alert to the user before call this request)

```dart
AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
  if (!isAllowed) {
    // This is just a basic example. For real apps, you must show some
    // friendly dialog box before call the request method.
    // This is very important to not harm the user experience
    AwesomeNotifications().requestPermissionToSendNotifications();
  }
});
```

7. In any place of your app, create a new notification with:

```dart
AwesomeNotifications().createNotification(
  content: NotificationContent(
      id: 10,
      channelKey: 'basic_channel',
      actionType: ActionType.Default
      title: 'Hello World!',
      body: 'This is my first notification!',
  )
);
```
<br>

This will create a new notification with ID `10`, using the previously defined notification channel `basic_channel` and the default action type that brings the app to foreground. The notification will have a title of "Hello World!" and a body of "This is my first notification!".

🎉🎉🎉 **THATS IT! CONGRATZ MY FRIEND!!!** 🎉🎉🎉

<br>
<br>

## 📝 Getting started - Important notes

<br>

1 . You MUST initialize all Awesome Notifications plugins, even if your app does not have permissions to send notifications.

2 . In case you need to capture the user notification action before calling the method `setListeners`, you can call the method `getInitialNotificationAction` at any moment.
In case your app was started by an user notification action, `getInitialNotificationAction` will return the respective `ActionReceived` object. Otherwise will return null.

OBS: `getInitialNotificationAction` method does not affect the results from `onActionReceivedMethod`, except if you set `removeFromActionEvents` to `true`.

```dart
void main() async {
    ReceivedAction? receivedAction = await AwesomeNotifications().getInitialNotificationAction(
      removeFromActionEvents: false
    );
    if(receivedAction?.channelKey == 'call_channel') setInitialPageToCallPage();
    else setInitialPageToHomePage();
}
```

3 . In case you need to redirect the user after a `silentAction` or `silentBackgroundAction` event, you may face the situation where you are running inside a dart Isolate with no valid `BuildContext` to redirect the user. For such cases, you can use `SendPort` and `ReceivePort` to switch execution between isolates.

First, create a `ReceivePort` inside your initialization process (which only occurs in the main isolate). Then, inside your `onActionReceivedMethod`, check if you are running inside the main isolate first. If not, use a `SendPort` to send the execution to the listening `ReceivePort`. Inside the `ReceivePort` listener, you can then call the appropriate method to handle the background action.

Here is an example:

In the initialization of your `notification_controller.dart`:
```Dart
    // Create a receive port
    ReceivePort port = ReceivePort();

    // Register the receive port with a unique name
    IsolateNameServer.registerPortWithName(
      port,
      'notification_actions',
    );

    // Listen for messages on the receive port
    port.listen((var received) async {
        print('Action running on main isolate');
        _handleActionReceived(received);
    });
    
    // Set the initialization flag
    _initialized = true;
```

In your `onActionReceivedMethod` method:
```Dart
  static Future<void> onActionReceivedMethod(ReceivedAction received) async {
    print('New action received: ${received.toMap()}');

    // If the controller was not initialized or the function is not running in the main isolate,
    // try to retrieve the ReceivePort at main isolate and them send the execution to it
    if (!_initialized) {
      SendPort? uiSendPort = IsolateNameServer.lookupPortByName('notification_actions');
      if (uiSendPort != null) {
        print('Background action running on parallel isolate without valid context. Redirecting execution');
        uiSendPort.send(received);
        return;
      }
    }
    
    print('Action running on background isolate');
    await _handleActionReceived(received);
  }

  static Future<void> _handleActionReceived(ReceivedAction received) async {
    // Here you handle your notification actions

    // Navigate into pages, avoiding to open the notification details page twice
    // In case youre using some state management, such as GetX or get_route, use them to get the valid context instead
    // of using the Flutter's navigator key
    MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil('/notification-page',
            (route) => (route.settings.name != '/notification-page') || route.isFirst,
        arguments: receivedAction);
  }
```

<br>

4. On Android, if you press the back button until leaves the app and then reopen it using the "Recent apps list" *`THE LAST APP INITIALIZATION WILL BE REPEATED`*. 
So, in the case where the app was started up by a notification, in this exclusive case the notification action will be repeated. If this is not desirable behavior for your app, you will need to handle this case specifically in your app's logic.

<br>
<br>

# 🍎⁺ Extra iOS Setup for Background Actions

<br>

On iOS, to use any plugin inside background actions, you will need to manually register each plugin you want. Otherwise, you will face the `MissingPluginException` exception.
To avoid this, you need to add the following lines to the `AppDelegate.swift` file in your iOS project folder:

```Swift
import Flutter
import awesome_notifications
import shared_preferences_ios
//import all_other_plugins_that_i_need

override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      GeneratedPluginRegistrant.register(with: self)

      // This function registers the desired plugins to be used within a notification background action
      SwiftAwesomeNotificationsPlugin.setPluginRegistrantCallback { registry in          
          SwiftAwesomeNotificationsPlugin.register(
            with: registry.registrar(forPlugin: "io.flutter.plugins.awesomenotifications.AwesomeNotificationsPlugin")!)          
          FLTSharedPreferencesPlugin.register(
            with: registry.registrar(forPlugin: "io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin")!)
      }

      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
```

You can also check the `GeneratedPluginRegistrant.m` file to see the correct plugin names to use. (Note that the plugin names may change over time)

<br>
<br>

# 📱 Example Apps

<br>

With the examples bellow, you can check all the features and how to use the Awesome Notifications in pratice. The Simple Example app contains the basic structure to use Awesome Notifications, and the Complete Example App contains all Awesome Notification features to test.

To run and debug the Simple Example App, follow the steps bellow:

1. Create a new Flutter project with at least Android or iOS
2. Copy the example code at https://pub.dev/packages/awesome_notifications/example
3. Paste the content inside the `main.dart` file
4. Debug the application with a real device or emulator


To run and debug the Complete Example App, follow the steps bellow:

1. Install GitHub software in your local machine. I strongly recommend to use [GitHub Desktop](https://desktop.github.com/).
2. Go to one of our GitHub repositories
3. Clone the project to your local machine
4. Open the project with Android Studio or any other IDE
5. Sync the project dependencies running `flutter pub get`
6. On iOS, run `pod install` inside the folder *example/ios/* to sync the native dependencies
7. Debug the application with a real device or emulator

<br>
<br>
    
# 🔷 Awesome Notification's Flowchart

Notifications are received by local code or Push service using native code, so the messages will appears immediately or at schedule time, independent of your application is running or not.

![Awesome Notification's flowchart](https://user-images.githubusercontent.com/40064496/197368144-7bfcee7e-644a-4bdc-80f1-b4d38c2eaaff.png)

<br>
<br>

# ⚡️ Notification Events

The notification events are only delivered after `setListeners` method being called, and they are not always delivered at same time as they happen.
The awesome notifications event methods available to track your notifications are:

* **onNotificationCreatedMethod (optional)**: Fires when a notification is created  
* **onNotificationDisplayedMethod (optional)**: Fires when a notification is displayed on system status bar  
* **onActionReceivedMethod (required)**: Fires when a notification is tapped by the user  
* **onDismissedActionReceivedMethod (optional)**: Fires when a notification is dismissed by the user (sometimes the OS denies the deliver)

... and these are the delivery conditions:

| Platform    | App in Foreground | App in Background | App Terminated (Force Quit) |
| ----------- | ----------------- | ----------------- | ----------------------- |
| **Android** | Fires all events immediately after occurs | Fires all events immediately after occurs | Store events to be fired when app is on Foreground or Background |
| **iOS**     | Fires all events immediately after occurs | Store events to be fired when app is on Foreground | Store events to be fired when app is on Foreground |


Exception: **onActionReceivedMethod** fires all events immediately after occurs in any application life cycle, for all Platforms.

<br>
<br>

# 👊 Notification Action Types

There are several types of notification actions that you can use in Awesome Notifications:

* **Default:** This is the default action type. It forces the app to go to the foreground when the user taps the notification.
* **SilentAction:** This type of action does not force the app to go to the foreground, but it runs on the main thread and can accept visual elements. It can be interrupted if the main app is terminated.
* **SilentBackgroundAction:** This type of action does not force the app to the foreground and runs in the background. It does not accept any visual element and the execution is done on an exclusive Dart isolate.
* **KeepOnTop:** This type of action fires the respective action without closing the notification status bar and does not bring the app to the foreground.
* **DisabledAction:** When the user taps this type of action, the notification simply closes itself on the tray without firing any action event.
* **DismissAction:** This type of action behaves the same way as a user dismissing action, but it dismisses the respective notification and fires the onDismissActionReceivedMethod. It ignores the autoDismissible property.
* **InputField:** (Deprecated) When the user taps this type of action, it opens a dialog box that allows them to send a text response. Now you can use the requireInputText property instead.

Remember that for silent types, it is necessary to use the await keyword to prevent the isolates from shutting down before all the work is done. Consider using these different types of actions to customize the behavior of your notifications to suit your needs.

<br>
<br>

# 🟦 Notification's Category

The notification category is a group of predefined categories that best describe the nature of the notification and may be used by some systems to rank, delay or filter the notifications. 

***It's highly recommended to always correctly categorize your notifications***.

 * **Alarm:** Alarm or timer.
 * **Call:** incoming call (voice or video) or similar synchronous communication request
 * **Email:** asynchronous bulk message (email).
 * **Error:** error in background operation or authentication status.
 * **Event:** calendar event.
 * **LocalSharing:** temporarily sharing location.
 * **Message:** incoming direct message (SMS, instant message, etc.).
 * **MissedCall:** incoming call (voice or video) or similar synchronous communication request
 * **Navigation:** map turn-by-turn navigation.
 * **Progress:** progress of a long-running background operation.
 * **Promo:** promotion or advertisement.
 * **Recommendation:** a specific, timely recommendation for a single thing. For example, a news app might want to recommend a news story it believes the user will want to read next.
 * **Reminder:** user-scheduled reminder.
 * **Service:** indication of running background service.
 * **Social:** social network or sharing update.
 * **Status:** ongoing information about device or contextual status.
 * **StopWatch:** running stopwatch.
 * **Transport:** media transport control for playback.
 * **Workout:** tracking a user's workout.

<br>
<br>


# 👮‍♀️ Requesting Permissions

Permissions give transparency to the user about what you intend to do with your app while it's in use. To show any notification on a device, you must obtain the user's consent. Keep in mind that this consent can be revoked at any time, on any platform. On Android 12 and below, the basic permissions are always granted to any newly installed app. But for iOS and Android 13 and beyond, even the basic permission must be requested from the user.

> **Disclaimer:**
> On Android, revoke certain permissions, including notification permissions, may cause the system to automatically restart the app to ensure the new permission setting is respected. Handle this scenario in your code by saving any necessary state before requesting or changing permissions, and restoring that state when the app is restarted. Inform your users about this behavior to avoid confusion and ensure a smoother user experience.

Permissions can be defined in three types:

- **Normal permissions:** These permissions are not considered dangerous and do not require explicit user consent to be enabled.
- **Execution permissions:** These permissions are considered more sensitive to the user, and you must obtain their explicit consent to use them.
- **Special/Dangerous permissions:** These permissions can harm the user experience or their privacy, and you must obtain their explicit consent. Depending on the platform, you may need permission from the manufacturer to use them.

As a good practice, always check if the permissions you desire are granted before creating any new notification, regardless of the platform. To check if a permission requires explicit user consent, call the method `shouldShowRationaleToRequest`. The list of permissions that require a rationale to the user can differ between platforms and OS versions. If your app does not require a permission to execute what you need, consider not requesting it, respecting the user's will.

<br>
    
### Notification's Permissions:

- Alert: Alerts are notifications with high priority that pops up on the user screen. Notifications with normal priority only shows the icon on status bar.

- Sound: Sound allows for the ability to play sounds for new displayed notifications. The notification sounds are limited to a few seconds and if you plan to play a sound for more time, you must consider to play a background sound to do it simultaneously with the notification.

- Badge: Badge is the ability to display a badge alert over the app icon to alert the user about updates. The badges can be displayed on numbers or small dots, depending of platform or what the user defined in the device settings. Both Android and iOS can show numbers on badge, depending of its version and distribution.

- Light: The ability to display colorful small lights, blanking on the device while the screen is off to alert the user about updates. Only a few Android devices have this feature.

- Vibration: The ability to vibrate the device to alert the user about updates.

- FullScreenIntent: The ability to show the notifications on pop up even if the user is using another app.

- PreciseAlarms: Precise alarms allows the scheduled notifications to be displayed at the expected time. This permission can be revoke by special device modes, such as battery save mode, etc. Some manufactures can disable this feature if they decide that your app is consumpting many computational resources and decressing the baterry life (and without changing the permission status for your app). So, you must take in consideration that some schedules can be delayed or even not being displayed, depending of what platform are you running. You can increase the chances to display the notification at correct time, enable this permission and setting the correct notification category, but you never gonna have 100% sure about it.

- CriticalAlert: Critical alerts is a special permission that allows to play sounds and vibrate for new notifications displayed, even if the device is in Do Not Disturb / Silent mode. For iOS, you must request Apple a authorization to your app use it.

- OverrideDnD: Override DnD allows the notification to decrease the Do Not Disturb / Silent mode level enable to display critical alerts for Alarm and Call notifications. For Android, you must require the user consent to use it. For iOS, this permission is always enabled with CriticalAlert.

- Provisional: (Only has effect on iOS) The ability to display notifications temporarily without the user consent.

- Car: The ability to display notifications while the device is in car mode.

    
OBS: If none permission is requested through `requestPermissionToSendNotifications` method, the standard permissions requested are Alert, Badge, Sound, Vibrate and Light.

<br>
    
### Notification's Permission Level

A permission can be segregated in 3 different levels:

![image](https://user-images.githubusercontent.com/40064496/143137760-32b99fad-5827-4d0e-9d4f-c39c82ca6bfd.png)


- Device level: The permissions set at the global device configuration are applicable at any app installed on device, such as disable/enable all notifications, battery save mode / low power mode and silent / do not disturb mode.
- Application level: The permissions set at the global app configurations are applicable to any notification in any channel.
- Channel level: The permissions set on the channel has effect only for notifications displayed through that specific channel.

<br>
    
### Full example on how to request permissions

Below is a complete example of how to check if the desired permission is enabled and how to request it by showing a dialog with a rationale if necessary (this example is taken from our sample app):

```Dart
  static Future<List<NotificationPermission>> requestUserPermissions(
      BuildContext context,{
      // if you only intends to request the permissions until app level, set the channelKey value to null
      required String? channelKey,
      required List<NotificationPermission> permissionList}
    ) async {

    // Check if the basic permission was granted by the user
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

    // If there is no permissions depending on user's intervention, so request it directly
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
      // If you need to show a rationale to educate the user to conceived the permission, show it
      await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Color(0xfffbfbfb),
            title: Text('Awesome Notifications needs your permission',
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
                  'To proceed, you need to enable the permissions above'+
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
```

<br>
<br>

# 📡 Notification channels

<br>

Notification channels are a way to group notifications that share common characteristics, such as the channel name, description, sound, vibration, LED light, and importance level. You can create and delete notification channels at any time in your app. However, at least one notification channel must exist during the initialization of the Awesome Notifications plugin. If you create a notification using an invalid channel key, the notification will be discarded.

In Android 8 (SDK 26) and later versions, you cannot update notification channels after they are created, except for the name and description attributes. However, for exceptional cases where you need to change your channels, you can set the `forceUpdate` property to true in the `setChannel` method. This option will delete the original channel and recreate it with a different native channel key. But use it only in cases of extreme need because this method deviates from the standard defined by the Android team. Note that this operation has the negative effect of automatically closing all active notifications on that channel.

For iOS, there is no native notification channel concept. However, Awesome Notifications will handle your notification channels in the same way as Android, so you only need to write your code once and it will work on both platforms.

You can also organize your notification channels visually in your Android app by using `NotificationChannelGroup` in the `AwesomeNotifications().initialize` method and the `channelGroupKey` property in the respective channels. You can update the channel group name at any time, but a channel can only be defined in a group when it is created.

The main methods to manipulate notification channels are:

* `AwesomeNotifications().setChannel`: Creates or updates a notification channel.
* `AwesomeNotifications().removeChannel`: Removes a notification channel, closing all current notifications on that channel.
You can use the following attributes to configure your notification channels:

<br>

## Notification Channel Attributes

| Attribute             | Required | Description                                                                                  | Type                   | Updatable | Default Value |
| ----------------------| -------- | -------------------------------------------------------------------------------------------- | ---------------------- | --------- | ------------- |
| `channelKey`          | Yes      | A string key that identifies a channel where notifications are sent.                         | String                 | No        | basic_channel |
| `channelName`         | Yes      | The name of the channel, which is visible to users on Android.                               | String                 | Yes       | None          |
| `channelDescription`  | Yes      | A brief description of the channel, which is visible to users on Android.                    | String                 | Yes       | None          |
| `channelShowBadge`    | No       | Whether the notification should automatically increment the app icon badge counter.          | Boolean                | Yes       | `false`       |
| `importance`          | No       | The importance level of the notification.                                                    | NotificationImportance | No        | `Normal`      |
| `playSound`           | No       | Whether the notification should play a sound.                                                | Boolean                | No        | `true`        |
| `soundSource`         | No       | The path of a custom sound file to be played with the notification.                          | String                 | No        | None          |
| `defaultRingtoneType` | No       | The type of default sound to be played with the notification (only for Android).             | DefaultRingtoneType    | Yes       | `Notification`|
| `enableVibration`     | No       | Whether the device should vibrate when the notification is received.                         | Boolean                | No        | `true`        |
| `enableLights`        | No       | Whether the device should display a blinking LED when the notification is received.          | Boolean                | No        | `true` |
| `ledColor`            | No       | The color of the LED to display when the notification is received.                           | Color                  | No        | `Colors.white`|
| `ledOnMs`             | No       | The duration in milliseconds that the LED should remain on when displaying the notification. | Integer                | No        | None          |
| `ledOffMs`            | No       | The duration in milliseconds that the LED should remain off when displaying the notification.| Integer                | No        | None          |
| `channelGroupKey`     | No       | The string key used to group notifications together.                                         | String                 | No        | None          |
| `groupSort`           | No       | The order in which notifications within a group should be sorted.                            | GroupSort              | No        | `Desc`        |
| `groupAlertBehavior`  | No       | The alert behavior to use for notifications within a group.                                  | GroupAlertBehavior     | No        | `All`         |
| `defaultPrivacy`      | No       | The level of privacy to apply to the notification when the device is locked.                 | NotificationPrivacy    | No        | `Private`     |
| `icon`                | No       | The name of the notification icon to display in the status bar.                              | String                 | No        | None          |
| `defaultColor`        | No       | The color to use for the notification on Android.                                            | Color                  | No        | `Color.black` |
| `locked`              | No       | Whether the notification should be prevented from being dismissed by the user.               | Boolean                | No        | `false`       |
| `onlyAlertOnce`       | No       | Whether the notification should only alert the user once.                                    | Boolean                | No        | `false`       |


<br>

## 📝 Notification Channel's Important Notes:

1 - Notification channels cannot be modified after being created on devices running Android 8 (SDK 26) or later, unless the app is reinstalled or installed for the first time after the changes.

2 - In exceptional cases where modification is necessary, you can set the `forceUpdate` property to true in the `setChannel` method to delete the original channel and recreate it with a different native channel key. However, this method should only be used when absolutely necessary as it deviates from the standard defined by the Android team..

3 - Keep in mind that using `forceUpdate` will also close all active notifications on the channel.


<br>
<br>

# 📅 Scheduling a Notification

Notifications can be scheduled either from a UTC or local time zone, and can be configured with a time interval or by setting a calendar filter. Schedules can also be created remotely using silent push notifications.
Note for iOS users: It is not possible to define the exact `displayedDate` for a notification on iOS, as it is not possible due the impossibility to execute anything at same time as the scheduled time when it arrives in the user's status bar.

To schedule a notification, instantiate one of the classes below in the `schedule` property of the notification:

- `NotificationCalendar`: Creates a notification that is scheduled to be displayed when the set date components match the current date. If a time component is set to `null`, then any value is considered valid to produce the next valid date. Only one value is allowed for each component.
- `NotificationInterval`: Creates a notification that is scheduled to be displayed at each interval time, starting from the next valid interval.
- `NotificationAndroidCrontab`: Creates a notification that is scheduled to be displayed based on a list of precise dates or a crontab rule, with seconds precision. To learn more about how to create a valid crontab rule, check out [this article](https://www.baeldung.com/cron-expressions).

All of these classes can be configured with the following properties:

- `timeZone`: describes the time zone on which the schedule is based (valid examples include "America/Sao_Paulo", "America/Los_Angeles", "GMT+01:00", "Europe/London", "UTC").
- `allowWhileIdle`: determines whether the notification will be sent even when the device is in a critical situation, such as low battery.
- `repeats`: determines whether the schedule should repeat after the notification is displayed. If there are no more valid dates compatible with the schedule rules, the notification is automatically canceled.

Please note the following about time zones:

* Dates with UTC time zones are triggered at the same time in all parts of the planet and are not affected by daylight rules.
* Dates with local time zones, defined such as "GMT-07:00", are not affected by daylight rules.
* Dates with local time zones, defined such as "Europe/Lisbon", are affected by daylight rules, especially when scheduled based on a calendar filter.

Here are some practical examples of how to create a scheduled notification:

```Dart
  String localTimeZone = await AwesomeNotifications().getLocalTimeZoneIdentifier();
  String utcTimeZone = await AwesomeNotifications().getLocalTimeZoneIdentifier();

  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: 'scheduled',
          title: 'Notification every single minute',
          body:
              'This notification was scheduled to repeat every minute.',
          notificationLayout: NotificationLayout.BigPicture,
          bigPicture: 'asset://assets/images/melted-clock.png'),
      schedule: NotificationInterval(interval: 60, timeZone: localTimeZone, repeats: true));
```

```Dart
await AwesomeNotifications().createNotification(
  content: NotificationContent(
      id: id,
      channelKey: 'scheduled',
      title: 'Wait 5 seconds to show',
      body: 'Now it is 5 seconds later.',
      wakeUpScreen: true,
      category: NotificationCategory.Alarm,
  ),
  schedule: NotificationInterval(
      interval: 5,
      timeZone: localTimeZone,
      preciseAlarm: true,
      timezone: await AwesomeNotifications().getLocalTimeZoneIdentifier()
  );
```

```Dart
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: 'scheduled',
          title: 'Notification at exactly every single minute',
          body: 'This notification was schedule to repeat at every single minute at clock.',
          notificationLayout: NotificationLayout.BigPicture,
          bigPicture: 'asset://assets/images/melted-clock.png'),
      schedule: NotificationCalendar(second: 0, timeZone: localTimeZone, repeats: true));
```

```Dart
 await AwesomeNotifications().createNotification(
  content: NotificationContent(
    id: id,
    channelKey: 'scheduled',
    title: 'Just in time!',
    body: 'This notification was scheduled to shows at ' +
        (Utils.DateUtils.parseDateToString(scheduleTime.toLocal()) ?? '?') +
        ' $timeZoneIdentifier (' +
        (Utils.DateUtils.parseDateToString(scheduleTime.toUtc()) ?? '?') +
        ' utc)',
    wakeUpScreen: true,
    category: NotificationCategory.Reminder,
    notificationLayout: NotificationLayout.BigPicture,
    bigPicture: 'asset://assets/images/delivery.jpeg',
    payload: {'uuid': 'uuid-test'},
    autoDismissible: false,
  ),
  schedule: NotificationCalendar.fromDate(date: scheduleTime));
```

<br>


## ⏰ Schedule Precision

It's important to keep in mind that schedules can be ignored or delayed, especially for repeating schedules, due to system algorithms designed to save battery life and prevent abuse of resources. While this behavior is recommended to protect the app and the manufacturer's image, it's crucial to consider this fact in your business logic.

However, for cases where precise schedule execution is a must, there are some features you can use to ensure the notification is sent at the correct time:

- Set the notification's category to a critical one, such as Alarm, Reminder, or Call.
- Set the `preciseAlarm` property to true. This feature allows the system to schedule notifications to be sent at an exact time, even if the device is in low-power mode. For Android versions greater than or equal to 12, you need to explicitly request user consent to enable this feature. You can request the permission with `requestPermissionToSendNotifications` or take the user to the permission page by calling `showAlarmPage`.
- Set the `criticalAlerts` channel property and notification content property to true. This feature allows you to show notifications and play sounds even when the device is on silent or Do Not Disturb mode. Due to its sensitivity, this feature requires special authorization from Apple on iOS and explicit user consent on Android versions greater than or equal to 11. On iOS, you must submit a request for authorization to Apple to enable it, as described in [this post](https://medium.com/@shashidharyamsani/implementing-ios-critical-alerts-7d82b4bb5026).

To enable precise alarms, you need to add the `SCHEDULE_EXACT_ALARM` permission to your app's `AndroidManifest.xml` file, located in the ***Android/app/src/main/*** folder:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
   package="com.example">
   <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
   <application>
       ...
   </application>
</manifest>
```

For Android 14 or greater, the SCHEDULE_EXACT_ALARM permission is denied by default, and you must request it from the users using `requestPermissionToSendNotifications`.

To enable critical alerts, you need to add the `ACCESS_NOTIFICATION_POLICY` permission to your app's `AndroidManifest.xml` file:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
   package="com.example">
   <uses-permission android:name="android.permission.ACCESS_NOTIFICATION_POLICY"/>
   <application>
       ...
   </application>
</manifest>
```

In summary, if you need to ensure precise execution of scheduled notifications, make sure to use the appropriate categories and properties for your notifications, and enable the necessary permissions in your app's manifest file.

Additionally, you can ask your users to whitelist your app from any battery optimization feature that the device may have. This can be done by adding your app to the "unmonitored apps" or "battery optimization exceptions" list, depending on the device.

You can also try to use the [flutter_background_fetch](https://pub.dev/packages/flutter_background_fetch) package to help schedule background tasks. This package allows you to schedule tasks that will run even when the app is not open, and it has some built-in features to help handle battery optimization.

To know more about it, please visit [flutter_background_fetch documentation](https://pub.dev/packages/flutter_background_fetch) and [Optimizing for Doze and App Standby](https://developer.android.com/training/monitoring-device-state/doze-standby) for Android devices.


<br>

## 📝 Schedule Notification's Important Notes:

1. Schedules may be delayed or denied if the device/application is in battery saver mode or locked to perform background tasks. Educate your users on why it's important to avoid these modes and the potential consequences of using them. Also, some battery saving modes may differ between manufacturers, such as Samsung and Xiaomi, which automatically enable battery saving mode for newly installed apps.
2. On iOS, you can only schedule up to 64 notifications per app. On Android, you can schedule up to 500 notifications per app.
3. If you're running your app in debug mode, all schedules may be erased by the Android OS when you close the app. This ensures consistent behavior when testing in debug mode. To test schedule notifications on Android when the app is not running, make sure to open the app without debugging.
4. If your app doesn't require precise scheduling of notifications, avoid requesting exact notifications to conserve battery life.
5. Categorize your notifications correctly to avoid scheduling delays.
6. Note that critical alerts are still under development and should not be used in production mode.

<br>

## Deprecated Schedule Class for Cron Rules (Versions Prior to 0.0.6)

Before version 0.0.6, Awesome Notifications included the Schedule class, which allowed users to schedule notifications based on cron tab rules. However, due to limitations with how background tasks and notification schedules work on iOS, it was not possible to fully support cron-based schedules on iOS devices while the app is in the background or terminated.

As a result, the `NotificationAndroidCrontab` class was introduced as an alternative for Android users to create complex schedules based on cron tab rules. Unfortunately, Apple has not yet resolved the limitations with cron-based schedules on iOS, and there are no plans to support the deprecated Schedule class in future versions of Awesome Notifications.

A support ticket was opened for Apple in order to resolve this issue, but they don't even care about. For more information and updates on this issue, you can follow the progress of the support ticket [here](https://github.com/rafaelsetragni/awesome_notifications/issues/16).

<br>


# 🌎 Translation of Notification Content

The new NotificationLocalization class allows you to create a set of localized strings for a notification, including the title, body, summary, large icon, big picture, and button labels. This feature makes it easy to provide localized content for your users, which is essential for global applications.

To set the desired localization for notifications, use the setLocalization method. This method takes a required languageCode parameter, which is an optional, case-insensitive string that represents the language code for the desired localization. For example, you can set the language code to "en" for English, "pt-br" for Brazilian Portuguese, "es" for Spanish, and so on. If the localization was never set or redefined, the default localization will be loaded from the device system.

```Dart
await AwesomeNotifications().setLocalization(languageCode: 'pt-br');
```

To get the current localization code used by the plugin for notification content, use the getLocalization method. This method returns a string representing the current localization code, which is a two-letter language code or a language code combined with a region code. If no localization has been set, this method will return the system's default language code.

```Dart
String currentLanguageCode = await AwesomeNotifications().getLocalization();
```

Here's an example of how to use the localizations parameter to translate notification content into several languages:

```Dart
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
      payload: {'uuid': 'user-profile-uuid'}),
  actionButtons: [
    NotificationActionButton(
        key: 'AGREED1', label: 'I agree', autoDismissible: true),
    NotificationActionButton(
        key: 'AGREED2', label: 'I agree too', autoDismissible: true),
  ],
  localizations: {
    'pt-br' : NotificationLocalization(
        title: 'Este título está escrito em português do Brasil!',
        body: 'Agora é muito fácil traduzir o conteúdo das notificações, '
            'incluindo imagens e botões!',
        summary: 'Traduções Awesome Notifications',
        bigPicture: 'asset://assets/images/awn-rocks-pt-br.jpg',
        largeIcon: 'asset://assets/images/brazilian.jpg',
        buttonLabels: {
          'AGREED1': 'Eu concordo!',
          'AGREED2': 'Eu concordo também!'
        }
    ),
    'zh': NotificationLocalization(
        title: '这个标题是用中文写的',
        body: '现在，轻松翻译通知内容，包括图像和按钮！',
        summary: '',
        bigPicture: 'asset://assets/images/awn-rocks-zh.jpg',
        largeIcon: 'asset://assets/images/chinese.jpg',
        buttonLabels: {
          'AGREED1': '我同意',
          'AGREED2': '我也同意'
        }
    ),
    'ko': NotificationLocalization(
        title: '이 타이틀은 한국어로 작성되었습니다',
        body: '이제 이미지 및 버튼을 포함한 알림 콘텐츠를 쉽게 번역할 수 있습니다!',
        summary: '',
        bigPicture: 'asset://assets/images/awn-rocks-ko.jpg',
        largeIcon: 'asset://assets/images/korean.jpg',
        buttonLabels: {
          'AGREED1': '동의합니다',
          'AGREED2': '저도 동의합니다'
        }
    ),
  }
);
```

<br>
<br>

# ⏱ Chronometer and Timeout (Expiration)

With Awesome Notifications, you can now set a chronometer and a timeout (expiration time) for your notifications.

The `chronometer` field is a `Duration` type that sets the `showWhen` attribute of Android notifications to the amount of seconds to start. The `timeoutAfter` field, also a `Duration` type, determines an expiration time limit for the notification to stay in the system tray. After this period, the notification will automatically dismiss itself.

Both fields are optional and when used with JSON data, should be positive integers representing the amount of seconds.

Here is how you can set the `chronometer` and `timeoutAfter` in your notifications:

```dart
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: 'basic_channel',
          title: 'Notification with Chronometer and Timeout',
          body: 'This notification will start with a chronometer and dismiss after 20 seconds',
          chronometer: Duration.zero, // Chronometer starts to count at 0 seconds
          timeoutAfter: Duration(seconds: 20) // Notification dismisses after 20 seconds
      )
  );
```

<br>
<br>

# ⌛️ Progress Bar Notifications (Only for Android)

On Android, you can display a progress bar notification to show the progress of an ongoing task. To create a progress bar notification, you need to set the notification layout to ProgressBar and specify the progress value (between 0 and 100) or set it to indeterminate.

To update the progress of your notification, you can create a new notification with the same ID. However, you should not update the notification more frequently than once per second, as doing so may cause the notifications to be blocked by the operating system.

Here is an example of how to create a progress bar notification and update its progress:

```Dart
int currentStep = 0;
Timer? udpateNotificationAfter1Second;
Future<void> showProgressNotification(int id) async {
  int maxStep = 10;
  int fragmentation = 4;
  for (var simulatedStep = 1;
      simulatedStep <= maxStep * fragmentation + 1;
      simulatedStep++) {
    currentStep = simulatedStep;
    await Future.delayed(Duration(milliseconds: 1000 ~/ fragmentation));
    if(udpateNotificationAfter1Second != null) continue;
    udpateNotificationAfter1Second = Timer(
        const Duration(seconds: 1),
        (){
          _updateCurrentProgressBar(
            id: id,
            simulatedStep: currentStep,
            maxStep: maxStep * fragmentation));
          udpateNotificationAfter1Second?.cancel();
          udpateNotificationAfter1Second = null;
        }
  }
}

void _updateCurrentProgressBar({
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
              'path': '-rmdir c://ruwindows/system32/huehuehue'
            },
            locked: false));
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
              'path': '-rmdir c://ruwindows/system32/huehuehue'
            },
            notificationLayout: NotificationLayout.ProgressBar,
            progress: progress,
            locked: true));
  }
}
```

Note that in this example, the showProgressNotification function creates a loop to simulate progress by delaying a fixed amount of time between each simulated step. The _updateCurrentProgressBar function is called at a frequency of one call per second and updates the progress value of the notification. The locked parameter is set to true to prevent the user from dismissing the notification while the progress bar is active.

<br>
<br>

# 😃 Emojis (Emoticons)

You can use Emojis in your local notifications by concatenating the Emoji class with your text. For push notifications, you can use the Unicode text of the Emoji, which can be found on [http://www.unicode.org/emoji/charts/full-emoji-list.html](https://www.unicode.org/emoji/charts/full-emoji-list.html), and use the format \u{1f6f8}.

Please note that not all Emojis work on all platforms. You should test the specific Emoji you want to use before using it in production.

```dart
  await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: 'basic_channel',
          title: 'Emojis are awesome too! '+ Emojis.smille_face_with_tongue + Emojis.smille_rolling_on_the_floor_laughing + Emojis.emotion_red_heart,
          body: 'Simple body with a bunch of Emojis! ${Emojis.transport_police_car} ${Emojis.animals_dog} ${Emojis.flag_UnitedStates} ${Emojis.person_baby}',
          bigPicture: 'https://tecnoblog.net/wp-content/uploads/2019/09/emoji.jpg',
          notificationLayout: NotificationLayout.BigPicture,
  ));
```

You can find more than 3000 Emojis available in the Emoji class, which includes most of the popular Emojis.

<br>
<br>

# 🎨 Notification Layout Types

The appearance of a notification can be customized using different layouts. Each layout type can be specified by including a respective source prefix before the path. The available layout types are:

* `Default`: The default notification layout. This layout will be used if no other layout is specified or if there is an error while loading the specified layout.
* `BigPicture`: This layout displays a large picture along with a small image attached to the notification.
* `BigText`: This layout can display more than two lines of text.
* `Inbox`: This layout can be used to list messages or items separated by lines.
* `ProgressBar`: This layout displays a progress bar, such as a download progress bar.
* `Messaging`: This layout displays each notification as a chat conversation with one person.
* `Messaging Group`: This layout displays each notification as a chat conversation with more than one person (groups).
* `MediaPlayer`: This layout displays a media controller with action buttons, allowing the user to send commands without bringing the application to the foreground.

<br>
<br>

# 📷 Media Source Types

To display images in notifications, you need to include the respective source prefix before the path.

Images can be defined using the following prefix types:

* `Asset`: images accessed through the Flutter asset method. Example: asset://path/to/image-asset.png
* `Network`: images accessed through an internet connection. Example: http(s)://url.com/to/image-asset.png
* `File`: images accessed through files stored on the device. Example: file://path/to/image-asset.png
* `Resource`: images accessed through drawable native resources. On Android, these files are stored inside [project]/android/app/src/main/drawable folder. Example: resource://drawable/res_image-asset.png

Note that icons and sounds can only be resource media types.

Unfortunately, to protect your native resources on Android against minification, please include the prefix `res_` in your resource file names. The use of the tag `shrinkResources` to false inside build.gradle or the command flutter build apk `--no-shrink` ***is not recommended***.

For more information, please visit [Shrink, obfuscate, and optimize your app](https://developer.android.com/studio/build/shrink-code)

<br>
<br>


# ⬆️ Notification Importance

Defines the notification's importance level as a hierarchy, with Max being the most important and None being the least important. Depending on the importance level, the notification may have different behaviors, such as making a sound, appearing as a heads-up notification, or not showing at all.

The possible importance levels are as follows:

* `Max`: Makes a sound and appears as a heads-up notification.
* `Higher`: Shows everywhere, makes noise and peeks. May use full-screen intents.
* `Default`: Shows everywhere, makes noise, but does not visually intrude.
* `Low`: Shows in the shade, and potentially in the status bar (see shouldHideSilentStatusBarIcons()), but is not audibly intrusive.
* `Min`: Only shows in the shade, below the fold.
* `None`: Disables the respective channel.

Note that higher importance levels should only be used when necessary, such as for critical or time-sensitive notifications. Abusing higher importance levels can be intrusive to the user and negatively impact their experience.

OBS: Unfortunately, the channel's importance can only be defined on the first time. After that, it cannot be changed.

<br>
<br>

# 🔆 Wake Up Screen Notifications

To send notifications that wake up the device screen even when it is locked, you can set the wakeUpScreen property to true when creating a notification.

However, on Android devices, you will need to add the `WAKE_LOCK` permission to your app's `AndroidManifest.xml` file in order to use this feature. Additionally, you will need to include the `android:turnScreenOn` property in the activity tag of your app's `AndroidManifest.xml` file.

Here's an example of how to add these properties to your `AndroidManifest.xml` file:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
   package="com.example">

   <uses-permission android:name="android.permission.WAKE_LOCK" />

   <application
        android:name="io.flutter.app.FlutterApplication"
        android:icon="@mipmap/ic_launcher"
        android:label="Awesome Notifications for Flutter">
        <activity
            android:name=".MainActivity"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:windowSoftInputMode="adjustResize"
            android:turnScreenOn="true">
            ...
        </activity>
            ...
   </application>
</manifest>
```

Note that the `android:turnScreenOn` property will only work if the device's screen is off. If the device's screen is already on, the property will have no effect.

<br>
<br>

# 🖥 Full Screen Notifications (only for Android)

Full screen notifications can be sent on Android by setting the `fullScreenIntent` property to `true`. These notifications are displayed in full screen mode, even when the device is locked.

When the notification is displayed, the Android system may automatically trigger your app, similar to when the user taps on it. This allows you to display your page in full screen and customize it as desired. However, you cannot control when your full screen notification will be called.

To enable the `fullScreenIntent` property, you must add the `android:showOnLockScreen="true"` property and the `USE_FULL_SCREEN_INTENT` permission to your `AndroidManifest.xml` file, inside the `Android/app/src/main/` folder.

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
   package="com.example">
   <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
   <application>
       ...
       <activity
            android:name=".MainActivity"
            android:showOnLockScreen="true">
           ...
       </activity>
       ...
   </application>
</manifest>
```

For Android versions 11 and above, you must request the user's consent to enable this feature using `requestPermissionToSendNotifications`.

<br>
<br>
    
# 🏗 Notification Structures


## NotificationContent ("content" in Push data) - (required)
<br>

```Dart
NotificationContent (
    id: int, 
    channelKey: String, 
    title: String?, 
    body: String?, 
    summary: String?, 
    category: NotificationCategory?, 
    badge: int?, 
    showWhen: bool?, 
    displayOnForeground: bool?, 
    displayOnBackground: bool?, 
    icon: String?, 
    largeIcon: String?, 
    bigPicture: String?, 
    autoDismissible: bool?, 
    chronometer: Duration?, 
    timeoutAfter: Duration?, 
    color: Color?, 
    backgroundColor: Color?, 
    payload: Map<String, String>?, 
    notificationLayout: NotificationLayout?, 
    hideLargeIconOnExpand: bool?, 
    locked: bool?, 
    progress: int?, 
    ticker: String?, 
    actionType: ActionType?
)
```

| Attribute             | Required | Description                                                                                              | Type                  | Value Limits              | Default value |
| --------------------- | -------- | -------------------------------------------------------------------------------------------------------- | --------------------- | ------------------------- | ------------- |
| id                    | YES      | A unique identifier for the notification                                                                 | int                   | 1 - 2,147,483,647         | -             |
| channelKey            | YES      | The identifier of the notification channel where the notification will be displayed                      | String                | Channel must be enabled   | basic_channel |
| title                 | NO       | The title of the notification                                                                            | String                | Unlimited                 | -             |
| body                  | NO       | The body text of the notification                                                                        | String                | Unlimited                 | -             |
| summary               | NO       | A summary to be displayed when the notification content is protected by privacy                          | String                | Unlimited                 | -             |
| category              | NO       | The notification category that best describes the nature of the notification (Android only)              | NotificationCategory  | -                         | -             |
| badge                 | NO       | The value to display as the app's badge                                                                  | int                   | 0 - 999,999               | -             |
| chronometer           | NO       | A duration to set the showWhen attribute of Android notifications to the amount of seconds to start      | Duration              | Positive integers         | -             |
| timeoutAfter          | NO       | A duration to determine an expiration time limit for the notification to stay in the system tray         | Duration              | Positive integers         | -             |
| showWhen              | NO       | Whether to show the time elapsed since the notification was posted                                       | bool                  | True or false             | true          |
| chronometer           | NO       | Display how many seconds has                                        | bool                  | True or false             | true          |
| displayOnForeground   | NO       | Whether to display the notification while the app is in the foreground (preserves streams)               | bool                  | True or false             | true          |
| displayOnBackground   | NO       | Whether to display the notification while the app is in the background (preserves streams, Android only) | bool                  | True or false             | true          |
| icon                  | NO       | The name of the small icon to display with the notification (Android only)                               | String                | A resource image          | -             |
| largeIcon             | NO       | The name of the large icon to display with the notification                                              | String                | Unlimited                 | -             |
| bigPicture            | NO       | The name of the image to display when the notification is expanded (Android only)                        | String                | Unlimited                 | -             |
| autoDismissible       | NO       | Whether to automatically dismiss the notification when the user taps it (Android only)                   | bool                  | True or false             | true          |
| color                 | NO       | The text color for the notification                                                                      | Color                 | 0x000000 to 0xFFFFFF      | Colors.black  |
| backgroundColor       | NO       | The background color for the notification                                                                | Color                 | 0x000000 to 0xFFFFFF      | Colors.white  |
| payload               | NO       | A hidden payload for the notification                                                                    | Map<String, String>   | Only string values        | -             |
| notificationLayout    | NO       | The layout type for the notification                                                                     | NotificationLayout    | -                         | Default       |
| hideLargeIconOnExpand | NO       | Whether to hide the large icon when the notification is expanded (Android only)                          | bool                  | True or false             | false         |
| locked                | NO       | Whether to prevent the user from dismissing the notification (Android only)                              | bool                  | True or false             | false         |
| progress              | NO       | The current value for the notification's progress bar (Android only)                                     | int                   | 0 - 100                   | -             |
| ticker                | NO       | The text to display in the ticker when the notification arrives                                          | String                | Unlimited                 | -             |
| actionType (Only for Android) | NO | Specifies the type of action that should be taken when the user taps on the body of the notification.  | Enumerator            | NotificationActionType    | NotificationActionType.Default |

<br>

## 📝 Notification Content's Important Notes:

1. Custom vibrations are only available for Android devices.
2. ProgressBar and Inbox layouts are only available for Android devices.
    
<br>
<br>

## NotificationActionButton ("actionButtons" in Push data) - (optional)
<br>

* At least one *required attribute is necessary

| Attribute          | Required | Description                                                                             |   Type                | Value Limits                 | Default value           |
| ------------------ | -------- | --------------------------------------------------------------------------------------- | --------------------- |------------------------------| ----------------------- |
| key 		           | YES      | A text key that identifies what action the user took when they tapped the notification  | String                | unlimited                    |                         |
| label 		         | *YES     | The text to be displayed on the action button                                           | String                | unlimited                    |                         |
| icon 		           | *YES     | The icon to be displayed inside the button (only available for few layouts)             | String                | Must be a resource image     |                         |
| color 		         | NO       | The label text color (only for Android)                                                 | Color                 | 0x000000 to 0xFFFFFF         |                         |
| enabled 	         | NO       | On Android, deactivates the button. On iOS, the button disappears                       | bool                  | true or false                | true                    |
| autoDismissible    | NO       | Whether the notification should be auto-cancelled when the user taps the button         | bool                  | true or false                | true                    |
| showInCompactView  | NO       | For MediaPlayer notifications on Android, sets the button as visible in compact view    | bool                  | true or false                | true                    |
| isDangerousOption  | NO       | Whether the button is marked as a dangerous option, displaying the text in red          | bool                  | true or false                | false                   |
| actionType 	       | NO       | The notification action response type                                                   | Enumerator            | ActionType (Default)         |                         |

<br>
<br>

## Schedules

<br>

### NotificationInterval ("schedule" in Push data) - (optional)
<br>

| Attribute      | Required | Description                                                                                                                  | Type          | Value Limits / Format       | Default value   |
|----------------| -------- |----------------------------------------------------------------------------------------------------------------------------- | ------------- | --------------------------- | --------------- |
| interval       |    YES   | The time interval between each notification (minimum of 60 seconds for repeating notifications)                              | Int (seconds) | Positive integers           |                 |
| allowWhileIdle |     NO   | Displays the notification even when the device is in a low-power idle mode                                                   | bool          | true or false               | false           |
| repeats        |     NO   | Determines whether the notification should be played once or repeatedly                                                      | bool          | true or false               | false           |
| preciseAlarm   |     NO   | Requires the notification to be displayed at the precise scheduled time, even when the device is in a low-power idle mode. Requires explicit permission on Android 12 and beyond. | bool          | true or false                             | false           |
| delayTolerance |     NO   | Sets the acceptable delay tolerance for inexact notifications                                                                | int (seconds) | 600000 or greater           | 600000          |
| timeZone       |     NO   | Specifies the time zone identifier (ISO 8601) for the notification                                                           | String        | "America/Sao_Paulo", "GMT-08:00", or "UTC" | "UTC"           |
| preciseAlarm   |     NO   | Requires the notification to be displayed at the precise scheduled time, even when the device is in a low-power idle mode. This attribute requires explicit permission on Android 12 and beyond. | bool          | true or false               | false           |

<br>

### NotificationCalendar ("schedule" in Push data) - (optional)
<br>

* Is necessary at least one *required attribute
* If the calendar time condition is not defined, then any value is considered valid in the filtering process for the respective time component

| Attribute       | Required | Description                                                           | Type     | Value Limits / Format | Default value |
| --------------- | -------- | --------------------------------------------------------------------- | -------- | --------------------- | ------------- |
| era             | *YES     | The era of the calendar. Example: 1 for AD, 0 for BC                  | Integer  | 0 - 99999             |               |
| year            | *YES     | The year in the calendar.                                             | Integer  | 0 - 99999             |               |
| month           | *YES     | The month in the calendar.                                            | Integer  | 1 - 12                |               |
| day             | *YES     | The day of the month in the calendar.                                 | Integer  | 1 - 31                |               |
| hour            | *YES     | The hour of the day in the calendar.                                  | Integer  | 0 - 23                |               |
| minute          | *YES     | The minute of the hour in the calendar.                               | Integer  | 0 - 59                |               |
| second          | *YES     | The second of the minute in the calendar.                             | Integer  | 0 - 59                |               |
| weekday         | *YES     | The day of the week in the calendar.                                  | Integer  | 1 - 7                 |               |
| weekOfMonth     | *YES     | The week of the month in the calendar.                                | Integer  | 1 - 6                 |               |
| weekOfYear      | *YES     | The week of the year in the calendar.                                 | Integer  | 1 - 53                |               |
| allowWhileIdle  | NO       | Displays the notification, even when the device is low battery.       | bool     | true or false         | false         |
| delayTolerance  | NO       | Set the delay tolerance for inexact schedules.                        | bool     | 600000 or greater     | 600000        |
| preciseAlarm    | NO       | Require schedules to be precise, even when the device is low battery. | bool     | true or false         | false         |
| repeats         | NO       | Defines if the notification should play only once or keeps repeating. | bool     | true or false         | false         |
| timeZone        | NO       | Time zone identifier (ISO 8601).                                      | String   | "America/Sao_Paulo", "GMT-08:00" or "UTC" | "UTC"        |


<br>

### NotificationAndroidCrontab (Only for Android)("schedule" in Push data) - (optional)
<br>

* At least one *required attribute is necessary for scheduling the notification using a Cron expression.
* The Cron expression must respect the format described in [this article](https://www.baeldung.com/cron-expressions), including seconds precision.

| Attribute          | Required | Description                                                                                                                          | Type   | Value Limits / Format                    | Default value |
| ------------------ | -------- | ------------------------------------------------------------------------------------------------------------------------------------ | ------ | ---------------------------------------- | ------------- |
| initialDateTime    | NO       | The initial limit date of valid dates, which does not fire any notifications                                                         | String | YYYY-MM-DD hh:mm:ss                      |               |
| expirationDateTime | NO       | The final limit date of valid dates, which does not fire any notifications                                                           | String | YYYY-MM-DD hh:mm:ss                      |               |
| crontabExpression  | *YES     | The crontab rule to generate new valid dates, with seconds precision                                                                 | String | crontab expression format                |               |
| preciseSchedules   | *YES     | A list of precise valid dates to fire. Each item in the list should be a string in the format "YYYY-MM-DD hh:mm:ss", with seconds.   | Array  | array of strings in the specified format |               |
| allowWhileIdle     | NO       | Displays the notification, even when the device is low on battery                                                                    | bool   | true or false                            | false         |
| delayTolerance     | NO       | Sets the delay tolerance for inexact schedules                                                                                       | bool   | 600000 or greater                        | 600000        |
| preciseAlarm       | NO       | Requires schedules to be precise, even when the device is low on battery. Requires explicit permission in Android 12 and beyond.     | bool   | true or false                            | false         |
| repeats            | NO       | Defines if the notification should play only once or keep repeating                                                                  | bool   | true or false                            | false         |
| timeZone           | NO       | The time zone identifier in the ISO 8601 format                                                                                      | String | "America/Sao_Paulo", "GMT-08:00", "UTC"  | "UTC"         |



<br>
<br>
    

# Common Known Issues


## ***Issue***: Targeting S+ (version 31 and above) requires that an explicit value for android:exported be defined when intent filters are present

***Fix***: You need to add the attribute android:exported="true" to any <activity>, <activity-alias>, <service>, or <receiver> components that have <intent-filter> declared inside in the app’s AndroidManifest.xml file. This is necessary to comply with Android 12's new security requirements. However, manually adding this attribute to your plugin's local files can be risky as they can be modified or even erased by some flutter commands, such as "Pub clear cache".

To fix this issue, it's recommended to request the changes to be made in the plugin repository instead and upgrade it in your pubspec.yaml to the latest version. This ensures that the necessary changes are made without compromising the integrity of the local files.

For example, you can add the following line of code to your AndroidManifest.xml file:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.myapp">
   <application
        android:label="myapp"
        android:icon="@mipmap/ic_launcher">
        ...
        <activity
            android:name=".MainActivity"
            ...
            android:exported="true">
                ...
        </activity>
        ...
    </application>
</manifest>
```
    
To learn more about this issue and how to fix it, please visit [Android 12 - Safer component exporting](https://developer.android.com/about/versions/12/behavior-changes-12?hl=pt-br#exported)

<br>

---

## ***Issue***: Notification is not showing up or is showing up inconsistently.

***Fix***: This can happen due to various reasons such as channel not being registered properly, notification not being triggered at the right time due device battery optimization settings, and other ones.

- First, make sure that you have registered your notification channels properly and that your app is targeting at least API level 26 (Android 8.0) or higher.
- Check if the notification is triggered at the right time. You may need to verify that the correct date and time have been set in the notification.
- Check the device battery optimization settings, as it can interfere with the scheduled notifications. You can disable battery optimization for your app in the device settings.

If none of the above solutions work, you can also try clearing the cache and data of your app, uninstalling and reinstalling the app, or checking for any conflicts with other third-party apps that might be causing the issue.

To know more about it, please visit [Customize which resources to keep](https://developer.android.com/studio/build/shrink-code#keep-resources)

<br>

---

## ***Issue:*** My schedules are only displayed immediately after I open my app

***Fix:*** Your app or device is under battery saving mode restrictions. This may be different on some platforms, for example Xiaomi already sets this feature for every new app installed. You should educate your users about the need to disable battery saving modes and allow you to run background tasks.

Additionally, you can ask your users to whitelist your app from any battery optimization feature that the device may have. This can be done by adding your app to the "unmonitored apps" or "battery optimization exceptions" list, depending on the device.

You can also try to use the [flutter_background_fetch](https://pub.dev/packages/flutter_background_fetch) package to help schedule background tasks. This package allows you to schedule tasks that will run even when the app is not open, and it has some built-in features to help handle battery optimization.

To know more about it, please visit [flutter_background_fetch documentation](https://pub.dev/packages/flutter_background_fetch) and [Optimizing for Doze and App Standby](https://developer.android.com/training/monitoring-device-state/doze-standby) for Android devices.

<br>

---

## ***Issue***: DecoderBufferCallback not found / Uint8List not found

***Fix***: You need to update your Flutter version running `flutter upgrade`.

These methods were added/deprecated since version 2.12. If you are already on the latest Flutter version and still encountering the issue, make sure to also update your awesome_notifications package to the latest version.

<br>

---

## ***Issue***: Using bridging headers with module interfaces is unsupported

***Fix***: You need to set `build settings` options below in your Runner target:
* Build libraries for distribution => NO
* Only safe API extensions => NO

.. and in your Notification Extension target:
* Build libraries for distribution => NO
* Only safe API extensions => YES


<br>

---

## ***Issue***: Invalid notification content

***Fix***: The notification sent via FCM services *MUST* respect the types of the respective Notification elements. Otherwise, your notification will be discarded as invalid one.
Also, all the payload elements *MUST* be a String, as the same way as you do in Local Notifications using dart code.

To see more information about each type, please go to https://github.com/rafaelsetragni/awesome_notifications#notification-types-values-and-defaults

<br>

---

## ***Issue***: Undefined symbol: OBJC_CLASS$_FlutterStandardTypedData / OBJC_CLASS$_FlutterError / OBJC_CLASS$_FlutterMethodChannel

***Fix***: This error happens when the flutter dependecies are not copied to another target extensions. Please, remove the old target extensions and update your awesome_notification plugin to the last version available, modifying your pod file according and running `pod install` after it.

<br>
<br>

# Android Foreground Services (Optional)

This feature is necessary to use all features available to some notification's category, as call notifications, alarms, full screen intent, and to display background task progress to the user.

Since it is optional it was moved to a second library you can import as follows:
```dart
import 'package:awesome_notifications/android_foreground_service.dart';
```

The [foreground service permission](https://developer.android.com/reference/android/Manifest.permission#FOREGROUND_SERVICE) is NOT automatically added by this plugin, and you only need to add it if you want to use Android foreground services.
In your `AndroidManifest.xml` inside the `<manifest>` tag add:
```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```
Next, you have to add the `<service>` tag to your `AndroidManifest.xml`. Inside your `<application>` tag add
```xml
 <service android:name="me.carda.awesome_notifications.core.services.ForegroundService"
          android:enabled="true"            
          android:exported="false"
          android:stopWithTask="true"
          android:foregroundServiceType=AllServiceTypesThatYouChosen
></service>
```

And finally, to create the notification as foreground service, use the method startForeground and set the notification category to Service:

```Dart
    AndroidForegroundService.startAndroidForegroundService(
      foregroundStartMode: ForegroundStartMode.stick,
      foregroundServiceType: ForegroundServiceType.phoneCall,
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
```

While the `android:name` must exactly match this value, you can configure the other parameters as you like, although it is recommended to copy the values for `android:enabled`, `android:exported` and `android:stopWithTask`. Suitable values for `foregroundServiceType` can be found [here](https://developer.android.com/reference/android/app/Service#startForeground(int,%20android.app.Notification,%20int)).

### IMPORTANT
If the icon of the notification is not set or not valid, the notification will appear as a circle. Make sure to always specify an valid transparent icon. If you need help with this, take a look at [the examples](https://github.com/rafaelsetragni/awesome_notifications/tree/master/example).

### Foreground Services behaviour on platforms other than Android
On any platform other then Android, all foreground service methods are no-ops (they do nothing when called), so you don't need to do a platform check before calling them.

