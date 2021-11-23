/// Constants for requesting authorization to interact with the user thought notifications
/// [Alert] The ability to display alerts.
/// [Sound] The ability to display alerts.
/// [Badge] The ability to display badge alerts.
/// [Light] The ability to show alert with lights.
/// [Vibration] The ability to vibrate the device.
/// [PreciseAlarms] The ability to schedule notifications with precise alarms (require special permissions)
/// [FullScreenIntent] The ability to display notifications in fullscreen.
/// [CriticalAlert] Critical alerts ignore the mute switch and Do Not Disturb; the system plays a critical alert's sound regardless of the device's mute or Do Not Disturb settings. You can specify a custom sound and volume.
/// Critical alerts require a special entitlement issued by Apple and Android.
/// [Provisional] The ability to post noninterrupting notifications provisionally to the Notification Center.
/// [Car] The ability to display notifications in a CarPlay environment.
enum NotificationPermission {
  /// [Alert] The ability to display alerts.
  Alert,

  /// [Sound] The ability to play sounds on notifications.
  Sound,

  /// [Badge] The ability to display badge alerts.
  Badge,

  /// [Light] The ability to show alert with lights.
  Light,

  /// [Vibration] The ability to vibrate the device.
  Vibration,

  /// [FullScreenIntent] The ability to display notifications in fullscreen.
  FullScreenIntent,

  /// [PreciseAlarms] The ability to schedule notifications with precise alarms (require special permissions)
  PreciseAlarms,

  /// [CriticalAlert] The ability to play sounds for critical alerts.
  CriticalAlert,

  /// [OverrideDnD] The ability to deactivate DnD when needs to show critical alerts.
  OverrideDnD,

  /// [Provisional] The ability to post noninterrupting notifications provisionally to the Notification Center.
  Provisional,

  /// [Car] The ability to display notifications in a CarPlay environment.
  Car
}
