## [0.7.7]
### Improved
* Enhanced versioning of iOS core libraries to better support DevOps, ensuring greater flexibility for future updates.

## [0.7.6]
### Added
* Integration with awesome_notifications_core to automatically manage versions
* Support for Android 14
### Improved
* Documentation updated

## [0.7.5]
### Added
* Full support for Flutter 3.13
* Support for iOS 17
* Compatibility with AGP 8 
* Automated tests for Dart code in master, with over 90% coverage
### Fixed
* New image provider for native resource media
### Improved
* Project dependencies upgraded to the latest version available
* Documentation updated

## [0.7.5-dev.3]
### Added
* Chronometer indicator for Android notifications
### Fixed
* Default app small icon fixed on Android
* New field timeoutAfter exposed on NotificationContentModel constructor
* Notification events changed to fire also for negative address
* Filters to separate meta data from payload on iOS pushes changed to ignore local notifications
* Order of recreation notification events changed on iOS to preserve expired lost events
### Improved
* iOS minimal deployment target decreased to 11
* TimeoutAfter modified to use Duration, instead of integer values to represent seconds

## [0.7.5-dev.2+1]
### Improved
* Android core dependencies moved to new repository 
* Added new native module switcher to avoid the folder copy at example/android folder.
* Added new test cases for actionType property 

## [0.7.5-dev.2]
### Fixed
* Replaces local references from development repositories to online versions
* Updates and improves documentation due new pub.dev requirements

## [0.7.5-dev.1]
### Added
* Added translation feature to notifications based on app configurations or custom configurations
* Added "AwnAppGroupName" property to "Info.plist" to support custom App Group names on iOS
* Added support for inexact schedules, allowing notifications to be scheduled at approximate times rather than exact times
* Added "delayTolerance" parameter to schedules to provide a tolerance for delayed notifications (in seconds)
* Added methods to API to list all active notification IDs and check if a notification ID is * * currently active
* Achieved 97.7% test coverage with new test cases for all relevant classes

### Improved
* SQLite database to replace SharedPreferences on Android
* Ability for displayed notification events to fire in the exact amount that they had displayed to the user, even with the same ID
* Example app with ReceivePort and SendPort

### Fixed
* schedule map conversions for interval notifications with repeat option on Android
* onCreated and onDisplayed calling events for Notification Target Extensions on iOS

## [0.7.4+1]
* Updates Discord markdown links on pub.dev
## [0.7.4]
* Adds single page example on pub.dev
* Fixes background action definition labels for iOS
* Fixes getInitialNotificationAction for larger projects with intense initial loading
* Ensures notifications with reply buttons do not close the status bar after sending text messages
* Updates and improves documentation
## [0.7.3]
* Adds badge parameter into notification's content to set the app badge value through notifications
* Adds deep merge method into MapUtils to allow notification content combinations
* Increases Flutter minimal version to 2.14 due to DecoderCallback deprecation
* Updates and improves documentation
## [0.7.2]
* Upgrades Media Style dependencies
## [0.7.1]
* Decreases Flutter SDK dependency from 2.18 to 2.12 to support old Flutter applications
* Adds switch imports for Dart:io and Dart:html to improve web support
* Updates Awesome web portal URLs
## [0.7.0+1]
* Updates iOS core dependency to version 0.7.1 to match FCM add-on plugin
## [0.7.0]
* Initial release of Awesome Notifications version 0.7.0
## [0.7.0-beta.7+6]
* Updates Android core dependency to 0.7.0-alpha.7+6
* Adds getInitialNotificationAction method
## [0.7.0-beta.7+5]
* Updates Android core dependency to 0.7.0-alpha.7+6
## [0.7.0-beta.7+4]
* Runs dart format over Lib to increase pub.dev score
## [0.7.0-beta.7+3]
* Decreases Dart support to support version 2.18.0.
* Replaces DecoderCallback with DecoderBufferCallback due to Flutter deprecation for resource images
## [0.7.0-beta.7+2]
* Makes modifications according to lint warnings to increase pub.dev score
## [0.7.0-beta.7+1]
* Fixes to change the plugin domain name
## [0.7.0-beta.7]
* Adds new Flutter plugin architecture to make it compatible with all available platforms
* Extracts Android and iOS core to be reused in remote repositories and other languages
## [0.7.0-beta.6+1]
* Includes the Donate with PayPal section
## [0.7.0-beta.6]
* Fixes out-of-sync definition values between Flutter, Android, and iOS
* Extends coverage to Android 13 (SDK 33), without the new request dialog (temporary)
## [0.7.0-beta.5]
* Fixes zero being saved instead of the actual handles for silent background actions
* Adds getLifeCycle function to return the current life cycle state of awesome notifications
* Adds optional value for payload data
## [0.7.0-beta.4]
* iOS notification actions improved to gain more performance and ensure the fast first opening
* iOS notification builder refactored to ensure the ios category creation before the notification being displayed
* iOS notification builder refactored to ensure the completion handle order for push notifications
* Fixes displayOnForeground e displayOnBackground for iOS
## [0.7.0-beta.3+2]
* Fixes empty title and body for messaging layout
* Removed Java cast warnings for cases where's a previous type checking.
## [0.7.0-beta.3+1]
* Fixes NotificationCalendar's inverted error "The time conditions are invalid"
* Documentation improved with new imports and observations with common found issues during beta phase
* Dart source code cleaned to improve pub points
## [0.7.0-beta.3]
* Coverage extended to Android 12L (SDK 32)
* All exceptions have been standardized with distinct exception codes to improve native error handling via PlatformException
* New exception catcher implemented to handle all native exceptions and provide better integration with Firebase Analytics.
* StopForeground method by id was Fixes on Android
* Message layout grouping Fixes (https://github.com/rafaelsetragni/awesome_notifications/pull/466)
* Background actions improved on iOS to hold long tasks
* Background actions improved on iOS to increase UI performance through background threads
* Adds console performance measures for iOS
* Adds warning messages for non implemented layouts on iOS
* Notification's payload attribute changed to support null values
* awesome_notifications_core package renamed to core to reduce import's path length
* Documentation improved
## [0.7.0-beta.2]
* AsyncTask replaced by Handler/Looper due deprecation in Android 12
* FULL_WAKE_LOCK replaced by SCREEN_BRIGHT_WAKE_LOCK to improve battery life in Android
* Implemented research by Android alarm intents to optimize the reschedule process
* Adds id helpers to improve the performance of ScheduleManger's cancellations process in almost 100 times
## [0.7.0-beta.1]
* Adds dart isolates to allow receiving background notifications without bring the app to foreground
* Adds silentBackground, silentBackgroundAction, disableAction and dismissAction action types for notifications and buttons
* InputField type deprecated, as now is possible to combine input buttons with all other action types. Now, to use InputField, please use the property requireInputText
* Internal architecture rewrote to decrease O.S. interventions, allowing to increase the performance while create and schedules notifications in almost 10 times
* Date objects replaced by Calendar type to enable real time zone operations in native layer
* Adds test unit cases to increase test coverage (55% coverage)
* Network images for foreground services are reactivated
* Upgraded external dependencies to become compatible with Flutter 2.10
## [0.6.21]
* Adds customSound feature for Android (only applicable for versions older than Android 8 (Oreo))
* Type parameter T removed from AwesomeAssertUtils to allows it to be compatible with Flutter web parser.
## [0.6.20]
* Adds rounded images for large icon and big picture
* Adds bool value extraction for Map objects in dart
* Fixes immutable error for input buttons in Android 12
* Network images for foreground services are temporarily disabled (https://github.com/rafaelsetragni/awesome_notifications/issues/369)
## [0.6.19]
* Adds sound extension for notifications with categories Alarm and Call
* Adds call notification behavior (stay floating on screen and keep playing the sound in loop) for Call category
* Adds CancellationManager to reorganize all dismiss and cancellation methods in a single place
* Created StatusBarManager to manage which notifications are currently active, improving performance and extending support to Android 5.0 Lollipop (SDK 21)
* Notification layouts BigPicture, Messaging and MessagingGroup improved to be more performative and to reuses network connection data
* Adds history box to notification's reply buttons on Android 8.0 to 12.0
* iOS swift completion handlers modified to allow display notifications from another plugins
## [0.6.18+2]
* Update readme file and PermissionManager to be compatible with Android 12 and Java 7
## [0.6.18+1]
* Java lambda expressions removed to turn Android source compatible with old Java 7
## [0.6.18]
* Adds Channel's Group feature for Android
* Adds notification's category feature for Android
* Adds fullScreenIntent permission and content option to allow to show notifications in full screen mode.
* Adds PreciseAlarms permission and schedule option to allow to show scheduled notifications with more precision.
* Adds showPage methods to provide shortcuts to channel permissions page and alarm permission page.
* Adds shouldShowRationale method for android to check if the requested permissions require user intervention to be enable.
* Adds request permissions methods to demand the users permissions considered dangerous by the system.
* Permission's request methods refactored to enable a more modular and scalable evolution to comport future permissions for Android
* Documentation has been improved with the new permissions methods, channel's group, notification categories, fullScreenIntent and PreciseAlarms permissions
## [0.6.17]
* Adds wakeUpScreen option in notification content to wake up screen when a notification is displayed (Requires to add WAKE_LOCK permission into AndroidManifest.xml).
* Adds custom permissions for method requestPermissionToSendNotifications (has no effect on Android).
* Documentation has been improved with wakeUpScreen option
## [0.6.16]
* Media button receiver removed from AndroidManifest.xml due incompatibility with some Galaxy models and another plugins (#81 and #320)
* Documentation on scheduling notifications has been improved
## [0.6.15]
* PushNotification class deprecated, as all push features are being moved to the new companion plugin. Instead, use NotificationModel.
* Adds isDangerousOption for action buttons, to color the text in red to indicate a dangerous option for the user.
* Adds color option for action buttons, to color the text in Android 8.0 Oreo and beyond (has no effect on iOS).
* Fixes for issue #321, when a new notification is erroneously created when the user taps on notification action button.
## [0.6.14]
* Adds validation to prevent scheduling with repeating intervals smaller than 60 seconds (iOS restriction)
* Adds crontab schedule to allow complex schedules based on initial and expiration date, a list of precise dates, or a crontab expression, and all four options can be combined together (only for Android)
* Defined the final standard to replace negative IDs by random values
* Minimum Android requirements increased to SDK 23 (Android 6.0 Marshmallow) due to new cancellation methods with unsecure procedures on API prior 23
## [0.6.13]
* Adds messaging layout and messaging group layout
* Adds method showNotificationPage to programmatically redirect the user to O.S. notifications permission page
* Minimum Android requirements increased to SDK 21 (Android 5.0 Lollipop) due to new cancellation methods
* Adds new cancellation methods (dismiss, cancel schedules and cancel all (dismiss and schedules at same time))) based on group key or channel key
* Property "autoCancel" changed to "autoDismissable", to match the new cancellation methods naming principles
* Adds internal group key based on ID, to prevent Android auto grouping with 4+ notification from same channel when group key was not specified
* Android channels refactored to keep the original channel key at maximum as possible, maximizing the compatibility with another plugins.
* Models refactored to follow the native standards and transformations from map data
* Calendar millisecond precision has been deprecated, due devices do not provide or ignore such precision.
* Adds error handling for image assets (iOS)
* Adds video tutorial into README file
* Version numbering has changed to better translate the stage of development for future releases.
## [0.0.6+12]
* Adds showInCompactView property for MediaPlayer buttons
* Adds support to multiple subscriptions on created, displayed, action and dismissed stream
* Removed channel key from Android Badge methods, because the segregation in channel keys was never used (now is all global)
* Adds increment and decrement badge methods (more performative)
## [0.0.6+11]
* Fix Android reschedules on startup process (issue #285)
* Improved Android channels to manage another package channels and convert then to the new standard, using channelKey as hashKey produced from digest channel content
## [0.0.6+10]
* Adds foreground services for Android
* Fixes android reference for guava package
## [0.0.6+9]
* Fixes null reference for main class inside NotificationBuilder.java
## [0.0.6+8]
* Fixes null reference for main class
## [0.0.6+7]
* Improves documentation
* Updates push notifications in the example app
## [0.0.6+6]
* Adds time zones for scheduled notifications
* Adds foreground behavior for input button
* Adds dismiss methods to dismiss the notifications without cancel their respective schedules
## [0.0.6+5]
* Adds behavior of bringing action buttons to foreground on iOS
* Adds debug option on initialize method to lower debug verbosity if not necessary
* Improves error messages and error handling for iOS and Android platforms
## [0.0.6+4]
* Adds native firebase handling for will present notification method
* Adds fixedDate to getNextDate on iOS
* Adds .aiff example files with more quality
* Adjust weekday to work with ISO 8601
## [0.0.6+3]
* Fixes Android canceling for a grouped notification set as summary behaviour
* Adds color hexadecimal representation for json content
## [0.0.6+2]
* Fixes Android first grouped message as summary behaviour.
## [0.0.6+1]
* Flutter version Fixes, according to pub.dev warnings
## [0.0.6]
* Plugin upgraded to support dart Null Safety
* FCM service native support removed for iOS and Android.
* iOS awesome extensions removed.
* Schedule feature downgraded due to iOS official developer's incapacity and SO limitations (could be reactivated manually).
* Adds an example to how to integrate awesome_notification with firebase_messaging plugin.
* Documentation improved
## [0.0.5+8]
* FCM service with comments removed for iOS.
## [0.0.5+7]
* Adds removeChannel method for iOS and error messages for Android removeChannel method.
* ios project and example project recovered.
## [0.0.5+6]
* Releasing of final version with push notifications enabled.
* Adds forceUpdate option on setChannel method, to allows to full update an channel on Android Oreo and above without need to reinstall the app, with the downside to close all current notifications.
* Flutter version updated to 3.0, with null safety support.
* Fixes privacy bugs
* Fixes grouping functionality and Adds sort option (sort only works for Android)
* Fixes media button errors for Android 10 and above
* Fixes media path errors for iOS
* Adds default sound options for Ringtone, Alarm and Notifications.
* Documentation improved
## [0.0.5+5]
* Adds the link to allows the community to remove or not the push notification functionality from Awesome Notifications plugin.
## [0.0.5+4]
* Adds the icon field inside notification content package to allow to change the small icon without need to use another channel
* Included the example for locked notifications for Android and improved the locked priority behaviour
* Adds importance level for notifications (Android 8 and above)
* Documentation improved
## [0.0.5+3]
* Internal firebase packages updated to the last Android and iOS version
* Fixes auto cancel off for schedule notifications (Android)
* Fixes action buttons for push notifications (iOS)
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
* Adds two app examples on documentation as tutorials
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
* Fixes wrong "Invalid push notification content", wrongly showed when notification is successfully created.
## [0.0.4+1]
* Simplifying the iOS setup process for the developer (it's still a bit complex)
## [0.0.4]
* Fixes complex schedules for iOS apps running on Foreground
* Included Global Badge indicators for iOS and some Android distributions
* Included request permission and check permission methods
* Included Firebase support to send push notifications on iOS (work in progress)

## [0.0.3+3]
* Fixes Shader's render problems on iOS devices
## [0.0.3+2]
* Fixes UTC Dates on iOS devices
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
* Adds precise schedules option to schedule a notification multiple times with precisely date and time

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