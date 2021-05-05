## [0.0.6+5]
* Added the behavior of bringing to the foreground for action buttons on iOS
* Added debug option on initialize method to lower the debug verbose if not necessary
* Leveled error messages and error handling for iOS and Android platforms
## [0.0.6+4]
* Added native firebase handling for willpresent notification method
* Added fixedDate to getNextDate on iOS
* Adjust weekday to work with ISO 8601
## [0.0.6+3]
* Fixed Android canceling for a grouped notification set as summary behaviour
* Added color hexadecimal representation for json content
## [0.0.6+2]
* Fixed Android first grouped message as summary behaviour.
## [0.0.6+1]
* Flutter version fixed, according to pub.dev warnings
## [0.0.6]
* Plugin upgraded to support dart Null Safety
* FCM service native support removed for iOS and Android.
* iOS awesome extensions removed.
* Schedule feature downgraded due to iOS official developer's incapacity and SO limitations (could be reactivated manually).
* Added an example to how to integrate awesome_notification with firebase_messaging plugin.
* Documentation improved
## [0.0.5+8]
* FCM service with comments removed for iOS.
## [0.0.5+7]
* Added removeChannel method for iOS and error messages for Android removeChannel method.
* ios project and example project recovered.
## [0.0.5+6]
* Releasing of final version with push notifications enabled.
* Added forceUpdate option on setChannel method, to allows to full update an channel on Android Oreo and above without need to reinstall the app, with the downside to close all current notifications.
* Flutter version updated to 3.0, with nullsafety support.
* Fixed privacy bugs
* Fixed grouping functionality and added sort option (sort only works for Android)
* Fixed media button errors for Android 10 and above
* Fixed media path errors for iOS
* Added default sound options for Ringtone, Alarm and Notifications.
* Documentation improved
## [0.0.5+5]
* Added the link to allows the community to remove or not the push notification functionality from Awesome Notifications plugin.
## [0.0.5+4]
* Added the icon field inside notification content package to allow to change the small icon without need to use another channel
* Included the example for locked notifications for Android and improved the locked priority behaviour
* Added importance level for notifications (Android 8 and above)
* Documentation improved
## [0.0.5+3]
* Internal firebase packages updated to the last Android and iOS version
* Fixed auto cancel off for schedule notifications (Android)
* Fixed action buttons for push notifications (iOS)
* Solution for DateUtils class conflict with the new Material "DateUtils" included on documentation
* Documentation improved
## [0.0.5+2]
* Included emojis to be used on local and push notifications
* Documentation improved
## [0.0.5+1]
* Included canceling capability to notification push service in cases of invalid notification
* iOS documentation improved
## [0.0.5]
* Finished FCM push messages for iOS 10 or higher
* Decreased the implementation complexity to use NotificationServiceExtension and NotificationContentExtension targets (iOS)
* Added two app examples on documentation as tutorials
* Improved the native resource decoder to work outside of main thread (Android)
* Included protect mode to native resources against obfuscation (Android)
* Improved object storage to work correctly with minification
* Documentation on README file updated

## [0.0.4+4]
* Improved error messages for notifications disabled in Android Devices
## [0.0.4+3]
* Fixing bug found at Android channel checking process (https://github.com/rafaelsetragni/awesome_notifications/issues/28)
## [0.0.4+2]
* Cleared log messages to decrease visual pollution.
* Replaced the native Java Log package by the Flutter's one.
* Fixed wrong "Invalid push notification content", wrongly showed when notification is successfully created.
## [0.0.4+1]
* Simplifying the iOS setup process for the developer (it's still a bit complex)
## [0.0.4]
* Fixed complex schedules for iOS apps running on Foreground
* Included Global Badge indicators for iOS and some Android distributions
* Included request permission and check permission methods
* Included Firebase support to send push notifications on iOS (work in progress)

## [0.0.3+3]
* Fixed Shader's render problems on iOS devices
## [0.0.3+2]
* Fixed UTC Dates on iOS devices
## [0.0.3+1]
* Adjusting the plugin content to pub.dev patterns
## [0.0.3]
* Documentation updated
* Included DismissedStream to capture dismissed notifications by the user
* Included iOS notification source code to enable send local notifications on iOS devices (still in development)
* Updated asset's load file method inside the java native code, due to flutter's 1.22 deprecation on "FlutterLoader.getInstance()"
* Extracted Bitmap class from bitmap package, due to buildGradle incompatibilities while running the project on release mode (Java)

## [0.0.2+2]
## [0.0.2+1]
* Documentation updated
## [0.0.2]
* Added precise schedules option to schedule a notification multiple times with precisely date and time

## [0.0.1+7]
## [0.0.1+6]
## [0.0.1+5]
* Documenting the code

## [0.0.1+4]
## [0.0.1+3]
## [0.0.1+2]
## [0.0.1+1]
* Adjusting the plugin content to pub.dev patterns

## [0.0.1]
* Initial release.
