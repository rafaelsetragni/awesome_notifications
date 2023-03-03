import 'dart:typed_data';

import 'package:awesome_notifications/src/models/notification_localization.dart';

import 'awesome_notifications.dart';

abstract class IAwesomeNotifications {
  /// DISPOSE METHODS *********************************************

  dispose();

  /// Initializes the plugin by creating a default icon and setting up the initial
  /// notification channels. This method only needs to be called once in the
  /// `main.dart` file of your application.
  ///
  /// The [defaultIcon] parameter specifies the resource media type of the default
  /// icon that will be used for notifications. This should be a `String`
  /// representing the resource name.
  ///
  /// The [channels] parameter is a list of [NotificationChannel] objects that
  /// represent the initial notification channels to be created. If any of the
  /// channels already exist, they will be updated with the provided information.
  ///
  /// The optional [channelGroups] parameter is a list of [NotificationChannelGroup]
  /// objects that are used to organize the channels visually in Android's
  /// notification configuration page.
  ///
  /// The optional [debug] parameter enables verbose logging in Awesome
  /// Notifications.
  ///
  /// The optional [languageCode] parameter is a `String` that represents the
  /// localization code for translating notification content. If specified, this
  /// code will be used to translate notification titles, bodies, and other
  /// contents into the appropriate language.
  ///
  /// This method returns a [Future] that resolves to `true` if the initialization
  /// was successful, or `false` if an error occurred.
  Future<bool> initialize(
      String? defaultIcon, List<NotificationChannel> channels,
      {
        List<NotificationChannelGroup>? channelGroups,
        bool debug = false,
        String? languageCode,
      });

  /// Defines the global or static methods that will receive notification events.
  /// Only after set at least one method, the notification's events will be delivered.
  /// These methods require to use the notation @pragma("vm:entry-point")
  ///
  /// The [onActionReceivedMethod] parameter is a function that receives all the
  /// notification actions that are triggered by the user.
  ///
  /// The optional [onNotificationCreatedMethod] parameter is a function that is
  /// called when a new notification or schedule is created on the system.
  ///
  /// The optional [onNotificationDisplayedMethod] parameter is a function that is
  /// called when a new notification is displayed on the status bar.
  ///
  /// The optional [onDismissActionReceivedMethod] parameter is a function that
  /// receives the notification dismiss actions.
  ///
  /// This method returns a [Future] that resolves to `true` if the listeners were
  /// successfully set, or `false` if an error occurred.
  Future<bool> setListeners(
      {required ActionHandler onActionReceivedMethod,
      NotificationHandler? onNotificationCreatedMethod,
      NotificationHandler? onNotificationDisplayedMethod,
      ActionHandler? onDismissActionReceivedMethod});

  /// NATIVE MEDIA METHODS *********************************************

  /// Decodes a native drawable resource into a [Uint8List] that can be used by
  /// Flutter widgets.
  ///
  /// The [drawablePath] parameter is a [String] that represents the path to the
  /// drawable resource.
  ///
  /// This method returns a [Future] that resolves to a [Uint8List] containing the
  /// decoded data, or `null` if an error occurred.
  ///
  /// This method is typically used to load native drawable resources, such as
  /// notification icons and images, and convert them into a format that can be used by
  /// Flutter widgets. The decoded data can then be used to create a [MemoryImage],
  /// which can be used as the image source for a [CircleAvatar], [Image], or
  /// other widget that accepts an [ImageProvider].
  Future<Uint8List?> getDrawableData(String drawablePath);

  /// LOCAL NOTIFICATION METHODS *********************************************

  /// Creates a new notification with the specified content.
  ///
  /// The [content] parameter is a [NotificationContent] object that represents
  /// the content of the notification, including the title, body, icon, and other
  /// details.
  ///
  /// The optional [schedule] parameter is a [NotificationSchedule] object that
  /// specifies when the notification should be delivered.
  ///
  /// The optional [actionButtons] parameter is a list of
  /// [NotificationActionButton] objects that represent the action buttons to be
  /// displayed on the notification.
  ///
  /// The optional [localizations] parameter is a [Map] of
  /// [NotificationLocalization] objects that represent the localized content of
  /// the notification, such as the title and body text in different languages.
  ///
  /// This method returns a [Future] that resolves to `true` if the notification
  /// was successfully created, or `false` if an error occurred.
  ///
  /// If the notification has no [body] or [title], it will be created but not
  /// displayed (i.e. it will be a "background" notification).
  ///
  /// This method is typically used to create a new notification with the
  /// specified content and delivery schedule. If an action button or buttons are
  /// provided, they will be displayed on the notification to allow the user to
  /// take specific actions in response to the notification.
  ///
  /// The [localizations] parameter can be used to provide localized versions of
  /// the notification content, such as the title and body text in different
  /// languages. To provide localized content, create a [NotificationLocalization]
  /// object for each language, and include them in a [Map] that maps the language
  /// codes as keys (e.g. "en", "pt-br", "es", etc.) to their corresponding localizations.
  /// When the notification is displayed, the appropriate localization will be selected
  /// based on the user's language preferences or the default system language.
  Future<bool> createNotification({
    required NotificationContent content,
    NotificationSchedule? schedule,
    List<NotificationActionButton>? actionButtons,
    Map<String, NotificationLocalization>? localizations,
  });

  /// Creates a new notification based on a map that is similar to the map
  /// produced by the `toMap()` method of a [NotificationModel] object.
  ///
  /// The [mapData] parameter is a [Map] that represents the model of the
  /// notification, including the content, schedule, buttons, and localizations.
  ///
  /// This method returns a [Future] that resolves to `true` if the notification
  /// was successfully created, or `false` if an error occurred.
  ///
  /// This method is typically used to recreate a notification from data that was
  /// previously saved or transmitted in a different format, such as JSON.
  /// To use this method, you must first create a [Map] of the notification data,
  /// using a format that is similar to the output of the `toMap()` method of a
  /// [NotificationModel] object. Then, pass this map to the
  /// `createNotificationFromJsonData()` method to create the notification.
  Future<bool> createNotificationFromJsonData(Map<String, dynamic> mapData);

  /// Gets the notification action that launched the app, if any.
  ///
  /// This method returns a [Future] that resolves to a [ReceivedAction] object
  /// if the app was launched by a notification action, or `null` if it wasn't.
  ///
  /// The optional [removeFromActionEvents] parameter is a boolean value that
  /// indicates whether the same action should be prevented from being delivered
  /// in the `onActionMethod()` function, in case it hasn't already happened.
  ///
  /// This method does not depend on the `setListeners()` method being called
  /// first, and can be used to retrieve the initial notification action even
  /// before the app is fully initialized.
  ///
  /// To prevent any delay in application initialization, you can use a timeout
  /// with the returned [Future] to specify a maximum duration for the method to
  /// wait for the initial notification action. If no action is received within
  /// the timeout duration, the [Future] will resolve to `null`. For example:
  ///
  /// ```dart
  /// final initialAction = await getInitialNotificationAction()
  ///     .timeout(Duration(seconds: 5));
  /// ```
  Future<ReceivedAction?> getInitialNotificationAction({
    bool removeFromActionEvents = false,
  });

  /// Opens the notification configuration page for the app.
  ///
  /// The optional [channelKey] parameter is a [String] that represents the key
  /// of the notification channel for which to show the configuration page. If
  /// this parameter is omitted, the page for the default notification channel
  /// will be shown.
  ///
  /// This method returns a [Future] that resolves when the notification
  /// configuration page was opened. The user can then configure the notification
  /// settings for the app, such as disabling or enabling notifications, changing
  /// the notification sound or vibration pattern, and so on.
  ///
  /// On iOS, as there is no channels specification page, it always open the
  /// default configuration page.
  ///
  /// This method can be used to provide a way for users to easily access and
  /// manage the notification settings for your app. For example, you might
  /// open this pages in case you need to require the user a special notification
  /// feature activated, or add a button to your app's settings page that calls
  /// this method when tapped, or include a prompt in your app to encourage users
  /// to visit the notification settings page to enable notifications.
  Future<void> showNotificationConfigPage({String? channelKey});

  /// Opens the system's notifications settings page for the app's alarms.
  ///
  /// This method returns a [Future] that resolves when the notification
  /// settings page is opened. The user can then configure the alarm settings
  /// for the app, such as setting a custom alarm sound, enabling or disabling
  /// alarms, and so on.
  ///
  /// This method can be used to provide a way for users to easily access and
  /// manage the alarm settings for your app. For example, you might add a button
  /// to your app's settings page that calls this method when tapped, or include
  /// a prompt in your app to encourage users to visit the alarm settings page to
  /// configure their alarms.
  Future<void> showAlarmPage();

  /// Opens the system settings page for overriding device Do Not Disturb mode.
  ///
  /// This method returns a [Future] that resolves when the system settings page
  /// is opened. The user can then configure the app's behavior during Do Not
  /// Disturb mode to play sounds and vibrate even if the app is in silent mode.
  ///
  /// On Android, this method opens the relevant system settings page directly.
  ///
  /// On iOS this requires additional setup and permission from Apple, and is
  /// not enabled by default.
  /// If your app has been granted permission to override Do Not Disturb mode on
  /// iOS, calling this method will open the relevant system settings page. If
  /// your app has not been granted permission, calling this method has no
  /// effect and DnD modes will prevent your notification to play sounds and vibrates.
  ///
  /// This method can be used to provide a way for users to easily access and
  /// manage the Do Not Disturb settings for your app. For example, you might add
  /// a button to your app's settings page that calls this method when tapped, or
  /// include a prompt in your app to encourage users to visit the Do Not Disturb
  /// settings page to configure their preferences.
  Future<void> showGlobalDndOverridePage();

  /// Checks whether notifications are currently allowed globally on the device.
  ///
  /// This method returns a [Future] that resolves to a [bool] value indicating
  /// whether notifications are allowed or not. If notifications are allowed,
  /// the value will be `true`. If notifications are not allowed, the value will
  /// be `false`.
  ///
  /// This method can be used to check whether the user has globally disabled
  /// notifications for the app. If notifications are not allowed, you can use
  /// the `showNotificationConfigPage()` method to prompt the user to enable
  /// notifications for the app.
  Future<bool> isNotificationAllowed();

  /// Checks whether a notification with the specified ID is currently active on the device's status bar.
  ///
  /// This method takes an integer id argument representing the ID of the notification
  /// to be checked. It returns a [Future] that resolves to a [bool] value indicating
  /// whether the specified notification is currently active on the device's status bar.
  /// If the notification is active, the value will be true. If the notification is
  /// not active, the value will be false.
  ///
  /// This method can be used to check whether a specific notification is currently being
  /// displayed on the device's status bar. If the notification is not active, you may want
  /// to take appropriate action, such as re-creating the notification or displaying a message
  /// to the user.
  ///
  /// Note: In order to use this method, you need to have the appropriate permissions
  /// set in your AndroidManifest.xml file. Specifically, you need to have the
  /// [android.permission.ACCESS_NOTIFICATION_POLICY] permission declared in your manifest
  /// in order to access the device's notification policy.
  Future<bool> isNotificationActiveOnStatusBar({
    required int id
  });

  Future<List<int>> getAllActiveNotificationIdsOnStatusBar();

  /// Requests permission from the user to send notifications from the app.
  ///
  /// The optional [channelKey] parameter is a [String] that represents the key
  /// of the notification channel for which to request permission. If this
  /// parameter is omitted, the permission will be set for all channels.
  ///
  /// The optional [permissions] parameter is a list of
  /// [NotificationPermission] values that the app requests permission to use.
  /// This parameter is optional and defaults to a list of permissions that
  /// are commonly requested by apps, including [NotificationPermission.Alert],
  /// [NotificationPermission.Sound], [NotificationPermission.Badge],
  /// [NotificationPermission.Vibration], and [NotificationPermission.Light].
  ///
  /// Some permissions may require explicit authorization from the user, such
  /// as the [NotificationPermission.Sound] permission on iOS. Other permissions
  /// may be granted automatically without user intervention. If a permission
  /// requires explicit authorization, this method will try to show the
  /// permission dialog without leaving the app. If the user has denied the
  /// permission too many times previously, and the permission dialog is not
  /// available, the user will be redirected to the app's notification settings
  /// to manually grant the permission.
  ///
  /// This method returns a [Future] that resolves to a [bool] value indicating
  /// whether the permission was granted or not. If the user grants the
  /// permission, the value will be `true`. If the user denies the permission the
  /// value will be `false`.
  ///
  /// In case the user is redirected to the app's notification settings to grant the
  /// permission, the future will wait until the user returns to app in foreground.
  Future<bool> requestPermissionToSendNotifications(
      {String? channelKey,
      List<NotificationPermission> permissions = const [
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Badge,
        NotificationPermission.Vibration,
        NotificationPermission.Light,
      ]});

  /// Checks which notification permissions have been granted to the app.
  ///
  /// The optional [channelKey] parameter is a [String] that represents the key
  /// of the notification channel for which to check permissions. If this
  /// parameter is omitted, permissions will be checked for all channels.
  ///
  /// The optional [permissions] parameter is a list of
  /// [NotificationPermission] values to check. This parameter is optional and
  /// defaults to a list of permissions that are commonly requested by apps,
  /// including [NotificationPermission.Alert], [NotificationPermission.Sound],
  /// [NotificationPermission.Badge], [NotificationPermission.Vibration], and
  /// [NotificationPermission.Light].
  ///
  /// This method returns a [Future] that resolves to a list of
  /// [NotificationPermission] values indicating which permissions have been
  /// granted to the app. If a permission has been granted, it will be included
  /// in the list. If a permission has not been granted, it will not be included
  /// in the list.
  ///
  /// This method can be used to check which notification permissions have been
  /// granted by the user, so that the app can adjust its behavior accordingly.
  Future<List<NotificationPermission>> checkPermissionList({
    String? channelKey,
    List<NotificationPermission> permissions = const [
      NotificationPermission.Badge,
      NotificationPermission.Alert,
      NotificationPermission.Sound,
      NotificationPermission.Vibration,
      NotificationPermission.Light
    ],
  });

  /// Checks whether the app should show a rationale to the user before requesting
  /// notification permissions.
  ///
  /// The optional [channelKey] parameter is a [String] that represents the key
  /// of the notification channel for which to check permissions. If this
  /// parameter is omitted, permissions will be checked for all channels.
  ///
  /// The optional [permissions] parameter is a list of
  /// [NotificationPermission] values to check. This parameter is optional and
  /// defaults to a list of permissions that are commonly requested by apps,
  /// including [NotificationPermission.Alert], [NotificationPermission.Sound],
  /// [NotificationPermission.Badge], [NotificationPermission.Vibration], and
  /// [NotificationPermission.Light].
  ///
  /// This method returns a [Future] that resolves to a list of
  /// [NotificationPermission] values indicating which permissions require user
  /// intervention in order to be granted. If a permission requires user
  /// intervention, it will be included in the list. If a permission does not
  /// require user intervention, it will not be included in the list. If no
  /// permissions require user intervention, the list will be empty.
  ///
  /// This method can be used to check whether the app should show a rationale to
  /// the user before requesting notification permissions. If any permissions
  /// require user intervention, the app should show a rationale to the user
  /// explaining why the permission is needed before requesting it.
  Future<List<NotificationPermission>> shouldShowRationaleToRequest({
    String? channelKey,
    List<NotificationPermission> permissions = const [
      NotificationPermission.Badge,
      NotificationPermission.Alert,
      NotificationPermission.Sound,
      NotificationPermission.Vibration,
      NotificationPermission.Light
    ],
  });

  /// Lists all active scheduled notifications.
  ///
  /// This method returns a [Future] that resolves to a list of
  /// [NotificationModel] objects representing all active scheduled
  /// notifications. If there are no active scheduled notifications, the list
  /// will be empty.
  ///
  /// This method can be used to get a list of all scheduled notifications in
  /// order to display them to the user or to cancel them programmatically.
  Future<List<NotificationModel>> listScheduledNotifications();

  /// Sets a new notification channel or updates an existing channel.
  ///
  /// The [notificationChannel] parameter is a [NotificationChannel] object that
  /// represents the channel to create or update.
  ///
  /// The optional [forceUpdate] parameter is a boolean value that determines
  /// whether to completely update the channel on Android Oreo and above, which
  /// requires cancelling all current notifications. If this parameter is set to
  /// `false`, the channel will be updated without force the update changing the
  /// channel key nor cancelling notifications.
  ///
  /// This method can be used to create or update notification channels for the
  /// app. On Android Oreo and above, updating a channel requires cancelling all
  /// current notifications associated with the channel. If the [forceUpdate]
  /// parameter is set to `true`, the channel will be updated using a new key
  /// managed by the plugin. This should only be used in emergency situations.
  Future<void> setChannel(
      NotificationChannel notificationChannel, {
        bool forceUpdate = false,
      });

  /// Removes a notification channel with the specified [channelKey].
  ///
  /// The [channelKey] parameter is a [String] that represents the unique key of
  /// the channel to remove.
  ///
  /// This method can be used to remove notification channels that are no longer
  /// needed by the app. Note that removing a channel also removes all
  /// notifications that were associated with the channel. If there are no
  /// notifications associated with the channel, the channel will be removed
  /// immediately. If there are notifications associated with the channel, they
  /// will be cancelled before the channel is removed.
  ///
  /// This method returns a [Future] that resolves to a boolean value indicating
  /// whether the channel was removed successfully. If the channel was removed
  /// successfully, the value will be `true`. If the channel was not found or
  /// could not be removed, the value will be `false`.
  Future<bool> removeChannel(String channelKey);

  /// Gets the global badge counter, which represents the number of unread
  /// notifications that are currently pending for the app.
  ///
  /// This method can be used to retrieve the current value of the app's badge
  /// counter, which can be displayed as a badge on the app's icon. Note that
  /// the badge counter is specific to the app and is not shared across devices.
  ///
  /// It's important to note that the behavior of the badge counter can vary
  /// across Android devices. For example, on Xiaomi devices, the badge counter
  /// is always the number of notifications displayed in the status bar. On
  /// Samsung devices, the badge counter is defined by the application, but is
  /// only displayed if there is at least one active notification in the status
  /// bar. However, the Awesome Notifications plugin handles these differences
  /// transparently, so the developer does not need to worry about them or handle
  /// them separately. Instead, the developer can treat the badge counter as it
  /// is done in iOS devices.
  ///
  /// This method returns a [Future] that resolves to an integer value indicating
  /// the current value of the app's badge counter. If there are no pending
  /// notifications, the value will be `0`.
  Future<int> getGlobalBadgeCounter();

  /// Sets the global badge counter to the specified value. This value will be
  /// displayed on the app's icon badge (if supported by the device). If the
  /// [amount] is 0, the badge counter will be cleared.
  ///
  /// ATTENTION: Developers should avoid mimicking increment and decrement functionality
  /// using this method and instead use [incrementGlobalBadgeCounter] and
  /// [decrementGlobalBadgeCounter], which are optimized for performance.
  ///
  /// Note that on some Android devices, such as those from Xiaomi or Samsung,
  /// the way badge counters are handled may be different from other devices
  /// and may not match the behavior on iOS devices. However, the Awesome
  /// Notifications plugin handles these differences automatically, so the
  /// developer should not need to worry about them.
  Future<void> setGlobalBadgeCounter(int amount);

  /// Increments the badge counter by 1 and returns the new value. If there is
  /// no current value for the badge counter, it will be set to 1. This method is
  /// the most performant way to increment the badge counter by a single unit.
  ///
  /// To increment the badge counter by a different value, the developer can get
  /// the current value of the counter with the [getGlobalBadgeCounter] method,
  /// add the desired amount, and then set the new value with the
  /// [setGlobalBadgeCounter] method.
  ///
  /// This method returns a [Future] that resolves to an [int] value
  /// representing the new value of the badge counter after it has been
  /// incremented.
  Future<int> incrementGlobalBadgeCounter();

  /// Decrements the global badge counter by 1.
  ///
  /// This method decrements the app's global badge counter by one. If the
  /// badge counter is already zero, this method has no effect. The updated
  /// badge counter value is returned as a [Future] that resolves to an [int].
  ///
  /// To decrement the badge counter by a different value, the developer can get
  /// the current value of the counter with the [getGlobalBadgeCounter] method,
  /// add the desired amount, and then set the new value with the
  /// [setGlobalBadgeCounter] method.
  ///
  /// This method returns a [Future] that resolves to an [int] value
  /// representing the new value of the badge counter after it has been
  /// decremented.
  Future<int> decrementGlobalBadgeCounter();

  /// Resets the global badge counter to zero. This removes any badge icon from
  /// the app icon in the launcher. Note that resetting the badge counter does
  /// not cancel any scheduled or active notifications.
  ///
  /// This method returns a [Future] that completes when the badge counter has
  /// been reset.
  Future<void> resetGlobalBadge();

  /// Gets the next valid date for a notification schedule. The [schedule]
  /// parameter is a valid [NotificationSchedule] model that specifies the
  /// notification schedule. The optional [fixedDate] parameter is a [DateTime]
  /// value that represents the reference date to simulate a schedule in a
  /// different time. If this parameter is omitted, the reference date will be
  /// set to the current date and time.
  ///
  /// This method returns a [Future] that resolves to a [DateTime] value that
  /// represents the next valid date for the notification schedule. If the
  /// notification schedule has expired or is invalid, the method will return
  /// `null`. If the notification schedule is a one-time event, the method will
  /// return the event's date and time. If the notification schedule is a
  /// repeating event, the method will return the next valid date and time for
  /// the event.
  Future<DateTime?> getNextDate(
    NotificationSchedule schedule, {
    DateTime? fixedDate,
  });

  /// The [setLocalization] method is used to set the desired localization for
  /// notifications. It takes a required [languageCode] parameter, which is an
  /// optional, case-insensitive [String] that represents the language code for
  /// the desired localization (e.g. "en" for English, "pt-br" for Brazilian
  /// Portuguese, "es" for Spanish, etc.). If the [languageCode] parameter is
  /// `null` or not provided, the default localization will be loaded from the
  /// device system.
  ///
  /// This method returns a [Future] that resolves to [true] if the localization
  /// was successfully set, or [false] if the localization could not be set for
  /// any reason (e.g. the specified language is not supported).
  ///
  /// The translation value for the title or  is defined on the parameter
  Future<bool> setLocalization({required String? languageCode});

  /// Gets the current localization code used by the plugin for notification content.
  ///
  /// This method returns a [Future] that resolves to a [String] representing
  /// the current localization code. The localization code is a two-letter language
  /// code (e.g. "en" for English, "pt" for Portuguese) or a language code combined
  /// with a region code (e.g. "pt-br" for Brazilian Portuguese). If no localization
  /// has been set, this method will return the system's default language code.
  Future<String> getLocalization();

  /// Returns the identifier for the UTC time zone.
  ///
  /// The identifier for the UTC time zone is a string in the format "Etc/GMT[+/-]hh:mm",
  /// where "[+/-]hh:mm" represents the time zone offset from UTC. For example, the
  /// identifier for the UTC time zone commonly is "UTC".
  ///
  /// This method returns a [Future] that resolves to a [String] value containing the
  /// UTC time zone identifier.
  Future<String> getUtcTimeZoneIdentifier();

  /// Returns the identifier for the device's local time zone.
  ///
  /// The identifier for a time zone is a string in the format "Area/Location", where
  /// "Area" is a continent or ocean name, and "Location" is a city or region within
  /// the area. For example, the identifier for the time zone of New York City is
  /// "America/New_York".
  ///
  /// This method returns a [Future] that resolves to a [String] value containing the
  /// identifier for the device's local time zone.
  Future<String> getLocalTimeZoneIdentifier();

  /// Returns the current state of the app lifecycle in regards to notifications.
  ///
  /// The returned value is an enumerator of type [NotificationLifeCycle]. The possible
  /// values are:
  ///
  /// - [NotificationLifeCycle.Foreground]: The app is currently in the foreground and actively
  ///   being used by the user.
  ///
  /// - [NotificationLifeCycle.Background]: The app is currently in the background and not
  ///   actively being used by the user, but still running.
  ///
  /// - [NotificationLifeCycle.AppKilled]: The app has been killed and is not running.
  ///
  /// This method returns a [Future] that resolves to a [NotificationLifeCycle] value
  /// representing the current state of the app in regards to notifications.
  Future<NotificationLifeCycle> getAppLifeCycle();

  /// Cancels a single notification and its respective schedule.
  ///
  /// The [id] parameter is an [int] that represents the unique identifier of
  /// the notification to cancel. This method cancels both the notification and
  /// its associated schedule.
  ///
  /// If the notification is already shown, it will be dismissed immediately.
  /// If the notification has not been shown yet but is scheduled to be shown in
  /// the future, the notification will be cancelled and the schedule will be
  /// removed.
  ///
  /// This method returns a [Future] that resolves to `void`.
  Future<void> cancel(int id);

  /// Dismisses a single notification without canceling its respective schedule.
  ///
  /// The [id] parameter is an [int] that represents the unique identifier of
  /// the notification to dismiss. This method dismisses the notification only,
  /// leaving its associated schedule intact.
  ///
  /// If the notification is currently shown, it will be dismissed immediately.
  /// If the notification is not currently shown, this method has no effect.
  ///
  /// This method returns a [Future] that resolves to `void`.
  Future<void> dismiss(int id);

  /// Cancels a single scheduled notification, without dismissing the active notification.
  ///
  /// The [id] parameter is an [int] that represents the unique identifier of
  /// the scheduled notification to cancel. This method cancels only the
  /// schedule associated with the notification, leaving the notification
  /// itself intact.
  ///
  /// If the notification has not been shown yet but is scheduled to be shown in
  /// the future, the schedule will be removed and the notification will not be
  /// shown. If the notification is already shown, this method has no effect on
  /// the currently active notification.
  ///
  /// This method returns a [Future] that resolves to `void`.
  Future<void> cancelSchedule(int id);

  /// Dismisses all active notifications with the specified [channelKey], without
  /// cancelling their respective schedules.
  ///
  /// The [channelKey] parameter is a [String] that represents the unique key of
  /// the channel that the notifications belong to.
  ///
  /// This method can be used to dismiss all active notifications that belong to
  /// a specific channel, without cancelling their respective schedules. Note that
  /// dismissing a notification does not remove it from the notification history.
  ///
  /// This method returns a [Future] that resolves when all active notifications
  /// with the specified channel key have been dismissed.
  Future<void> dismissNotificationsByChannelKey(String channelKey);

  /// Cancels all active schedules with the specified [channelKey], without
  /// dismissing the respective notifications.
  ///
  /// The [channelKey] parameter is a [String] that represents the unique key of
  /// the channel that the schedules belong to.
  ///
  /// This method can be used to cancel all active schedules that belong to
  /// a specific channel, without dismissing the respective notifications.
  ///
  /// This method returns a [Future] that resolves when all active schedules
  /// with the specified channel key have been cancelled.
  Future<void> cancelSchedulesByChannelKey(String channelKey);

  /// Cancels all active notifications and schedules with the specified [channelKey].
  ///
  /// The [channelKey] parameter is a [String] that represents the unique key of
  /// the channel that the notifications and schedules belong to.
  ///
  /// This method can be used to cancel all active notifications and schedules
  /// that belong to a specific channel.
  ///
  /// This method returns a [Future] that resolves when all active notifications
  /// and schedules with the specified channel key have been cancelled.
  Future<void> cancelNotificationsByChannelKey(String channelKey);

  /// Dismisses all active notifications with the specified [groupKey], without
  /// cancelling their respective schedules.
  ///
  /// The [groupKey] parameter is a [String] that represents the unique key of
  /// the group that the notifications belong to.
  ///
  /// This method can be used to dismiss all active notifications that belong to
  /// a specific group, without cancelling their respective schedules. Note that
  /// dismissing a notification does not remove it from the notification history.
  ///
  /// This method returns a [Future] that resolves when all active notifications
  /// with the specified group key have been dismissed.
  Future<void> dismissNotificationsByGroupKey(String groupKey);

  /// Cancels all active schedules with the specified [groupKey], without dismissing
  /// the respective notifications.
  ///
  /// The [groupKey] parameter is a [String] that represents the unique key of
  /// the group that the schedules belong to.
  ///
  /// This method can be used to cancel all active schedules that belong to
  /// a specific group, without dismissing the respective notifications.
  ///
  /// This method returns a [Future] that resolves when all active schedules
  /// with the specified group key have been cancelled.
  Future<void> cancelSchedulesByGroupKey(String groupKey);

  /// Cancels all active notifications and schedules with the specified [groupKey].
  ///
  /// The [groupKey] parameter is a [String] that represents the unique key of
  /// the group that the notifications and schedules belong to.
  ///
  /// This method can be used to cancel all active notifications and schedules
  /// that belong to a specific group.
  ///
  /// This method returns a [Future] that resolves when all active notifications
  /// and schedules with the specified [groupKey] have been cancelled.
  Future<void> cancelNotificationsByGroupKey(String groupKey);

  /// Dismisses all active notifications without cancelling their respective schedules.
  /// Note that dismissing a notification does not remove it from the notification history.
  ///
  /// This method returns a [Future] that resolves when all active notifications
  /// with the specified group key have been dismissed.
  Future<void> dismissAllNotifications();

  /// Cancels all active schedules, without dismissing the respective notifications.
  ///
  /// This method returns a [Future] that resolves when all active schedules
  /// with the specified group key have been cancelled.
  Future<void> cancelAllSchedules();

  /// Cancels all active notifications and schedules.
  ///
  /// This method returns a [Future] that resolves when all active notifications
  /// and schedules have been cancelled.
  Future<void> cancelAll();
}
