/// Constants for requesting authorization to interact with the user thought notifications
/// [Alert] The ability to display alerts.
/// [Sound] The ability to display alerts.
/// [Badge] The ability to play sounds.
/// [CriticalAlert] The ability to play sounds for critical alerts.
/// [Provisional] The ability to post noninterrupting notifications provisionally to the Notification Center.
/// [Car] The ability to display notifications in a CarPlay environment.
enum NotificationPermission {
  /// [Alert] The ability to display alerts.
  Alert,
  /// [Sound] The ability to display alerts.
  Sound,
  /// [Badge] The ability to play sounds.
  Badge,
  /// [CriticalAlert] The ability to play sounds for critical alerts.
  CriticalAlert,
  /// [Provisional] The ability to post noninterrupting notifications provisionally to the Notification Center.
  Provisional,
  /// [Car] The ability to display notifications in a CarPlay environment.
  Car
}