<div align=center>

---

<img src="md-assets/banner.png" alt="Awesome Notifications">

---

![Built for Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Compatible%20with%20Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white)
[![Discord](https://img.shields.io/badge/Discord-%237289DA.svg?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/MP3sEXPTnx)
[![Open Source](https://img.shields.io/badge/Open%20Source-black.svg?style=for-the-badge&logo=Github)](https://github.com/rafaelsetragni/awesome_notifications)
[![Donate](https://img.shields.io/badge/Donate-white.svg?style=for-the-badge&logo=PayPal)](https://www.paypal.com/donate/?business=9BKB6ZCQLLMZY&no_recurring=0&item_name=Help+us+to+improve+and+maintain+Awesome+Notifications+with+donations+of+any+amount.&currency_code=USD)

[![Pub Version](https://img.shields.io/pub/v/awesome_notifications.svg?style=for-the-badge)](https://pub.dev/packages/awesome_notifications)
[![Pub Likes](https://img.shields.io/pub/likes/awesome_notifications.svg?style=for-the-badge)](https://pub.dev/packages/awesome_notifications/score)
[![Pub Points](https://img.shields.io/pub/points/awesome_notifications.svg?style=for-the-badge)](https://pub.dev/packages/awesome_notifications/score)
[![Pub Popularity](https://img.shields.io/pub/popularity/awesome_notifications.svg?style=for-the-badge)](https://pub.dev/packages/awesome_notifications/score)

#### Compatible with:
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-teal?style=for-the-badge&logo=ios&logoColor=white)
<!--
  Uncomment when this plugin supports Flutter Web 

![Flutter Web](https://img.shields.io/badge/Web-yellow.svg?style=for-the-badge&logo=Flutter&logoColor=white) 
-->

</div>

---
## Index
- [Introduction](#introduction)
  - [Features](#features)
  - [Disclamer](#disclamer)
  - [Support Us](#support-us)
- [Migration Guide](#migration-guide)
  - [from 0.6 to 0.7](#from-06-to-07)
- [Requirements](#requirements)
    - [Android](#android)
    - [iOS](#ios)
      - [Optional](#optional)
- [Setup](#setup)
- [Examples](#examples)
  - [Video Tutorial](#video-tutorial)
  - [Complete Example](#complete-example)
- [Behind the Scenes](#behind-the-scenes)
- [Understanding Awesome Notifications](#understading-awesome-notifications)
  - [Notification Permissions](#notification-permissions)
    - [Example](#here-is-a-sample-of-requesting-notification-permissions)
  - [Notification Categories](#notification-categories)

---
## Introduction

Awesome Notifications is a Flutter plugin that allows you to create local notifications for Android and iOS. 
You can also easily integrate push notification services, such as Firebase Cloud Messaging, with minimal effort.

We developed awesome_notifications with two things in mind: performance and simplicity. You should be able to implement reliable notifications without headaches, right from your Flutter source code.

This plugin helps you acheive picture-perfect notifications without bottlenecks, so you can do more with less boilerplate.

### Features

With Awesome Notifications, you can:
- Create awesome notifications for Android and iOS locally, or using other push notifications services;
- Customize the notification's title and body, images, buttons, icons and sounds;
- Use more notification layouts, such as 
    - Basic
    - Media
    - Inbox
    - Messaging
    - Progress Bar
    - Grouped
    - etc;
- Create notifications in any state of the app (foreground, background or terminated);
- Schedule notifications with high precision;
- Stop worrying about notifications not arriving on time to your users.

### Disclamer

This plugin is under construction, so there may be small issues, but most importantly more breaking changes than you would find in a stable one.
That said, any feedback is appreciated.

For the moment, this plugin only supports Android and iOS, but we plan supporting Web in the future. You can check out [our roadmap](#roadmap) for our next targets.

### Support Us

We're maintaining Awesome Notifications in our free time, so if you want to support us and help us maintaining our work, you can donate any amount on PayPal. Your donations will be used in purchasing new devices and equipment necessary for testing and maintaining Awesome Notifications, as well as our other plugins.

<a href="https://www.paypal.com/donate/?business=9BKB6ZCQLLMZY&no_recurring=0&item_name=Help+us+to+improve+and+maintain+Awesome+Notifications+with+donations+of+any+amount.&currency_code=USD">
  <img src="https://raw.githubusercontent.com/stefan-niedermann/paypal-donate-button/master/paypal-donate-button.png" alt="Donate with PayPal" width="200px"/>
</a>

---
## Migration Guide

Sometimes, improvements in performance, reliability or code refactoring may have some breaking changes, requiring users to change some bits of their code.

### From 0.6 to 0.7

1. Replace any `createdStream`, `displayedStream`, `dismissedStream` and `actionStream` with the new `AwesomeNotifications().setListeners`. Instead of listening to streams, now you provide global static methods that Awesome Notifications will use internally.

#### Before
```dart
AwesomeNotifications().actionStream.listen((receivedNotification) {
  // Here you had set up your own action when an event was received.
);
// Same goes for the other streams.
```

#### After
```dart
// Make your own NotificationController class based on the example provided below.

class NotificationController {
  /// Use this method to detect when a new notification or a schedule is created
  static Future <void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect every time that a new notification is displayed
  static Future <void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect if the user dismissed a notification
  static Future <void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    // Your code goes here
  }

  /// Use this method to detect when the user taps on a notification or action button
  static Future <void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    // Your code goes here
  }
}

// Then, later in your code, call `AwesomeNotifications().setListeners`.

AwesomeNotifications().setListeners(
    onActionReceivedMethod: NotificationController.onActionReceivedMethod,
    onNotificationCreatedMethod: NotificationController.onNotificationCreatedMethod,
    onNotificationDisplayedMethod: NotificationController.onNotificationDisplayedMethod,
    onDismissActionReceivedMethod: NotificationController.onDismissActionReceivedMethod,
);
```
For more context, please re-check out the [setup](#setup).

2. `ButtonType` is now called `ActionType`.
3. `ActionType.InputField` is deprecated. You can specify `requireInputText: true` in your `NotificationActionButton` to maintain the same functionality.

#### Before
```dart
NotificationActionButton(
  actionType: ActionType.InputField,
)
```

#### After
```dart
NotificationActionButton(
  requireTextInput: true,
)
```

4. Awesome Notifications no longer officially support `firebase_messaging`, as this plugin has pieces which make it conflict with Awesome Notifications. We will release a plugin named `awesome_notifications_fcm` that will replace `firebase_messaging`, improving upon the Firebase Cloud Messaging functionality. 
<br> If you were using `firebase_messaging` successfully, you can continue to do so.

---
## Requirements

As with any plugin that touches native code, we have to set a few requirements in order to ensure peak functionality.

### Android

Your Android app should have a `minSdkVersion` of API 21 (Android 5.0) and the `compileSdkVersion` of API 33 (Android 13). You can change these values from the `build.gradle` file inside android/app. More details can be found [here](https://stackoverflow.com/questions/5427195/how-to-change-the-minsdkversion-of-a-project).

Also, to make your app compatible with Android 12, you need to add `android:exported` to any `<activity>`, `<activity-alias>`, `<service>` or `<receiver>` component inside your app's `AndroidManifest.xml`. Make sure that the third party packages you are using in your project also support Android 12. More information on this change can be found [here](https://cafonsomota.medium.com/android-12-dont-forget-to-set-android-exported-on-your-activities-services-and-receivers-3bee33f37beb).

### iOS

The minimum required iOS version for your app should be `10`. You can change this value through Xcode in Project Runner (clicking on the app icon) > Info > Deployment Target and changing the option "ios minimum deployment target" to 10.0.

#### Optional: 

For using plugins in background actions, you need to manually register each plugin that you want to use, or else you will get `MissingPluginException`s. You can do this by registering the plugins inside your `didFinishLaunchingWithOptions` method inside your iOS project's `AppDelegate.m` / `AppDelegate.swift`.

Here's an example on how to register your plugins.

```swift
import Flutter
import awesome_notifications
import shared_preferences_ios
// Here you will import other plugins that you will want to use below.

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

If you don't know what your plugin is called, you can check `GeneratedPluginRegistrant.m`

---
## Setup

To show notifications, you need to set up the `awesome_notifications` plugin.

1. Add `awesome_notifications` to your Flutter project.
    - You can do this by running `flutter pub add awesome_notifications` at the root of your project.
2. Import the plugin in your Dart code:

```dart
import 'package:awesome_notifications/awesome_notifications.dart';
```

3. Initialize the plugin inside your main method, before `runApp()`

```dart
await AwesomeNotifications().initialize(
  // Replace 'ICON' with a resource from inside the app.
  'resource://drawable/ICON',
  [
    NotificationChannel(
      channelKey: 'basic',
      channelName: 'Basic Channel',
      channelDescription: 'This is a basic channel.',
    )
  ],
  debug: false, /* Tip: Setting debug to true will show supplimentary logs in case you encounter issues. */
  );
  // Set up Awesome Notifications before runApp.
runApp(
```

4. Create a `NotificationController` class that will handle notification interactions, based on the model provided below:

```dart
class NotificationController {
  /// Use this method to detect when a new notification or a schedule is created
  static Future <void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect every time that a new notification is displayed
  static Future <void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect if the user dismissed a notification
  static Future <void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    // Your code goes here
  }

  /// Use this method to detect when the user taps on a notification or action button
  static Future <void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    // Your code goes here
  }
}
```

5. Inside your app bind your NotificationController to the internal Awesome Notifications controller using `AwesomeNotifications().setListeners`. A recommended place would be inside the main method, after `AwesomeNotifications().initialize` but before `runApp`, but you can also choose `initState` of a high level custom `Widget`.

```dart
AwesomeNotifications().setListeners(
    onActionReceivedMethod: NotificationController.onActionReceivedMethod,
    onNotificationCreatedMethod: NotificationController.onNotificationCreatedMethod,
    onNotificationDisplayedMethod: NotificationController.onNotificationDisplayedMethod,
    onDismissActionReceivedMethod: NotificationController.onDismissActionReceivedMethod,
);
```
  - Note: You will receive notification events only after setting at least 1 notification listener.
  - Note: the example below **is not valid**, because it does not use static global methods, but instead it uses anonymous functions. If you wish to use any parameters, for example `BuildContext` if you use `Navigator`, you need to find other methods to accomplish your request. An example of a navigation without context implementation can be found [here](https://medium.com/flutter-community/navigate-without-context-in-flutter-with-a-navigation-service-e6d76e880c1c).

```dart
// This is wrong.
AwesomeNotifications().setListeners(
    onActionReceivedMethod: (ReceivedAction receivedAction){
        NotificationController.onActionReceivedMethod(context, receivedAction);
    },
    onNotificationCreatedMethod: (ReceivedNotification receivedNotification) {
        NotificationController.onNotificationCreatedMethod(context, receivedNotification);
    },
    onNotificationDisplayedMethod: (ReceivedNotification receivedNotification) {
        NotificationController.onNotificationDisplayedMethod(context, receivedNotification);
    },
    onDismissActionReceivedMethod: (ReceivedAction receivedAction) {
        NotificationController.onDismissActionReceivedMethod(context, receivedAction);
    },
);
```

6. Request the permission from the user to show local notifications, using `AwesomeNotifications().requestPermissionToSendNotifications()`. A preferred way of requesting this permission is with an in-app dialog, later in the app setup. You should make this request as friendly as possible, otherwise the user experience may be harmed, and some app stores will even remove your app for bad behavior. 
Here is an example on how to request this permission.

```dart
// This is a very simple example. Please make sure that you do not 
// harm the user experience, as described above.
AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
  if (!isAllowed) {
    AwesomeNotifications().requestPermissionToSendNotifications();
  }
});
```

7. When you are ready to send a notification, use `AwesomeNotifications().createNotification`.

```dart
AwesomeNotifications().createNotification(
  content: NotificationContent(
      id: 10,
      channelKey: 'basic', /* channel key set in step 3 */
      title: 'Simple Notification',
      body: 'Simple body',
      actionType: ActionType.Default
  )
);
```

---
## Examples

Here are some examples that you can check out to understand how to use Awesome Notifications.

### Video Tutorial

Ashley Novik from the [Reso Coder](https://resocoder.com) team did a great job showcasing a use-case for `awesome_notifications`. You can check out the tutorial below.

<iframe width="560" height="315" src="https://www.youtube.com/embed/JAq9fVn3X7U" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

### Complete Example

We have provided a complete example that includes the majority of use-cases for Awesome Notifications. It is available on GitHub, inside the `example` folder.

To run the examples locally, follow these steps:

- Clone `awesome_notifications` locally. We recommend using [GitHub Desktop](https://desktop.github.com).
- Open the example folder in your favorite IDE.
- Sync the project dependencies by running `flutter pub get`.
- If you want to run the app on iOS, make sure to also sync the native dependencies, by running `pod install`.
- Start debugging using `flutter run`.

---
## Frequently Asked Questions

**Q**: `Apps targeting Android 12 and higher are required to specify an explicit value for android:exported`.

A: Starting from Android 12, you must explicitly specify `android:exported` to any `<activity>`, `<activity-alias>`, `<service>` or `<receiver>` component inside your app's `AndroidManifest.xml`. Make sure that the third party packages you are using in your project also support Android 12. More information on this change can be found [here](https://cafonsomota.medium.com/android-12-dont-forget-to-set-android-exported-on-your-activities-services-and-receivers-3bee33f37beb).


**Q**: Awesome Notifications does not show my custom icon or sound in release mode on Android.

A: In release mode, Gradle shrinks and optimizes your app, so the unused resources will be deleted. Unfortunately, as Flutter is not native, Gradle does not know that those resources are being required inside your app, so they will not be included. An easy fix would be putting `res_` as a prefix to your file you want to keep. For example: `res_image.png`. It is absolutely *not recommended* to turn of shrinking via `build.gradle` or via the `--no-shrink` tag provided to your Flutter build command.


**Q**: While my app is in background mode, or terminated, notifications are successfully sent by Firebase Cloud Messaging, but my device does not display them.

A: The downside of `firebase_messaging` is that this plugin runs in background mode, conflicting with iOS' background execution rules. iOS will suspend Firebase's background activity indefinetly, so notifications will not always arrive on time. 

**Q**: So, because [x] depends on awesome_notifications and [y] from sdk, version solving failed. pub get failed.

A: We limit our dependencies to the latest stable release for production apps to not have issues like this, but sometimes, updating Flutter or other plugins may set dependencies constraints that `awesome_notifications` is not compatible with at the moment. You can create an issue about this and we will update our constraints to support the latest dependencies as soon as possible.


**Q**: I keep getting `Invalid notification content`.

A: Notifications sent via Firebase Cloud Messaging must respect the rules that Firebase imposes, such as field types, otherwise your notification will be discarded as invalid. A common mistake is setting fields in the payload that have a different type than String. You should only provide strings in the payload.


**Q**: `Undefined symbol: OBJC_CLASS$_FlutterStandardTypedData / OBJC_CLASS$_FlutterError / OBJC_CLASS$_FlutterMethodChannel`

A: Remove old target extensions and update `awesome_notifications` to the latest version available.

---
## Behind the Scenes

Awesome Notifications was created with simplicity in mind. Here is a graph that best describes this plugin's lifecycle.

![FlowChart](https://user-images.githubusercontent.com/40064496/155190796-eae6d442-2190-427b-bf28-dc470ea778de.png)

---
## Understading Awesome Notifications

### Notification Permissions

Permissions give transparency to the user on how you plan to use notifications. Every operating system is responsible for regulating these permissions.

While iOS is more restrictive and requires requesting all levels of permission, Android versions up to 13 have permitted notifications by default on any app the user installed. Starting with Android 13, users have to approve every time they install a new app if the app wants to send notifications. To learn more about Android 13's new Notification Permission Request, click [here](https://developer.android.com/develop/ui/views/notifications/notification-permission).

Please note that the notification permission can be approved and revoke anytime, that's why you need a flow that does not hurt the user experience. 

Notification permissions can be divided into 3 categories:

- Normal: Permissions that are not considered dangerous and do not require explicit user consent to be enabled.
- Execution: Permissions considered more sensible to the user experience and which require explicit user consent to be enabled.
- Special: Permissions that can harm the privacy and user experience of the user. Depending on the platform that you run on, you may need to request special permissions from the user, or request explicit permission from the manufacturer of the operating system itself.

In Awesome Notifications, we compiled a set of notification permissions that both suit Android, as well as iOS:

- Alert: High priority notifications that pop up on the user's screen (often called Heads up).
- Sound: Notifications that plays a sound when it's displayed. Note that the notification sounds are often limited to a few seconds to not harm the user experience.
- Badge: Notifications that are able to set a small badge on their icon, usually on the home screen, to inform a user that the app has unread notifications. Depending on the operating system implementations and on the user preferences, badges may be displayed with a number, or only with a dot.
- Light: Notifications that are able to light up a hardware light specific for notifying the user about new notifications being received. Only select Android devices have this ability.
- Vibration: Notifications that are able to vibrate the devices when they are being received, alerting the user that they received a notification.
- FullScreenIntent: Popup notifications that are shown even if the user is using another app. These notifications act like they have been clicked already, the app being opened in the foreground.
- PreciseAlarms: Notifications (often scheduled ones) that need to be displayed at the expected time. Note that manufacturers, as well as operating systems, can restrict the way these notifications are being received, for example in case the device has battery saving mode enabled, or if the device does not have sufficient resources to compute those notifications, things which have to be taken into consideration if you plan using these type of notifications. You can increase your chances by correctly selecting the notification category.
- CriticalAlert: Special permission that allows notifications to be displayed on the user's screen, as well as play a sound, even when the user is in Do not Disturb Mode, or in Silent mode. On iOS, you must request the authorization from Apple for your app to be able to use this mode.
- OverrideDnD: Allows you to decrease the Do not Disturb / Silent mode level to display critical alerts for Alarm and Call notifications. On Android, you must explicitly request the permission from the user, and on iOS this permission is bundled with CriticalAlert.
- Provisional: Notifications that are temporaily displayed without notifications permission. It only has effect on iOS.
- Car: Notifications that can be displayed while the device is in car mode.

Note that, if you don't manually input the wanted permissions in `requestPermissionToSendNotifications`, the default permissions requested are Alert, Badge, Sound, Vibrate and Light.

Notification permissions can be:

| Device level | App level | Channel level |
|-|-|-|
| Enable or Disable Notifications | Enable or Disable Notifications | Enable or Disable Notifications |
| Disable badges | Alerts | Badge |
| Disable sounds | Badges | Sound |
| | Sounds | Vibration |
| | Critical Alerts | Light
| | Override Do not Disturb | Full Intents |
| | | Critical Alerts |

Device level: Permissions set globally on the device by the manufacturer, applicable to any app installed on the device, like enable / disable all notifications, battery saving mode, do not disturb.
App level: Permissions requested by the app globally, applicable to any notification in any channel.
Channel level: Permissions set on a channel that only have effect on that channel.

#### Here is a sample of requesting notification permissions.

<details>
<summary>Click to expand.</summary>

```dart
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

</details>


### Notification Categories

<!-- To be continued... -->