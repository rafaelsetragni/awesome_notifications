---
title: Extra iOS Setup for Background Actions
# description: Quidem magni aut exercitationem maxime rerum eos.
---

On iOS, to use any plugin inside background actions, you will need to manually register each plugin you want. Otherwise, you will face the `MissingPluginException` exception.
To avoid this, you need to add the following lines to the `didFinishLaunchingWithOptions` method in your iOS project's AppDelegate.m/AppDelegate.swift file:

```swift
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

And you can check how to correctly call each plugin opening the file `GeneratedPluginRegistrant.m`

---

# 📱 Example Apps

With the examples bellow, you can check all the features and how to use the Awesome Notifications in pratice. The Simple Example app contains the basic structure to use Awesome Notifications, and the Complete Example App contains all Awesome Notification features to test.

To run and debug the Simple Example App, follow the steps bellow:

1. Create a new Flutter project with at least Android and iOS
2. Copy the example content at https://pub.dev/packages/awesome_notifications/example
3. Paste the content inside the `main.dart` file
4. Debug the application with a real device or emulator

To run and debug the Complete Example App, follow the steps bellow:

1. Install GitHub software in your local machine. I strongly recommend to use [GitHub Desktop](https://desktop.github.com/).
2. Go to one of our GitHub repositories
3. Clone the project to your local machine
4. Open the project with Android Studio or any other IDE
5. Sync the project dependencies running `flutter pub get`
6. On iOS, run `pod install` inside the folder _example/ios/_ to sync the native dependencies
7. Debug the application with a real device or emulator
