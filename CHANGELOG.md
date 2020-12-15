## [0.0.5+3]
* Internal firebase packages updated to the last Android and iOS version
* Fixed auto cancel off for schedule notifications (Android)
* DateUtils class name changed to "DateUtil" to avoid conflict with new DateUtils Flutter Material class
* Improved documentation
## [0.0.5+2]
* Included emojis to be send on local and push notifications
* Improved documentation
## [0.0.5+1]
* Included canceling capability to notification push service in cases of invalid notification
* Improved iOS documentation
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
