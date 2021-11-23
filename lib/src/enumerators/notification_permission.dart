/// Constants for requesting authorization to interact with the user thought notifications
/// [Alert] Alerts are notifications with high priority that pops up on the user screen. Notifications with normal priority only shows the icon on status bar.
/// [Sound] Sound allows the ability to play sounds for new displayed notifications. The notification sounds are limited to a few seconds and if you pretend to play a sound for more time, you must consider to play a background sound to do it simultaneously with the notification.
/// [Badge] Badge is the ability to display a badge alert over the app icon to alert the user about updates. The badges can be displayed on numbers or small dots, depending of platform or what the user defined in the device settings. Both Android and iOS can show numbers on badge, depending of its version and distribution.
/// [Light] The ability to display colorful small lights, blanking on the device while the screen is off to alert the user about updates. Only a few Android devices have this feature.
/// [Vibration] The ability to vibrate the device to alert the user about updates.
/// [PreciseAlarms] Precise alarms allows the scheduled notifications to be displayed at the expected time. This permission can be revoke by special device modes, such as baterry save mode, etc. Some manufactures can disable this feature if they decide that your app is consumpting many computational resources and decressing the baterry life (and without changing the permission status for your app). So, you must take in consideration that some schedules can be delayed or even not being displayed, depending of what platform are you running. You can increase the chances to display the notification at correct time, enable this permission and setting the correct notification category, but you never gonna have 100% sure about it.
/// [FullScreenIntent] The ability to show the notifications on pop up even if the user is using another app.
/// [CriticalAlert] Critical alerts is a special permission that allows to play sounds and vibrate for new notifications displayed, even if the device is in Do Not Disturbe / Silent mode. For iOS, you must request Apple a authorization to your app use it.
/// [OverrideDnD] Override DnD allows the notification to decrease the Do Not Disturbe / Silent mode level enable to display critical alerts for Alarm and Call notifications. For Android, you must require the user consent to use it. For iOS, this permission is always enabled with CriticalAlert.
/// [Provisional] (Only has effect on iOS) The ability to display notifications temporarially without the user consent.
/// [Car] The ability to display notifications while the device is in car mode.
enum NotificationPermission {
  /// [Alert] Alerts are notifications with high priority that pops up on the user screen. Notifications with normal priority only shows the icon on status bar.
  Alert,

  /// [Sound] Sound allows the ability to play sounds for new displayed notifications. The notification sounds are limited to a few seconds and if you pretend to play a sound for more time, you must consider to play a background sound to do it simultaneously with the notification.
  Sound,

  /// [Badge] Badge is the ability to display a badge alert over the app icon to alert the user about updates. The badges can be displayed on numbers or small dots, depending of platform or what the user defined in the device settings. Both Android and iOS can show numbers on badge, depending of its version and distribution.
  Badge,

  /// [Light] The ability to display colorful small lights, blanking on the device while the screen is off to alert the user about updates. Only a few Android devices have this feature.
  Light,

  /// [Vibration] The ability to vibrate the device to alert the user about updates.
  Vibration,

  /// [FullScreenIntent] The ability to show the notifications on pop up even if the user is using another app.
  FullScreenIntent,

  /// [PreciseAlarms] Precise alarms allows the scheduled notifications to be displayed at the expected time. This permission can be revoke by special device modes, such as baterry save mode, etc. Some manufactures can disable this feature if they decide that your app is consumpting many computational resources and decressing the baterry life (and without changing the permission status for your app). So, you must take in consideration that some schedules can be delayed or even not being displayed, depending of what platform are you running. You can increase the chances to display the notification at correct time, enable this permission and setting the correct notification category, but you never gonna have 100% sure about it.
  PreciseAlarms,

  /// [CriticalAlert] Critical alerts is a special permission that allows to play sounds and vibrate for new notifications displayed, even if the device is in Do Not Disturbe / Silent mode. For iOS, you must request Apple a authorization to your app use it.
  CriticalAlert,

  /// [OverrideDnD] Override DnD allows the notification to decrease the Do Not Disturbe / Silent mode level enable to display critical alerts for Alarm and Call notifications. For Android, you must require the user consent to use it. For iOS, this permission is always enabled with CriticalAlert.
  OverrideDnD,

  /// [Provisional] (Only has effect on iOS) The ability to display notifications temporarially without the user consent.
  Provisional,

  /// [Car] The ability to display notifications while the device is in car mode.
  Car
}
